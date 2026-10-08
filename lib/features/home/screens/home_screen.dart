import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../activity/models/rescue_order.dart';
import '../../profile/models/user_profile.dart';
import '../../profile/providers/profile_provider.dart';
import '../../rescue_station/models/rescue_station.dart';
import '../../vehicle/providers/vehicle_provider.dart';
import '../models/home_destination.dart';
import '../models/home_user.dart';
import '../providers/home_provider.dart';
import '../theme/home_theme.dart';
import '../widgets/home_bottom_navigation.dart';
import '../widgets/home_header.dart';
import '../widgets/home_sections.dart';
import '../widgets/home_service_grid.dart';
import '../widgets/home_sheets.dart';
import '../widgets/promo_banner_slider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, this.user, this.onDestinationSelected});
  final HomeUser? user;
  final ValueChanged<HomeDestination>? onDestinationSelected;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          widget.user == null ||
          ref.read(profileProvider).initialized) {
        return;
      }
      final user = widget.user!;
      ref
          .read(profileProvider.notifier)
          .initialize(
            UserProfile(
              id: user.memberId ?? '',
              fullName: user.displayName.trim(),
              memberTier: user.membershipLabel,
              rewardPoints: user.rewardPoints,
            ),
          );
    });
  }

  HomeUser get _user {
    final state = ref.read(profileProvider);
    if (!state.initialized && widget.user != null) return widget.user!;
    return HomeUser(
      displayName: state.profile.fullName,
      memberId: state.profile.id,
      membershipLabel: state.profile.memberTier,
      rewardPoints: state.profile.rewardPoints,
    );
  }

  void _selectDestination(HomeDestination destination) {
    if (destination == HomeDestination.home) return;
    if (widget.onDestinationSelected != null) {
      widget.onDestinationSelected!(destination);
      return;
    }
    final route = switch (destination) {
      HomeDestination.activity => '/hoat-dong',
      HomeDestination.myVehicles => '/xe-cua-toi',
      HomeDestination.rescueStations => '/tram-cuu-ho',
      HomeDestination.messages => '/tin-nhan',
      HomeDestination.personalInfo => '/thong-tin-ca-nhan',
      HomeDestination.account => '/tai-khoan',
      HomeDestination.services => '/dich-vu',
      HomeDestination.membership => '/tich-diem',
      HomeDestination.nearbyServices => '/tram-sac-tiem-sua',
      HomeDestination.vouchers => '/kho-voucher',
      HomeDestination.prices => '/bang-gia',
      HomeDestination.partnership => '/dang-ky-tho',
      HomeDestination.serviceCommitment => '/cam-ket-dich-vu',
      HomeDestination.help => '/faq',
      HomeDestination.emergencyTips => '/meo-xu-ly',
      HomeDestination.home => '/trang-chu',
    };
    context.push(
      route,
      extra:
          destination == HomeDestination.personalInfo ||
              destination == HomeDestination.membership
          ? _user
          : null,
    );
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
    if (context.mounted && order != null) _showOrderNotice(context, order);
  }

  void _showOrderNotice(BuildContext context, RescueOrder order) {
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

  void _selectService(BuildContext context, HomeService service) =>
      context.push(service.partnerRoute);

  void _showStation(BuildContext context, RescueStation station) {
    showHomeSheet<void>(
      context,
      HomeSheetContent(
        title: station.name,
        children: [
          Text(station.address, style: const TextStyle(height: 1.5)),
          const SizedBox(height: 12),
          Text(
            '★ ${station.rating.toStringAsFixed(1)} • ${station.completedRescues} lượt cứu hộ',
            style: const TextStyle(color: HomeColors.secondary),
          ),
          const SizedBox(height: 12),
          const Text(
            'Thông tin trạm tham khảo. Kiểm tra khả dụng và chi phí tại danh sách trạm trước khi gọi.',
            style: TextStyle(color: HomeColors.secondary, height: 1.5),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _selectDestination(HomeDestination.rescueStations);
            },
            child: const Text('Xem danh sách trạm cứu hộ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileProvider);
    final user = state.initialized
        ? HomeUser(
            displayName: state.profile.fullName,
            membershipLabel: state.profile.memberTier,
            rewardPoints: state.profile.rewardPoints,
          )
        : widget.user;
    final name = user?.displayName.trim();
    final vehicle = ref.watch(defaultVehicleProvider);
    final location = ref.watch(rescueLocationProvider);
    final stations = ref.watch(homeNearbyStationsProvider);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: HomeColors.surface,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Theme(
        data: HomeTheme.red,
        child: Builder(
          builder: (context) => Scaffold(
            backgroundColor: HomeColors.background,
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: ListView(
                  key: const ValueKey('home-scroll'),
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    HomeHeader(
                      name: name == null || name.isEmpty ? 'bạn' : name,
                      tier: user?.membershipLabel ?? '',
                      address: location?.address ?? 'Chưa chọn vị trí',
                      vehicle: vehicle == null
                          ? 'Chọn xe cần cứu hộ'
                          : '${vehicle.name} (${vehicle.licensePlate})',
                      onLocation: () => _changeLocation(context),
                      onVehicle: () => _changeVehicle(context),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const PromoBannerSlider(),
                          const SizedBox(height: 20),
                          HomeServiceGrid(
                            onSelected: (service) =>
                                _selectService(context, service),
                          ),
                          const SizedBox(height: 22),
                          HomeClubCard(
                            accentColor: HomeColors.red,
                            gradientColors: const [
                              HomeColors.tint,
                              HomeColors.selected,
                            ],
                            points: user?.rewardPoints ?? 0,
                            onPressed: () =>
                                _selectDestination(HomeDestination.membership),
                          ),
                          const SizedBox(height: 20),
                          HomeNearbySection(
                            stations: stations,
                            location: location,
                            onViewAll: () => _selectDestination(
                              HomeDestination.rescueStations,
                            ),
                            onStation: (station) =>
                                _showStation(context, station),
                          ),
                          const SizedBox(height: 20),
                          HomeOffersSection(
                            onVouchers: () =>
                                _selectDestination(HomeDestination.vouchers),
                            onTips: () => _selectDestination(
                              HomeDestination.emergencyTips,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            bottomNavigationBar: HomeBottomNavigation(
              light: true,
              selectedIconColor: HomeColors.red,
              selectedBackgroundColor: HomeColors.redSelected,
              selectedDestination: HomeDestination.home,
              onSelected: _selectDestination,
            ),
          ),
        ),
      ),
    );
  }
}
