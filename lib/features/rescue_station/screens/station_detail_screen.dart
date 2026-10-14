import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../partner/providers/partner_cart_provider.dart';
import '../models/station_model.dart';
import '../providers/station_details_provider.dart';
import '../services/rescue_station_actions.dart';
import '../services/station_share_service.dart';
import '../theme/station_detail_theme.dart';
import '../widgets/station_detail_bottom_bar.dart';
import '../widgets/station_info_header.dart';
import '../widgets/station_photo_carousel.dart';
import '../widgets/station_quick_specs.dart';
import '../widgets/station_services_section.dart';
import 'mechanic_reviews_screen.dart';

/// Deep links resolve the current directory; a route extra keeps the model typed.
class StationDetailRoute extends ConsumerWidget {
  const StationDetailRoute({
    super.key,
    required this.stationId,
    this.station,
    this.serviceType = 'Tất cả dịch vụ',
    this.showReviews = false,
  });

  final String stationId;
  final StationModel? station;
  final String serviceType;
  final bool showReviews;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(stationModelProvider(stationId));
    if (current == null) {
      return Theme(
        data: StationDetailTheme.light,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Thông tin trạm'),
            leading: IconButton(
              tooltip: 'Quay lại',
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go('/trang-chu'),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.storefront_outlined,
                    size: 48,
                    color: StationDetailColors.muted,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Trạm không còn trong danh sách.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => context.go('/trang-chu'),
                    child: const Text('Về Trang chủ'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    final model = station?.id == stationId ? station! : current;
    return showReviews
        ? MechanicReviewsScreen(station: model)
        : StationDetailScreen(station: model, serviceType: serviceType);
  }
}

class StationDetailScreen extends ConsumerStatefulWidget {
  const StationDetailScreen({
    super.key,
    required this.station,
    this.serviceType = 'Tất cả dịch vụ',
  });

  final StationModel station;
  final String serviceType;

  @override
  ConsumerState<StationDetailScreen> createState() =>
      _StationDetailScreenState();
}

class _StationDetailScreenState extends ConsumerState<StationDetailScreen> {
  bool _sharing = false;

  Future<void> _share(StationModel station, BuildContext buttonContext) async {
    if (_sharing) return;
    final box = buttonContext.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final origin = box.localToGlobal(Offset.zero) & box.size;
    setState(() => _sharing = true);
    try {
      await ref.read(stationShareServiceProvider).share(station, origin);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Không thể chia sẻ thông tin trạm. Vui lòng thử lại.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final station =
        ref.watch(stationModelProvider(widget.station.id)) ?? widget.station;
    final favorite = ref.watch(stationFavoritesProvider).contains(station.id);
    final shop = ref.watch(partnerShopProvider(station.id));
    final canBook =
        station.isOpen &&
        shop != null &&
        shop.menu(widget.serviceType).isNotEmpty;
    final bannerHeight = 285.0 + MediaQuery.paddingOf(context).top;
    return Theme(
      data: StationDetailTheme.light,
      child: Scaffold(
        body: CustomScrollView(
          key: const ValueKey('station-detail-scroll'),
          slivers: [
            SliverToBoxAdapter(
              child: Stack(
                children: [
                  StationPhotoCarousel(
                    images: station.imageAssets,
                    height: bannerHeight,
                    favorite: favorite,
                    onBack: () => context.canPop()
                        ? context.pop()
                        : context.go('/trang-chu'),
                    onFavorite: () => ref
                        .read(stationFavoritesProvider.notifier)
                        .toggle(station.id),
                    onShare: _sharing
                        ? null
                        : (buttonContext) => _share(station, buttonContext),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: bannerHeight - 24),
                    child: StationInfoHeader(
                      station: station,
                      onDirections: () => RescueStationActions.directions(
                        context,
                        ref,
                        station.station,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StationQuickSpecs(
                      station: station,
                      onReviews: () => context.push(
                        '/stations/${Uri.encodeComponent(station.id)}/reviews',
                        extra: station,
                      ),
                    ),
                    const SizedBox(height: 28),
                    StationServicesSection(station: station),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: StationDetailBottomBar(
          isOpen: station.isOpen,
          onBook: !canBook
              ? null
              : () => context.push(
                  '/partners/${Uri.encodeComponent(station.id)}?service=${Uri.encodeQueryComponent(widget.serviceType)}',
                ),
          onChat: () => context.push(
            '/chat-detail',
            extra: ref
                .read(stationDetailsServiceProvider)
                .conversation(station),
          ),
        ),
      ),
    );
  }
}
