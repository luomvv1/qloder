part of payment_view;

// Header thanh toán: mã order, bàn, trạng thái và tạm tính.
class _PaymentHeader extends StatelessWidget {
  const _PaymentHeader({required this.order, required this.table});

  final RestaurantOrder order;
  final RestaurantTable table;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: const Icon(Icons.receipt_long, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.id,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                Text('${table.name} - ${order.status}'),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('Tạm tính'),
              Text(
                formatMoney(order.subtotal),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Cảnh báo khi còn món chưa xác nhận nên chưa được thanh toán.
class _PendingWarning extends StatelessWidget {
  const _PendingWarning();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: const Padding(
        padding: EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Còn món chưa xác nhận. Quay lại màn hình gọi món và bấm xác nhận trước khi thanh toán.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Tóm tắt các món trong order để nhân viên kiểm tra trước khi thu tiền.
class _OrderItemsSummary extends StatelessWidget {
  const _OrderItemsSummary({required this.details});

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
              'Món đã gọi',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            if (details.isEmpty)
              const Text('Order chưa có món.')
            else
              for (final detail in details)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${detail.quantity} x ${detail.foodName} (${detail.variantName})',
                        ),
                      ),
                      Text(
                        formatMoney(detail.lineTotal),
                        style: const TextStyle(fontWeight: FontWeight.w700),
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

// Khung tìm/thêm thành viên và chọn số điểm muốn sử dụng.
class _CustomerPanel extends StatelessWidget {
  const _CustomerPanel({
    required this.controller,
    required this.order,
    required this.onCreateCustomer,
  });

  final PaymentController controller;
  final RestaurantOrder order;
  final VoidCallback onCreateCustomer;

  @override
  Widget build(BuildContext context) {
    final customer = controller.customer;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Khách hàng thành viên',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 420;

                final phoneField = TextField(
                  controller: controller.phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Số điện thoại',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                );
                final searchButton = FilledButton.icon(
                  onPressed: controller.isSearchingCustomer
                      ? null
                      : controller.findCustomer,
                  icon: controller.isSearchingCustomer
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                  label: const Text('Tìm'),
                );

                if (compact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      phoneField,
                      const SizedBox(height: 10),
                      searchButton,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: phoneField),
                    const SizedBox(width: 10),
                    searchButton,
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: controller.isCreatingCustomer
                  ? null
                  : onCreateCustomer,
              icon: controller.isCreatingCustomer
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.person_add_alt_1),
              label: const Text('Thêm thành viên mới'),
            ),
            if (customer != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.fullName,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    Text('Điểm hiện có: ${customer.points}'),
                    Text(
                      'Điểm cộng sau thanh toán: ${controller.pointsEarned(order.subtotal)}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 420;

                  final pointsField = TextField(
                    controller: controller.pointsController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Điểm sử dụng',
                      helperText:
                          '1 điểm = ${formatMoney(controller.settings.pointValue)}',
                      prefixIcon: const Icon(Icons.stars_outlined),
                    ),
                  );
                  final maxButton = OutlinedButton(
                    onPressed: () => controller.useMaxPoints(order.subtotal),
                    child: const Text('Dùng tối đa'),
                  );

                  if (compact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        pointsField,
                        const SizedBox(height: 10),
                        maxButton,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: pointsField),
                      const SizedBox(width: 10),
                      maxButton,
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Chọn phương thức thanh toán: tiền mặt hoặc chuyển khoản.
class _PaymentMethodPanel extends StatelessWidget {
  const _PaymentMethodPanel({required this.controller});

  final PaymentController controller;

  @override
  Widget build(BuildContext context) {
    const methods = ['Tiền mặt', 'Chuyển khoản'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Phương thức thanh toán',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                for (final method in methods)
                  ChoiceChip(
                    label: Text(method),
                    selected: controller.paymentMethod == method,
                    onSelected: (_) => controller.setPaymentMethod(method),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Khung tính tổng: tạm tính, giảm giá, trừ điểm và thành tiền.
class _TotalPanel extends StatelessWidget {
  const _TotalPanel({required this.controller, required this.order});

  final PaymentController controller;
  final RestaurantOrder order;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Tổng thanh toán',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            // Giảm giá là số tiền trừ trực tiếp trước khi tính điểm sử dụng.
            TextField(
              controller: controller.discountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Giảm giá',
                prefixIcon: Icon(Icons.discount_outlined),
              ),
            ),
            const SizedBox(height: 12),
            _MoneyRow(label: 'Tạm tính', value: order.subtotal),
            _MoneyRow(label: 'Giảm giá', value: -controller.discountAmount),
            _MoneyRow(
              label: 'Trừ điểm',
              value: -controller.pointsValueForSubtotal(order.subtotal),
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
                  formatMoney(controller.totalAmount(order.subtotal)),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: Theme.of(context).colorScheme.primary,
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

// Một dòng tiền trong bảng tổng thanh toán.
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

// Định dạng tiền Việt, có hỗ trợ số âm cho giảm giá/trừ điểm.
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
