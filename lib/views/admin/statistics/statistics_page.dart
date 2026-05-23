import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  _StatisticPeriod _period = _StatisticPeriod.today;

  CollectionReference<Map<String, dynamic>> get _invoices =>
      FirebaseFirestore.instance.collection('invoices');
  CollectionReference<Map<String, dynamic>> get _orderDetails =>
      FirebaseFirestore.instance.collection('order_details');
  CollectionReference<Map<String, dynamic>> get _tables =>
      FirebaseFirestore.instance.collection('tables');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(title: const Text('Thống kê')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _invoices.snapshots(),
        builder: (context, invoiceSnapshot) {
          if (invoiceSnapshot.hasError) {
            return const _StatisticMessage(
              icon: Icons.error_outline,
              message: 'Không tải được dữ liệu hóa đơn',
            );
          }
          if (!invoiceSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _orderDetails.snapshots(),
            builder: (context, detailSnapshot) {
              if (detailSnapshot.hasError) {
                return const _StatisticMessage(
                  icon: Icons.error_outline,
                  message: 'Không tải được dữ liệu món đã bán',
                );
              }
              if (!detailSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _tables.snapshots(),
                builder: (context, tableSnapshot) {
                  if (tableSnapshot.hasError) {
                    return const _StatisticMessage(
                      icon: Icons.error_outline,
                      message: 'Không tải được dữ liệu bàn',
                    );
                  }
                  if (!tableSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final data = _buildStatisticData(
                    invoices: invoiceSnapshot.data!.docs,
                    details: detailSnapshot.data!.docs,
                    tables: tableSnapshot.data!.docs,
                  );
                  return _StatisticContent(
                    data: data,
                    period: _period,
                    onPeriodChanged: (period) {
                      setState(() => _period = period);
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  _StatisticData _buildStatisticData({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> invoices,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> details,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> tables,
  }) {
    final filteredInvoices = invoices.where((doc) {
      final paidAt = (doc.data()['paidAt'] as Timestamp?)?.toDate();
      return _period.contains(paidAt);
    }).toList();

    final paidOrderIds = filteredInvoices
        .map((doc) => doc.data()['orderId'] as String? ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();

    final revenue = filteredInvoices.fold<num>(
      0,
      (sum, doc) => sum + (doc.data()['totalAmount'] as num? ?? 0),
    );
    final subtotal = filteredInvoices.fold<num>(
      0,
      (sum, doc) => sum + (doc.data()['subtotal'] as num? ?? 0),
    );
    final discount = filteredInvoices.fold<num>(
      0,
      (sum, doc) => sum + (doc.data()['discountAmount'] as num? ?? 0),
    );
    final pointsUsed = filteredInvoices.fold<int>(
      0,
      (sum, doc) => sum + ((doc.data()['pointsUsed'] as num? ?? 0).toInt()),
    );
    final pointsEarned = filteredInvoices.fold<int>(
      0,
      (sum, doc) => sum + ((doc.data()['pointsEarned'] as num? ?? 0).toInt()),
    );

    final servedTableIds = <String>{};
    for (final invoice in filteredInvoices) {
      final data = invoice.data();
      final rawTableIds = data['tableIds'] as List<dynamic>?;
      final tableId = data['tableId'] as String? ?? '';
      final tableIds =
          rawTableIds?.whereType<String>().where((id) => id.isNotEmpty) ??
          const Iterable<String>.empty();
      servedTableIds.addAll(tableIds);
      if (tableId.isNotEmpty) servedTableIds.add(tableId);
    }

    final servingTables = tables.where((doc) {
      final status = doc.data()['status'] as String? ?? '';
      return status == 'Đang phục vụ' || status == 'serving';
    }).length;

    final topFoods = <String, _FoodSale>{};
    for (final detail in details) {
      final data = detail.data();
      final orderId = data['orderId'] as String? ?? '';
      if (!paidOrderIds.contains(orderId)) continue;

      final foodName = data['foodName'] as String? ?? 'Món không tên';
      final quantity = (data['quantity'] as num? ?? 0).toInt();
      final lineTotal = data['lineTotal'] as num? ?? 0;
      final current = topFoods[foodName] ?? _FoodSale(name: foodName);
      current.quantity += quantity;
      current.revenue += lineTotal;
      topFoods[foodName] = current;
    }

    final sortedTopFoods = topFoods.values.toList()
      ..sort((a, b) => b.quantity.compareTo(a.quantity));

    filteredInvoices.sort((a, b) {
      final dateA = (a.data()['paidAt'] as Timestamp?)?.toDate();
      final dateB = (b.data()['paidAt'] as Timestamp?)?.toDate();
      return (dateB ?? DateTime(1900)).compareTo(dateA ?? DateTime(1900));
    });

    return _StatisticData(
      revenue: revenue,
      subtotal: subtotal,
      discount: discount,
      pointsUsed: pointsUsed,
      pointsEarned: pointsEarned,
      invoiceCount: filteredInvoices.length,
      orderCount: paidOrderIds.length,
      servedTableCount: servedTableIds.length,
      servingTableCount: servingTables,
      topFoods: sortedTopFoods.take(5).toList(),
      recentInvoices: filteredInvoices.take(8).toList(),
    );
  }
}

enum _StatisticPeriod {
  today('Hôm nay'),
  month('Tháng này'),
  all('Tất cả');

  const _StatisticPeriod(this.label);

  final String label;

  bool contains(DateTime? date) {
    if (this == _StatisticPeriod.all) return true;
    if (date == null) return false;

    final now = DateTime.now();
    if (this == _StatisticPeriod.today) {
      return date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    }

    return date.year == now.year && date.month == now.month;
  }
}

class _StatisticContent extends StatelessWidget {
  const _StatisticContent({
    required this.data,
    required this.period,
    required this.onPeriodChanged,
  });

  final _StatisticData data;
  final _StatisticPeriod period;
  final ValueChanged<_StatisticPeriod> onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _PeriodSelector(period: period, onChanged: onPeriodChanged),
        const SizedBox(height: 12),
        _SummaryGrid(data: data),
        const SizedBox(height: 12),
        _MoneyBreakdown(data: data),
        const SizedBox(height: 12),
        _TopFoodCard(foods: data.topFoods),
        const SizedBox(height: 12),
        _RecentInvoiceCard(invoices: data.recentInvoices),
      ],
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({required this.period, required this.onChanged});

  final _StatisticPeriod period;
  final ValueChanged<_StatisticPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<_StatisticPeriod>(
      segments: [
        for (final item in _StatisticPeriod.values)
          ButtonSegment(value: item, label: Text(item.label)),
      ],
      selected: {period},
      onSelectionChanged: (selected) => onChanged(selected.first),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.data});

  final _StatisticData data;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 720 ? 4 : 2;
        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: constraints.maxWidth >= 720 ? 1.6 : 1.25,
          children: [
            _MetricCard(
              icon: Icons.payments_outlined,
              title: 'Doanh thu đã thu',
              value: _formatVnd(data.revenue),
              color: const Color(0xFF0F766E),
            ),
            _MetricCard(
              icon: Icons.receipt_long,
              title: 'Hóa đơn',
              value: data.invoiceCount.toString(),
              color: const Color(0xFF2563EB),
            ),
            _MetricCard(
              icon: Icons.shopping_bag_outlined,
              title: 'Order đã thanh toán',
              value: data.orderCount.toString(),
              color: const Color(0xFFC2410C),
            ),
            _MetricCard(
              icon: Icons.table_restaurant,
              title: 'Bàn đang phục vụ',
              value: data.servingTableCount.toString(),
              color: const Color(0xFF7C3AED),
            ),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String value;
  final String? subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const Spacer(),
            Text(title, style: const TextStyle(color: Color(0xFF64748B))),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
          ],
        ),
      ),
    );
  }
}

class _MoneyBreakdown extends StatelessWidget {
  const _MoneyBreakdown({required this.data});

  final _StatisticData data;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Chi tiết thanh toán',
      icon: Icons.account_balance_wallet_outlined,
      child: Column(
        children: [
          _InfoRow(label: 'Tạm tính', value: _formatVnd(data.subtotal)),
          _InfoRow(label: 'Giảm giá', value: '-${_formatVnd(data.discount)}'),
          _InfoRow(label: 'Điểm đã dùng', value: data.pointsUsed.toString()),
          _InfoRow(label: 'Điểm đã cộng', value: data.pointsEarned.toString()),
          const Divider(height: 22),
          _InfoRow(
            label: 'Thành tiền',
            value: _formatVnd(data.revenue),
            isStrong: true,
          ),
        ],
      ),
    );
  }
}

class _TopFoodCard extends StatelessWidget {
  const _TopFoodCard({required this.foods});

  final List<_FoodSale> foods;

  @override
  Widget build(BuildContext context) {
    final maxQuantity = foods.isEmpty
        ? 1
        : foods.map((food) => food.quantity).reduce((a, b) => a > b ? a : b);

    return _SectionCard(
      title: 'Món bán chạy',
      icon: Icons.local_fire_department_outlined,
      child: foods.isEmpty
          ? const _StatisticMessage(
              icon: Icons.no_food_outlined,
              message: 'Chưa có món bán trong khoảng thời gian này',
              compact: true,
            )
          : Column(
              children: [
                for (final food in foods)
                  _TopFoodRow(food: food, maxQuantity: maxQuantity),
              ],
            ),
    );
  }
}

class _TopFoodRow extends StatelessWidget {
  const _TopFoodRow({required this.food, required this.maxQuantity});

  final _FoodSale food;
  final int maxQuantity;

  @override
  Widget build(BuildContext context) {
    final percent = maxQuantity <= 0 ? 0.0 : food.quantity / maxQuantity;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  food.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Text('${food.quantity} món'),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 8,
              backgroundColor: const Color(0xFFE2E8F0),
              color: const Color(0xFF0F766E),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Doanh thu: ${_formatVnd(food.revenue)}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}

class _RecentInvoiceCard extends StatelessWidget {
  const _RecentInvoiceCard({required this.invoices});

  final List<QueryDocumentSnapshot<Map<String, dynamic>>> invoices;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Hóa đơn gần đây',
      icon: Icons.history,
      child: invoices.isEmpty
          ? const _StatisticMessage(
              icon: Icons.receipt_long_outlined,
              message: 'Chưa có hóa đơn trong khoảng thời gian này',
              compact: true,
            )
          : Column(
              children: [
                for (final invoice in invoices)
                  _RecentInvoiceTile(invoice: invoice),
              ],
            ),
    );
  }
}

class _RecentInvoiceTile extends StatelessWidget {
  const _RecentInvoiceTile({required this.invoice});

  final QueryDocumentSnapshot<Map<String, dynamic>> invoice;

  @override
  Widget build(BuildContext context) {
    final data = invoice.data();
    final invoiceNo = data['invoiceNo'] as String? ?? invoice.id;
    final totalAmount = data['totalAmount'] as num? ?? 0;
    final paidAt = (data['paidAt'] as Timestamp?)?.toDate();

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const CircleAvatar(child: Icon(Icons.receipt_long, size: 20)),
      title: Text(
        invoiceNo,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(_formatDateTime(paidAt)),
      trailing: Text(
        _formatVnd(totalAmount),
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF0F766E)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.isStrong = false,
  });

  final String label;
  final String value;
  final bool isStrong;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isStrong ? FontWeight.w900 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: isStrong ? const Color(0xFF0F766E) : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatisticMessage extends StatelessWidget {
  const _StatisticMessage({
    required this.icon,
    required this.message,
    this.compact = false,
  });

  final IconData icon;
  final String message;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? 10 : 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: compact ? 28 : 44, color: const Color(0xFF64748B)),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatisticData {
  const _StatisticData({
    required this.revenue,
    required this.subtotal,
    required this.discount,
    required this.pointsUsed,
    required this.pointsEarned,
    required this.invoiceCount,
    required this.orderCount,
    required this.servedTableCount,
    required this.servingTableCount,
    required this.topFoods,
    required this.recentInvoices,
  });

  final num revenue;
  final num subtotal;
  final num discount;
  final int pointsUsed;
  final int pointsEarned;
  final int invoiceCount;
  final int orderCount;
  final int servedTableCount;
  final int servingTableCount;
  final List<_FoodSale> topFoods;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> recentInvoices;
}

class _FoodSale {
  _FoodSale({required this.name});

  final String name;
  int quantity = 0;
  num revenue = 0;
}

String _formatDateTime(DateTime? date) {
  if (date == null) return '-';
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$day/$month/${date.year} $hour:$minute';
}

String _formatVnd(num value) {
  final number = value.round();
  final text = number.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    final indexFromEnd = text.length - i;
    buffer.write(text[i]);
    if (indexFromEnd > 1 && indexFromEnd % 3 == 1) {
      buffer.write('.');
    }
  }
  return '${buffer.toString()}đ';
}
