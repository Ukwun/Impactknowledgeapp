import 'package:get/get.dart';
import '../providers/auth_controller.dart';
import '../providers/course_controller.dart';
import '../providers/achievement_controller.dart';
import '../providers/payment_controller.dart';

class AppBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthController>(() => AuthController(), fenix: true);
    Get.lazyPut<CourseController>(() => CourseController(), fenix: true);
    Get.lazyPut<AchievementController>(
      () => AchievementController(),
      fenix: true,
    );
    Get.lazyPut<PaymentController>(() => PaymentController(), fenix: true);
  }
}
