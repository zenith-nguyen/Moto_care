import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../activity/providers/activity_provider.dart';
import '../../home/data/home_station_details.dart';
import '../../home/providers/home_discovery_provider.dart';
import '../../home/providers/home_provider.dart';
import '../../partner/providers/partner_provider.dart';
import '../../rescue/providers/service_rating_provider.dart';
import '../data/station_profiles.dart';
import '../models/station_model.dart';
import '../services/station_details_service.dart';

final stationProfilesProvider = Provider<Map<String, StationProfile>>(
  (ref) => stationProfiles,
);

final stationDetailsServiceProvider = Provider<StationDetailsService>(
  (ref) => const StationDetailsService(),
);

final stationModelProvider = Provider.autoDispose.family<StationModel?, String>(
  (ref, id) {
    final shops = ref
        .watch(partnerShopsProvider)
        .where((shop) => shop.id == id);
    if (shops.isEmpty) return null;
    final shop = shops.first;
    return ref
        .watch(stationDetailsServiceProvider)
        .build(
          shop: shop,
          details: homeStationDetailsFor(
            id,
            ref.watch(homeStationDetailsProvider),
          ),
          profile:
              ref.watch(stationProfilesProvider)[id] ?? defaultStationProfile,
          distanceKm: stationDistanceKm(
            shop.station,
            ref.watch(rescueLocationProvider),
          ),
        );
  },
);

final stationFavoritesProvider =
    NotifierProvider<StationFavoritesController, Set<String>>(
      StationFavoritesController.new,
    );

class StationFavoritesController extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  void toggle(String id) {
    final next = {...state};
    if (!next.remove(id)) next.add(id);
    state = Set.unmodifiable(next);
  }
}

/// Confirmed reviews use the order's partner ID, never its display name.
/// The customer's own confirmed ratings are shown first, followed by a stable
/// set of community reviews so a station profile never looks empty.
final stationReviewsProvider = Provider.autoDispose
    .family<List<StationReview>, String>((ref, id) {
      final activity = ref.watch(activityProvider);
      final mine = [
        for (final review in ref.watch(serviceRatingsProvider).values)
          if (activity.orderById(review.orderId)?.partnerId == id)
            StationReview(
              id: review.orderId,
              author: 'Bạn',
              stars: review.stars,
              comment: review.comment,
              createdAt: review.createdAt,
            ),
      ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return List.unmodifiable([...mine, ..._communityReviews(id)]);
    });

/// A deterministic slice of community reviews, so each station shows a stable,
/// realistic set. These illustrate the review UI; the customer's own ratings
/// above are the confirmed ones.
List<StationReview> _communityReviews(String id) {
  const pool = <(String, int, String)>[
    (
      'Trần Hoàng Nam',
      5,
      'Xe mình thủng lốp lúc đêm trên đường xa, thợ tới siêu nhanh trong 10 '
          'phút, vá lốp rất cẩn thận và đúng giá niêm yết. Rất an tâm!',
    ),
    (
      'Nguyễn Minh Phương',
      5,
      'Xe đột ngột chết máy giữa trưa nắng 35 độ, may bắt được thợ gần nên tới '
          'liền. Thợ kiểm tra bugi và bình ắc quy rất nhiệt tình.',
    ),
    (
      'Lê Quốc Bảo',
      4,
      'Thợ tới sau khoảng 15 phút, có kẹt xe một chút, nhưng kỹ và kích bình '
          'ắc quy chuyên nghiệp. Còn chỉ mẹo bảo quản xe nữa.',
    ),
    (
      'Phạm Thu Hà',
      5,
      'Hết xăng dọc đường buổi tối, gọi là có người mang tới ngay. Giá hợp lý, '
          'thái độ dễ thương.',
    ),
    (
      'Đỗ Văn Khánh',
      5,
      'Thay lốp nhanh gọn, báo giá rõ ràng trước khi làm, không phát sinh. '
          'Sẽ ủng hộ tiếp.',
    ),
    (
      'Vũ Thị Mai',
      4,
      'Dịch vụ ổn, thợ lịch sự. Chờ hơi lâu do giờ cao điểm nhưng xử lý gọn.',
    ),
  ];
  final seed = id.hashCode.abs();
  final count = 3 + seed % 3; // 3..5 reviews
  final now = DateTime.now();
  return [
    for (var i = 0; i < count; i++)
      () {
        final entry = pool[(seed + i) % pool.length];
        return StationReview(
          id: 'community-$id-$i',
          author: entry.$1,
          stars: entry.$2,
          comment: entry.$3,
          createdAt: now.subtract(Duration(days: 1 + (seed + i * 3) % 20)),
        );
      }(),
  ];
}
