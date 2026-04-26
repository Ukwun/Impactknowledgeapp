const { query } = require('../database');

class AuditService {
  static async log({
    actorId = null,
    actorRole = null,
    action,
    entityType = null,
    entityId = null,
    metadata = {},
    req = null,
  }) {
    if (!action) return;

    const ipAddress =
      req?.headers?.['x-forwarded-for']?.toString().split(',')[0]?.trim() ||
      req?.ip ||
      null;
    const userAgent = req?.headers?.['user-agent'] || null;

    await query(
      `INSERT INTO audit_logs (
        actor_id,
        actor_role,
        action,
        entity_type,
        entity_id,
        ip_address,
        user_agent,
        metadata
      ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8)`,
      [
        actorId,
        actorRole,
        action,
        entityType,
        entityId,
        ipAddress,
        userAgent,
        JSON.stringify(metadata || {}),
      ]
    );
  }
}

module.exports = AuditService;
