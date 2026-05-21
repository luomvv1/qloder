import 'package:flutter/material.dart';

import '../../controllers/invoice_controller.dart';
import '../../models/invoice.dart';
import 'invoice_detail_view.dart';

class InvoiceListView extends StatefulWidget {
  const InvoiceListView({super.key});

  @override
  State<InvoiceListView> createState() => _InvoiceListViewState();
}

class _InvoiceListViewState extends State<InvoiceListView> {
  late final InvoiceController _controller = InvoiceController();

  @override
  void initState() {
    super.initState();
    _controller.searchController.addListener(_controller.onSearchChanged);
  }

  @override
  void dispose() {
    _controller.searchController.removeListener(_controller.onSearchChanged);
    _controller.dispose();
    super.dispose();
  }

  // Màn hình danh sách hóa đơn dùng chung cho quản lý và nhân viên.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hóa đơn')),
      body: StreamBuilder<List<Invoice>>(
        stream: _controller.invoicesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _ErrorState(message: snapshot.error.toString());
          }

          final invoices = snapshot.data ?? const <Invoice>[];

          return AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final filteredInvoices = _controller.filterInvoices(invoices);
              final totalRevenue = filteredInvoices.fold<num>(
                0,
                (sum, invoice) => sum + invoice.totalAmount,
              );

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _InvoiceHeader(
                    invoiceCount: filteredInvoices.length,
                    totalRevenue: totalRevenue,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _controller.searchController,
                    decoration: const InputDecoration(
                      labelText: 'Tìm hóa đơn',
                      hintText: 'Nhập mã hóa đơn, order, bàn hoặc thành viên',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (filteredInvoices.isEmpty)
                    const _EmptyState()
                  else
                    for (final invoice in filteredInvoices)
                      _InvoiceCard(
                        invoice: invoice,
                        onTap: () => _openInvoiceDetail(invoice),
                      ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // Mở chi tiết hóa đơn được chọn.
  void _openInvoiceDetail(Invoice invoice) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InvoiceDetailView(invoiceId: invoice.id),
      ),
    );
  }
}

// Header tổng quan: số hóa đơn và tổng doanh thu trong danh sách hiện tại.
class _InvoiceHeader extends StatelessWidget {
  const _InvoiceHeader({
    required this.invoiceCount,
    required this.totalRevenue,
  });

  final int invoiceCount;
  final num totalRevenue;

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
                  '$invoiceCount hóa đơn',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const Text('Danh sách hóa đơn đã thanh toán'),
              ],
            ),
          ),
          Text(
            formatMoney(totalRevenue),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

// Card một hóa đơn trong danh sách, bấm để xem chi tiết.
class _InvoiceCard extends StatelessWidget {
  const _InvoiceCard({required this.invoice, required this.onTap});

  final Invoice invoice;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const CircleAvatar(child: Icon(Icons.payments_outlined)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invoice.invoiceNo,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    Text('Order: ${invoice.orderId}'),
                    Text('Bàn: ${invoice.tableIds.join(', ')}'),
                    Text('Ngày: ${formatDateTime(invoice.paidAt?.toDate())}'),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatMoney(invoice.totalAmount),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Trạng thái khi không tìm thấy hóa đơn.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: Text('Không có hóa đơn phù hợp.')),
      ),
    );
  }
}

// Trạng thái lỗi khi không đọc được collection invoices.
class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Không đọc được danh sách hóa đơn:\n$message',
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
