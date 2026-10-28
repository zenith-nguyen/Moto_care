import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/main_navigation.dart';
import '../../../core/theme/app_theme.dart';
import '../../home/models/home_destination.dart';
import '../../home/models/home_service.dart';
import '../../home/widgets/home_bottom_navigation.dart';
import '../../home/widgets/home_sheets.dart';
import '../../vehicle/providers/vehicle_provider.dart';
import '../models/service_catalog_item.dart';
import '../providers/service_catalog_provider.dart';
import '../theme/service_catalog_theme.dart';
import '../widgets/service_photo_card.dart';

class ServicesScreen extends ConsumerStatefulWidget {
  const ServicesScreen({super.key});
  @override
  ConsumerState<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends ConsumerState<ServicesScreen> {
  final _search = TextEditingController();
  final _scroll = ScrollController();
  String _query = '';
  ServiceCatalogCategory _category = ServiceCatalogCategory.all;

  @override
  void dispose() {
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _openService(HomeService service) {
    FocusScope.of(context).unfocus();
    context.push(service.partnerRoute);
  }

  Future<void> _changeVehicle() async {
    final id = await showHomeSheet<String>(context, const HomeVehicleSheet());
    if (!mounted || id == null) return;
    if (id == HomeVehicleSheet.manageVehicles) {
      context.push('/xe-cua-toi');
    } else {
      ref.read(vehicleProvider.notifier).setDefault(id);
    }
  }

  void _reset() {
    FocusScope.of(context).unfocus();
    _search.clear();
    setState(() {
      _query = '';
      _category = ServiceCatalogCategory.all;
    });
    if (_scroll.hasClients) {
      _scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(
      filteredServiceCatalogProvider((_query, _category)),
    );
    final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
    return Theme(
      data: ServiceCatalogTheme.light,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
          centerTitle: true,
          title: Text('Tất cả dịch vụ', style: AppTextStyles.pageTitle),
          leading: IconButton(
            tooltip: 'Quay lại',
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/trang-chu'),
          ),
        ),
        body: SafeArea(
          top: false,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 380 && scale <= 1.2
                      ? 2
                      : 1;
                  return CustomScrollView(
                    key: const ValueKey('services-catalog-scroll'),
                    controller: _scroll,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                        sliver: SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _banner(),
                              const SizedBox(height: 16),
                              _searchField(),
                              const SizedBox(height: 14),
                            ],
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(child: _filters()),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 14),
                        sliver: SliverToBoxAdapter(
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Danh sách dịch vụ',
                                  style: AppTextStyles.cardTitle,
                                ),
                              ),
                              Text(
                                '${items.length} dịch vụ',
                                style: AppTextStyles.caption.copyWith(
                                  color: ServiceCatalogTheme.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (items.isEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.search_off_rounded,
                                  size: 40,
                                  color: ServiceCatalogTheme.muted,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Không tìm thấy dịch vụ phù hợp',
                                  style: AppTextStyles.body,
                                  textAlign: TextAlign.center,
                                ),
                                TextButton(
                                  onPressed: _reset,
                                  child: const Text('Xem tất cả dịch vụ'),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverGrid.builder(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: columns,
                                  mainAxisExtent:
                                      310 + (scale - 1).clamp(0, 2) * 180,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 14,
                                ),
                            itemCount: items.length,
                            itemBuilder: (context, index) => ServicePhotoCard(
                              key: ValueKey(
                                'service-${items[index].service.name}',
                              ),
                              item: items[index],
                              onTap: () => _openService(items[index].service),
                            ),
                          ),
                        ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                        sliver: SliverToBoxAdapter(child: _utilities()),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
        bottomNavigationBar: HomeBottomNavigation(
          light: true,
          selectedDestination: HomeDestination.services,
          onSelected: (destination) => navigateMainTab(context, destination),
        ),
      ),
    );
  }

  Widget _banner() {
    final vehicle = ref.watch(defaultVehicleProvider);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ServiceCatalogTheme.paleBlue,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bạn cần trợ giúp gì cho xe hôm nay?',
            style: AppTextStyles.cardTitle,
          ),
          const SizedBox(height: 8),
          Text(
            'Cho chúng tôi biết sự cố hoặc nhu cầu bảo dưỡng của bạn.',
            style: AppTextStyles.body.copyWith(
              color: ServiceCatalogTheme.muted,
            ),
          ),
          const SizedBox(height: 14),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            child: ListTile(
              key: const ValueKey('home-vehicle'),
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              leading: const Icon(
                Icons.two_wheeler_outlined,
                color: ServiceCatalogTheme.blue,
              ),
              title: Text(
                vehicle == null
                    ? 'Chọn xe cần cứu hộ'
                    : '${vehicle.name} (${vehicle.licensePlate})',
                style: AppTextStyles.body,
              ),
              trailing: const Icon(Icons.expand_more_rounded),
              onTap: _changeVehicle,
            ),
          ),
        ],
      ),
    );
  }

  OutlineInputBorder _searchBorder(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: BorderSide(color: color),
  );

  Widget _searchField() => TextField(
    key: const ValueKey('services-search'),
    controller: _search,
    onChanged: (value) => setState(() => _query = value),
    onSubmitted: (_) => FocusScope.of(context).unfocus(),
    textInputAction: TextInputAction.search,
    style: AppTextStyles.body,
    decoration: InputDecoration(
      hintText: 'Tìm dịch vụ (vd: kích bình, thay lốp, cứu hộ...)',
      hintStyle: AppTextStyles.body.copyWith(color: ServiceCatalogTheme.muted),
      prefixIcon: const Icon(Icons.search, color: ServiceCatalogTheme.muted),
      suffixIcon: _query.isEmpty
          ? null
          : IconButton(
              tooltip: 'Xóa tìm dịch vụ',
              onPressed: () {
                _search.clear();
                setState(() => _query = '');
              },
              icon: const Icon(Icons.close, size: 18),
            ),
      filled: true,
      fillColor: const Color(0xFFEEF2F7),
      border: _searchBorder(ServiceCatalogTheme.border),
      enabledBorder: _searchBorder(ServiceCatalogTheme.border),
      focusedBorder: _searchBorder(ServiceCatalogTheme.blue),
    ),
  );

  Widget _filters() => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Row(
      children: [
        for (final category in ServiceCatalogCategory.values)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              key: ValueKey('services-category-${category.name}'),
              label: Text(category.label),
              selected: _category == category,
              showCheckmark: false,
              selectedColor: ServiceCatalogTheme.blue,
              backgroundColor: const Color(0xFFEBEFF5),
              side: BorderSide.none,
              labelStyle: AppTextStyles.body.copyWith(
                fontSize: 13,
                fontWeight: _category == category
                    ? FontWeight.w600
                    : FontWeight.w500,
                color: _category == category ? Colors.white : Colors.black87,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              onSelected: (_) {
                FocusScope.of(context).unfocus();
                setState(() => _category = category);
              },
            ),
          ),
      ],
    ),
  );

  Widget _utilities() => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: ServiceCatalogTheme.border),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        _utility(
          key: const ValueKey('service-charging'),
          icon: Icons.ev_station_outlined,
          title: 'Trạm sạc gần nhất',
          onTap: () => _openService(HomeService.charging),
        ),
        const Divider(height: 1, color: ServiceCatalogTheme.border),
        _utility(
          key: const ValueKey('service-prices'),
          icon: Icons.receipt_long_outlined,
          title: 'Bảng giá phụ tùng',
          onTap: () => context.push('/bang-gia'),
        ),
        _utility(
          key: const ValueKey('service-tips'),
          icon: Icons.lightbulb_outline_rounded,
          title: 'Mẹo tự xử lý sự cố',
          onTap: () => context.push('/meo-xu-ly'),
        ),
        _utility(
          key: const ValueKey('service-stations'),
          icon: Icons.location_on_outlined,
          title: 'Tìm trạm cứu hộ',
          onTap: () => context.push('/tram-cuu-ho'),
        ),
      ],
    ),
  );

  Widget _utility({
    required Key key,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) => ListTile(
    key: key,
    leading: Icon(icon, color: ServiceCatalogTheme.blue),
    title: Text(title, style: AppTextStyles.body),
    trailing: const Icon(Icons.chevron_right_rounded),
    onTap: onTap,
  );
}
