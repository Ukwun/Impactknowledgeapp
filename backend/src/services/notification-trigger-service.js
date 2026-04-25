const { query } = require('../database');

const FCM_ENDPOINT = 'https://fcm.googleapis.com/fcm/send';

class NotificationTriggerService {
  static async notifyUser({
    userId,
    title,
    message,
    type = 'info',
    actionUrl = null,
    metadata = {},
    push = true,
  }) {
    if (!userId || !title || !message) return;

    await query(
      `INSERT INTO notifications (user_id, title, message, type, action_url, metadata)
       VALUES ($1, $2, $3, $4, $5, $6)`,
      [userId, title, message, type, actionUrl, JSON.stringify(metadata || {})]
    );

    if (!push) return;

    try {
      const userResult = await query(
        'SELECT fcm_token FROM users WHERE id = $1 LIMIT 1',
        [userId]
      );
      const token = userResult.rows[0]?.fcm_token;
      const serverKey = process.env.FIREBASE_SERVER_KEY;

      if (!token || !serverKey) return;

      await fetch(FCM_ENDPOINT, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `key=${serverKey}`,
        },
        body: JSON.stringify({
          to: token,
          priority: 'high',
          notification: {
            title,
            body: message,
          },
          data: {
            type,
            action: metadata?.action || type,
            resource_id: metadata?.resourceId?.toString() || '',
          },
        }),
      }).catch(() => {});
    } catch (_) {
      // Keep notification pipeline non-blocking.
    }
  }

  static async notifyMany({
    userIds,
    title,
    message,
    type = 'info',
    actionUrl = null,
    metadata = {},
    push = false,
  }) {
    if (!Array.isArray(userIds) || userIds.length === 0) return;

    await Promise.all(
      userIds.map((userId) =>
        this.notifyUser({
          userId,
          title,
          message,
          type,
          actionUrl,
          metadata,
          push,
        })
      )
    );
  }

  static async notifyAllActiveUsers({
    title,
    message,
    type = 'announcement',
    actionUrl = null,
    metadata = {},
    push = false,
  }) {
    const users = await query(
      `SELECT id
       FROM users
       WHERE is_active = true`
    );

    const userIds = users.rows.map((u) => u.id).filter(Boolean);
    if (userIds.length === 0) return;

    await this.notifyMany({
      userIds,
      title,
      message,
      type,
      actionUrl,
      metadata,
      push,
    });
  }
}

module.exports = NotificationTriggerService;
