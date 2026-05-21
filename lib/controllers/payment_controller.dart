import 'package:flutter/material.dart';

import '../models/customer.dart';
import '../models/restaurant_order.dart';
import '../models/restaurant_table.dart';
import '../services/payment_service.dart';

class PaymentController extends ChangeNotifier {
  PaymentController({PaymentService? paymentService})
    : _paymentService = paymentService ?? PaymentService();

  final PaymentService _paymentService;
  final phoneController = TextEditingController();
  final discountController = TextEditingController(text: '0');
  final pointsController = TextEditingController(text: '0');

  PaymentSettings settings = const PaymentSettings(
    pointRate: 10000,
    pointValue: 1000,
  );
  Customer? customer;
  String paymentMethod = 'Tiền mặt';
  bool isLoadingSettings = false;
  bool isSearchingCustomer = false;
  bool isCreatingCustomer = false;
  bool isPaying = false;
  bool customerNotFound = false;
  String? errorMessage;

  num get discountAmount {
    return num.tryParse(discountController.text.trim()) ?? 0;
  }

  int get pointsUsed {
    return int.tryParse(pointsController.text.trim()) ?? 0;
  }

  num pointsValue() {
    if (customer == null) return 0;
    return pointsUsed * settings.pointValue;
  }

  num pointsValueForSubtotal(num subtotal) {
    if (customer == null) return 0;
    final validPoints = pointsUsed <= maxUsablePoints(subtotal)
        ? pointsUsed
        : maxUsablePoints(subtotal);
    return validPoints * settings.pointValue;
  }

  int pointsEarned(num subtotal) {
    if (customer == null || settings.pointRate <= 0) return 0;
    return (subtotal / settings.pointRate).floor();
  }

  num totalAmount(num subtotal) {
    final total =
        subtotal - _validDiscount() - pointsValueForSubtotal(subtotal);
    return total < 0 ? 0 : total;
  }

  int maxUsablePoints(num subtotal) {
    final currentCustomer = customer;
    if (currentCustomer == null || settings.pointValue <= 0) return 0;

    final amountCanUse = subtotal - _validDiscount();
    if (amountCanUse <= 0) return 0;

    final pointsByAmount = (amountCanUse / settings.pointValue).floor();
    return pointsByAmount < currentCustomer.points
        ? pointsByAmount
        : currentCustomer.points;
  }

  Future<void> loadSettings() async {
    isLoadingSettings = true;
    notifyListeners();

    try {
      settings = await _paymentService.getPaymentSettings();
    } catch (_) {
      settings = const PaymentSettings(pointRate: 10000, pointValue: 1000);
    } finally {
      isLoadingSettings = false;
      notifyListeners();
    }
  }

  Future<void> findCustomer() async {
    errorMessage = null;
    customer = null;
    customerNotFound = false;
    pointsController.text = '0';
    isSearchingCustomer = true;
    notifyListeners();

    try {
      customer = await _paymentService.findCustomerByPhone(
        phoneController.text,
      );
      if (customer == null) {
        customerNotFound = true;
        errorMessage =
            'Không tìm thấy thành viên với số điện thoại này. Bạn có thể thêm mới ngay.';
      }
    } catch (error) {
      errorMessage = error.toString().replaceFirst('Exception: ', '');
    } finally {
      isSearchingCustomer = false;
      notifyListeners();
    }
  }

  Future<bool> createCustomer({
    required String fullName,
    required String phone,
  }) async {
    errorMessage = null;
    isCreatingCustomer = true;
    notifyListeners();

    try {
      customer = await _paymentService.createCustomer(
        fullName: fullName,
        phone: phone,
      );
      phoneController.text = customer?.phone ?? phone.trim();
      pointsController.text = '0';
      customerNotFound = false;
      return true;
    } catch (error) {
      errorMessage = error.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      isCreatingCustomer = false;
      notifyListeners();
    }
  }

  void setPaymentMethod(String method) {
    paymentMethod = method;
    notifyListeners();
  }

  void useMaxPoints(num subtotal) {
    pointsController.text = maxUsablePoints(subtotal).toString();
    notifyListeners();
  }

  void onAmountChanged() {
    notifyListeners();
  }

  Future<String?> pay({
    required RestaurantOrder order,
    required RestaurantTable table,
  }) async {
    errorMessage = null;
    isPaying = true;
    notifyListeners();

    try {
      return await _paymentService.payOrder(
        order: order,
        table: table,
        customer: customer,
        discountAmount: _validDiscount(),
        pointsUsed: pointsUsed,
        paymentMethod: paymentMethod,
      );
    } catch (error) {
      errorMessage = error.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      isPaying = false;
      notifyListeners();
    }
  }

  num _validDiscount() {
    return discountAmount < 0 ? 0 : discountAmount;
  }

  @override
  void dispose() {
    phoneController.dispose();
    discountController.dispose();
    pointsController.dispose();
    super.dispose();
  }
}
