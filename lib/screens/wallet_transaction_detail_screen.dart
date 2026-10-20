import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/app_state.dart';
import 'order_chat_screen.dart';
import 'order_received_screen.dart';
import 'order_history_detail_screen.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/ui.dart';

/// Total length of the success celebration (ms, see the timeline helpers).
const _totalMs = 1500;
Interval _at(int from, int to, [Curve curve = Curves.easeOut]) =>
    Interval(from / _totalMs, to / _totalMs, curve: curve);

class WalletTransactionDetailScreen extends StatefulWidget {
  const WalletTransactionDetailScreen({super.key, required this.tx});

  final WalletTransaction tx;

  @override
  State<WalletTransactionDetailScreen> createState() =>
      _WalletTransactionDetailScreenState();
}

class _WalletTransactionDetailScreenState
    extends State<WalletTransactionDetailScreen>
    with SingleTickerProviderStateMixin {
  // Visual only: runs once when the screen opens and never touches the
  // transaction, the wallet or any app state.
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: _totalMs));
  late final bool _success =
      widget.tx.isCredit || widget.tx.withdrawStatus == WithdrawStatus.approved;
  bool _started = false;

  WalletTransaction get tx => widget.tx;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!_success || MediaQuery.disableAnimationsOf(context)) {
      _c.value = 1;
    } else {
      HapticFeedback.lightImpact();
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// Fade + small upward slide (and optional scale) inside a time window.
  Widget _reveal(Interval window, double dy, Widget child,
      {double fromScale = 1}) {
    final t = CurvedAnimation(parent: _c, curve: window);
    return FadeTransition(
        opacity: t,
        child: AnimatedBuilder(
            animation: t,
            builder: (_, c) => Transform.translate(
                offset: Offset(0, dy * (1 - t.value)),
                child: Transform.scale(
                    scale: fromScale + (1 - fromScale) * t.value, child: c)),
            child: child));
  }

  Widget _badge(bool credit, Color color) {
    const size = 64.0;
    final bg = credit ? AppColors.successSoft : AppColors.dangerSoft;
    final icon = credit ? Icons.check : Icons.arrow_downward;
    if (!_success) {
      return Center(
          child:
              IconCircle(icon: icon, size: size, background: bg, color: color));
    }
    final pop = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: .7, end: 1.08)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 300),
      TweenSequenceItem(
          tween: Tween(begin: 1.08, end: 1.0)
              .chain(CurveTween(curve: Curves.easeOutBack)),
          weight: 250),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: _totalMs - 550),
    ]);
    final tickFade = CurvedAnimation(parent: _c, curve: _at(150, 450));
    final tickScale =
        CurvedAnimation(parent: _c, curve: _at(150, 450, Curves.easeOutBack));
    return Center(
        child: SizedBox(
            width: size,
            height: size,
            child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                      animation: _c,
                      builder: (_, __) => _c.value >= 1000 / _totalMs
                          ? const SizedBox.shrink()
                          : IgnorePointer(
                              child: RepaintBoundary(
                                  child: CustomPaint(
                                      key: const ValueKey('tx-burst'),
                                      size: const Size(size, size),
                                      painter: _SuccessBurst(_at(300, 1000)
                                          .transform(_c.value)))))),
                  FadeTransition(
                      opacity: CurvedAnimation(parent: _c, curve: _at(0, 250)),
                      child: ScaleTransition(
                          key: const ValueKey('tx-circle'),
                          scale: _c.drive(pop),
                          child: Container(
                              width: size,
                              height: size,
                              decoration: BoxDecoration(
                                  color: bg, shape: BoxShape.circle),
                              child: FadeTransition(
                                  opacity: tickFade,
                                  child: ScaleTransition(
                                      scale: Tween(begin: .6, end: 1.0)
                                          .animate(tickScale),
                                      child: Icon(icon,
                                          size: size * 0.46, color: color)))))),
                ])));
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final credit = tx.isCredit;
        final pending = tx.withdrawStatus == WithdrawStatus.pending;
        final failed = tx.withdrawStatus == WithdrawStatus.failed;
        final color = credit
            ? AppColors.success
            : failed
                ? AppColors.textSub
                : AppColors.primary;
        final net = tx.amount;
        final gross = tx.finalPrice == 0 ? net + tx.platformFee : tx.finalPrice;
        final netShare = gross == 0 ? 1.0 : (net / gross).clamp(0.0, 1.0);

        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                ScreenHeader(
                    title: 'Chi tiết giao dịch',
                    trailing: pending && appState.demoEnabled
                        ? PopupMenuButton<bool>(
                            tooltip: 'Mô phỏng giao dịch',
                            icon: const Icon(Icons.science_outlined, size: 20),
                            onSelected: (approved) => appState
                                .resolveWithdraw(tx.txnId, approved: approved),
                            itemBuilder: (_) => const [
                                  PopupMenuItem(
                                      value: true,
                                      child: Text('Demo · Thành công')),
                                  PopupMenuItem(
                                      value: false,
                                      child:
                                          Text('Demo · Thất bại và hoàn tiền'))
                                ])
                        : null),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    children: [
                      _badge(credit, color),
                      const SizedBox(height: 16),
                      // Số tiền: w700 để cùng độ đậm với các tiêu đề / con số khác trên màn hình.
                      _reveal(
                          _at(750, 1200, Curves.easeOutCubic),
                          10,
                          Text(
                            failed
                                ? formatVnd(tx.amount)
                                : formatSignedVnd(tx.amount, plus: credit),
                            textAlign: TextAlign.center,
                            style: appText(24,
                                weight: FontWeight.w700,
                                color: color,
                                letterSpacing: -0.5),
                          ),
                          fromScale: .96),
                      const SizedBox(height: 10),
                      _reveal(
                          _at(850, 1150),
                          6,
                          Center(
                            child: pending
                                ? const StatusBadge.pending('Đang chờ duyệt')
                                : failed
                                    ? const StatusBadge.danger(
                                        'Thất bại · Đã hoàn tiền')
                                    : const StatusBadge.success(
                                        'Giao dịch thành công',
                                        icon: Icons.check),
                          )),
                      if (failed)
                        Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                                'Số tiền đã được hoàn lại vào số dư khả dụng.',
                                textAlign: TextAlign.center,
                                style: appText(12, color: AppColors.textSub))),
                      if (tx.customerName != null) ...[
                        const SizedBox(height: 22),
                        _reveal(
                            _at(950, 1250),
                            8,
                            ShadowCard(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 14, 14, 14),
                              child: Row(
                                children: [
                                  AvatarCircle(
                                      initials: initialsOf(tx.customerName!),
                                      dark: false,
                                      size: 52),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(tx.customerName!,
                                            style: appText(14,
                                                weight: FontWeight.w600)),
                                        Text(
                                          maskPhone(tx.customerPhone!),
                                          style: appText(12,
                                              color: AppColors.textSub),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  RoundIconButton(
                                    icon: Icons.call_outlined,
                                    tooltip: 'Gọi khách',
                                    onTap: () => callCustomer(context,
                                        tx.customerName!, tx.customerPhone!),
                                  ),
                                  const SizedBox(width: 8),
                                  RoundIconButton(
                                    icon: Icons.chat_bubble_outline,
                                    tooltip: 'Nhắn khách',
                                    onTap: () {
                                      final orders = appState.history
                                          .where((o) => o.code == tx.orderCode);
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) => OrderChatScreen(
                                                  orderId:
                                                      tx.orderCode ?? tx.code,
                                                  customerName:
                                                      tx.customerName!,
                                                  customerPhone:
                                                      tx.customerPhone!,
                                                  messages: orders.isEmpty
                                                      ? []
                                                      : orders.first.messages,
                                                  readOnly: true)));
                                    },
                                  ),
                                ],
                              ),
                            )),
                      ],
                      const SizedBox(height: 16),
                      _reveal(
                          _at(1010, 1310),
                          8,
                          SurfaceCard(
                            radius: AppRadius.lg,
                            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (tx.orderCode != null) ...[
                                  Text('Đơn hàng liên quan',
                                      style:
                                          appText(14, weight: FontWeight.w600)),
                                  const SizedBox(height: 6),
                                  _Row('Mã đơn', tx.orderCode!, bold: true),
                                  if (appState.history.any(
                                      (item) => item.orderId == tx.orderCode))
                                    TextButton(
                                        onPressed: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) => OrderHistoryDetailScreen(
                                                    item: appState.history
                                                        .firstWhere((item) =>
                                                            item.orderId ==
                                                            tx.orderCode)))),
                                        child: Text('Xem chi tiết đơn',
                                            style: appText(12,
                                                color: AppColors.primary))),
                                  _Row('Dịch vụ', tx.serviceName ?? '',
                                      bold: true),
                                  _Row(
                                      'Thời gian',
                                      formatDayTime(tx.time)
                                          .replaceAll(' · ', ', '),
                                      bold: true),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 14),
                                    child: DashedDivider(),
                                  ),
                                ],
                                Text('Chi tiết giao dịch',
                                    style:
                                        appText(14, weight: FontWeight.w600)),
                                const SizedBox(height: 6),
                                _Row('Mã giao dịch', tx.txnId, bold: true),
                                if (credit) ...[
                                  _Row('Giá cuối đơn', formatVnd(gross),
                                      bold: true),
                                  _Row(
                                    '- Chiết khấu sàn',
                                    formatSignedVnd(tx.platformFee,
                                        plus: false),
                                    valueColor: AppColors.danger,
                                    bold: true,
                                  ),
                                  const SizedBox(height: 10),
                                  _SplitBar(share: netShare),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 18,
                                    runSpacing: 6,
                                    children: [
                                      _Legend(
                                          color: AppColors.success,
                                          label: 'Thực nhận ${formatVnd(net)}'),
                                      _Legend(
                                        color: AppColors.danger,
                                        label:
                                            'Chiết khấu ${formatVnd(tx.platformFee)}',
                                      ),
                                    ],
                                  ),
                                ] else ...[
                                  const _Row(
                                      'Phương thức', 'Chuyển khoản ngân hàng',
                                      bold: true),
                                  _Row('Thời gian yêu cầu',
                                      formatDayTime(tx.time),
                                      bold: true),
                                ],
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Column(
                    children: [
                      _reveal(
                          _at(1070, 1370),
                          6,
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.shield_outlined,
                                  size: 18, color: AppColors.textSub),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Giao dịch mô phỏng · Không chuyển tiền thật',
                                  style: appText(13, color: AppColors.textSub),
                                ),
                              ),
                            ],
                          )),
                      const SizedBox(height: 14),
                      _reveal(
                          _at(1130, 1430),
                          6,
                          OutlineActionButton(
                            label: 'Sao chép biên nhận',
                            icon: Icons.share_outlined,
                            onPressed: () {
                              Clipboard.setData(ClipboardData(
                                  text:
                                      'REVO · Biên nhận ${tx.txnId}\n${formatSignedVnd(tx.amount, plus: tx.isCredit)}\n${formatDayTime(tx.time)}'));
                              showAppSnack(context, 'Đã sao chép biên nhận.');
                            },
                          )),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      });
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value,
      {this.valueColor = AppColors.ink, this.bold = false});
  final String label;
  final String value;
  final Color valueColor;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return KeyValueRow(
      label,
      value,
      valueStyle: appText(13,
          weight: bold ? FontWeight.w600 : FontWeight.w500, color: valueColor),
    );
  }
}

/// Thanh tỉ lệ thực nhận (xanh) / chiết khấu (đỏ).
class _SplitBar extends StatelessWidget {
  const _SplitBar({required this.share});
  final double share;

  @override
  Widget build(BuildContext context) {
    final net = (share * 1000).round().clamp(1, 999);
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        height: 10,
        child: Row(
          children: [
            Expanded(flex: net, child: Container(color: AppColors.success)),
            Expanded(
                flex: 1000 - net, child: Container(color: AppColors.danger)),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label,
            style:
                appText(12, weight: FontWeight.w500, color: AppColors.textSub)),
      ],
    );
  }
}

/// Eight short rays plus four dots in REVO blue, mint and a touch of gold that
/// drift ~28dp outward while fading out. Drawn once, then removed.
class _SuccessBurst extends CustomPainter {
  const _SuccessBurst(this.t);
  final double t;
  static const _colors = [
    Color(0xFF317CBB),
    Color(0xFF8FD9B8),
    Color(0xFF9CC8F3),
    Color(0xFF317CBB),
    Color(0xFF8FD9B8),
    Color(0xFF9CC8F3),
    Color(0xFF317CBB),
    Color(0xFFF2C14E),
  ];
  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;
    final c = size.center(Offset.zero);
    final ease = Curves.easeOutCubic.transform(t);
    final alpha = (1 - Curves.easeIn.transform(t)).clamp(0.0, 1.0);
    for (var i = 0; i < 8; i++) {
      final a = -math.pi / 2 + i * math.pi / 4 + math.pi / 8;
      final d = Offset(math.cos(a), math.sin(a));
      final start = size.width / 2 + 8 + 24 * ease;
      canvas.drawLine(
          c + d * start,
          c + d * (start + 8),
          Paint()
            ..color = _colors[i].withValues(alpha: alpha)
            ..strokeWidth = 3
            ..strokeCap = StrokeCap.round);
    }
    for (var i = 0; i < 4; i++) {
      final a = -math.pi / 2 + i * math.pi / 2;
      final d = Offset(math.cos(a), math.sin(a));
      canvas.drawCircle(
          c + d * (size.width / 2 + 18 + 22 * ease),
          2.4 * (1 - .4 * t),
          Paint()..color = _colors[(i * 2 + 1) % 8].withValues(alpha: alpha));
    }
  }

  @override
  bool shouldRepaint(_SuccessBurst old) => old.t != t;
}
