import 'package:get/get.dart';
import 'package:money_control/Services/recurring_service.dart';

class RecurringPaymentController extends GetxController {
  static RecurringPaymentController get to => Get.find();

  final RecurringService _service = RecurringService();
  final RxDouble pendingSubscriptions = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    _bindStream();
  }

  void _bindStream() {
    // bindStream automatically updates the RxDouble with every new stream event!
    pendingSubscriptions.bindStream(_service.getMonthlyTotal());
  }
}
