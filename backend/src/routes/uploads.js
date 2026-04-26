const express = require('express');
const { v4: uuidv4 } = require('uuid');
const { v2: cloudinary } = require('cloudinary');
const { query } = require('../database');
const { verifyToken, requireRoles } = require('../middleware/auth');
const { uploadLimiter } = require('../middleware/rateLimiter');
const AuditService = require('../services/audit-service');

const router = express.Router();

const MAX_PDF_BYTES = 20 * 1024 * 1024;
const MAX_IMAGE_BYTES = 15 * 1024 * 1024;
const MAX_VIDEO_BYTES = 250 * 1024 * 1024;

const allowedMimeGroups = {
  pdf: ['application/pdf'],
  image: ['image/jpeg', 'image/png', 'image/webp'],
  video: ['video/mp4', 'video/quicktime', 'video/x-matroska'],
};

const facilitatorRoles = [
  'admin',
  'facilitator',
  'instructor',
  'school_admin',
  'mentor',
];

cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
  secure: true,
});

function resolveMediaKind(mimeType) {
  if (allowedMimeGroups.pdf.includes(mimeType)) return 'pdf';
  if (allowedMimeGroups.image.includes(mimeType)) return 'image';
  if (allowedMimeGroups.video.includes(mimeType)) return 'video';
  return null;
}

function validateUploadPolicy({ mimeType, byteSize }) {
  const mediaKind = resolveMediaKind(mimeType);
  if (!mediaKind) {
    return { ok: false, error: 'Unsupported file type. Only PDF, image, and video are allowed.' };
  }

  if (mediaKind === 'pdf' && byteSize > MAX_PDF_BYTES) {
    return { ok: false, error: 'PDF exceeds 20MB size policy.' };
  }
  if (mediaKind === 'image' && byteSize > MAX_IMAGE_BYTES) {
    return { ok: false, error: 'Image exceeds 15MB size policy.' };
  }
  if (mediaKind === 'video' && byteSize > MAX_VIDEO_BYTES) {
    return { ok: false, error: 'Video exceeds 250MB size policy.' };
  }

  return { ok: true, mediaKind };
}

router.post('/sign', verifyToken, requireRoles(...facilitatorRoles), uploadLimiter, async (req, res) => {
  try {
    const {
      fileName,
      mimeType,
      byteSize,
      accessScope = 'private',
      purpose = 'course_asset',
    } = req.body || {};

    if (!fileName || !mimeType || !byteSize) {
      return res.status(400).json({
        success: false,
        error: 'fileName, mimeType, and byteSize are required.',
      });
    }

    const fileSize = Number(byteSize);
    if (!Number.isFinite(fileSize) || fileSize <= 0) {
      return res.status(400).json({ success: false, error: 'byteSize must be a positive number.' });
    }

    const policy = validateUploadPolicy({ mimeType: String(mimeType), byteSize: fileSize });
    if (!policy.ok) {
      return res.status(400).json({ success: false, error: policy.error });
    }

    if (!process.env.CLOUDINARY_CLOUD_NAME || !process.env.CLOUDINARY_API_KEY || !process.env.CLOUDINARY_API_SECRET) {
      return res.status(500).json({
        success: false,
        error: 'Cloud upload service is not configured.',
      });
    }

    const mediaKind = policy.mediaKind;
    const publicId = `impactknowledge/${req.user.id}/${Date.now()}_${uuidv4()}`;
    const folder = `impactknowledge/${mediaKind}`;
    const resourceType = mediaKind === 'video' ? 'video' : 'auto';
    const timestamp = Math.floor(Date.now() / 1000);

    const paramsToSign = {
      folder,
      public_id: publicId,
      resource_type: resourceType,
      timestamp,
    };

    const signature = cloudinary.utils.api_sign_request(
      paramsToSign,
      process.env.CLOUDINARY_API_SECRET
    );

    const insert = await query(
      `INSERT INTO media_assets (
        owner_id,
        file_name,
        mime_type,
        byte_size,
        storage_path,
        access_scope,
        scan_status,
        transcoding_status,
        metadata
      ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)
      RETURNING id, created_at`,
      [
        req.user.id,
        String(fileName),
        String(mimeType),
        fileSize,
        publicId,
        String(accessScope),
        'pending_scan',
        mediaKind === 'video' ? 'queued' : null,
        JSON.stringify({ purpose, mediaKind }),
      ]
    );

    const asset = insert.rows[0];

    await AuditService.log({
      actorId: req.user.id,
      actorRole: req.user.role,
      action: 'UPLOAD_SIGN_REQUESTED',
      entityType: 'media_asset',
      entityId: String(asset.id),
      metadata: { mediaKind, mimeType, byteSize: fileSize, accessScope },
      req,
    });

    return res.json({
      success: true,
      data: {
        assetId: asset.id,
        upload: {
          cloudName: process.env.CLOUDINARY_CLOUD_NAME,
          apiKey: process.env.CLOUDINARY_API_KEY,
          timestamp,
          folder,
          publicId,
          resourceType,
          signature,
          uploadUrl: `https://api.cloudinary.com/v1_1/${process.env.CLOUDINARY_CLOUD_NAME}/${resourceType}/upload`,
        },
        policy: {
          malwareScan: 'required_before_publish',
          maxSizeBytes: mediaKind === 'pdf' ? MAX_PDF_BYTES : mediaKind === 'image' ? MAX_IMAGE_BYTES : MAX_VIDEO_BYTES,
        },
      },
    });
  } catch (err) {
    console.error('Sign upload error:', err);
    return res.status(500).json({ success: false, error: 'Failed to create upload signature.' });
  }
});

router.post('/complete', verifyToken, requireRoles(...facilitatorRoles), async (req, res) => {
  try {
    const {
      assetId,
      secureUrl,
      uploadedBytes,
      format,
      duration,
      width,
      height,
      virusScanStatus = 'clean',
    } = req.body || {};

    if (!assetId || !secureUrl) {
      return res.status(400).json({ success: false, error: 'assetId and secureUrl are required.' });
    }

    const assetResult = await query(
      'SELECT * FROM media_assets WHERE id = $1 AND owner_id = $2 LIMIT 1',
      [assetId, req.user.id]
    );

    if (!assetResult.rows.length) {
      return res.status(404).json({ success: false, error: 'Media asset record not found.' });
    }

    if (virusScanStatus !== 'clean') {
      await query(
        `UPDATE media_assets
         SET scan_status = 'quarantined',
             metadata = COALESCE(metadata, '{}'::jsonb) || $2::jsonb,
             updated_at = NOW()
         WHERE id = $1`,
        [assetId, JSON.stringify({ virusScanStatus })]
      );

      return res.status(422).json({
        success: false,
        error: 'Upload failed malware safety checks. Asset quarantined.',
      });
    }

    const source = assetResult.rows[0];
    const metadataPatch = {
      secureUrl,
      uploadedBytes,
      format,
      duration,
      width,
      height,
      virusScanStatus,
    };

    const thumbnailPath = source.mime_type?.startsWith('video/')
      ? secureUrl.replace('/upload/', '/upload/so_2,w_640,h_360,c_fill/')
      : null;

    const updated = await query(
      `UPDATE media_assets
       SET scan_status = 'clean',
           transcoding_status = CASE
             WHEN mime_type LIKE 'video/%' THEN 'processing'
             ELSE transcoding_status
           END,
           thumbnail_path = COALESCE($2, thumbnail_path),
           metadata = COALESCE(metadata, '{}'::jsonb) || $3::jsonb,
           updated_at = NOW()
       WHERE id = $1
       RETURNING id, owner_id, file_name, mime_type, access_scope, scan_status, transcoding_status, thumbnail_path, metadata, created_at`,
      [assetId, thumbnailPath, JSON.stringify(metadataPatch)]
    );

    await AuditService.log({
      actorId: req.user.id,
      actorRole: req.user.role,
      action: 'UPLOAD_COMPLETED',
      entityType: 'media_asset',
      entityId: String(assetId),
      metadata: { virusScanStatus, secureUrl },
      req,
    });

    return res.json({ success: true, data: updated.rows[0] });
  } catch (err) {
    console.error('Complete upload error:', err);
    return res.status(500).json({ success: false, error: 'Failed to finalize upload.' });
  }
});

router.get('/:assetId/access', verifyToken, async (req, res) => {
  try {
    const assetId = Number(req.params.assetId);
    if (!Number.isFinite(assetId)) {
      return res.status(400).json({ success: false, error: 'Invalid asset id.' });
    }

    const result = await query('SELECT * FROM media_assets WHERE id = $1 LIMIT 1', [assetId]);
    if (!result.rows.length) {
      return res.status(404).json({ success: false, error: 'Asset not found.' });
    }

    const asset = result.rows[0];
    const isOwner = asset.owner_id === req.user.id;
    const isPrivileged = facilitatorRoles.includes(req.user.role);

    if (asset.access_scope !== 'public' && !isOwner && !isPrivileged) {
      return res.status(403).json({ success: false, error: 'Access denied.' });
    }

    const secureUrl = asset.metadata?.secureUrl || null;

    await AuditService.log({
      actorId: req.user.id,
      actorRole: req.user.role,
      action: 'UPLOAD_ACCESS_GRANTED',
      entityType: 'media_asset',
      entityId: String(assetId),
      metadata: { accessScope: asset.access_scope },
      req,
    });

    return res.json({
      success: true,
      data: {
        id: asset.id,
        fileName: asset.file_name,
        mimeType: asset.mime_type,
        accessScope: asset.access_scope,
        secureUrl,
        thumbnailUrl: asset.thumbnail_path,
        scanStatus: asset.scan_status,
        transcodingStatus: asset.transcoding_status,
      },
    });
  } catch (err) {
    console.error('Asset access error:', err);
    return res.status(500).json({ success: false, error: 'Failed to fetch asset access URL.' });
  }
});

module.exports = router;
