import 'package:flutter/material.dart';

import '../data/home_catalog.dart';
import '../services/home_feed_repository.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/home_components.dart';
import '../widgets/ui.dart';
import 'nearby_jobs_screen.dart';
import 'service_management_screen.dart';

enum _ServiceFilter { all, rescue, maintenance, enabled }

/// Service discovery: registration summary, search, filters, photo cards and a
/// shortcut to nearby jobs. Skill switches stay in [ServiceManagementScreen].
class AllServicesScreen extends StatefulWidget {
  const AllServicesScreen({super.key, required this.repository});
  final HomeFeedRepository repository;

  static const serviceIds = [
    'battery',
    'tire',
    'flood',
    'tow',
    'repair',
    'fuel',
    'maintenance'
  ];

  @override
  State<AllServicesScreen> createState() => _AllServicesScreenState();
}

class _AllServicesScreenState extends State<AllServicesScreen> {
  final _search = TextEditingController();
  var _filter = _ServiceFilter.all;

  HomeFeedRepository get _repo => widget.repository;
  List<HomeService> get _catalog => [
        for (final id in AllServicesScreen.serviceIds)
          homeServices.firstWhere((s) => s.id == id)
      ];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<HomeService> get _visible {
    final key = homeSearchKey(_search.text.trim());
    return _catalog.where((s) {
      final inFilter = switch (_filter) {
        _ServiceFilter.all => true,
        _ServiceFilter.rescue => s.category == HomeServiceCategory.rescue,
        _ServiceFilter.maintenance =>
          s.category == HomeServiceCategory.maintenance,
        _ServiceFilter.enabled => _repo.serviceEnabled(s.id),
      };
      return inFilter &&
          homeSearchKey('${s.label} ${s.description} ${s.keywords}')
              .contains(key);
    }).toList();
  }

  bool get _filtered =>
      _filter != _ServiceFilter.all || _search.text.isNotEmpty;

  void _clear() => setState(() {
        _search.clear();
        _filter = _ServiceFilter.all;
      });

  void _open(HomeService service) {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_repo.serviceEnabled(service.id)) {
      showAppSnack(context,
          '${service.label} đang tắt. Bật trong Tài khoản → Quản lý dịch vụ để nhận đơn.');
    }
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => NearbyJobsScreen(
                repository: _repo, initialServiceId: service.id)));
  }

  void _openManagement() {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const ServiceManagementScreen()));
  }

  void _openNearby() {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => NearbyJobsScreen(repository: _repo)));
  }

  Widget _info(int enabled) => Container(
      key: const ValueKey('all-services-info'),
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 8),
      decoration: BoxDecoration(
          color: const Color(0xFFEAF4FC),
          borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Dịch vụ dành cho bạn',
            style:
                appText(14, weight: FontWeight.w700, color: HomePalette.text)),
        const SizedBox(height: 3),
        Text(
            'Khám phá các dịch vụ cứu hộ và bảo dưỡng phù hợp với kỹ năng của bạn.',
            style: appText(11, color: HomePalette.secondary, height: 1.4)),
        const SizedBox(height: 6),
        Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Bạn đã đăng ký $enabled/$homeServiceCount dịch vụ',
                  key: const ValueKey('all-services-registered'),
                  style: appText(12,
                      weight: FontWeight.w600, color: AppColors.primary)),
              TextButton(
                  key: const ValueKey('all-services-manage'),
                  onPressed: _openManagement,
                  style: TextButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      padding: const EdgeInsets.symmetric(horizontal: 6)),
                  child: Text('Quản lý dịch vụ →',
                      style: appText(11.5,
                          weight: FontWeight.w600, color: AppColors.primary))),
            ]),
      ]));

  Widget _searchBar() => TextField(
      key: const ValueKey('all-services-search'),
      controller: _search,
      onChanged: (_) => setState(() {}),
      style: appText(13),
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
          hintText: 'Tìm kiếm dịch vụ...',
          hintMaxLines: 2,
          hintStyle: appText(12, color: HomePalette.secondary),
          filled: true,
          fillColor: const Color(0xFFEAF0F6),
          prefixIcon: const Icon(Icons.search_rounded,
              size: 22, color: HomePalette.secondary),
          suffixIcon: _search.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Xóa từ khóa',
                  onPressed: () => setState(_search.clear),
                  icon: const Icon(Icons.close_rounded,
                      size: 20, color: HomePalette.secondary)),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none)));

  Widget _chips() => SingleChildScrollView(
      key: const ValueKey('all-services-filters'),
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        for (final (value, label, id) in const [
          (_ServiceFilter.all, 'Tất cả', 'all'),
          (_ServiceFilter.rescue, 'Cứu hộ', 'rescue'),
          (_ServiceFilter.maintenance, 'Bảo dưỡng', 'maintenance'),
          (_ServiceFilter.enabled, 'Đang bật', 'enabled'),
        ]) ...[
          if (value != _ServiceFilter.all) const SizedBox(width: 8),
          ChoiceChip(
              key: ValueKey('all-services-chip-$id'),
              label: Text(label,
                  style: appText(11.5,
                      weight: FontWeight.w600,
                      color:
                          _filter == value ? Colors.white : HomePalette.text)),
              showCheckmark: false,
              selected: _filter == value,
              selectedColor: AppColors.primary,
              backgroundColor: const Color(0xFFEAF0F6),
              side: BorderSide.none,
              onSelected: (_) => setState(() => _filter = value)),
        ],
      ]));

  Widget _grid(List<HomeService> services) =>
      LayoutBuilder(builder: (context, box) {
        final width = (box.maxWidth - 10) / 2;
        final scaler = MediaQuery.textScalerOf(context);
        final height = services
            .map((s) => HomeServiceTile.heightFor(s, width, scaler))
            .reduce((a, b) => a > b ? a : b);
        return Wrap(spacing: 10, runSpacing: 10, children: [
          for (final s in services)
            SizedBox(
                width: width,
                height: height,
                child: HomeServiceTile(
                    key: ValueKey('all-service-${s.id}'),
                    service: s,
                    selected: false,
                    imageHeight: width * HomeServiceTile.imageRatio,
                    badge: _repo.serviceEnabled(s.id) ? 'Đang bật' : 'Chưa bật',
                    badgeActive: _repo.serviceEnabled(s.id),
                    onTap: () => _open(s))),
        ]);
      });

  Widget _empty() => Container(
      key: const ValueKey('all-services-empty'),
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: HomePalette.border, width: .7)),
      child: Column(children: [
        const Icon(Icons.search_off_rounded,
            size: 28, color: HomePalette.secondary),
        const SizedBox(height: 8),
        Text('Không tìm thấy dịch vụ phù hợp',
            textAlign: TextAlign.center,
            style:
                appText(14, weight: FontWeight.w700, color: HomePalette.text)),
        const SizedBox(height: 4),
        Text('Thử từ khóa khác hoặc thay đổi bộ lọc.',
            textAlign: TextAlign.center,
            style: appText(12, color: HomePalette.secondary, height: 1.4)),
        const SizedBox(height: 8),
        TextButton(
            onPressed: _clear,
            child: Text('Xóa bộ lọc',
                style: appText(12.5, weight: FontWeight.w600))),
      ]));

  Widget _nearbyCta() => Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: HomePalette.border, width: .7)),
      child: InkWell(
          key: const ValueKey('all-services-nearby'),
          borderRadius: BorderRadius.circular(14),
          onTap: _openNearby,
          child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: Color(0xFFEAF4FC)),
                    child: const Icon(Icons.location_on_rounded,
                        size: 22, color: AppColors.primary)),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('Tìm công việc gần bạn',
                          style: appText(13,
                              weight: FontWeight.w700,
                              color: HomePalette.text)),
                      const SizedBox(height: 2),
                      Text(
                          'Khám phá các yêu cầu cứu hộ phù hợp với dịch vụ bạn đã đăng ký.',
                          style: appText(10.5,
                              color: HomePalette.secondary, height: 1.4)),
                      const SizedBox(height: 4),
                      Text('Xem đơn gần bạn →',
                          style: appText(11.5,
                              weight: FontWeight.w600,
                              color: AppColors.primary)),
                    ])),
              ]))));

  @override
  Widget build(BuildContext context) => ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final services = _visible;
        final enabled =
            _catalog.where((s) => _repo.serviceEnabled(s.id)).length;
        return Scaffold(
            backgroundColor: HomePalette.background,
            body: SafeArea(
                child: Column(children: [
              const ScreenHeader(title: 'Tất cả dịch vụ'),
              Expanded(
                  child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _info(enabled),
                            const SizedBox(height: 12),
                            _searchBar(),
                            const SizedBox(height: 10),
                            _chips(),
                            const SizedBox(height: 16),
                            Row(children: [
                              Expanded(
                                  child: Text('Danh sách dịch vụ',
                                      style: appText(15,
                                          weight: FontWeight.w700,
                                          color: HomePalette.text))),
                              Text('${services.length} dịch vụ',
                                  key: const ValueKey('all-services-count'),
                                  style: appText(11.5,
                                      color: HomePalette.secondary)),
                            ]),
                            const SizedBox(height: 10),
                            if (services.isEmpty) _empty() else _grid(services),
                            if (_filtered && services.isNotEmpty)
                              Align(
                                  alignment: Alignment.centerLeft,
                                  child: TextButton(
                                      onPressed: _clear,
                                      child: Text('Xóa bộ lọc',
                                          style: appText(11.5,
                                              weight: FontWeight.w600)))),
                            const SizedBox(height: 16),
                            _nearbyCta(),
                          ]))),
            ])));
      });
}
