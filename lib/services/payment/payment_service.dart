import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../api/api_service.dart';

// ============================================
// PAYMENT MODELS
// ============================================

class CardPaymentResponse {
  final bool success;
  final String reference;
  final String paymentUrl;
  final String accessCode;
  final double amount;

  CardPaymentResponse({
    required this.success,
    required this.reference,
    required this.paymentUrl,
    required this.accessCode,
    required this.amount,
  });

  factory CardPaymentResponse.fromJson(Map<String, dynamic> json) {
    return CardPaymentResponse(
      success: json['success'] ?? false,
      reference: json['reference'] ?? '',
      paymentUrl: json['paymentUrl'] ?? '',
      accessCode: json['accessCode'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'reference': reference,
      'paymentUrl': paymentUrl,
      'accessCode': accessCode,
      'amount': amount,
    };
  }
}

class BankTransferResponse {
  final bool success;
  final String reference;
  final String method;
  final BankDetails bankDetails;
  final DateTime expiresAt;
  final List<String> instructions;

  BankTransferResponse({
    required this.success,
    required this.reference,
    required this.method,
    required this.bankDetails,
    required this.expiresAt,
    required this.instructions,
  });

  factory BankTransferResponse.fromJson(Map<String, dynamic> json) {
    return BankTransferResponse(
      success: json['success'] ?? false,
      reference: json['reference'] ?? '',
      method: json['method'] ?? 'bank_transfer',
      bankDetails: BankDetails.fromJson(json['bankDetails']),
      expiresAt: DateTime.parse(json['expiresAt']),
      instructions: List<String>.from(json['instructions'] ?? []),
    );
  }
}

class BankDetails {
  final String accountName;
  final String accountNumber;
  final String bankCode;
  final String bankName;
  final double amount;
  final String transferReference;
  final String description;

  BankDetails({
    required this.accountName,
    required this.accountNumber,
    required this.bankCode,
    required this.bankName,
    required this.amount,
    required this.transferReference,
    required this.description,
  });

  factory BankDetails.fromJson(Map<String, dynamic> json) {
    return BankDetails(
      accountName: json['accountName'] ?? '',
      accountNumber: json['accountNumber'] ?? '',
      bankCode: json['bankCode'] ?? '',
      bankName: json['bankName'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      transferReference: json['transferReference'] ?? '',
      description: json['description'] ?? '',
    );
  }
}

class PaymentHistory {
  final int id;
  final String reference;
  final String itemType;
  final double amount;
  final String status; // pending, completed, failed
  final String paymentMethod; // card, bank_transfer
  final DateTime createdAt;

  PaymentHistory({
    required this.id,
    required this.reference,
    required this.itemType,
    required this.amount,
    required this.status,
    required this.paymentMethod,
    required this.createdAt,
  });

  factory PaymentHistory.fromJson(Map<String, dynamic> json) {
    return PaymentHistory(
      id: json['id'] ?? 0,
      reference: json['reference'] ?? '',
      itemType: json['item_type'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
      paymentMethod: json['payment_method'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

// ============================================
// PAYMENT SERVICE
// ============================================

class PaymentService {
  final ApiService apiService;
  final Logger logger = Logger();

  PaymentService({required this.apiService});

  /// Initialize card payment
  Future<CardPaymentResponse?> initializeCardPayment({
    required String itemType,
    required String itemId,
    required double amount,
    String? description,
  }) async {
    try {
      final response = await apiService.post(
        '/api/payments/card/initialize',
        data: {
          'itemType': itemType,
          'itemId': itemId,
          'amount': amount,
          'description': description,
        },
      );

      logger.i('Card payment initialized: ${response['reference']}');
      return CardPaymentResponse.fromJson(response);
    } on DioException catch (e) {
      logger.e('Initialize card payment error: $e');
      return null;
    } catch (e) {
      logger.e('Card payment exception: $e');
      return null;
    }
  }

  /// Verify card payment
  Future<Map<String, dynamic>?> verifyCardPayment({
    required String reference,
  }) async {
    try {
      final response = await apiService.post(
        '/api/payments/card/verify',
        data: {'reference': reference},
      );

      if (response['success'] == true) {
        logger.i('Payment verified: $reference');
        return response;
      }

      logger.w('Payment verification failed: ${response['error']}');
      return null;
    } on DioException catch (e) {
      logger.e('Verify card payment error: $e');
      return null;
    } catch (e) {
      logger.e('Card payment verification exception: $e');
      return null;
    }
  }

  /// Initialize bank transfer
  Future<BankTransferResponse?> initializeBankTransfer({
    required String itemType,
    required String itemId,
    required double amount,
    String? description,
  }) async {
    try {
      final response = await apiService.post(
        '/api/payments/bank-transfer/initialize',
        data: {
          'itemType': itemType,
          'itemId': itemId,
          'amount': amount,
          'description': description,
        },
      );

      logger.i('Bank transfer initialized: ${response['reference']}');
      return BankTransferResponse.fromJson(response);
    } on DioException catch (e) {
      logger.e('Initialize bank transfer error: $e');
      return null;
    } catch (e) {
      logger.e('Bank transfer exception: $e');
      return null;
    }
  }

  /// Check bank transfer status
  Future<Map<String, dynamic>?> checkBankTransferStatus({
    required String reference,
  }) async {
    try {
      final response = await apiService.get(
        '/api/payments/bank-transfer/$reference/status',
      );

      logger.i('Bank transfer status: ${response['status']}');
      return response;
    } on DioException catch (e) {
      logger.e('Check bank transfer status error: $e');
      return null;
    } catch (e) {
      logger.e('Bank transfer status exception: $e');
      return null;
    }
  }

  /// Get payment history
  Future<List<PaymentHistory>> getPaymentHistory({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await apiService.get(
        '/api/payments/history',
        queryParameters: {'limit': limit, 'offset': offset},
      );

      if (response['success'] == true) {
        final payments = (response['data'] as List)
            .map((p) => PaymentHistory.fromJson(p))
            .toList();
        logger.i('Retrieved ${payments.length} payments');
        return payments;
      }

      return [];
    } on DioException catch (e) {
      logger.e('Get payment history error: $e');
      return [];
    } catch (e) {
      logger.e('Payment history exception: $e');
      return [];
    }
  }

  /// Get payment details
  Future<Map<String, dynamic>?> getPaymentDetails({
    required String reference,
  }) async {
    try {
      final response = await apiService.get('/api/payments/$reference');

      if (response['success'] == true) {
        logger.i('Retrieved payment: $reference');
        return response['payment'];
      }

      return null;
    } on DioException catch (e) {
      logger.e('Get payment details error: $e');
      return null;
    } catch (e) {
      logger.e('Payment details exception: $e');
      return null;
    }
  }

  /// Get membership tiers
  Future<List<Map<String, dynamic>>> getMembershipTiers() async {
    try {
      final response = await apiService.get('/api/payments/tiers');
      if (response is List) {
        return List<Map<String, dynamic>>.from(response);
      }
      return [];
    } catch (e) {
      logger.e('Get membership tiers error: $e');
      return [];
    }
  }

  /// Get user payments
  Future<List<Map<String, dynamic>>> getUserPayments({int limit = 10}) async {
    try {
      final response = await apiService.get(
        '/api/payments/user',
        queryParameters: {'limit': limit},
      );
      if (response is List) {
        return List<Map<String, dynamic>>.from(response);
      }
      return [];
    } catch (e) {
      logger.e('Get user payments error: $e');
      return [];
    }
  }

  /// Get user membership
  Future<Map<String, dynamic>?> getUserMembership() async {
    try {
      return await apiService.get('/api/payments/membership');
    } catch (e) {
      logger.e('Get user membership error: $e');
      return null;
    }
  }

  /// Initiate course payment
  Future<Map<String, dynamic>?> initiateCoursePayment(
    String courseId,
    double amount,
  ) async {
    try {
      return await initializeCardPayment(
        itemType: 'course',
        itemId: courseId,
        amount: amount,
      ).then((response) => response?.toJson());
    } catch (e) {
      logger.e('Initiate course payment error: $e');
      return null;
    }
  }

  /// Initiate membership payment
  Future<Map<String, dynamic>?> initiateMembershipPayment(
    String tierId,
    double amount,
  ) async {
    try {
      return await initializeCardPayment(
        itemType: 'membership',
        itemId: tierId,
        amount: amount,
      ).then((response) => response?.toJson());
    } catch (e) {
      logger.e('Initiate membership payment error: $e');
      return null;
    }
  }

  /// Verify payment
  Future<Map<String, dynamic>?> verifyPayment(String reference) async {
    return verifyCardPayment(reference: reference);
  }

  /// Cancel membership
  Future<bool> cancelMembership() async {
    try {
      final response = await apiService.post('/api/payments/membership/cancel');
      return response['success'] == true;
    } catch (e) {
      logger.e('Cancel membership error: $e');
      return false;
    }
  }

  /// Check if course is purchased
  Future<bool> isCoursePurchased(String courseId) async {
    try {
      final response = await apiService.get(
        '/api/payments/course/$courseId/purchased',
      );
      return response['purchased'] == true;
    } catch (e) {
      logger.e('Check course purchased error: $e');
      return false;
    }
  }
}
