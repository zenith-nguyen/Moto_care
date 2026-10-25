import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/revo_brand.dart';
import '../../../core/theme/revo_theme.dart';
import '../application/professional_profile_provider.dart';
import '../application/provider_reviews_provider.dart';
import '../application/provider_stats_provider.dart';
import '../../reviews/domain/order_review.dart';
import '../domain/provider_models.dart';
import 'provider_formatters.dart';

/// Thống kê & Đánh giá: weekly operations come from the real backend
/// (GET /providers/me/statistics/weekly). Rank and the sample review list are
/// illustrative placeholders, clearly labelled "Dữ liệu minh họa" because the
/// backend does not expose those aggregates yet.
class ProviderStatsScreen extends ConsumerWidget {
  const ProviderStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekly = ref.watch(providerWeeklyStatsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Thống kê & Đánh giá')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(providerWeeklyStatsProvider),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            weekly.when(
              loading: () => const Card(
                child: Padding(
                  padding: EdgeInsets.all(28),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (error, _) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: RevoBrandColors.dangerDark,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Không tải được thống kê tuần.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () =>
                            ref.invalidate(providerWeeklyStatsProvider),
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (stats) => _WeeklyCard(stats: stats),
            ),
            const SizedBox(height: 20),
            const _RankCard(),
            const SizedBox(height: 20),
            const _ReviewsSection(),
          ],
        ),
      ),
    );
  }
}

class _WeeklyCard extends StatelessWidget {
  const _WeeklyCard({required this.stats});

  final ProviderWeeklyStats stats;

  @override
  Widget build(BuildContext context) {
    final rating = stats.averageRating;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tuần này', style: RevoTypography.title),
            const SizedBox(height: 2),
            Text(
              'Từ ${stats.weekStart} · giờ Việt Nam',
              style: RevoTypography.caption,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    icon: Icons.task_alt_rounded,
                    label: 'Đơn hoàn tất',
                    value: '${stats.completedOrders}',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatTile(
                    icon: Icons.payments_rounded,
                    label: 'Thu nhập',
                    value: formatProviderMoney(stats.creditedAmount),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    icon: Icons.star_rounded,
                    label: 'Đánh giá TB',
                    value: rating == null
                        ? 'Chưa có'
                        : rating.toStringAsFixed(1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatTile(
                    icon: Icons.reviews_rounded,
                    label: 'Lượt đánh giá',
                    value: '${stats.reviewCount}',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: RevoBrandColors.surfaceSoft,
        borderRadius: BorderRadius.circular(RevoRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: RevoBrandColors.primary, size: 22),
          const SizedBox(height: 10),
          Text(value, style: RevoTypography.title),
          const SizedBox(height: 2),
          Text(label, style: RevoTypography.caption),
        ],
      ),
    );
  }
}

class _DemoBadge extends StatelessWidget {
  const _DemoBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: RevoBrandColors.warningSoft,
        borderRadius: BorderRadius.circular(RevoRadius.pill),
      ),
      child: const Text(
        'Dữ liệu minh họa',
        style: TextStyle(
          color: RevoBrandColors.warningDark,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _RankCard extends ConsumerWidget {
  const _RankCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tier = ref.watch(professionalProfileProvider).asData?.value.tier;
    final tierName = _tierName(tier);
    final isReal = tierName != null;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: RevoGradients.balance,
        borderRadius: BorderRadius.circular(RevoRadius.lg),
        boxShadow: RevoShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.workspace_premium_rounded, color: Colors.white),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Hạng thợ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              // The tier is real backend data; only the progress toward the
              // next tier below is illustrative.
              if (!isReal) const _DemoBadge(),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            tierName ?? 'Vàng',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(RevoRadius.pill),
            child: const LinearProgressIndicator(
              value: 0.7,
              minHeight: 8,
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isReal
                ? 'Tiến độ lên hạng tiếp theo là minh họa.'
                : 'Còn 3 đơn nữa để lên hạng Bạch Kim (minh họa).',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  static String? _tierName(String? tier) => switch (tier?.toUpperCase()) {
    'STANDARD' => 'Tiêu chuẩn',
    'SILVER' => 'Bạc',
    'GOLD' => 'Vàng',
    'PLATINUM' => 'Bạch Kim',
    _ => null,
  };
}

class _ReviewsSection extends ConsumerWidget {
  const _ReviewsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviews = ref.watch(providerReviewsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Đánh giá khách hàng', style: RevoTypography.title),
            ),
            reviews.maybeWhen(
              data: (data) => data.count == 0
                  ? const SizedBox.shrink()
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 18,
                          color: RevoBrandColors.warning,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${data.averageRating.toStringAsFixed(1)} · ${data.count} đánh giá',
                          style: RevoTypography.label,
                        ),
                      ],
                    ),
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),
        const SizedBox(height: 12),
        reviews.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Expanded(child: Text('Không tải được đánh giá.')),
                  TextButton(
                    onPressed: () => ref.invalidate(providerReviewsProvider),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          ),
          data: (data) => data.items.isEmpty
              ? const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Chưa có đánh giá nào. Hoàn tất đơn để nhận đánh giá từ khách.',
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (final review in data.items)
                      _ReviewCard(review: review),
                  ],
                ),
        ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});

  final OrderReview review;

  @override
  Widget build(BuildContext context) {
    final date = review.createdAt.toLocal();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Đơn #${review.orderId}',
                      style: RevoTypography.label,
                    ),
                  ),
                  Row(
                    children: [
                      for (var i = 0; i < 5; i++)
                        Icon(
                          i < review.rating
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          size: 16,
                          color: RevoBrandColors.warning,
                        ),
                    ],
                  ),
                ],
              ),
              if (review.comment != null &&
                  review.comment!.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(review.comment!.trim(), style: RevoTypography.body),
              ],
              const SizedBox(height: 6),
              Text(
                '${date.day.toString().padLeft(2, '0')}/'
                '${date.month.toString().padLeft(2, '0')}/${date.year}',
                style: RevoTypography.body.copyWith(
                  color: RevoBrandColors.textSubtle,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
