const express = require('express');
const { query } = require('../database');
const { verifyToken } = require('../middleware/auth');

const router = express.Router();

const allowedNamespaces = new Set(['mentor', 'circle_member', 'progress']);

function normalizeNamespace(raw) {
  return (raw || '').toString().trim().toLowerCase().replace('-', '_');
}

router.get('/:namespace', verifyToken, async (req, res) => {
  try {
    const namespace = normalizeNamespace(req.params.namespace);
    if (!allowedNamespaces.has(namespace)) {
      return res.status(400).json({ success: false, error: 'Invalid namespace' });
    }

    const includeAll =
      req.user.role === 'admin' ||
      (namespace === 'circle_member' && req.query.scope === 'all');
    const params = [namespace];
    let sql = `
      SELECT id, namespace, owner_user_id, title, description, status, metadata, created_at, updated_at
      FROM role_resources
      WHERE namespace = $1
    `;

    if (!includeAll) {
      sql += ' AND owner_user_id = $2';
      params.push(req.user.id);
    }

    sql += ' ORDER BY updated_at DESC';

    const result = await query(sql, params);
    res.json({ success: true, data: result.rows });
  } catch (err) {
    console.error('Role resources list error:', err);
    res.status(500).json({ success: false, error: 'Failed to fetch resources' });
  }
});

router.post('/:namespace', verifyToken, async (req, res) => {
  try {
    const namespace = normalizeNamespace(req.params.namespace);
    if (!allowedNamespaces.has(namespace)) {
      return res.status(400).json({ success: false, error: 'Invalid namespace' });
    }

    const { title, description, status = 'active', metadata = {} } = req.body;
    if (!title || !title.toString().trim()) {
      return res.status(400).json({ success: false, error: 'title is required' });
    }

    const created = await query(
      `INSERT INTO role_resources
        (namespace, owner_user_id, title, description, status, metadata)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING id, namespace, owner_user_id, title, description, status, metadata, created_at, updated_at`,
      [namespace, req.user.id, title.toString().trim(), description || null, status, JSON.stringify(metadata)]
    );

    res.status(201).json({ success: true, data: created.rows[0] });
  } catch (err) {
    console.error('Role resources create error:', err);
    res.status(500).json({ success: false, error: 'Failed to create resource' });
  }
});

router.put('/:namespace/:id', verifyToken, async (req, res) => {
  try {
    const namespace = normalizeNamespace(req.params.namespace);
    const id = parseInt(req.params.id, 10);
    if (!allowedNamespaces.has(namespace)) {
      return res.status(400).json({ success: false, error: 'Invalid namespace' });
    }

    const existing = await query(
      `SELECT owner_user_id FROM role_resources WHERE id = $1 AND namespace = $2`,
      [id, namespace]
    );

    if (existing.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Resource not found' });
    }

    const canEdit = existing.rows[0].owner_user_id === req.user.id || req.user.role === 'admin';
    if (!canEdit) {
      return res.status(403).json({ success: false, error: 'Unauthorized' });
    }

    const { title, description, status, metadata } = req.body;
    const updated = await query(
      `UPDATE role_resources
       SET title = COALESCE($3, title),
           description = COALESCE($4, description),
           status = COALESCE($5, status),
           metadata = COALESCE($6, metadata),
           updated_at = NOW()
       WHERE id = $1 AND namespace = $2
       RETURNING id, namespace, owner_user_id, title, description, status, metadata, created_at, updated_at`,
      [id, namespace, title, description, status, metadata ? JSON.stringify(metadata) : null]
    );

    res.json({ success: true, data: updated.rows[0] });
  } catch (err) {
    console.error('Role resources update error:', err);
    res.status(500).json({ success: false, error: 'Failed to update resource' });
  }
});

router.delete('/:namespace/:id', verifyToken, async (req, res) => {
  try {
    const namespace = normalizeNamespace(req.params.namespace);
    const id = parseInt(req.params.id, 10);
    if (!allowedNamespaces.has(namespace)) {
      return res.status(400).json({ success: false, error: 'Invalid namespace' });
    }

    const existing = await query(
      `SELECT owner_user_id FROM role_resources WHERE id = $1 AND namespace = $2`,
      [id, namespace]
    );

    if (existing.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Resource not found' });
    }

    const canDelete = existing.rows[0].owner_user_id === req.user.id || req.user.role === 'admin';
    if (!canDelete) {
      return res.status(403).json({ success: false, error: 'Unauthorized' });
    }

    await query('DELETE FROM role_resources WHERE id = $1', [id]);
    res.json({ success: true, message: 'Resource deleted' });
  } catch (err) {
    console.error('Role resources delete error:', err);
    res.status(500).json({ success: false, error: 'Failed to delete resource' });
  }
});

module.exports = router;
