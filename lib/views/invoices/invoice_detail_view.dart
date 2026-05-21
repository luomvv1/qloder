import 'package:flutter/material.dart';

import '../../controllers/invoice_controller.dart';
import '../../models/invoice.dart';
import '../../models/order_detail.dart';

class InvoiceDetailView extends StatefulWidget {
  const InvoiceDetailView({super.key, required this.invoiceId});

  final String invoiceId;

  @override
  State<InvoiceDetailView> createState() => _InvoiceDetailViewState();
}

class _InvoiceDetailViewState extends State<InvoiceDetailView> {
  late final InvoiceController _controller = InvoiceController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Màn hình chi tiết hóa đơn dùng chung cho quản lý và nhân viên.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết hóa đơn')),
      body: StreamBuilder<Invoice>(
        stream: _controller.watchInvoice(widget.invoiceId),
        builder: (context, invoiceSnapshot) {
          if (invoiceSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (invoiceSnapshot.hasError || !invoiceSnapshot.hasData) {
            return _ErrorState(
              message: invoiceSnapshot.error?.toString() ?? 'Không có dữ liệu.',
            );
          }

          final invoice = invoiceSnapshot.data!;

          return StreamBuilder<List<OrderDetail>>(
            stream: _controller.watchInvoiceDetails(invoice.orderId),
            builder: (context, detailSnapshot) {
              final details = detailSnapshot.data ?? const <OrderDetail>[];

              if (detailSnapshot.hasError) {
                return _ErrorState(message: detailSnapshot.error.toString());
              }

              return FutureBuilder<InvoiceReferenceInfo>(
                future: _controller.getReferenceInfo(invoice),
                builder: (context, referenceSnapshot) {
                  final referenceInfo = referenceSnapshot.data;

                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _InvoiceDetailHeader(invoice: invoice),
                      const SizedBox(height: 12),
                      _InvoiceInfoPanel(
                        invoice: invoice,
                        referenceInfo: referenceInfo,
                        isLoadingReference:
                            referenceSnapshot.connectionState ==
                            ConnectionState.waiting,
                      ),
                      const SizedBox(height: 12),
                      _InvoiceItemsPanel(details: details),
                      const SizedBox(height: 12),
                      _InvoiceTotalPanel(invoice: invoice),
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
}

// Header chi tiết: mã hóa đơn và tổng tiền.
class _InvoiceDetailHeader extends StatelessWidget {
  const _InvoiceDetailHeader({required this.invoice});

  final Invoice invoice;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: colorScheme.primary,
            child: Icon(Icons.receipt_long, color: colorScheme.onPrimary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invoice.invoiceNo,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                Text('Ngày: ${formatDateTime(invoice.paidAt?.toDate())}'),
              ],
            ),
          ),
          Text(
            formatMoney(invoice.totalAmount),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

// Thông tin chung: hiển thị tên dễ hiểu kèm ID gốc trong ngoặc.
class _InvoiceInfoPanel extends StatelessWidget {
  const _InvoiceInfoPanel({
    required this.invoice,
    required this.referenceInfo,
    required this.isLoadingReference,
  });

  final Invoice invoice;
  final InvoiceReferenceInfo? referenceInfo;
  final bool isLoadingReference;

  @override
  Widget build(BuildContext context) {
    final tableText =
        referenceInfo?.tableNames.join(', ') ??
        (invoice.tableIds.isEmpty ? invoice.tableId : invoice.tableIds.join(', '));
    final customerText =
        referenceInfo?.customerName ??
        (invoice.customerId?.isNotEmpty == true ? invoice.customerId! : 'Không có');
    final paidByText = referenceInfo?.paidByName ?? invoice.paidBy;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Thông tin hóa đơn',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (isLoadingReference)
                  const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            _InfoRow(label: 'Mã order', value: invoice.orderId),
            _InfoRow(label: 'Bàn', value: tableText),
            _InfoRow(label: 'Thành viên', value: customerText),
            _InfoRow(label: 'Nhân viên thu', value: paidByText),
            _InfoRow(label: 'Phương thức', value: invoice.paymentMethod),
          ],
        ),
      ),
    );
  }
}

// Danh sách món trong hóa đơn lấy theo orderId.
class _InvoiceItemsPanel extends StatelessWidget {
  const _InvoiceItemsPanel({required this.details});

  final List<OrderDetail> details;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Món đã thanh toán',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            if (details.isEmpty)
              const Text('Không có chi tiết món.')
            else
              for (final detail in details)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              detail.foodName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              '${detail.quantity} x ${detail.variantName}'
                              ' - ${formatMoney(detail.unitPrice)}',
                            ),
                            if (detail.note.isNotEmpty)
                              Text('Ghi chú: ${detail.note}'),
                          ],
                        ),
                      ),
                      Text(
                        formatMoney(detail.lineTotal),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

// Tổng kết tiền: ghi rõ giảm giá và điểm đã trừ bao nhiêu tiền.
class _InvoiceTotalPanel extends StatelessWidget {
  const _InvoiceTotalPanel({required this.invoice});

  final Invoice invoice;

  @override
  Widget build(BuildContext context) {
    final pointsDiscount =
        invoice.subtotal - invoice.discountAmount - invoice.totalAmount;
    final validPointsDiscount = pointsDiscount < 0 ? 0 : pointsDiscount;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _MoneyRow(label: 'Tạm tính', value: invoice.subtotal),
            _MoneyRow(
              label: 'Giảm giá đã trừ',
              value: -invoice.discountAmount,
            ),
            _InfoRow(
              label: 'Điểm đã dùng',
              value:
                  '${invoice.pointsUsed} điểm (${formatMoney(-validPointsDiscount)})',
            ),
            _InfoRow(
              label: 'Điểm được cộng',
              value: '${invoice.pointsEarned} điểm',
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Thành tiền',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  formatMoney(invoice.totalAmount),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(child: Text(value.isEmpty ? '-' : value)),
        ],
      ),
    );
  }
}

class _MoneyRow extends StatelessWidget {
  const _MoneyRow({required this.label, required this.value});

  final String label;
  final num value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            formatMoney(value),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Không đọc được chi tiết hóa đơn:\n$message',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

String formatMoney(num value) {
  final isNegative = value < 0;
  final text = value.abs().round().toString();
  final buffer = StringBuffer();

  for (var i = 0; i < text.length; i++) {
    final indexFromEnd = text.length - i;
    buffer.write(text[i]);
    if (indexFromEnd > 1 && indexFromEnd % 3 == 1) {
      buffer.write('.');
    }
  }

  return '${isNegative ? '-' : ''}${buffer}đ';
}

String formatDateTime(DateTime? value) {
  if (value == null) return '-';

  String twoDigits(int number) => number.toString().padLeft(2, '0');

  return '${twoDigits(value.day)}/${twoDigits(value.month)}/${value.year} '
      '${twoDigits(value.hour)}:${twoDigits(value.minute)}';
}
