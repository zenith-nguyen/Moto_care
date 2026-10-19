import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/ui.dart';
import '../widgets/app_status.dart';
import 'wallet_transaction_detail_screen.dart';
import 'withdraw_screen.dart';
import 'weekly_summary_screen.dart';

const _navy = Color(0xFF172638);
const _secondary = Color(0xFF71839E);
const _border = Color(0xFFE3EAF3);
const _ivory = Color(0xFFF4FBF7);

enum _TxSort { newest, oldest }

class MechanicWalletScreen extends StatefulWidget {
  const MechanicWalletScreen({super.key});
  @override
  State<MechanicWalletScreen> createState() => _MechanicWalletScreenState();
}

class _MechanicWalletScreenState extends State<MechanicWalletScreen> {
  final _historyKey = GlobalKey();
  var _sort = _TxSort.newest;

  void _open(Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  Widget _header() => Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Ví của tôi',
            style: appText(MediaQuery.sizeOf(context).width < 360 ? 25 : 30,
                weight: FontWeight.w700, color: _navy, height: 1.2)),
        const SizedBox(height: 8),
        Text('Quản lý số dư và theo dõi các giao dịch thu nhập từ công việc.',
            style: appText(13.5, color: _secondary, height: 1.5)),
      ]));

  Widget _balanceCard() {
    // The art would crowd the amount on very narrow phones, so it is dropped.
    final narrow = MediaQuery.sizeOf(context).width < 360;
    return Container(
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
            gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1F9877),
                  Color(0xFF0E6B56),
                  Color(0xFF05433F)
                ],
                stops: [
                  0,
                  .45,
                  1
                ]),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: const Color(0x33FFFFFF), width: 1),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x330E6B56),
                  blurRadius: 22,
                  offset: Offset(0, 10))
            ]),
        child: Stack(children: [
          const Positioned.fill(child: CustomPaint(painter: _EmeraldPainter())),
          if (!narrow)
            const Positioned(
                right: 10,
                bottom: 6,
                child: SizedBox(
                    key: ValueKey('wallet-card-art'),
                    width: 112,
                    height: 112,
                    child: CustomPaint(painter: _WalletArtPainter()))),
          Padding(
              padding: EdgeInsets.fromLTRB(20, 18, narrow ? 20 : 100, 18),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Flexible(
                          child: Text('Số dư khả dụng',
                              style:
                                  appText(13.5, color: _ivory, height: 1.3))),
                      const SizedBox(width: 8),
                      const Icon(Icons.info_outline_rounded,
                          size: 18, color: _ivory),
                    ]),
                    const SizedBox(height: 6),
                    FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(formatVnd(appState.balance),
                            key: const ValueKey('wallet-balance'),
                            style: appText(34,
                                weight: FontWeight.w700,
                                color: Colors.white,
                                height: 1.2))),
                    const SizedBox(height: 6),
                    Text('Sẵn sàng cho các giao dịch của bạn',
                        style: appText(12.5, color: _ivory, height: 1.4)),
                  ])),
        ]));
  }

  Widget _action(String key, IconData icon, String title, String subtitle,
          VoidCallback onTap) =>
      Material(
          color: const Color(0xFFF1F7FD),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(17),
              side: const BorderSide(color: _border)),
          child: InkWell(
              key: ValueKey(key),
              borderRadius: BorderRadius.circular(17),
              onTap: onTap,
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(6, 14, 6, 12),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(icon, size: 28, color: AppColors.primary),
                    const SizedBox(height: 10),
                    Text(title,
                        textAlign: TextAlign.center,
                        style: appText(12.5,
                            weight: FontWeight.w600,
                            color: _navy,
                            height: 1.25)),
                    const SizedBox(height: 3),
                    Text(subtitle,
                        textAlign: TextAlign.center,
                        style: appText(10.5, color: _secondary, height: 1.3)),
                  ]))));

  Widget _quickActions() {
    final tiles = [
      _action('wallet-action-topup', Icons.account_balance_wallet_outlined,
          'Nạp tiền', 'Qua ngân hàng', () {
        // Wallet income only comes from completed orders; no top-up exists.
        showAppSnack(context,
            'Nạp tiền chưa khả dụng. Ví chỉ ghi nhận thu nhập từ đơn hoàn thành.');
      }),
      _action('wallet-action-withdraw', Icons.credit_card_outlined, 'Rút tiền',
          'Về tài khoản', () => _open(const WithdrawScreen())),
      _action('wallet-action-stats', Icons.bar_chart_rounded, 'Thống kê',
          'Thu nhập', () => _open(const WeeklySummaryScreen())),
    ];
    // Always one row of three equal-width, equal-height cards.
    return IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      for (var i = 0; i < tiles.length; i++) ...[
        if (i > 0) const SizedBox(width: 11),
        Expanded(child: tiles[i]),
      ],
    ]));
  }

  Widget _sortButton() => PopupMenuButton<_TxSort>(
      key: const ValueKey('wallet-sort'),
      tooltip: 'Sắp xếp giao dịch',
      initialValue: _sort,
      onSelected: (v) => setState(() => _sort = v),
      itemBuilder: (_) => [
            PopupMenuItem(
                value: _TxSort.newest,
                child: Text('Mới nhất', style: appText(13))),
            PopupMenuItem(
                value: _TxSort.oldest,
                child: Text('Cũ nhất', style: appText(13))),
          ],
      child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: _border)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.swap_vert_rounded, size: 18, color: _navy),
            const SizedBox(width: 6),
            Text(_sort == _TxSort.newest ? 'Mới nhất' : 'Cũ nhất',
                style: appText(12.5, weight: FontWeight.w500, color: _navy)),
            const Icon(Icons.keyboard_arrow_down_rounded,
                size: 18, color: _navy),
          ])));

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: appState,
        builder: (context, _) {
          final txs = [...appState.transactions]..sort((a, b) =>
              _sort == _TxSort.newest
                  ? b.time.compareTo(a.time)
                  : a.time.compareTo(b.time));
          return Stack(children: [
            const Positioned.fill(
                child: IgnorePointer(child: _WalletBackground())),
            SafeArea(
              bottom: false,
              child: ListView(
                padding: const EdgeInsets.only(bottom: 16),
                children: [
                  _header(),
                  Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: _balanceCard()),
                  Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: _quickActions()),
                  Padding(
                      key: _historyKey,
                      padding: const EdgeInsets.fromLTRB(20, 26, 20, 14),
                      child: Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          runSpacing: 10,
                          spacing: 12,
                          children: [
                            Text('Lịch sử giao dịch',
                                style: appText(20,
                                    weight: FontWeight.w700, color: _navy)),
                            _sortButton(),
                          ])),
                  if (txs.isEmpty)
                    const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: AppStatusView(
                          kind: AppStatusKind.empty,
                          message: 'Chưa có giao dịch nào trong ví.',
                          compact: true,
                        )),
                  for (final tx in txs)
                    Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                        child: _TransactionTile(tx: tx)),
                ],
              ),
            ),
          ]);
        },
      );
}

/// Very light blue wash with one soft curve in the top-right; decorative only.
class _WalletBackground extends StatelessWidget {
  const _WalletBackground();
  @override
  Widget build(BuildContext context) => const RepaintBoundary(
      child: DecoratedBox(
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                Color(0xFFEDF4FC),
                Color(0xFFF7FAFE),
                Color(0xFFF7F9FC)
              ])),
          child: SizedBox.expand(child: CustomPaint(painter: _WalletCurve()))));
}

class _WalletCurve extends CustomPainter {
  const _WalletCurve();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(Offset(size.width * .95, size.height * .05),
        size.width * .45, Paint()..color = const Color(0x12317CBB));
  }

  @override
  bool shouldRepaint(_WalletCurve old) => false;
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.tx});
  final WalletTransaction tx;

  String get _subtitle => tx.isCredit
      ? 'Hoàn thành đơn ${tx.orderCode}'
      : tx.withdrawStatus == WithdrawStatus.failed
          ? 'Rút tiền thất bại · Đã hoàn tiền'
          : tx.withdrawStatus == WithdrawStatus.pending
              ? 'Rút tiền · Đang xử lý'
              : 'Rút tiền thành công';

  @override
  Widget build(BuildContext context) => Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: _border, width: 1)),
      child: InkWell(
          key: ValueKey('wallet-tx-${tx.txnId}'),
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => WalletTransactionDetailScreen(tx: tx))),
          child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: tx.isCredit
                            ? AppColors.successSoft
                            : AppColors.dangerSoft),
                    child: Icon(
                        tx.isCredit
                            ? Icons.add_circle_outline_rounded
                            : Icons.north_east_rounded,
                        size: 24,
                        color: tx.isCredit
                            ? AppColors.successDark
                            : AppColors.dangerDark)),
                const SizedBox(width: 14),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(
                          tx.withdrawStatus == WithdrawStatus.failed
                              ? formatVnd(tx.amount)
                              : formatSignedVnd(tx.amount, plus: tx.isCredit),
                          key: ValueKey('wallet-amount-${tx.txnId}'),
                          style: appText(17,
                              weight: FontWeight.w700,
                              color: _navy,
                              height: 1.25)),
                      const SizedBox(height: 3),
                      Text(_subtitle,
                          style:
                              appText(12.5, color: _secondary, height: 1.35)),
                    ])),
                const SizedBox(width: 8),
                Text(formatDM(tx.time), style: appText(12, color: _secondary)),
                const Icon(Icons.chevron_right_rounded,
                    size: 22, color: _secondary),
              ]))));
}

/// Soft glow and translucent discs behind the balance text; decoration only.
class _EmeraldPainter extends CustomPainter {
  const _EmeraldPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawCircle(
        Offset(w * .08, h * .05),
        w * .45,
        Paint()
          ..shader = const RadialGradient(
                  colors: [Color(0x33FFFFFF), Color(0x00FFFFFF)])
              .createShader(Rect.fromCircle(
                  center: Offset(w * .08, h * .05), radius: w * .45)));
    final disc = Offset(w * .86, h * .6);
    canvas.drawCircle(disc, h * 1.05, Paint()..color = const Color(0x0DFFFFFF));
    canvas.drawCircle(
        disc,
        h * 1.05,
        Paint()
          ..color = const Color(0x1FFFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);
    canvas.drawCircle(Offset(w * .66, h * 1.3), h * .7,
        Paint()..color = const Color(0x0DFFFFFF));
  }

  @override
  bool shouldRepaint(_EmeraldPainter old) => false;
}

/// Frosted wallet and a plain coin (deliberately no glyph on the coin).
class _WalletArtPainter extends CustomPainter {
  const _WalletArtPainter();

  void _glass(Canvas c, RRect r, double alpha) {
    c.drawRRect(
        r,
        Paint()
          ..shader = LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.fromRGBO(190, 240, 215, alpha),
                Color.fromRGBO(70, 170, 130, alpha * .6)
              ]).createShader(r.outerRect));
    c.drawRRect(
        r,
        Paint()
          ..color = const Color(0xB3FFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    canvas.save();
    canvas.translate(s * .5, s * .45);
    canvas.rotate(-.12);
    _glass(
        canvas,
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(s * .06, -s * .1),
                width: s * .62,
                height: s * .42),
            Radius.circular(s * .08)),
        .5);
    canvas.rotate(.06);
    _glass(
        canvas,
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(-s * .02, s * .04),
                width: s * .7,
                height: s * .5),
            Radius.circular(s * .09)),
        .72);
    canvas.restore();
    final coin = Offset(s * .74, s * .72);
    final r = s * .2;
    canvas.drawCircle(
        coin + Offset(0, r * .12), r, Paint()..color = const Color(0x33032B28));
    canvas.drawCircle(
        coin,
        r,
        Paint()
          ..shader = const RadialGradient(
                  center: Alignment(-.4, -.4),
                  colors: [Color(0xFFF1F9EC), Color(0xFFB9D9B8)])
              .createShader(Rect.fromCircle(center: coin, radius: r)));
    canvas.drawCircle(
        coin,
        r * .72,
        Paint()
          ..color = const Color(0x33417D5C)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4);
  }

  @override
  bool shouldRepaint(_WalletArtPainter old) => false;
}
