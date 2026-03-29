import 'package:get/get.dart';
import '../models/payments/payment_model.dart';
import '../services/payment/payment_service.dart';
import '../config/service_locator.dart';

class PaymentController extends GetxController {
  final paymentService = getIt<PaymentService>();

  final membershipTiers = RxList<MembershipTierModel>();
  final userPayments = RxList<Payment>();
  final userMembership = Rx<UserMembership?>(null);
  final selectedTier = Rx<MembershipTierModel?>(null);

  final isLoading = false.obs;
  final errorMessage = RxString('');

  @override
  void onInit() {
    super.onInit();
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    await Future.wait([
      fetchMembershipTiers(),
      fetchUserPayments(),
      fetchUserMembership(),
    ]);
  }

  Future<void> fetchMembershipTiers() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      membershipTiers.value = await paymentService.getMembershipTiers();
    } catch (e) {
      errorMessage.value = 'Failed to load membership tiers';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchUserPayments({
    int page = 1,
    int pageSize = 20,
    String? status,
  }) async {
    try {
      errorMessage.value = '';
      userPayments.value = await paymentService.getUserPayments(
        page: page,
        pageSize: pageSize,
        status: status,
      );
    } catch (e) {
      errorMessage.value = 'Failed to load payment history';
    }
  }

  Future<void> fetchUserMembership() async {
    try {
      errorMessage.value = '';
      userMembership.value = await paymentService.getUserMembership();
    } catch (e) {
      // Membership might be null for free users
    }
  }

  Future<bool> initiateCoursePayment(
    String courseId, {
    required String email,
    required String phoneNumber,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      final response = await paymentService.initiateCoursePayment(
        courseId,
        email: email,
        phoneNumber: phoneNumber,
      );

      if (response.link != null) {
        // Open Flutterwave link
        // You can use url_launcher package here
        return true;
      }
      return false;
    } catch (e) {
      errorMessage.value = 'Failed to initiate payment';
      Get.snackbar('Error', 'Could not start payment process');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> initiateMembershipPayment(
    String membershipTierId, {
    required String email,
    required String phoneNumber,
    required String billingCycle,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      final response = await paymentService.initiateMembershipPayment(
        membershipTierId,
        email: email,
        phoneNumber: phoneNumber,
        billingCycle: billingCycle,
      );

      if (response.link != null) {
        // Open Flutterwave link
        return true;
      }
      return false;
    } catch (e) {
      errorMessage.value = 'Failed to initiate payment';
      Get.snackbar('Error', 'Could not start payment process');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> verifyPayment(String reference) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      final payment = await paymentService.verifyPayment(reference);

      if (payment.status == PaymentStatus.completed) {
        Get.snackbar('Success', 'Payment successful!');
        await fetchUserPayments();
        await fetchUserMembership();
        return true;
      } else {
        errorMessage.value = 'Payment could not be verified';
        return false;
      }
    } catch (e) {
      errorMessage.value = 'Failed to verify payment';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> cancelMembership() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      await paymentService.cancelMembership();
      userMembership.value = null;
      Get.snackbar('Success', 'Membership cancelled');
    } catch (e) {
      errorMessage.value = 'Failed to cancel membership';
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> isCoursePurchased(String courseId) async {
    try {
      return await paymentService.isCoursePurchased(courseId);
    } catch (e) {
      return false;
    }
  }

  void clearError() {
    errorMessage.value = '';
  }
}
