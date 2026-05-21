import 'package:flutter/material.dart';

// Cụm nút thao tác nhanh cho bàn đang phục vụ trong sơ đồ bàn.
// Gồm: xem order, chuyển bàn, gộp bàn, thanh toán và hủy order.
class ServingTableActions extends StatelessWidget {
  const ServingTableActions({
    super.key,
    required this.onOpenOrder,
    required this.onTransfer,
    required this.onMerge,
    required this.onPayment,
    required this.onCancel,
  });

  final VoidCallback onOpenOrder;
  final VoidCallback onTransfer;
  final VoidCallback onMerge;
  final VoidCallback onPayment;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
        final orderButton = FilledButton.icon(
          onPressed: onOpenOrder,
          icon: const Icon(Icons.receipt_long),
          label: const Text('Xem order'),
        );
        final transferButton = OutlinedButton.icon(
          onPressed: onTransfer,
          icon: const Icon(Icons.swap_horiz),
          label: const Text('Chuyển bàn'),
        );
        final mergeButton = OutlinedButton.icon(
          onPressed: onMerge,
          icon: const Icon(Icons.call_merge),
          label: const Text('Gộp bàn'),
        );
        final paymentButton = OutlinedButton.icon(
          onPressed: onPayment,
          icon: const Icon(Icons.payments_outlined),
          label: const Text('Thanh toán'),
        );
        final cancelButton = OutlinedButton.icon(
          onPressed: onCancel,
          icon: const Icon(Icons.cancel_outlined),
          label: const Text('Hủy order'),
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              orderButton,
              const SizedBox(height: 10),
              transferButton,
              const SizedBox(height: 10),
              mergeButton,
              const SizedBox(height: 10),
              paymentButton,
              const SizedBox(height: 10),
              cancelButton,
            ],
          );
        }

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            SizedBox(width: 150, child: orderButton),
            SizedBox(width: 150, child: transferButton),
            SizedBox(width: 150, child: mergeButton),
            SizedBox(width: 150, child: paymentButton),
            SizedBox(width: 150, child: cancelButton),
          ],
        );
      },
    );
  }
}
