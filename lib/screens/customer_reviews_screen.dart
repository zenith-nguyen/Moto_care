import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/ui.dart';
import '../widgets/app_status.dart';
import 'order_history_detail_screen.dart';

/// Reviews the customer left for this mechanic, distinct from mechanic-to-customer ratings.
class CustomerReviewsScreen extends StatelessWidget {
  const CustomerReviewsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
          body: SafeArea(
              child: Column(children: [
        const ScreenHeader(title: 'Đánh giá từ khách hàng'),
        Expanded(
            child: ListenableBuilder(
                listenable: appState,
                builder: (context, _) {
                  final reviews = appState.history
                      .where((o) => o.customerRating != null)
                      .toList();
                  return ListView(padding: AppSpace.pageInsets, children: [
                    SurfaceCard(
                        color: AppColors.surfaceSoft,
                        child: Text(
                            'Đánh giá gắn với từng đơn demo. Tổng ${appState.profile.ratingCount} đánh giá trên hồ sơ là số liệu mẫu, chưa có toàn bộ nội dung chi tiết.',
                            style: appText(12))),
                    const SizedBox(height: 12),
                    if (reviews.isEmpty)
                      const AppStatusView(kind: AppStatusKind.empty),
                    for (final item in reviews)
                      Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: ShadowCard(
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => OrderHistoryDetailScreen(
                                          item: item))),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [
                                      AvatarCircle(
                                          dark: false,
                                          initials:
                                              initialsOf(item.customerName),
                                          size: 34),
                                      const SizedBox(width: 10),
                                      Expanded(
                                          child: Text(item.customerName,
                                              style: AppTypography.label)),
                                      const Icon(Icons.star_rounded,
                                          size: 18, color: AppColors.warning),
                                      Text('${item.customerRating}.0',
                                          style: AppTypography.label)
                                    ]),
                                    const SizedBox(height: 8),
                                    Text(
                                        item.customerReview
                                                    ?.trim()
                                                    .isNotEmpty ==
                                                true
                                            ? item.customerReview!
                                            : 'Khách đã đánh giá, chưa có nhận xét.',
                                        style: appText(13)),
                                    const SizedBox(height: 8),
                                    Text(
                                        '${item.code} · ${formatDayTime(item.time)}',
                                        style: AppTypography.caption),
                                  ]))),
                  ]);
                })),
      ])));
}
