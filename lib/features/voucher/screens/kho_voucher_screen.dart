import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/router/main_navigation.dart';
import '../../../core/widgets/service_scaffold.dart';
import '../../home/models/home_destination.dart';
import '../providers/voucher_provider.dart';

class KhoVoucherScreen extends ConsumerStatefulWidget {
  const KhoVoucherScreen({super.key});

  @override
  ConsumerState<KhoVoucherScreen> createState() => _KhoVoucherScreenState();
}

class _KhoVoucherScreenState extends ConsumerState<KhoVoucherScreen> {
  final _promo = TextEditingController();

  @override
  void dispose() {
    _promo.dispose();
    super.dispose();
  }

  void _apply() {
    FocusScope.of(context).unfocus();
    final error = ref.read(voucherProvider.notifier).applyCode(_promo.text);
    showServiceMessage(context, error ?? 'Đã thêm voucher vào kho của bạn.');
    if (error == null) _promo.clear();
  }

  @override
  Widget build(BuildContext context) {
    final vouchers = ref.watch(voucherProvider);
    final now = ref.read(voucherClockProvider)();
    return DefaultTabController(
      length: 2,
      child: ServiceScaffold(
        title: 'Kho ưu đãi',
        selectedDestination: HomeDestination.vouchers,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _promo,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Mã promo code',
                        hintText: 'Nhập mã ưu đãi',
                      ),
                      onSubmitted: (_) => _apply(),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: _apply,
                        icon: const Icon(Icons.redeem),
                        label: const Text('Áp dụng'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: TabBar(
                labelColor: ServiceColors.orange,
                unselectedLabelColor: ServiceColors.muted,
                indicatorColor: ServiceColors.orange,
                tabs: [
                  Tab(text: 'Voucher sẵn có'),
                  Tab(text: 'Lịch sử sử dụng'),
                ],
              ),
            ),
          ],
          body: TabBarView(
            children: [
              for (final used in [false, true])
                Builder(
                  builder: (context) {
                    final items = vouchers
                        .where((v) => (v.usedAt != null) == used)
                        .toList();
                    if (items.isEmpty) {
                      return Center(
                        child: Text(
                          used
                              ? 'Bạn chưa sử dụng voucher nào.'
                              : 'Chưa có voucher sẵn có.',
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: items.length,
                      separatorBuilder: (_, index) =>
                          const SizedBox(height: 16),
                      itemBuilder: (context, index) =>
                          _VoucherCard(voucher: items[index], now: now),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VoucherCard extends StatelessWidget {
  const _VoucherCard({required this.voucher, required this.now});
  final VoucherOffer voucher;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final used = voucher.usedAt != null;
    final expired = !voucher.expiresAt.isAfter(now);
    return CustomPaint(
      painter: _TicketPainter(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.local_offer_outlined,
              color: ServiceColors.orange,
              size: 30,
            ),
            const SizedBox(height: 12),
            Text(
              voucher.title,
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Text(
              'HSD: ${DateFormat('dd/MM/yyyy').format(voucher.expiresAt)}',
              style: const TextStyle(color: ServiceColors.muted),
            ),
            const SizedBox(height: 6),
            Text(voucher.minimumOrder),
            const SizedBox(height: 6),
            Text(
              'Mã: ${voucher.code}',
              style: const TextStyle(color: ServiceColors.orange),
            ),
            const SizedBox(height: 16),
            if (used)
              Text(
                'Đã sử dụng: ${DateFormat('dd/MM/yyyy').format(voucher.usedAt!)}',
                style: const TextStyle(color: ServiceColors.muted),
              )
            else
              FilledButton(
                onPressed: expired ? null : () => returnToHome(context),
                child: Text(expired ? 'Đã hết hạn' : 'Dùng ngay'),
              ),
          ],
        ),
      ),
    );
  }
}

class _TicketPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const inset = 6.0;
    const tooth = 12.0;
    final path = Path()
      ..moveTo(inset, 0)
      ..lineTo(size.width - inset, 0);
    for (var y = 0.0; y < size.height; y += tooth) {
      path.lineTo(size.width, (y + tooth / 2).clamp(0, size.height));
      path.lineTo(size.width - inset, (y + tooth).clamp(0, size.height));
    }
    path.lineTo(inset, size.height);
    for (var y = size.height; y > 0; y -= tooth) {
      path.lineTo(0, (y - tooth / 2).clamp(0, size.height));
      path.lineTo(inset, (y - tooth).clamp(0, size.height));
    }
    path.close();
    canvas.drawPath(path, Paint()..color = ServiceColors.surface);
    canvas.drawPath(
      path,
      Paint()
        ..color = ServiceColors.orange
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_TicketPainter oldDelegate) => false;
}
