import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';

const _navy = Color(0xFF172638);
const _secondary = Color(0xFF71839E);
const _border = Color(0xFFE3EAF3);

/// A forecast based only on the real completed-order history.
class RankForecast {
  const RankForecast(
      {required this.weeklyAverage, required this.weeks, required this.span});
  final double weeklyAverage;
  final int weeks;
  final int span; // days of history the average is based on

  /// Needs at least two weeks of history and three completed orders, otherwise
  /// the pace would be a guess. Returns null when there is not enough data.
  static RankForecast? compute(
      {required List<OrderHistoryItem> history,
      required DateTime now,
      required int remaining}) {
    final done =
        history.where((o) => o.status == OrderStatus.completed).toList();
    if (done.length < 3 || remaining <= 0) return null;
    final first =
        done.map((o) => o.time).reduce((a, b) => a.isBefore(b) ? a : b);
    final days = now.difference(first).inDays;
    if (days < 14) return null;
    final weekly = done.length / (days / 7);
    return RankForecast(
        weeklyAverage: weekly, weeks: (remaining / weekly).ceil(), span: days);
  }
}

/// "Hạng thợ & Quyền lợi": the existing tier data from the profile, shown with
/// progress. Nothing here invents rules, benefits or progress.
class RankBenefitsScreen extends StatelessWidget {
  const RankBenefitsScreen({super.key});

  Widget _card({required Widget child, Key? key}) => Container(
      key: key,
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _border),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0A172638), blurRadius: 14, offset: Offset(0, 5))
          ]),
      child: child);

  Widget _title(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(2, 22, 2, 10),
      child: Text(text,
          style: appText(16, weight: FontWeight.w700, color: _navy)));

  @override
  Widget build(BuildContext context) => ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final p = appState.profile;
        final remaining = p.ordersToNextTier;
        final reached = remaining == 0;
        final forecast = RankForecast.compute(
            history: appState.history,
            now: DateTime.now(),
            remaining: remaining);
        return Scaffold(
            backgroundColor: const Color(0xFFF7F9FC),
            body: SafeArea(
                child: Column(children: [
              const ScreenHeader(title: 'Hạng thợ & Quyền lợi'),
              Expanded(
                  child: ListView(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                      children: [
                    _card(
                        key: const ValueKey('rank-current'),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Expanded(
                                    child: Text('Hạng hiện tại',
                                        style: appText(13, color: _secondary))),
                                Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                        color: AppColors.light,
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    child: Text('Demo',
                                        style: appText(10,
                                            weight: FontWeight.w600,
                                            color: AppColors.primary))),
                              ]),
                              const SizedBox(height: 4),
                              Text(p.tierName,
                                  key: const ValueKey('rank-tier-name'),
                                  style: appText(30,
                                      weight: FontWeight.w700, color: _navy)),
                              const SizedBox(height: 4),
                              Text(
                                  reached
                                      ? 'Đã đủ số đơn để lên Hạng ${p.nextTierName}'
                                      : 'Tiến tới Hạng ${p.nextTierName}',
                                  style: appText(13.5,
                                      weight: FontWeight.w600,
                                      color: AppColors.primary)),
                              const SizedBox(height: 14),
                              ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                      key: const ValueKey('rank-progress'),
                                      value: p.tierProgress,
                                      minHeight: 10,
                                      backgroundColor: AppColors.light,
                                      color: AppColors.primary)),
                              const SizedBox(height: 10),
                              Wrap(
                                  alignment: WrapAlignment.spaceBetween,
                                  spacing: 12,
                                  runSpacing: 4,
                                  children: [
                                    Text(
                                        '${p.tierOrders}/${p.nextTierTarget} đơn đã ghi nhận',
                                        key: const ValueKey('rank-recorded'),
                                        style: appText(12.5, color: _navy)),
                                    Text(
                                        reached
                                            ? 'Đã đạt mốc'
                                            : 'Còn $remaining đơn hợp lệ',
                                        key: const ValueKey('rank-remaining'),
                                        style: appText(12.5,
                                            weight: FontWeight.w600,
                                            color: _navy)),
                                  ]),
                              const SizedBox(height: 10),
                              Text(
                                  'Demo · Tiến độ mô phỏng, chưa phải xếp hạng chính thức.',
                                  style: appText(11,
                                      color: _secondary, height: 1.4)),
                            ])),
                    _title('Điều kiện lên hạng'),
                    _card(
                        key: const ValueKey('rank-conditions'),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                        reached
                                            ? Icons.check_circle_rounded
                                            : Icons
                                                .radio_button_unchecked_rounded,
                                        size: 22,
                                        color: reached
                                            ? AppColors.success
                                            : _secondary),
                                    const SizedBox(width: 12),
                                    Expanded(
                                        child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                          Text(
                                              'Hoàn thành ${p.nextTierTarget} đơn hợp lệ',
                                              style: appText(14,
                                                  weight: FontWeight.w600,
                                                  color: _navy)),
                                          const SizedBox(height: 3),
                                          Text(
                                              'Hiện tại: ${p.tierOrders}/${p.nextTierTarget} đơn',
                                              style: appText(12.5,
                                                  color: _secondary)),
                                        ])),
                                  ]),
                              const SizedBox(height: 12),
                              Text(
                                  'Ứng dụng hiện chưa có thêm tiêu chí nào khác (điểm đánh giá, chất lượng dịch vụ). Các tiêu chí này sẽ được hiển thị khi REVO công bố quy định chính thức.',
                                  style: appText(11.5,
                                      color: _secondary, height: 1.5)),
                            ])),
                    _title('Dự kiến lên hạng'),
                    _card(
                        key: const ValueKey('rank-forecast'),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  reached
                                      ? 'Bạn đã đủ số đơn để đạt mốc Hạng ${p.nextTierName}.'
                                      : 'Còn $remaining đơn để đạt mốc Hạng ${p.nextTierName}.',
                                  style: appText(14,
                                      weight: FontWeight.w600,
                                      color: _navy,
                                      height: 1.4)),
                              const SizedBox(height: 8),
                              Text(
                                  reached
                                      ? ''
                                      : forecast == null
                                          ? 'Chưa đủ dữ liệu để dự đoán thời điểm lên hạng. Cần ít nhất 2 tuần lịch sử với 3 đơn hoàn thành.'
                                          : 'Với tốc độ trung bình ${forecast.weeklyAverage.toStringAsFixed(1)} đơn/tuần (tính trên ${forecast.span} ngày), bạn có thể đạt mốc sau khoảng ${forecast.weeks} tuần. Đây chỉ là ước tính, không phải cam kết.',
                                  key: const ValueKey('rank-forecast-text'),
                                  style: appText(12.5,
                                      color: _secondary, height: 1.5)),
                            ])),
                    _title('Quyền lợi'),
                    _card(
                        key: const ValueKey('rank-benefits'),
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.info_outline_rounded,
                                  size: 22, color: _secondary),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: Text(
                                      'Quyền lợi theo từng hạng chưa được REVO công bố trong ứng dụng. Phần này sẽ được cập nhật khi có thông tin chính thức.',
                                      style: appText(12.5,
                                          color: _secondary, height: 1.5))),
                            ])),
                  ])),
            ])));
      });
}
