import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/main_navigation.dart';
import '../../activity/models/rescue_order.dart';
import '../../chat/providers/chat_directory_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../../rescue_station/providers/station_details_provider.dart';
import '../../vehicle/providers/vehicle_provider.dart';
import '../data/home_media_assets.dart';
import '../models/home_destination.dart';
import '../models/home_discovery.dart';
import '../models/home_rescue_quick_action.dart';
import '../models/home_user.dart';
import '../providers/home_discovery_provider.dart';
import '../providers/home_provider.dart';
import '../providers/home_weather_provider.dart';
import '../theme/revo_home_theme.dart';
import '../widgets/home_bottom_navigation.dart';
import '../widgets/home_discovery_filter_sheet.dart';
import '../widgets/home_service_grid.dart';
import '../widgets/home_sheets.dart';
import '../widgets/home_station_grid_card.dart';
import '../widgets/smart_weather_rescue_card.dart';
import '../widgets/revo_home_header.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, this.user, this.onDestinationSelected});
  final HomeUser? user;
  final ValueChanged<HomeDestination>? onDestinationSelected;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          widget.user == null ||
          ref.read(profileProvider).initialized) {
        return;
      }
      ref
          .read(profileProvider.notifier)
          .initializeFromHome(widget.user, onlyIfUninitialized: true);
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _selectDestination(HomeDestination destination) {
    if (destination == HomeDestination.home) return;
    if (widget.onDestinationSelected != null) {
      widget.onDestinationSelected!(destination);
      return;
    }
    if (HomeDestination.homeNavigationItems.contains(destination)) {
      navigateMainTab(context, destination);
      return;
    }
    final route = switch (destination) {
      HomeDestination.myVehicles => '/xe-cua-toi',
      HomeDestination.messages => '/tin-nhan',
      HomeDestination.personalInfo => '/thong-tin-ca-nhan',
      HomeDestination.services => '/dich-vu',
      HomeDestination.nearbyServices => '/tram-sac-tiem-sua',
      HomeDestination.prices => '/bang-gia',
      HomeDestination.partnership => '/dang-ky-tho',
      HomeDestination.serviceCommitment => '/cam-ket-dich-vu',
      HomeDestination.help => '/faq',
      HomeDestination.emergencyTips => '/meo-xu-ly',
      _ => '/trang-chu',
    };
    context.push(route);
  }

  Future<void> _changeVehicle(BuildContext context) async {
    final id = await showHomeSheet<String>(context, const HomeVehicleSheet());
    if (!mounted || id == null) return;
    if (id == HomeVehicleSheet.manageVehicles) {
      _selectDestination(HomeDestination.myVehicles);
    } else {
      ref.read(vehicleProvider.notifier).setDefault(id);
    }
  }

  Future<void> _changeLocation(BuildContext context) async {
    final order = await context.push<RescueOrder>('/incident-location');
    if (context.mounted && order != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã lưu yêu cầu thử nghiệm ${order.orderCode}'),
          action: SnackBarAction(
            label: 'Hoạt động',
            onPressed: () => _selectDestination(HomeDestination.activity),
          ),
        ),
      );
    }
  }

  Future<void> _showFilters(BuildContext context) async {
    FocusScope.of(context).unfocus();
    final filters = await showHomeSheet<HomeDiscoveryFilters>(
      context,
      HomeDiscoveryFilterSheet(
        filters: ref.read(homeDiscoveryProvider).filters,
      ),
    );
    if (mounted && filters != null) {
      ref.read(homeDiscoveryProvider.notifier).applyFilters(filters);
    }
  }

  void _showServices(BuildContext context) {
    FocusScope.of(context).unfocus();
    showHomeSheet<void>(
      context,
      Consumer(
        builder: (context, ref, _) {
          final vehicle = ref.watch(defaultVehicleProvider);
          return HomeSheetContent(
            title: 'Cứu hộ khẩn cấp',
            children: [
              Material(
                color: RevoHomeColors.surface,
                borderRadius: BorderRadius.circular(20),
                child: ListTile(
                  key: const ValueKey('home-vehicle'),
                  leading: const Icon(Icons.two_wheeler_outlined),
                  title: Text(
                    vehicle == null
                        ? 'Chọn xe cần cứu hộ'
                        : '${vehicle.name} (${vehicle.licensePlate})',
                    style: const TextStyle(fontSize: 14),
                  ),
                  trailing: const Icon(Icons.expand_more_rounded),
                  onTap: () => _changeVehicle(context),
                ),
              ),
              const SizedBox(height: 20),
              HomeServiceGrid(
                monochrome: true,
                onSelected: (service) {
                  Navigator.pop(context);
                  this.context.push(service.partnerRoute);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _selectQuickAction(HomeRescueQuickAction action) {
    _search.value = TextEditingValue(
      text: action.searchQuery,
      selection: TextSelection.collapsed(offset: action.searchQuery.length),
    );
    ref.read(homeDiscoveryProvider.notifier).selectQuickAction(action);
  }

  void _openStation(BuildContext context, HomeStationListing listing) {
    final station = ref.read(stationModelProvider(listing.station.id));
    if (station == null) return;
    final discovery = ref.read(homeDiscoveryProvider);
    final service =
        discovery.quickAction.serviceType?.label ??
        switch (discovery.category) {
          HomeStationCategory.towing => 'Xe cẩu kéo',
          HomeStationCategory.tire24h => 'Vá xe',
          _ => 'Tất cả dịch vụ',
        };
    context.push(
      '/stations/${Uri.encodeComponent(station.id)}?service=${Uri.encodeQueryComponent(service)}',
      extra: station,
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final location = ref.watch(rescueLocationProvider);
    final discovery = ref.watch(homeDiscoveryProvider);
    final stations = ref.watch(homeDiscoveryStationsProvider);
    final weather = ref.watch(homeWeatherProvider);
    final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Theme(
        data: RevoHomeTheme.light,
        child: Builder(
          builder: (context) => Scaffold(
            backgroundColor: Colors.white,
            extendBody: true,
            body: SafeArea(
              top: false,
              bottom: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: CustomScrollView(
                    key: const ValueKey('home-scroll'),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    slivers: [
                      DecoratedSliver(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          image: DecorationImage(
                            image: AssetImage(
                              HomeMediaAssets.weatherBackground,
                            ),
                            fit: BoxFit.cover,
                            alignment: Alignment.topCenter,
                            colorFilter: ColorFilter.mode(
                              Color(0x3DFFFFFF),
                              BlendMode.srcATop,
                            ),
                          ),
                        ),
                        sliver: SliverMainAxisGroup(
                          slivers: [
                            SliverPadding(
                              padding: EdgeInsets.fromLTRB(
                                20,
                                MediaQuery.paddingOf(context).top + 12,
                                20,
                                12,
                              ),
                              sliver: SliverToBoxAdapter(
                                child: RevoHomeHeader(
                                  location:
                                      location?.address ?? 'Quận 1, TP.HCM',
                                  profile: profile,
                                  hasNotifications: ref
                                      .watch(chatNotificationsProvider)
                                      .isNotEmpty,
                                  onLocation: () => _changeLocation(context),
                                  onNotifications: () => this.context.push(
                                    '/tin-nhan?tab=notifications',
                                  ),
                                  onAccount: () => _selectDestination(
                                    HomeDestination.account,
                                  ),
                                ),
                              ),
                            ),
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                              sliver: SliverToBoxAdapter(
                                child: SmartWeatherRescueCard(
                                  weather: weather.asData?.value,
                                  isLoading: weather.isLoading,
                                  hasWeatherError: weather.hasError,
                                  onRetryWeather: () =>
                                      ref.invalidate(homeWeatherProvider),
                                  searchController: _search,
                                  onSearchChanged: (value) => ref
                                      .read(homeDiscoveryProvider.notifier)
                                      .search(value),
                                  onFilter: () => _showFilters(context),
                                  activeFilterCount:
                                      discovery.filters.activeCount,
                                  selectedAction: discovery.quickAction,
                                  onQuickAction: _selectQuickAction,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                        sliver: SliverToBoxAdapter(
                          child: Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Trạm cứu hộ',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              TextButton(
                                key: const ValueKey('home-services'),
                                onPressed: () => _showServices(context),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Dịch vụ',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(width: 3),
                                    Icon(Icons.arrow_outward_rounded, size: 14),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: SingleChildScrollView(
                          key: const ValueKey('home-categories'),
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              for (final category in HomeStationCategory.values)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ChoiceChip(
                                    key: ValueKey(
                                      'home-category-${category.name}',
                                    ),
                                    label: Text(category.label),
                                    selected: discovery.category == category,
                                    showCheckmark: false,
                                    selectedColor: RevoHomeColors.ink,
                                    backgroundColor: RevoHomeColors.surface,
                                    side: BorderSide.none,
                                    shape: const StadiumBorder(),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 9,
                                    ),
                                    labelStyle: TextStyle(
                                      color: discovery.category == category
                                          ? Colors.white
                                          : RevoHomeColors.muted,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    onSelected: (_) => ref
                                        .read(homeDiscoveryProvider.notifier)
                                        .selectCategory(category),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 22, 20, 14),
                        sliver: SliverToBoxAdapter(
                          child: Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Trạm gần bạn',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text(
                                '${stations.length} trạm',
                                style: const TextStyle(
                                  color: RevoHomeColors.muted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (stations.isEmpty)
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          sliver: SliverToBoxAdapter(
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: RevoHomeColors.surface,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.location_off_outlined,
                                    size: 36,
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Không tìm thấy trạm phù hợp',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Thử từ khóa khác hoặc mở rộng bộ lọc.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: RevoHomeColors.muted,
                                      fontSize: 13,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      _search.clear();
                                      ref
                                          .read(homeDiscoveryProvider.notifier)
                                          .reset();
                                    },
                                    child: const Text('Xóa tìm kiếm và bộ lọc'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverGrid.builder(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                mainAxisExtent: 250 + (scale - 1) * 160,
                              ),
                          itemCount: stations.length,
                          itemBuilder: (context, index) => HomeStationGridCard(
                            key: ValueKey(
                              'home-station-${stations[index].station.id}',
                            ),
                            listing: stations[index],
                            onTap: () => _openStation(context, stations[index]),
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: SizedBox(height: 130 + (scale - 1) * 30),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            bottomNavigationBar: HomeBottomNavigation(
              selectedDestination: HomeDestination.home,
              onSelected: _selectDestination,
            ),
          ),
        ),
      ),
    );
  }
}
