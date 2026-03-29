import '../api/api_service.dart';
import '../../models/payments/payment_model.dart';

class PaymentService {
  final ApiService apiService;

  PaymentService({required this.apiService});

  // Get all membership tiers
  Future<List<MembershipTierModel>> getMembershipTiers() async {
    try {
      final response = await apiService.get<List<dynamic>>(
        '/api/membership-tiers',
      );
      return response
          .map(
            (item) =>
                MembershipTierModel.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Get membership tier by ID
  Future<MembershipTierModel> getMembershipTierById(String tierId) async {
    try {
      final response = await apiService.get<Map<String, dynamic>>(
        'membership-tiers/$tierId',
      );
      return MembershipTierModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  // Initiate payment for course
  Future<FlutterwaveInitResponse> initiateCoursePayment(
    String courseId, {
    required String email,
    required String phoneNumber,
  }) async {
    try {
      final response = await apiService.post<Map<String, dynamic>>(
        'payments/courses/initiate',
        data: {
          'courseId': courseId,
          'email': email,
          'phoneNumber': phoneNumber,
        },
      );
      return FlutterwaveInitResponse.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  // Initiate payment for membership
  Future<FlutterwaveInitResponse> initiateMembershipPayment(
    String membershipTierId, {
    required String email,
    required String phoneNumber,
    required String billingCycle, // 'monthly' or 'annual'
  }) async {
    try {
      final response = await apiService.post<Map<String, dynamic>>(
        'payments/membership/initiate',
        data: {
          'membershipTierId': membershipTierId,
          'email': email,
          'phoneNumber': phoneNumber,
          'billingCycle': billingCycle,
        },
      );
      return FlutterwaveInitResponse.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  // Verify payment
  Future<Payment> verifyPayment(String reference) async {
    try {
      final response = await apiService.post<Map<String, dynamic>>(
        'payments/verify',
        data: {'reference': reference},
      );
      return Payment.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  // Get user payments
  Future<List<Payment>> getUserPayments({
    int page = 1,
    int pageSize = 20,
    String? status,
  }) async {
    try {
      final response = await apiService.get<List<dynamic>>(
        'payments',
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
          if (status != null) 'status': status,
        },
      );
      return response
          .map((item) => Payment.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Get payment by ID
  Future<Payment> getPaymentById(String paymentId) async {
    try {
      final response = await apiService.get<Map<String, dynamic>>(
        'payments/$paymentId',
      );
      return Payment.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  // Get user membership
  Future<UserMembership?> getUserMembership() async {
    try {
      final response = await apiService.get<Map<String, dynamic>?>(
        'users/membership',
      );
      if (response == null) return null;
      return UserMembership.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  // Cancel membership
  Future<void> cancelMembership() async {
    try {
      await apiService.post('users/membership/cancel');
    } catch (e) {
      rethrow;
    }
  }

  // Check if course is purchased
  Future<bool> isCoursePurchased(String courseId) async {
    try {
      final response = await apiService.get<Map<String, dynamic>>(
        'payments/courses/$courseId/purchased',
      );
      return response['purchased'] as bool;
    } catch (e) {
      rethrow;
    }
  }

  // Get payment receipt
  Future<String> getPaymentReceipt(String paymentId) async {
    try {
      final response = await apiService.get<Map<String, dynamic>>(
        'payments/$paymentId/receipt',
      );
      return response['receiptUrl'] as String;
    } catch (e) {
      rethrow;
    }
  }
}
