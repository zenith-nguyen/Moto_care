import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/models.dart';
import '../services/weekly_summary_data.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/income_chart.dart';
import '../widgets/order_identity.dart';
import '../widgets/ui.dart';
import '../theme/rank_theme.dart';
import 'order_history_detail_screen.dart';
import 'rank_screen.dart';

/// The existing Weekly Summary route, with all amounts read from the Wallet.
class WeeklySummaryScreen extends StatefulWidget {
  const WeeklySummaryScreen({super.key});

  @override
  State<WeeklySummaryScreen> createState() => _WeeklySummaryScreenState();
}

class _WeeklySummaryScreenState extends State<WeeklySummaryScreen> {
  late DateTime _anchor = DateTime.now();
  bool _monthChart = false;

  @override
  void dispose() {
    // A simulated rank never outlives this screen.
    rankPreview.clear();
    super.dispose();
  }

  void _openTab(int tab) {
    appState.setTab(tab);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _chooseWeek() async {
    final day = await showDatePicker(
      context: context,
      initialDate: _anchor,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'Chọn một ngày trong tuần cần xem',
      cancelText: 'Hủy',
      confirmText: 'Xem tuần',
    );
    if (day != null && mounted) setState(() => _anchor = day);
  }

  WeeklySummaryData _data(DateTime now, {bool monthly = false}) =>
      WeeklySummaryData(
        history: appState.history,
        transactions: appState.transactions,
        anchor: _anchor,
        now: now,
        monthly: monthly,
      );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: appState,
        builder: (context, _) {
          final now = DateTime.now();
          final week = _data(now);
          final chart = _monthChart ? _data(now, monthly: true) : week;
          final lastDay =
              DateTime(week.end.year, week.end.month, week.end.day - 1);
          final range =
              '${formatDM(week.start)} – ${formatDM(lastDay)}/${lastDay.year}';
          return Scaffold(
            backgroundColor: const Color(0xFFF6F9FF),
            body: SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                key: const ValueKey('weekly-summary-scroll'),
                padding: const EdgeInsets.fromLTRB(14, 6, 14, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _header(range),
                    const SizedBox(height: 12),
                    _IncomeHero(
                      week: week,
                      onShare: () {
                        Clipboard.setData(ClipboardData(
                            text:
                                'REVO · $range · Dữ liệu demo\nThu nhập sau phí: ${formatVnd(week.income)}\n${week.orders.length} đơn hoàn thành · ${week.ratingCount} đánh giá'));
                        showAppSnack(context, 'Đã sao chép thành tích.');
                      },
                    ),
                    const SizedBox(height: 10),
                    _metrics(week),
                    const SizedBox(height: 10),
                    _SummaryCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _chartHeader(),
                          const SizedBox(height: 5),
                          Text(
                            _monthChart
                                ? 'Tháng ${_anchor.month}/${_anchor.year} · ${formatVnd(chart.income)}'
                                : 'Thu nhập 7 ngày trong tuần',
                            style: appText(11, color: AppColors.textSub),
                          ),
                          const SizedBox(height: 12),
                          IncomeLineChart(
                              values: chart.dailyIncome, dates: chart.days),
                          if (chart.income == 0)
                            Text('Chưa có giao dịch thu nhập trong kỳ.',
                                style: appText(10, color: AppColors.textSub)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    _SummaryCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Expanded(
                              child: Text('Danh sách đơn trong tuần',
                                  style: appText(15, weight: FontWeight.w700)),
                            ),
                            TextButton(
                              key: const ValueKey('weekly-see-all'),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF111111),
                                padding: const EdgeInsets.only(left: 8),
                                minimumSize: const Size(48, 44),
                              ),
                              onPressed: () => _openTab(1),
                              child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('Xem tất cả',
                                        style: appText(10,
                                            color: const Color(0xFF111111))),
                                    const Icon(Icons.chevron_right, size: 16),
                                  ]),
                            ),
                          ]),
                          if (week.orders.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              child: Text(
                                  'Chưa có đơn hoàn thành trong tuần này.',
                                  style: appText(12, color: AppColors.textSub)),
                            ),
                          for (var i = 0;
                              i < week.orders.take(3).length;
                              i++) ...[
                            if (i > 0)
                              const Divider(
                                  height: 16, color: AppColors.border),
                            _WeeklyOrderRow(
                                item: week.orders[i],
                                income:
                                    week.incomeForOrder(week.orders[i].code)),
                          ],
                          if (week.unmatchedIncome != 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(
                                '${formatVnd(week.unmatchedIncome)} đã ghi có trong Ví; chưa có chi tiết đơn trong kỳ này.',
                                style: appText(10, color: AppColors.textSub),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const _TrustStrip(),
                  ],
                ),
              ),
            ),
            bottomNavigationBar: AppBottomNav(
              currentIndex: appState.tabIndex,
              onChanged: _openTab,
            ),
          );
        },
      );

  Widget _header(String range) => LayoutBuilder(builder: (context, box) {
        final date = OutlinedButton(
          key: const ValueKey('weekly-date-range'),
          onPressed: _chooseWeek,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            backgroundColor: Colors.white,
            side: const BorderSide(color: AppColors.border),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            minimumSize: const Size(0, 36),
            shape: const StadiumBorder(),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.calendar_month_outlined, size: 15),
            const SizedBox(width: 5),
            Text(range, style: appText(9.5, color: AppColors.primary)),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down, size: 14),
          ]),
        );
        final compact = box.maxWidth < 350 ||
            MediaQuery.textScalerOf(context).scale(1) > 1.25;
        final title = Row(children: [
          SizedBox(
            width: 32,
            child: IconButton(
              tooltip: 'Quay lại',
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
          Expanded(
            child: Text('Tổng kết tuần',
                textAlign: TextAlign.center,
                style: appText(17, weight: FontWeight.w700)),
          ),
          if (!compact) date else const SizedBox(width: 32),
        ]);
        return Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          title,
          if (compact) date,
        ]);
      });

  /// "Biểu đồ thu nhập" title and the Tuần/Tháng switch. Wide enough: one row
  /// with the switch on the right; otherwise the switch drops below, still
  /// right-aligned.
  Widget _chartHeader() => LayoutBuilder(builder: (context, box) {
        final title = Text('Biểu đồ thu nhập',
            style: appText(15, weight: FontWeight.w700));
        final painter = TextPainter(
            text: TextSpan(
                text: 'Biểu đồ thu nhập',
                style: appText(15, weight: FontWeight.w700)),
            textDirection: TextDirection.ltr,
            textScaler: MediaQuery.textScalerOf(context))
          ..layout();
        const gap = 16.0;
        final room = box.maxWidth - painter.width - gap;
        final sideBySide = room >= 168;
        final width = sideBySide
            ? room.clamp(168.0, 220.0)
            : box.maxWidth.clamp(0.0, 220.0);
        if (sideBySide) {
          return Row(children: [
            title,
            const Spacer(),
            _periodTabs(width.toDouble()),
          ]);
        }
        return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              title,
              const SizedBox(height: 10),
              Align(
                  alignment: Alignment.centerRight,
                  child: _periodTabs(width.toDouble())),
            ]);
      });

  Widget _periodTabs(double width) {
    final fast = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 200);
    return Container(
      key: const ValueKey('weekly-period-switch'),
      width: width,
      height: 42,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
          color: const Color(0xFFEFF4F9),
          borderRadius: BorderRadius.circular(22)),
      child: Row(children: [
        for (var i = 0; i < 2; i++)
          Expanded(
            child: Semantics(
              selected: _monthChart == (i == 1),
              button: true,
              child: InkWell(
                onTap: () => setState(() => _monthChart = i == 1),
                borderRadius: BorderRadius.circular(19),
                child: AnimatedContainer(
                  key:
                      ValueKey(i == 0 ? 'weekly-tab-week' : 'weekly-tab-month'),
                  duration: fast,
                  curve: Curves.easeOut,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _monthChart == (i == 1)
                        ? const Color(0xFF111111)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(19),
                  ),
                  child: AnimatedDefaultTextStyle(
                      duration: fast,
                      style: appText(11.5,
                          weight: FontWeight.w500,
                          color: _monthChart == (i == 1)
                              ? Colors.white
                              : const Color(0xFF71839E)),
                      child: Text(i == 0 ? 'Tuần này' : 'Tháng này',
                          maxLines: 1, softWrap: false)),
                ),
              ),
            ),
          ),
      ]),
    );
  }

  Widget _metrics(WeeklySummaryData week) => IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(
              child: _MetricCard(
                  key: const ValueKey('weekly-metric-orders'),
                  icon: Icons.assignment_turned_in_outlined,
                  value: '${week.orders.length} đơn',
                  label: 'Đơn hoàn thành',
                  detail: 'Trong tuần này')),
          const SizedBox(width: 12),
          Expanded(
              child: _MetricCard(
                  key: const ValueKey('weekly-metric-rating'),
                  icon: Icons.star_outline_rounded,
                  value: week.averageRating?.toStringAsFixed(1) ?? '—',
                  trailing: week.averageRating == null
                      ? null
                      : const Icon(Icons.star_rounded,
                          size: 20, color: Color(0xFFFFA81F)),
                  label: 'Đánh giá trung bình',
                  detail: week.averageRating == null
                      ? 'Chưa có đánh giá'
                      : '${week.ratingCount} lượt đánh giá')),
        ]),
      );
}

/// What the rank panel shows: the real profile, or a simulated preview.
class _RankView {
  const _RankView(
      this.tierName, this.nextTierName, this.remaining, this.progress,
      {this.simulated = false});
  final String tierName, nextTierName;
  final int remaining;
  final double progress;
  final bool simulated;
}

class _IncomeHero extends StatelessWidget {
  const _IncomeHero({required this.week, required this.onShare});
  final WeeklySummaryData week;
  final VoidCallback onShare;

  Widget _income() => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(children: [
              Expanded(
                  child: Text('Thu nhập tuần này',
                      style: appText(13, color: Colors.white))),
              SizedBox(
                  width: 22,
                  height: 24,
                  child: IconButton(
                      tooltip: 'Sao chép thành tích',
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.ios_share,
                          color: Colors.white, size: 15),
                      onPressed: onShare))
            ]),
            const SizedBox(height: 5),
            FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(formatVnd(week.income),
                    key: const ValueKey('weekly-income-total'),
                    style: appText(30,
                        weight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -.5))),
            const SizedBox(height: 8),
            Text('Demo · Thu nhập sau phí',
                style: appText(9, color: Colors.white.withValues(alpha: .9))),
          ]);

  Duration _d(BuildContext context, int ms) =>
      MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : Duration(milliseconds: ms);

  /// Animates a colour change (text etc.) with the rank-change timing.
  Widget _tint(BuildContext context, Color to,
          Widget Function(Color color) builder) =>
      TweenAnimationBuilder<Color?>(
          tween: ColorTween(end: to),
          duration: _d(context, 400),
          curve: Curves.easeInOutCubic,
          builder: (_, c, __) => builder(c ?? to));

  Widget _switch(BuildContext context, Object key, Widget child) =>
      AnimatedSwitcher(
          duration: _d(context, 300),
          switchInCurve: Curves.easeOut,
          transitionBuilder: (w, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                  position: Tween(begin: const Offset(0, .25), end: Offset.zero)
                      .animate(anim),
                  child: w)),
          layoutBuilder: (cur, prev) => Stack(
              alignment: Alignment.centerLeft,
              children: [...prev, if (cur != null) cur]),
          child: KeyedSubtree(key: ValueKey(key), child: child));

  Widget _rank(BuildContext context, _RankView v, RankVisualTheme st,
          {bool stacked = false}) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          TweenAnimationBuilder<Color?>(
              tween: ColorTween(end: st.badge),
              duration: _d(context, 400),
              builder: (_, c, child) => Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                  child: child),
              child: _switch(
                  context,
                  'icon-${v.tierName}',
                  Icon(Icons.workspace_premium_outlined,
                      color: st.icon, size: 24))),
          const SizedBox(width: 8),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                _tint(context, st.subtitle,
                    (c) => Text('Hạng Thợ', style: appText(10, color: c))),
                _switch(
                    context,
                    'name-${v.tierName}',
                    Text(v.tierName,
                        key: const ValueKey('weekly-tier-name'),
                        style: appText(18,
                            weight: FontWeight.w700, color: st.title))),
              ])),
        ]),
        const SizedBox(height: 4),
        _switch(
            context,
            'next-${v.tierName}',
            Text(
                v.nextTierName.isEmpty
                    ? '${v.tierName} · Hạng cao nhất'
                    : '${v.tierName} → ${v.nextTierName}',
                style: appText(10, weight: FontWeight.w600, color: st.title))),
        const SizedBox(height: 4),
        _tint(
            context,
            st.subtitle,
            (c) => Text(
                v.nextTierName.isEmpty
                    ? 'Bạn đang ở hạng cao nhất'
                    : v.remaining == 0
                        ? 'Đã đủ số đơn cho mốc tiếp theo'
                        : 'Còn ${v.remaining} đơn hợp lệ để đạt mốc tiếp theo',
                style: appText(9, color: c, height: 1.4))),
        const SizedBox(height: 8),
        ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
                tween: Tween(end: v.progress),
                duration: _d(context, 520),
                curve: Curves.easeInOutCubic,
                builder: (_, value, __) => TweenAnimationBuilder<Color?>(
                    tween: ColorTween(end: st.track),
                    duration: _d(context, 400),
                    builder: (_, track, __) => TweenAnimationBuilder<Color?>(
                        tween: ColorTween(end: st.progress),
                        duration: _d(context, 400),
                        builder: (_, fill, __) => LinearProgressIndicator(
                            key: const ValueKey('weekly-rank-progress'),
                            value: value,
                            minHeight: 5,
                            backgroundColor: track,
                            color: fill))))),
        if (v.simulated) ...[
          const SizedBox(height: 6),
          Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              children: [
                Container(
                    key: const ValueKey('weekly-rank-simulated'),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                        color: st.title.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(8)),
                    child: Text('Mô phỏng',
                        style: appText(8.5,
                            weight: FontWeight.w600, color: st.title))),
                InkWell(
                    key: const ValueKey('weekly-rank-preview-end'),
                    onTap: rankPreview.clear,
                    child: ConstrainedBox(
                        constraints:
                            const BoxConstraints(minHeight: 32, minWidth: 32),
                        child: Align(
                            alignment: Alignment.centerRight,
                            child: Text('Kết thúc',
                                style: appText(8.5,
                                    weight: FontWeight.w600,
                                    color: st.link))))),
              ]),
        ],
        if (stacked) const SizedBox(height: 6) else const Spacer(),
        Row(children: [
          Expanded(
              child: InkWell(
                  key: const ValueKey('weekly-rank-link'),
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const RankBenefitsScreen())),
                  child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 44),
                      child: Align(
                          alignment: Alignment.bottomLeft,
                          child: _tint(
                              context,
                              st.link,
                              (c) => Text('Xem lộ trình lên hạng →',
                                  style: appText(9.5,
                                      weight: FontWeight.w600, color: c))))))),
        ]),
        if (appState.demoEnabled && !v.simulated)
          InkWell(
              key: const ValueKey('weekly-rank-try'),
              onTap: rankPreview.runDemo,
              child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 32),
                  child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Xem thử hạng',
                          style: appText(8.5,
                              weight: FontWeight.w600, color: st.subtitle))))),
      ]);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
        listenable: rankPreview, builder: (context, _) => _hero(context));
  }

  Widget _hero(BuildContext context) {
    final p = appState.profile;
    final pv = rankPreview.state;
    final v = pv != null
        ? _RankView(pv.tierName, pv.nextTierName, pv.remaining, pv.progress,
            simulated: true)
        : _RankView(p.tierName, p.nextTierName, p.ordersToNextTier,
            p.nextTierName.isEmpty ? 1.0 : p.tierProgress);
    final st = rankThemeFor(v.tierName);
    return Container(
      key: const ValueKey('weekly-income-hero'),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
            colors: [AppColors.primary, Color(0xFF3685BD)]),
      ),
      child: LayoutBuilder(builder: (context, box) {
        // Very narrow or very large text: income panel above the rank panel.
        final stacked = box.maxWidth < 300 ||
            MediaQuery.textScalerOf(context).scale(1) > 1.45;
        final rank = AnimatedContainer(
            key: const ValueKey('weekly-rank-panel'),
            duration: _d(context, 400),
            curve: Curves.easeInOutCubic,
            padding: const EdgeInsets.fromLTRB(14, 18, 12, 4),
            decoration: BoxDecoration(
                gradient: st.gradient == null
                    ? null
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: st.gradient!),
                border: Border(
                    left: stacked
                        ? BorderSide.none
                        : BorderSide(
                            color: st.border ??
                                Colors.white.withValues(alpha: .25)),
                    top: stacked
                        ? BorderSide(
                            color: st.border ??
                                Colors.white.withValues(alpha: .25))
                        : BorderSide.none)),
            child: _rank(context, v, st, stacked: stacked));
        final income = Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 12, 18),
            child: _income());
        return Stack(children: [
          const Positioned.fill(child: CustomPaint(painter: _HeroWave())),
          stacked
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [income, rank])
              : IntrinsicHeight(
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                      Expanded(flex: 6, child: income),
                      Expanded(flex: 4, child: rank),
                    ])),
        ]);
      }),
    );
  }
}

class _HeroWave extends CustomPainter {
  const _HeroWave();
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * .25, size.height)
      ..cubicTo(size.width * .58, size.height * .42, size.width * .65,
          size.height * 1.25, size.width, size.height * .64)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = Colors.white.withValues(alpha: .06));
  }

  @override
  bool shouldRepaint(covariant _HeroWave oldDelegate) => false;
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard(
      {required this.child,
      this.padding = const EdgeInsets.all(14),
      this.radius = 14});
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x05317CBB), blurRadius: 6, offset: Offset(0, 2))
            ]),
        child: child,
      );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard(
      {super.key,
      required this.icon,
      required this.value,
      required this.label,
      required this.detail,
      this.trailing});
  final IconData icon;
  final String value, label, detail;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => _SummaryCard(
        radius: 19,
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                  color: AppColors.light, shape: BoxShape.circle),
              child: Icon(icon, color: AppColors.primary, size: 22)),
          const SizedBox(height: 12),
          FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(value,
                    style: appText(24,
                        weight: FontWeight.w700, color: AppColors.navy)),
                if (trailing != null) ...[
                  const SizedBox(width: 4),
                  trailing!,
                ],
              ])),
          const SizedBox(height: 4),
          Text(label,
              style: appText(12.5,
                  weight: FontWeight.w600, color: AppColors.navy, height: 1.3)),
          const SizedBox(height: 4),
          Text(detail,
              style: appText(11, color: AppColors.textSub, height: 1.3)),
        ]),
      );
}

class _WeeklyOrderRow extends StatelessWidget {
  const _WeeklyOrderRow({required this.item, required this.income});
  final OrderHistoryItem item;
  final int? income;
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final compact = box.maxWidth < 300 ||
            MediaQuery.textScalerOf(context).scale(1) > 1.25;
        final status = Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
                color: AppColors.successSoft,
                borderRadius: BorderRadius.circular(20)),
            child: Text('Đã hoàn thành',
                style: appText(8, color: AppColors.successDark)));
        // Positive income uses the success green; "not yet credited" keeps blue.
        final money = Text(
            income == null ? 'Chưa ghi có' : '+${formatVnd(income!)}',
            key: ValueKey('weekly-money-${item.code}'),
            style: appText(12,
                weight: FontWeight.w700,
                color: income == null ? AppColors.primary : AppColors.success));
        return InkWell(
          key: ValueKey('weekly-order-${item.code}'),
          borderRadius: BorderRadius.circular(10),
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => OrderHistoryDetailScreen(item: item))),
          child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                VehicleThumbnail(vehicle: item.vehicle, size: 50),
                const SizedBox(width: 10),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('${item.issue} · ${vehicleLabel(item.vehicle)}',
                          style: appText(11, weight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.location_on_outlined,
                                size: 12, color: AppColors.primary),
                            const SizedBox(width: 3),
                            Expanded(
                                child: Text(item.address,
                                    style:
                                        appText(9, color: AppColors.textSub)))
                          ]),
                      const SizedBox(height: 3),
                      Text('${formatDM(item.time)} · ${formatHm(item.time)}',
                          style: appText(8, color: AppColors.textSub)),
                      Text(item.code,
                          style: appText(8, color: AppColors.textSub)),
                      if (compact) ...[
                        const SizedBox(height: 6),
                        Wrap(
                            spacing: 10,
                            runSpacing: 4,
                            children: [status, money])
                      ],
                    ])),
                if (!compact) ...[
                  const SizedBox(width: 8),
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [status, const SizedBox(height: 7), money])
                ],
              ])),
        );
      });
}

/// Display-only strip of the four platform values (no navigation).
class _TrustStrip extends StatelessWidget {
  const _TrustStrip();
  static const _icons = [
    Icons.verified_user_outlined,
    Icons.visibility_outlined,
    Icons.lock_outline,
    Icons.headset_mic_outlined
  ];
  static const _labels = ['Uy tín', 'Tiến trình', 'Minh bạch', 'Hỗ trợ'];

  @override
  Widget build(BuildContext context) => Container(
        key: const ValueKey('weekly-trust-strip'),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 1.5),
            borderRadius: BorderRadius.circular(30)),
        child: LayoutBuilder(builder: (context, box) {
          final style =
              appText(13, weight: FontWeight.w500, color: AppColors.ink);
          final itemWidth = (box.maxWidth - 3 * 10) / 4;
          // Widest label with its icon: if it does not fit beside the icon,
          // put the icon above the text instead of shrinking or clipping.
          var widest = 0.0;
          for (final l in _labels) {
            final p = TextPainter(
                text: TextSpan(text: l, style: style),
                textDirection: TextDirection.ltr,
                textScaler: MediaQuery.textScalerOf(context))
              ..layout();
            if (p.width > widest) widest = p.width;
          }
          final inline = 20 + 7 + widest <= itemWidth;
          return IntrinsicHeight(
              child: Row(children: [
            for (var i = 0; i < 4; i++) ...[
              if (i > 0)
                const VerticalDivider(width: 10, color: AppColors.border),
              Expanded(
                  child: Semantics(
                      label: _labels[i],
                      child: inline
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                  Icon(_icons[i],
                                      size: 20, color: AppColors.primary),
                                  const SizedBox(width: 7),
                                  Flexible(
                                      child: Text(_labels[i], style: style)),
                                ])
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                  Icon(_icons[i],
                                      size: 20, color: AppColors.primary),
                                  const SizedBox(height: 6),
                                  Text(_labels[i],
                                      textAlign: TextAlign.center,
                                      style: style),
                                ]))),
            ],
          ]));
        }),
      );
}
