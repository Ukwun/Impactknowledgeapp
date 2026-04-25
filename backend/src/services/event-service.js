const { query } = require('../database');
const ActivityService = require('./activity-service');

class EventService {
  /**
   * Create a new event
   */
  static async createEvent(eventData, userId, req) {
    try {
      const {
        title,
        description,
        eventType,
        startDate,
        endDate,
        location,
        capacity,
        thumbnailUrl,
      } = eventData;

      const result = await query(
        `INSERT INTO events 
        (title, description, event_type, start_date, end_date, location, 
         capacity, thumbnail_url, created_by) 
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9) 
        RETURNING *`,
        [
          title,
          description,
          eventType,
          startDate,
          endDate || null,
          location,
          capacity || null,
          thumbnailUrl || null,
          userId,
        ]
      );

      await ActivityService.logActivity(
        userId,
        'EVENT_CREATED',
        'event',
        result.rows[0].id,
        { title, eventType },
        req
      );

      return { success: true, data: result.rows[0] };
    } catch (err) {
      return { success: false, error: err.message };
    }
  }

  /**
   * Get event by ID with registration details
   */
  static async getEvent(eventId, userId = null) {
    try {
      const eventResult = await query(
        'SELECT * FROM events WHERE id = $1',
        [eventId]
      );

      if (eventResult.rows.length === 0) {
        throw new Error('Event not found');
      }

      const event = eventResult.rows[0];

      // Get registration count
      const regCountResult = await query(
        'SELECT COUNT(*) as count FROM event_registrations WHERE event_id = $1',
        [eventId]
      );
      event.registrations_count = parseInt(regCountResult.rows[0].count);

      // Get capacity percentage
      if (event.capacity) {
        event.capacity_percentage = Math.round(
          (event.registrations_count / event.capacity) * 100
        );
      }

      // If user is specified, get their registration status
      if (userId) {
        const userRegResult = await query(
          'SELECT * FROM event_registrations WHERE event_id = $1 AND user_id = $2',
          [eventId, userId]
        );
        event.user_registration = userRegResult.rows[0] || null;
      }

      return { success: true, data: event };
    } catch (err) {
      return { success: false, error: err.message };
    }
  }

  /**
   * List events with filtering
   */
  static async listEvents(filters = {}) {
    try {
      const {
        eventType,
        status = 'scheduled',
        upcomingOnly = false,
        page = 1,
        limit = 20,
      } = filters;

      const offset = (page - 1) * limit;
      let whereConditions = ['is_published = true'];
      const params = [];
      let paramCount = 1;

      if (eventType) {
        whereConditions.push(`event_type = $${paramCount}`);
        params.push(eventType);
        paramCount++;
      }

      if (status) {
        whereConditions.push(`status = $${paramCount}`);
        params.push(status);
        paramCount++;
      }

      if (upcomingOnly) {
        whereConditions.push('start_date >= CURRENT_TIMESTAMP');
      }

      params.push(limit);
      params.push(offset);

      const countResult = await query(
        `SELECT COUNT(*) as total FROM events WHERE ${whereConditions.join(' AND ')}`
      );

      const result = await query(
        `SELECT e.*, 
                COUNT(DISTINCT er.user_id) as registrations_count
         FROM events e
         LEFT JOIN event_registrations er ON e.id = er.event_id
         WHERE ${whereConditions.join(' AND ')}
         GROUP BY e.id
         ORDER BY e.start_date ASC
         LIMIT $${paramCount} OFFSET $${paramCount + 1}`,
        [...params.slice(0, paramCount - 2), limit, offset]
      );

      return {
        success: true,
        data: result.rows,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total: parseInt(countResult.rows[0].total),
        },
      };
    } catch (err) {
      return { success: false, error: err.message };
    }
  }

  /**
   * Update event
   */
  static async updateEvent(eventId, updates, userId, req) {
    try {
      const event = await query(
        'SELECT created_by FROM events WHERE id = $1',
        [eventId]
      );

      if (event.rows.length === 0) {
        throw new Error('Event not found');
      }

      if (event.rows[0].created_by !== userId) {
        throw new Error('Unauthorized: You did not create this event');
      }

      const fields = [];
      const values = [];
      let paramCount = 1;

      const allowedFields = [
        'title',
        'description',
        'event_type',
        'start_date',
        'end_date',
        'location',
        'capacity',
        'thumbnail_url',
        'status',
        'is_published',
      ];

      Object.keys(updates).forEach((key) => {
        if (allowedFields.includes(key)) {
          fields.push(`${key} = $${paramCount}`);
          values.push(updates[key]);
          paramCount++;
        }
      });

      if (fields.length === 0) {
        return { success: false, error: 'No valid fields to update' };
      }

      values.push(eventId);
      fields.push('updated_at = CURRENT_TIMESTAMP');

      const result = await query(
        `UPDATE events SET ${fields.join(', ')} WHERE id = $${paramCount} RETURNING *`,
        values
      );

      await ActivityService.logActivity(
        userId,
        'EVENT_UPDATED',
        'event',
        eventId,
        { updates },
        req
      );

      return { success: true, data: result.rows[0] };
    } catch (err) {
      return { success: false, error: err.message };
    }
  }

  /**
   * Delete event
   */
  static async deleteEvent(eventId, userId, req) {
    try {
      const event = await query(
        'SELECT created_by FROM events WHERE id = $1',
        [eventId]
      );

      if (event.rows.length === 0) {
        throw new Error('Event not found');
      }

      if (event.rows[0].created_by !== userId) {
        throw new Error('Unauthorized: You did not create this event');
      }

      await query('DELETE FROM events WHERE id = $1', [eventId]);

      await ActivityService.logActivity(
        userId,
        'EVENT_DELETED',
        'event',
        eventId,
        {},
        req
      );

      return { success: true, data: { id: eventId } };
    } catch (err) {
      return { success: false, error: err.message };
    }
  }

  /**
   * Register user for event
   */
  static async registerForEvent(eventId, userId, req) {
    try {
      // Check if event exists and has capacity
      const eventResult = await query(
        'SELECT capacity FROM events WHERE id = $1',
        [eventId]
      );

      if (eventResult.rows.length === 0) {
        throw new Error('Event not found');
      }

      const event = eventResult.rows[0];

      // Check capacity
      if (event.capacity) {
        const regCountResult = await query(
          'SELECT COUNT(*) as count FROM event_registrations WHERE event_id = $1',
          [eventId]
        );

        if (regCountResult.rows[0].count >= event.capacity) {
          throw new Error('Event is at full capacity');
        }
      }

      // Check if already registered
      const existingReg = await query(
        'SELECT id FROM event_registrations WHERE event_id = $1 AND user_id = $2',
        [eventId, userId]
      );

      if (existingReg.rows.length > 0) {
        throw new Error('Already registered for this event');
      }

      // Create registration
      const result = await query(
        `INSERT INTO event_registrations (event_id, user_id)
         VALUES ($1, $2)
         RETURNING *`,
        [eventId, userId]
      );

      await ActivityService.logActivity(
        userId,
        'EVENT_REGISTERED',
        'event',
        eventId,
        {},
        req
      );

      return { success: true, data: result.rows[0] };
    } catch (err) {
      return { success: false, error: err.message };
    }
  }

  /**
   * Unregister from event
   */
  static async unregisterFromEvent(eventId, userId, req) {
    try {
      const result = await query(
        'DELETE FROM event_registrations WHERE event_id = $1 AND user_id = $2 RETURNING *',
        [eventId, userId]
      );

      if (result.rows.length === 0) {
        throw new Error('Registration not found');
      }

      await ActivityService.logActivity(
        userId,
        'EVENT_UNREGISTERED',
        'event',
        eventId,
        {},
        req
      );

      return { success: true, data: { message: 'Unregistered from event' } };
    } catch (err) {
      return { success: false, error: err.message };
    }
  }

  /**
   * Get event attendees (event creator only)
   */
  static async getEventAttendees(eventId, userId) {
    try {
      // Verify user created the event
      const eventCheck = await query(
        'SELECT created_by FROM events WHERE id = $1',
        [eventId]
      );

      if (eventCheck.rows.length === 0) {
        throw new Error('Event not found');
      }

      if (eventCheck.rows[0].created_by !== userId) {
        throw new Error('Unauthorized');
      }

      const result = await query(
        `SELECT er.*, u.full_name, u.email, u.profile_picture_url
         FROM event_registrations er
         JOIN users u ON er.user_id = u.id
         WHERE er.event_id = $1
         ORDER BY er.registration_date DESC`,
        [eventId]
      );

      return { success: true, data: result.rows };
    } catch (err) {
      return { success: false, error: err.message };
    }
  }

  /**
   * Get event analytics (event creator/admin view)
   */
  static async getEventAnalytics(eventId, userId) {
    try {
      const eventCheck = await query(
        'SELECT created_by FROM events WHERE id = $1',
        [eventId]
      );

      if (eventCheck.rows.length === 0) {
        throw new Error('Event not found');
      }

      if (eventCheck.rows[0].created_by !== userId) {
        throw new Error('Unauthorized');
      }

      const result = await query(
        `SELECT
           e.id,
           e.title,
           e.capacity,
           COUNT(er.id) as registrations_count,
           COUNT(CASE WHEN er.attendance_status = 'attended' THEN 1 END) as attended_count,
           COUNT(CASE WHEN er.attendance_status = 'registered' THEN 1 END) as registered_count
         FROM events e
         LEFT JOIN event_registrations er ON er.event_id = e.id
         WHERE e.id = $1
         GROUP BY e.id`,
        [eventId]
      );

      return { success: true, data: result.rows[0] || {} };
    } catch (err) {
      return { success: false, error: err.message };
    }
  }

  /**
   * Get user's registered events
   */
  static async getUserEvents(userId) {
    try {
      const result = await query(
        `SELECT e.*, COUNT(DISTINCT er.user_id) as registrations_count
         FROM events e
         INNER JOIN event_registrations er ON e.id = er.event_id
         WHERE er.user_id = $1 AND e.is_published = true
         GROUP BY e.id
         ORDER BY e.start_date ASC`,
        [userId]
      );

      return { success: true, data: result.rows };
    } catch (err) {
      return { success: false, error: err.message };
    }
  }

  /**
   * Mark attendance status
   */
  static async markAttendance(eventId, userId, attendanceStatus, req) {
    try {
      const result = await query(
        `UPDATE event_registrations 
         SET attendance_status = $1
         WHERE event_id = $2 AND user_id = $3
         RETURNING *`,
        [attendanceStatus, eventId, userId]
      );

      if (result.rows.length === 0) {
        throw new Error('Registration not found');
      }

      await ActivityService.logActivity(
        userId,
        'ATTENDANCE_MARKED',
        'event',
        eventId,
        { status: attendanceStatus },
        req
      );

      return { success: true, data: result.rows[0] };
    } catch (err) {
      return { success: false, error: err.message };
    }
  }
}

module.exports = EventService;
