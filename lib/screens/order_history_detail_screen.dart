import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/ui.dart';
import 'order_chat_screen.dart';

/// Mở bottom sheet đánh giá khách (dùng ở màn Hoàn thành đơn).
Future<void> showRateCustomerSheet(
    BuildContext context, OrderHistoryItem item) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(
          20, 0, 20, MediaQuery.viewInsetsOf(ctx).bottom + 20),
      child: ListenableBuilder(
        listenable: appState,
        builder: (_, __) => _RatingSection(
          item: item,
          onSubmitted: () {
            Navigator.of(ctx).pop();
            showAppSnack(context, 'Đã gửi đánh giá khách ${item.customerName}');
          },
        ),
      ),
    ),
  );
}

const _navy = Color(0xFF172638);
const _secondary = Color(0xFF71839E);
const _wallet = Color(0xFF317CBB);

class OrderHistoryDetailScreen extends StatelessWidget {
  const OrderHistoryDetailScreen({super.key, required this.item});

  final OrderHistoryItem item;

  IconData get _vehicleIcon => switch (vehicleLabel(item.vehicle)) {
        'Ô tô' => Icons.directions_car_rounded,
        'Xe tay ga' => Icons.electric_moped_rounded,
        _ => Icons.two_wheeler_rounded,
      };

  void _openChat(BuildContext context) => Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => OrderChatScreen(
              orderId: item.orderId,
              customerName: item.customerName,
              customerPhone: item.customerPhone,
              messages: item.messages,
              readOnly: true)));

  /// Only orders that really produced a wallet transaction open the wallet.
  void _openWallet(BuildContext context) {
    final hasTransaction =
        appState.transactions.any((t) => t.orderCode == item.code);
    if (!hasTransaction) {
      showAppSnack(context,
          'Đơn trình diễn không ghi vào Ví nên không có giao dịch tương ứng.');
      return;
    }
    appState.setTab(2);
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  Widget _header(BuildContext context) => Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
      child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Row(children: [
            Tooltip(
                message: 'Quay lại',
                child: Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    elevation: 2,
                    shadowColor: const Color(0x26317CBB),
                    child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => Navigator.of(context).maybePop(),
                        child: const SizedBox(
                            width: 44,
                            height: 44,
                            child: Icon(Icons.arrow_back_rounded,
                                size: 22, color: _wallet))))),
            Expanded(
                child: Text('Chi tiết đơn hàng',
                    textAlign: TextAlign.center,
                    style: appText(22, weight: FontWeight.w700, color: _navy))),
            const SizedBox(width: 44),
          ])));

  Widget _statusRow(bool done) => Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: 8,
          spacing: 12,
          children: [
            Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                    color: done ? AppColors.successSoft : AppColors.dangerSoft,
                    borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(done ? Icons.check_circle_rounded : Icons.cancel_rounded,
                      size: 18,
                      color: done
                          ? const Color(0xFF12A15B)
                          : AppColors.dangerDark),
                  const SizedBox(width: 6),
                  Text(done ? 'Hoàn thành' : 'Đã hủy',
                      style: appText(12.5,
                          weight: FontWeight.w600,
                          color: done
                              ? AppColors.successDark
                              : AppColors.dangerDark)),
                ])),
            Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 17, color: _secondary),
              const SizedBox(width: 6),
              Text(formatDayTime(item.time),
                  style: appText(12.5, color: _secondary)),
            ]),
          ]);

  Widget _customerCard(BuildContext context) => _SoftCard(
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
                shape: BoxShape.circle, color: Color(0xFFE4EFFA)),
            child: Text(initialsOf(item.customerName),
                style: appText(15, weight: FontWeight.w700, color: _navy))),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item.customerName,
              style: appText(16,
                  weight: FontWeight.w700, color: _navy, height: 1.25)),
          const SizedBox(height: 2),
          Text(item.code, style: appText(12.5, color: _secondary, height: 1.3)),
        ])),
        const SizedBox(width: 8),
        Tooltip(
            message: 'Lịch sử trò chuyện',
            child: Material(
                color: const Color(0xFFE4EFFA),
                shape: const CircleBorder(),
                child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => _openChat(context),
                    child: const SizedBox(
                        width: 46,
                        height: 46,
                        child: Icon(Icons.chat_bubble_outline_rounded,
                            size: 22, color: _wallet))))),
      ]));

  Widget _vehicleCard() => _SoftCard(
      gradient: const [Color(0xFFF3F8FD), Color(0xFFE6F1FB)],
      borderColor: const Color(0xFFDCE9F6),
      wave: const Color(0xFFD5E8F8),
      waveAtTop: true,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(children: [
        Row(children: [
          Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x14317CBB),
                        blurRadius: 10,
                        offset: Offset(0, 4))
                  ]),
              child: Icon(_vehicleIcon, size: 28, color: _wallet)),
          const SizedBox(width: 16),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(vehicleLabel(item.vehicle),
                    style: appText(16, weight: FontWeight.w700, color: _navy)),
                const SizedBox(height: 4),
                Text(item.issue,
                    style: appText(15, color: _secondary, height: 1.3)),
              ])),
        ]),
        const SizedBox(height: 12),
        const Divider(height: 1, color: Color(0xFFD8E6F4)),
        const SizedBox(height: 12),
        Row(children: [
          Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.location_on_rounded,
                  size: 18, color: _wallet)),
          const SizedBox(width: 12),
          Expanded(
              child: Text(item.address,
                  style: appText(13.5, color: _navy, height: 1.35))),
        ]),
      ]));

  Widget _incomeCard() => _SoftCard(
      key: const ValueKey('detail-income'),
      gradient: const [Color(0xFFF3FCF8), Color(0xFFE0F6EC)],
      borderColor: const Color(0xFFD9F1E6),
      wave: const Color(0xFFC9EEDC),
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
                color: const Color(0xFFD7F3E6),
                borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.account_balance_wallet_outlined,
                key: ValueKey('detail-income-icon'),
                size: 28,
                color: Color(0xFF12A15B))),
        const SizedBox(width: 16),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Thu nhập', style: appText(13.5, color: _secondary)),
          const SizedBox(height: 2),
          FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(formatVnd(item.earning),
                  key: const ValueKey('detail-income-amount'),
                  style: appText(26,
                      weight: FontWeight.w700, color: _navy, height: 1.2))),
        ])),
      ]));

  Widget _walletButton(BuildContext context) => Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFD9E8F6), width: 1)),
      child: InkWell(
          key: const ValueKey('detail-wallet'),
          borderRadius: BorderRadius.circular(20),
          onTap: () => _openWallet(context),
          child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  child: Row(children: [
                    const Icon(Icons.account_balance_wallet_outlined,
                        size: 24, color: _wallet),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Text('Xem trong ví',
                            style: appText(15.5,
                                weight: FontWeight.w700, color: _wallet))),
                    const Icon(Icons.chevron_right_rounded,
                        size: 24, color: _wallet),
                  ])))));

  @override
  Widget build(BuildContext context) {
    final done = item.status == OrderStatus.completed;
    return Scaffold(
        backgroundColor: const Color(0xFFF2F7FD),
        body: Stack(children: [
          const Positioned.fill(
              child: IgnorePointer(child: _DetailBackground())),
          SafeArea(
              child: ListenableBuilder(
            listenable: appState,
            builder: (context, _) => Column(children: [
              _header(context),
              Expanded(
                  child: ListView(
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
                      children: [
                    _statusRow(done),
                    const SizedBox(height: 16),
                    _customerCard(context),
                    const SizedBox(height: 14),
                    _vehicleCard(),
                    if (done) ...[
                      const SizedBox(height: 14),
                      _incomeCard(),
                    ],
                    if (done && item.customerRating != null) ...[
                      const SizedBox(height: 14),
                      _SoftCard(
                          padding: const EdgeInsets.all(14),
                          child: Column(children: [
                            Row(children: [
                              const Icon(Icons.verified_outlined,
                                  size: 26, color: AppColors.primary),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: Text('Đánh giá từ khách',
                                      style: appText(15,
                                          weight: FontWeight.w600,
                                          color: _navy))),
                              Text(
                                  '${item.customerRating!.toStringAsFixed(1)} ',
                                  style: appText(20,
                                      weight: FontWeight.w700, color: _navy)),
                              const Icon(Icons.star_rounded,
                                  color: Color(0xFFFFA81F), size: 26),
                            ]),
                            if (item.customerReview != null)
                              Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: Text('“${item.customerReview}”',
                                      style: appText(13.5,
                                          color: _secondary, height: 1.4),
                                      textAlign: TextAlign.center)),
                          ])),
                    ],
                    if (done) ...[
                      const SizedBox(height: 14),
                      _walletButton(context),
                    ],
                    const SizedBox(height: 14),
                    _SoftCard(
                        padding: EdgeInsets.zero,
                        child: Theme(
                            data: Theme.of(context)
                                .copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              key: const ValueKey('detail-extra'),
                              tilePadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),
                              childrenPadding:
                                  const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              shape: const Border(),
                              collapsedShape: const Border(),
                              iconColor: _secondary,
                              collapsedIconColor: _secondary,
                              leading: const Icon(Icons.description_outlined,
                                  size: 26, color: _secondary),
                              title: Text('Thông tin bổ sung',
                                  style: appText(16,
                                      weight: FontWeight.w500, color: _navy)),
                              children: [
                                KeyValueRow('Mã đơn', item.code),
                                KeyValueRow('Biển số', item.plate),
                                KeyValueRow('Dòng xe', item.vehicle),
                                if (done) ...[
                                  KeyValueRow('Giá ban đầu',
                                      formatVnd(item.initialPrice)),
                                  KeyValueRow('Phụ phí phát sinh',
                                      formatVnd(item.extra)),
                                  if (item.extraReason != null)
                                    Text(item.extraReason!,
                                        style: appText(12,
                                            color: AppColors.textSub)),
                                  for (final line in item.extraItems)
                                    KeyValueRow(
                                        '${line.name} × ${line.quantity}',
                                        formatVnd(line.amount)),
                                  KeyValueRow(
                                      'Chiết khấu', formatVnd(item.fee)),
                                  KeyValueRow(
                                      'Giá cuối', formatVnd(item.finalPrice)),
                                ],
                                const SizedBox(height: 16),
                                _Timeline(
                                    events: item.timeline, cancelled: !done),
                                const SizedBox(height: 12),
                                SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton(
                                        onPressed: () => _openChat(context),
                                        style: OutlinedButton.styleFrom(
                                            minimumSize: const Size(0, 46),
                                            foregroundColor: _navy,
                                            side: const BorderSide(
                                                color: AppColors.border),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 10),
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(14))),
                                        child: Text('Xem lại lịch sử chat',
                                            textAlign: TextAlign.center,
                                            style: appText(13,
                                                weight: FontWeight.w600,
                                                color: _navy)))),
                                if (done)
                                  Padding(
                                      padding: const EdgeInsets.only(top: 10),
                                      child: PrimaryButton(
                                          label: 'Đánh giá khách',
                                          onPressed: () =>
                                              showRateCustomerSheet(
                                                  context, item))),
                              ],
                            ))),
                  ])),
            ]),
          )),
        ]));
  }
}

/// White (or tinted) rounded card with a soft shadow, optional gradient and a
/// decorative corner wave that never intercepts touches.
class _SoftCard extends StatelessWidget {
  const _SoftCard(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(16),
      this.gradient,
      this.borderColor = const Color(0xFFE8EEF6),
      this.wave,
      this.waveAtTop = false});
  final Widget child;
  final EdgeInsets padding;
  final List<Color>? gradient;
  final Color borderColor;
  final Color? wave;
  final bool waveAtTop;
  @override
  Widget build(BuildContext context) => DecoratedBox(
      decoration: BoxDecoration(
          color: gradient == null ? Colors.white : null,
          gradient: gradient == null
              ? null
              : LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: gradient!),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: borderColor, width: 1),
          boxShadow: const [
            BoxShadow(
                color: Color(0x10172638), blurRadius: 18, offset: Offset(0, 6))
          ]),
      child: ClipRRect(
          borderRadius: BorderRadius.circular(21),
          child: Stack(children: [
            if (wave != null)
              Positioned.fill(
                  child: IgnorePointer(
                      child: CustomPaint(
                          painter: _CornerWave(wave!, atTop: waveAtTop)))),
            Padding(padding: padding, child: child),
          ])));
}

class _CornerWave extends CustomPainter {
  const _CornerWave(this.color, {required this.atTop});
  final Color color;
  final bool atTop;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withValues(alpha: .55);
    final w = size.width;
    final h = size.height;
    final path = Path();
    if (atTop) {
      path
        ..moveTo(w * .62, 0)
        ..quadraticBezierTo(w * .8, h * .22, w, h * .2)
        ..lineTo(w, 0)
        ..close();
    } else {
      path
        ..moveTo(w * .66, h)
        ..quadraticBezierTo(w * .84, h * .55, w, h * .42)
        ..lineTo(w, h)
        ..close();
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CornerWave old) =>
      old.color != color || old.atTop != atTop;
}

/// Very light blue wash with a soft curve in the lower-left corner.
class _DetailBackground extends StatelessWidget {
  const _DetailBackground();
  @override
  Widget build(BuildContext context) => const RepaintBoundary(
      child: DecoratedBox(
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                Color(0xFFE9F2FC),
                Color(0xFFF3F8FD),
                Color(0xFFF7FAFE)
              ])),
          child: SizedBox.expand(
              child: CustomPaint(painter: _BackgroundCurves()))));
}

class _BackgroundCurves extends CustomPainter {
  const _BackgroundCurves();
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final lower = Path()
      ..moveTo(0, h * .84)
      ..cubicTo(w * .25, h * .8, w * .5, h * .9, w * .62, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(lower, Paint()..color = const Color(0x14317CBB));
    final upper = Path()
      ..moveTo(w * .55, 0)
      ..quadraticBezierTo(w * .8, h * .06, w, h * .05)
      ..lineTo(w, 0)
      ..close();
    canvas.drawPath(upper, Paint()..color = const Color(0x0F317CBB));
  }

  @override
  bool shouldRepaint(_BackgroundCurves old) => false;
}

class _Stars extends StatelessWidget {
  const _Stars({required this.value});
  final int value;
  static const double size = 26;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            i <= value ? Icons.star_rounded : Icons.star_outline_rounded,
            size: size,
            color: i <= value ? AppColors.warning : AppColors.textMuted,
          ),
      ],
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.events, required this.cancelled});
  final List<TimelineEvent> events;
  final bool cancelled;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < events.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 18,
                  child: Column(
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        margin: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                          color: cancelled && i == events.length - 1
                              ? AppColors.danger
                              : AppColors.ink,
                          shape: BoxShape.circle,
                        ),
                      ),
                      if (i < events.length - 1)
                        Expanded(
                            child:
                                Container(width: 3, color: AppColors.border)),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formatHm(events[i].time),
                          style: appText(13,
                              weight: FontWeight.w500,
                              color: AppColors.textSub),
                        ),
                        Text(events[i].label,
                            style: appText(13, weight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Đánh giá khách (thợ đánh giá): hiển thị đánh giá đã gửi, hoặc form nếu chưa đánh giá.
class _RatingSection extends StatefulWidget {
  const _RatingSection({required this.item, required this.onSubmitted});
  final OrderHistoryItem item;
  final VoidCallback onSubmitted;

  @override
  State<_RatingSection> createState() => _RatingSectionState();
}

class _RatingSectionState extends State<_RatingSection> {
  final _commentController = TextEditingController();
  int _stars = 0;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final rated = item.rating != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SectionTitle(
          'Đánh giá khách',
          subtitle: rated
              ? null
              : 'Đánh giá giúp REVO bảo vệ thợ khỏi khách không hợp tác.',
        ),
        const SizedBox(height: 10),
        if (rated)
          SurfaceCard(
            radius: AppRadius.md,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Stars(value: item.rating!),
                if (item.ratingComment != null) ...[
                  const SizedBox(height: 6),
                  Text(item.ratingComment!, style: appText(13, height: 1.45)),
                ],
              ],
            ),
          )
        else ...[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 1; i <= 5; i++)
                IconButton(
                  tooltip: '$i sao',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => setState(() => _stars = i),
                  icon: Icon(
                    i <= _stars
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 26,
                    color:
                        i <= _stars ? AppColors.warning : AppColors.textMuted,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _commentController,
            minLines: 2,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            style: appText(15),
            decoration: InputDecoration(
              hintText: 'Nhận xét về khách (không bắt buộc)',
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                borderSide:
                    const BorderSide(color: AppColors.border, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                borderSide: const BorderSide(color: AppColors.ink, width: 1.6),
              ),
            ),
          ),
          const SizedBox(height: 14),
          PrimaryButton(
            label: 'Gửi đánh giá',
            height: 46,
            onPressed: _stars == 0
                ? null
                : () {
                    appState.rateCustomer(
                        item, _stars, _commentController.text);
                    widget.onSubmitted();
                  },
          ),
        ],
      ],
    );
  }
}
