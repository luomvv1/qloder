library payment_view;

import 'package:flutter/material.dart';

import '../../controllers/payment_controller.dart';
import '../../models/order_detail.dart';
import '../../models/restaurant_order.dart';
import '../../models/restaurant_table.dart';
import '../../services/order_service.dart';

part 'widgets/payment_widgets.dart';

class PaymentView extends StatefulWidget {
  const PaymentView({super.key, required this.order, required this.table});

  final RestaurantOrder order;
  final RestaurantTable table;

  @override
  State<PaymentView> createState() => _PaymentViewState();
}

class _PaymentViewState extends State<PaymentView> {
  late final PaymentController _controller = PaymentController();
  late final OrderService _orderService = OrderService();

  @override
  void initState() {
    super.initState();
    _controller.loadSettings();
    _controller.discountController.addListener(_controller.onAmountChanged);
    _controller.pointsController.addListener(_controller.onAmountChanged);
  }

  @override
  void dispose() {
    _controller.discountController.removeListener(_controller.onAmountChanged);
    _controller.pointsController.removeListener(_controller.onAmountChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thanh toán')),
      body: StreamBuilder<RestaurantOrder>(
        stream: _orderService.watchOrder(widget.order.id),
        builder: (context, orderSnapshot) {
          final order = orderSnapshot.data ?? widget.order;

          return StreamBuilder<List<OrderDetail>>(
            stream: _orderService.watchOrderDetails(widget.order.id),
            builder: (context, detailSnapshot) {
              final details = detailSnapshot.data ?? const <OrderDetail>[];

              if (orderSnapshot.hasError || detailSnapshot.hasError) {
                return const Center(
                  child: Text('Không đọc được dữ liệu thanh toán.'),
                );
              }

              return AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final hasPending = details.any((detail) => detail.isPending);

                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _PaymentHeader(order: order, table: widget.table),
                      const SizedBox(height: 12),
                      if (hasPending) ...[
                        const _PendingWarning(),
                        const SizedBox(height: 12),
                      ],
                      _OrderItemsSummary(details: details),
                      const SizedBox(height: 12),
                      _CustomerPanel(
                        controller: _controller,
                        order: order,
                        onCreateCustomer: _showCreateCustomerDialog,
                      ),
                      const SizedBox(height: 12),
                      _PaymentMethodPanel(controller: _controller),
                      const SizedBox(height: 12),
                      _TotalPanel(controller: _controller, order: order),
                      if (_controller.errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _controller.errorMessage!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _controller.isPaying || hasPending
                            ? null
                            : () => _pay(order),
                        icon: _controller.isPaying
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.payments_outlined),
                        label: const Text('Hoàn tất thanh toán'),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  // Hoàn tất thanh toán, tạo hóa đơn và quay lại sơ đồ bàn.
  Future<void> _pay(RestaurantOrder order) async {
    final invoiceId = await _controller.pay(order: order, table: widget.table);
    if (!mounted || invoiceId == null) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Đã tạo hóa đơn $invoiceId.')));
    Navigator.of(context).pop(true);
  }

  // Mở dialog thêm thành viên mới ngay tại màn hình thanh toán.
  Future<void> _showCreateCustomerDialog() async {
    final formKey = GlobalKey<FormState>();
    var fullName = '';
    var phone = _controller.phoneController.text.trim();

    final result = await showDialog<({String fullName, String phone})>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Thêm thành viên mới'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: fullName,
                  autofocus: true,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Tên khách hàng',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập tên khách hàng';
                    }
                    return null;
                  },
                  onSaved: (value) => fullName = value?.trim() ?? '',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: phone,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Số điện thoại',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: (value) {
                    final normalized = (value ?? '').replaceAll(
                      RegExp(r'\s+'),
                      '',
                    );
                    if (!RegExp(r'^\d{10}$').hasMatch(normalized)) {
                      return 'Số điện thoại phải đủ 10 chữ số';
                    }
                    return null;
                  },
                  onSaved: (value) =>
                      phone = (value ?? '').replaceAll(RegExp(r'\s+'), ''),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                FocusManager.instance.primaryFocus?.unfocus();
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () {
                final form = formKey.currentState;
                if (form == null || !form.validate()) return;
                form.save();

                FocusManager.instance.primaryFocus?.unfocus();
                Navigator.of(
                  dialogContext,
                ).pop((fullName: fullName, phone: phone));
              },
              child: const Text('Lưu thành viên'),
            ),
          ],
        );
      },
    );

    if (result == null) return;

    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (!mounted) return;

    final created = await _controller.createCustomer(
      fullName: result.fullName,
      phone: result.phone,
    );
    if (!mounted) return;

    if (created) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('?? th?m v? ch?n th?nh vi?n m?i.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _controller.errorMessage ?? 'Kh?ng th? th?m th?nh vi?n.',
          ),
        ),
      );
    }
  }
}
