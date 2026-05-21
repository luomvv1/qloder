import 'package:flutter/material.dart';

import '../models/restaurant_order.dart';
import '../models/restaurant_table.dart';
import '../services/order_service.dart';

class OrderController extends ChangeNotifier {
  OrderController({OrderService? orderService})
    : _orderService = orderService ?? OrderService();

  final OrderService _orderService;

  bool isCreating = false;
  bool isCanceling = false;
  String? errorMessage;

  Future<RestaurantOrder?> createOrderForTable(RestaurantTable table) async {
    errorMessage = null;
    isCreating = true;
    notifyListeners();

    try {
      return await _orderService.createOrderForTable(table);
    } catch (error) {
      errorMessage = error.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      isCreating = false;
      notifyListeners();
    }
  }

  Future<RestaurantOrder?> getOrder(String orderId) async {
    errorMessage = null;
    isCreating = true;
    notifyListeners();

    try {
      return await _orderService.getOrder(orderId);
    } catch (error) {
      errorMessage = error.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      isCreating = false;
      notifyListeners();
    }
  }

  // Hủy order hiện tại của bàn và đưa bàn về trạng thái trống.
  Future<bool> cancelOrder({
    required RestaurantOrder order,
    required RestaurantTable table,
  }) async {
    errorMessage = null;
    isCanceling = true;
    notifyListeners();

    try {
      await _orderService.cancelOrder(order: order, table: table);
      return true;
    } catch (error) {
      errorMessage = error.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      isCanceling = false;
      notifyListeners();
    }
  }
}
