import 'package:flutter/material.dart';

import '../../activity/models/rescue_order.dart';
import '../../activity/widgets/order_summary.dart';
import '../../home/models/rescue_location.dart';
import '../models/checkout_quote.dart';
import '../models/marketplace_booking.dart';
import '../theme/order_summary_theme.dart';

class OrderSummaryCard extends StatelessWidget {
  const OrderSummaryCard({super.key, required this.child, this.shadow = false});
  final Widget child;
  final bool shadow;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: OrderSummaryColors.border),
      boxShadow: shadow
          ? const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 14,
                offset: Offset(0, 4),
              ),
            ]
          : null,
    ),
    child: Material(color: Colors.transparent, child: child),
  );
}

class OrderSummaryHeading extends StatelessWidget {
  const OrderSummaryHeading(this.title, {super.key});
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      title,
      style: const TextStyle(
        color: OrderSummaryColors.text,
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class OrderMechanicCard extends StatelessWidget {
  const OrderMechanicCard({
    super.key,
    required this.name,
    required this.distance,
    this.imageAsset,
  });
  final String name;
  final double distance;
  final String? imageAsset;

  @override
  Widget build(BuildContext context) => OrderSummaryCard(
    child: Row(
      children: [
        ClipOval(
          child: SizedBox(
            width: 56,
            height: 56,
            child: imageAsset == null
                ? _placeholder()
                : Image.asset(
                    imageAsset!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _placeholder(),
                  ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: OrderSummaryColors.text,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: OrderSummaryColors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Cách bạn ~${distance.toStringAsFixed(1)} km',
                  style: const TextStyle(
                    fontSize: 12,
                    color: OrderSummaryColors.muted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _placeholder() => const ColoredBox(
    color: OrderSummaryColors.surface,
    child: Icon(Icons.person_rounded, color: OrderSummaryColors.muted),
  );
}

class OrderAccidentLocationCard extends StatelessWidget {
  const OrderAccidentLocationCard({
    super.key,
    required this.addressController,
    required this.addressFocus,
    required this.location,
    required this.loading,
    required this.onChanged,
    required this.onLocate,
    this.error,
  });
  final TextEditingController addressController;
  final FocusNode addressFocus;
  final RescueLocation? location;
  final bool loading;
  final ValueChanged<String> onChanged;
  final VoidCallback onLocate;
  final String? error;

  @override
  Widget build(BuildContext context) => OrderSummaryCard(
    shadow: true,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(
              Icons.location_on_rounded,
              color: OrderSummaryColors.red,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Vị trí sự cố',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            TextButton(
              key: const ValueKey('checkout-change-address'),
              style: TextButton.styleFrom(
                foregroundColor: OrderSummaryColors.red,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              onPressed: () {
                addressFocus.requestFocus();
                addressController.selection = TextSelection(
                  baseOffset: 0,
                  extentOffset: addressController.text.length,
                );
              },
              child: const Text('Thay đổi', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        TextField(
          key: const ValueKey('checkout-address'),
          controller: addressController,
          focusNode: addressFocus,
          minLines: 1,
          maxLines: null,
          scrollPhysics: const NeverScrollableScrollPhysics(),
          maxLength: 240,
          textInputAction: TextInputAction.done,
          style: const TextStyle(
            color: OrderSummaryColors.text,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1.5,
          ),
          decoration: const InputDecoration(
            hintText: 'Nhập địa chỉ nơi xe gặp sự cố',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            contentPadding: EdgeInsets.symmetric(vertical: 8),
            counterText: '',
          ),
          onChanged: onChanged,
        ),
        Text(
          location?.hasCoordinates == true
              ? 'GPS: ${location!.latitude!.toStringAsFixed(6)}, '
                    '${location!.longitude!.toStringAsFixed(6)}'
              : 'Chưa có tọa độ GPS',
          style: const TextStyle(fontSize: 11, color: OrderSummaryColors.muted),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              error!,
              style: const TextStyle(
                fontSize: 12,
                color: OrderSummaryColors.red,
              ),
            ),
          ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            key: const ValueKey('checkout-locate'),
            style: OutlinedButton.styleFrom(
              foregroundColor: OrderSummaryColors.text,
              side: const BorderSide(color: OrderSummaryColors.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            onPressed: loading ? null : onLocate,
            icon: loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location_rounded, size: 16),
            label: Text(
              loading ? 'Đang lấy vị trí...' : 'Lấy vị trí hiện tại',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ),
      ],
    ),
  );
}

class OrderPriceBreakdown extends StatelessWidget {
  const OrderPriceBreakdown({
    super.key,
    required this.booking,
    required this.quote,
  });
  final MarketplaceBooking booking;
  final CheckoutQuote quote;

  @override
  Widget build(BuildContext context) => OrderSummaryCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const OrderSummaryHeading('Chi tiết chi phí'),
        for (final item in booking.items)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: OrderSummaryColors.surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.build_outlined, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        children: [
                          Text(
                            'x${item.quantity}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: OrderSummaryColors.muted,
                            ),
                          ),
                          Text(
                            formatOrderPrice(item.total),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const Divider(height: 16, color: OrderSummaryColors.border),
        _PriceRow('Phí dịch vụ', formatOrderPrice(booking.subtotal)),
        _PriceRow(
          'Phí di chuyển (${quote.distance.toStringAsFixed(1)} km)',
          formatOrderPrice(quote.travelFee),
        ),
        const _PriceRow('Giảm giá (Voucher)', '-0đ'),
        const Divider(height: 24, color: OrderSummaryColors.border),
        _PriceRow(
          'Tổng thanh toán',
          formatOrderPrice(quote.total),
          prominent: true,
        ),
      ],
    ),
  );
}

class _PriceRow extends StatelessWidget {
  const _PriceRow(this.label, this.value, {this.prominent = false});
  final String label, value;
  final bool prominent;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final labelWidget = Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: prominent
                ? OrderSummaryColors.text
                : OrderSummaryColors.muted,
            fontWeight: prominent ? FontWeight.w700 : FontWeight.w500,
          ),
        );
        final valueWidget = Text(
          value,
          style: TextStyle(
            color: prominent ? OrderSummaryColors.red : OrderSummaryColors.text,
            fontSize: prominent ? 18 : 14,
            fontWeight: FontWeight.w700,
          ),
        );
        if (constraints.maxWidth < 260 &&
            MediaQuery.textScalerOf(context).scale(14) > 17) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [labelWidget, const SizedBox(height: 4), valueWidget],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: labelWidget),
            const SizedBox(width: 12),
            valueWidget,
          ],
        );
      },
    ),
  );
}

String orderPaymentLabel(RescuePaymentMethod method) =>
    method == RescuePaymentMethod.cash ? 'Tiền mặt cho thợ' : method.label;

class OrderPaymentCard extends StatelessWidget {
  const OrderPaymentCard({
    super.key,
    required this.payment,
    required this.onChoose,
  });
  final RescuePaymentMethod payment;
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) => OrderSummaryCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const OrderSummaryHeading('Phương thức thanh toán'),
        ListTile(
          key: const ValueKey('checkout-payment'),
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            payment == RescuePaymentMethod.cash
                ? Icons.payments_outlined
                : Icons.account_balance_wallet_outlined,
            color: OrderSummaryColors.text,
          ),
          title: Text(
            orderPaymentLabel(payment),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          trailing: const Icon(
            Icons.expand_more_rounded,
            color: OrderSummaryColors.muted,
          ),
          onTap: onChoose,
        ),
      ],
    ),
  );
}
