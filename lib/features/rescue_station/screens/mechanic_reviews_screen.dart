import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../models/station_model.dart';
import '../providers/station_details_provider.dart';
import '../theme/station_detail_theme.dart';

class MechanicReviewsScreen extends ConsumerWidget {
  const MechanicReviewsScreen({super.key, required this.station});
  final StationModel station;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(stationModelProvider(station.id)) ?? station;
    final reviews = ref.watch(stationReviewsProvider(current.id));
    return Theme(
      data: StationDetailTheme.light,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Đánh giá trạm'),
          leading: IconButton(
            tooltip: 'Quay lại',
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/trang-chu'),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              current.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: StationDetailColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Wrap(
                spacing: 10,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Icon(
                    Icons.star_rounded,
                    color: StationDetailColors.yellow,
                    size: 30,
                  ),
                  Text(
                    current.rating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    current.reviewCount == null
                        ? 'Đánh giá dịch vụ'
                        : '${current.reviewCount} lượt đánh giá',
                    style: const TextStyle(
                      fontSize: 12,
                      color: StationDetailColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (reviews.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    Icon(
                      Icons.rate_review_outlined,
                      size: 40,
                      color: StationDetailColors.muted,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Chưa có nhận xét để hiển thị.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: StationDetailColors.muted),
                    ),
                  ],
                ),
              ),
            for (final review in reviews)
              Container(
                key: ValueKey('station-review-${review.id}'),
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: StationDetailColors.border),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            review.author,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Text(
                          DateFormat('dd/MM/yyyy').format(review.createdAt),
                          style: const TextStyle(
                            fontSize: 10,
                            color: StationDetailColors.muted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Semantics(
                      label: '${review.stars} trên 5 sao',
                      child: Row(
                        children: [
                          for (var star = 1; star <= 5; star++)
                            Icon(
                              star <= review.stars
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              size: 18,
                              color: StationDetailColors.yellow,
                            ),
                        ],
                      ),
                    ),
                    if (review.comment.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        review.comment,
                        style: const TextStyle(fontSize: 13, height: 1.6),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
