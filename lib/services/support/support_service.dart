import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../api/api_service.dart';

class SupportTicket {
  final int id;
  final String category;
  final String subject;
  final String status;
  final String priority;
  final DateTime createdAt;
  final DateTime? updatedAt;

  SupportTicket({
    required this.id,
    required this.category,
    required this.subject,
    required this.status,
    required this.priority,
    required this.createdAt,
    this.updatedAt,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id: json['id'],
      category: json['category'],
      subject: json['subject'],
      status: json['status'],
      priority: json['priority'] ?? 'normal',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }
}

class SupportMessage {
  final int id;
  final int senderId;
  final String message;
  final String? senderName;
  final String? senderRole;
  final DateTime createdAt;

  SupportMessage({
    required this.id,
    required this.senderId,
    required this.message,
    this.senderName,
    this.senderRole,
    required this.createdAt,
  });

  factory SupportMessage.fromJson(Map<String, dynamic> json) {
    return SupportMessage(
      id: json['id'],
      senderId: json['sender_id'],
      message: json['message'],
      senderName: json['full_name'],
      senderRole: json['role'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class SupportService {
  final ApiService apiService;
  final Logger logger = Logger();

  SupportService({required this.apiService});

  /// Create a new support ticket
  Future<Map<String, dynamic>> createTicket({
    required String category,
    required String subject,
    required String description,
  }) async {
    try {
      final response = await apiService.post(
        '/api/support/tickets',
        data: {
          'category': category,
          'subject': subject,
          'description': description,
        },
      );

      if (response['success'] == true) {
        logger.i('Ticket created: ${response['ticket_id']}');
        return {
          'success': true,
          'ticket_id': response['ticket_id'],
          'created_at': response['created_at'],
        };
      }

      return {
        'success': false,
        'error': response['error'] ?? 'Failed to create ticket',
      };
    } on DioException catch (e) {
      logger.e('Create ticket error: $e');
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Network error',
      };
    } catch (e) {
      logger.e('Create ticket exception: $e');
      return {'success': false, 'error': 'An unexpected error occurred'};
    }
  }

  /// Get user's support tickets
  Future<List<SupportTicket>> getMyTickets({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await apiService.get(
        '/api/support/tickets',
        queryParameters: {'limit': limit, 'offset': offset},
      );

      if (response['success'] == true) {
        final tickets = (response['data'] as List)
            .map((ticket) => SupportTicket.fromJson(ticket))
            .toList();
        logger.i('Retrieved ${tickets.length} tickets');
        return tickets;
      }

      logger.w('Failed to get tickets: ${response['error']}');
      return [];
    } on DioException catch (e) {
      logger.e('Get tickets error: $e');
      return [];
    } catch (e) {
      logger.e('Get tickets exception: $e');
      return [];
    }
  }

  /// Get specific ticket with messages
  Future<Map<String, dynamic>?> getTicket(int ticketId) async {
    try {
      final response = await apiService.get('/api/support/tickets/$ticketId');

      if (response['success'] == true) {
        final ticket = SupportTicket.fromJson(response['ticket']);
        final messages = (response['messages'] as List)
            .map((msg) => SupportMessage.fromJson(msg))
            .toList();

        logger.i(
          'Retrieved ticket #$ticketId with ${messages.length} messages',
        );
        return {'success': true, 'ticket': ticket, 'messages': messages};
      }

      logger.w('Failed to get ticket: ${response['error']}');
      return null;
    } on DioException catch (e) {
      logger.e('Get ticket error: $e');
      return null;
    } catch (e) {
      logger.e('Get ticket exception: $e');
      return null;
    }
  }

  /// Add message to ticket
  Future<Map<String, dynamic>> addMessage({
    required int ticketId,
    required String message,
  }) async {
    try {
      final response = await apiService.post(
        '/api/support/tickets/$ticketId/messages',
        data: {'message': message},
      );

      if (response['success'] == true) {
        logger.i('Message added to ticket #$ticketId');
        return {'success': true, 'message_id': response['message_id']};
      }

      return {
        'success': false,
        'error': response['error'] ?? 'Failed to add message',
      };
    } on DioException catch (e) {
      logger.e('Add message error: $e');
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Network error',
      };
    } catch (e) {
      logger.e('Add message exception: $e');
      return {'success': false, 'error': 'An unexpected error occurred'};
    }
  }

  /// Update ticket status
  Future<bool> updateTicketStatus({
    required int ticketId,
    required String status,
  }) async {
    try {
      final response = await apiService.put(
        '/api/support/tickets/$ticketId',
        data: {'status': status},
      );

      if (response['success'] == true) {
        logger.i('Ticket #$ticketId status updated to $status');
        return true;
      }

      logger.w('Failed to update ticket: ${response['error']}');
      return false;
    } on DioException catch (e) {
      logger.e('Update ticket error: $e');
      return false;
    } catch (e) {
      logger.e('Update ticket exception: $e');
      return false;
    }
  }

  /// Get all tickets (admin only)
  Future<Map<String, dynamic>?> getAdminTickets({
    String status = 'open',
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await apiService.get(
        '/api/admin/support/tickets',
        queryParameters: {'status': status, 'limit': limit, 'offset': offset},
      );

      if (response['success'] == true) {
        final tickets = (response['data'] as List)
            .map((t) => SupportTicket.fromJson(t))
            .toList();

        logger.i('Retrieved ${tickets.length} admin tickets');
        return {
          'success': true,
          'tickets': tickets,
          'pagination': response['pagination'],
        };
      }

      return null;
    } on DioException catch (e) {
      logger.e('Get admin tickets error: $e');
      return null;
    } catch (e) {
      logger.e('Get admin tickets exception: $e');
      return null;
    }
  }

  /// Get support statistics (admin only)
  Future<Map<String, dynamic>?> getStats() async {
    try {
      final response = await apiService.get('/api/admin/support/stats');

      if (response['success'] == true) {
        logger.i('Retrieved support statistics');
        return {
          'success': true,
          'stats': response['stats'],
          'by_category': response['by_category'],
        };
      }

      return null;
    } on DioException catch (e) {
      logger.e('Get stats error: $e');
      return null;
    } catch (e) {
      logger.e('Get stats exception: $e');
      return null;
    }
  }
}
