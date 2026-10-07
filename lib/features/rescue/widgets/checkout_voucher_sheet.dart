import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../activity/widgets/order_summary.dart';
import '../../home/theme/home_theme.dart';
import '../../voucher/providers/voucher_provider.dart';
import '../models/marketplace_booking.dart';

class CheckoutVoucherSheet extends ConsumerStatefulWidget {
  const CheckoutVoucherSheet({super.key, required this.booking});
  final MarketplaceBooking booking;
  @override
  ConsumerState<CheckoutVoucherSheet> createState() =>
      _CheckoutVoucherSheetState();
}

class _CheckoutVoucherSheetState extends ConsumerState<CheckoutVoucherSheet> {
  final _code = TextEditingController();
  String? _error;
  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _apply() {
    final code = _code.text.trim().toUpperCase();
    var matches = ref
        .read(voucherProvider)
        .where((offer) => offer.code == code);
    if (matches.isEmpty) {
      final error = ref.read(voucherProvider.notifier).applyCode(code);
      if (error != null) {
        setState(() => _error = error);
        return;
      }
      matches = ref.read(voucherProvider).where((offer) => offer.code == code);
    }
    if (widget.booking.discountFor(
          matches.first,
          ref.read(voucherClockProvider)(),
        ) ==
        0) {
      setState(
        () => _error = 'Mã đã dùng, hết hạn hoặc đơn chưa đủ điều kiện.',
      );
      return;
    }
    Navigator.pop(context, code);
  }

  @override
  Widget build(BuildContext context) {
    final now = ref.read(voucherClockProvider)();
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: ListView(
          shrinkWrap: true,
          children: [
            const Text(
              'Ưu đãi của bạn',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const ValueKey('checkout-voucher-code'),
              controller: _code,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: 'Mã giảm giá',
                errorText: _error,
              ),
              onSubmitted: (_) => _apply(),
            ),
            const SizedBox(height: 12),
            FilledButton(onPressed: _apply, child: const Text('Áp dụng mã')),
            ListTile(
              title: const Text('Không dùng voucher'),
              onTap: () => Navigator.pop(context, 'none'),
            ),
            for (final offer in ref.watch(voucherProvider))
              ListTile(
                leading: const Icon(
                  Icons.local_offer_outlined,
                  color: HomeColors.red,
                ),
                title: Text('${offer.code} • ${offer.title}'),
                subtitle: Text(
                  widget.booking.discountFor(offer, now) > 0
                      ? 'Giảm ${formatOrderPrice(widget.booking.discountFor(offer, now))}'
                      : '${offer.minimumOrder} • Chưa đủ điều kiện, hết hạn hoặc đã dùng',
                ),
                enabled: widget.booking.discountFor(offer, now) > 0,
                onTap: () => Navigator.pop(context, offer.code),
              ),
          ],
        ),
      ),
    );
  }
}
