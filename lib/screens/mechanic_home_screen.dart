import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../data/home_catalog.dart';
import '../services/home_feed_repository.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/app_status.dart';
import '../widgets/home_components.dart';
import '../widgets/revo_brand.dart';
import '../widgets/ui.dart';
import 'all_services_screen.dart';
import 'incoming_order_popup.dart';
import 'nearby_jobs_screen.dart';
import 'notifications_screen.dart';
import 'order_history_detail_screen.dart';
import 'order_received_screen.dart';
import 'service_management_screen.dart';
import 'weekly_summary_screen.dart';

class MechanicHomeScreen extends StatefulWidget {
  const MechanicHomeScreen({super.key, this.repository});
  final HomeFeedRepository? repository;
  @override
  State<MechanicHomeScreen> createState() => _MechanicHomeScreenState();
}

class _MechanicHomeScreenState extends State<MechanicHomeScreen> {
  late final HomeFeedRepository _feed =
      widget.repository ?? HomeFeedRepository(appState);
  final _search = TextEditingController();
  late final Timer _clock;
  String _serviceId = 'all';
  double _radius = 10;
  bool _newest = false, _offerOpen = false;
  String _lastClockKey = '';
  HomeService get _service =>
      homeServices.firstWhere((s) => s.id == _serviceId);
  String get _query => _search.text.trim();
  List<HomeRequest> get _requests => _feed
      .search(
          query: _query,
          serviceId: _serviceId,
          radiusKm: _radius,
          newestFirst: _newest)
      .where((r) =>
          _feed.statusOf(r) != HomeRequestStatus.completed &&
          _feed.statusOf(r) != HomeRequestStatus.cancelled)
      .toList();

  @override
  void initState() {
    super.initState();
    // Only rebuild at minute/availability boundaries, without an always-running animation.
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      final key = '${DateTime.now().millisecondsSinceEpoch ~/ 60000}'
          '${_feed.requests.map((r) => _feed.statusOf(r).name).join()}';
      if (mounted && key != _lastClockKey) setState(() => _lastClockKey = key);
    });
  }

  @override
  void dispose() {
    _clock.cancel();
    _search.dispose();
    super.dispose();
  }

  /// False only for services the demo dispatcher has no offers for.
  bool _hasDemoOffers(HomeService service) {
    final index = service.dispatchIndex;
    return index == null || appState.services[index].hasDemoOffers;
  }

  Future<void> _receive({HomeRequest? request}) async {
    if (_offerOpen) return;
    FocusManager.instance.primaryFocus?.unfocus();
    final active = appState.activeOrder;
    if (active != null) {
      openActiveOrder(context, active);
      return;
    }
    if (request == null && (_query.isNotEmpty || !_hasDemoOffers(_service))) {
      _allRequests();
      return;
    }
    setState(() => _offerOpen = true);
    try {
      final offer = request == null
          ? appState.nextOffer(serviceIndex: _service.dispatchIndex)
          : _feed.proposalFor(request);
      await showIncomingOrder(context, offer);
    } on StateError catch (error) {
      if (mounted) showAppSnack(context, error.message);
    } finally {
      if (mounted) setState(() => _offerOpen = false);
    }
  }

  void _services() => Navigator.push(context,
      MaterialPageRoute(builder: (_) => const ServiceManagementScreen()));

  void _online(bool value) {
    if (value && !appState.gpsEnabled) {
      showAppSnack(context, 'Vui lòng bật định vị trong Cài đặt để nhận đơn.');
      return;
    }
    if (value && !appState.networkAvailable) {
      showAppSnack(context,
          'Mất mạng mô phỏng. Vào Cài đặt → Chế độ demo để kết nối lại.');
      return;
    }
    appState.setOnline(value);
  }

  Future<void> _area() => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
          child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SheetHandle(),
                    const SizedBox(height: 16),
                    const Text('Khu vực hoạt động', style: AppTypography.title),
                    const SizedBox(height: 6),
                    const Text(
                        'Khu vực hồ sơ · Vị trí trên bản đồ hiện được mô phỏng.',
                        style: AppTypography.caption),
                    for (final area in [
                      'Quận 1, TP.HCM',
                      'Quận 3, TP.HCM',
                      'Quận 5, TP.HCM',
                      'Quận 7, TP.HCM',
                      'Quận 10, TP.HCM',
                      'Bình Thạnh, TP.HCM',
                      'Thủ Đức, TP.HCM'
                    ])
                      ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(area, style: appText(13)),
                          trailing: appState.profile.area == area
                              ? const Icon(Icons.check_rounded,
                                  color: AppColors.primary)
                              : null,
                          onTap: () {
                            appState.setArea(area);
                            Navigator.pop(ctx);
                          }),
                  ]))));

  Future<void> _filters() async {
    var service = _serviceId;
    var radius = _radius;
    var newest = _newest;
    final result = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        builder: (ctx) => StatefulBuilder(
            builder: (ctx, update) => SafeArea(
                child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SheetHandle(),
                          const SizedBox(height: 16),
                          const Text('Bộ lọc đơn gần bạn',
                              style: AppTypography.title),
                          const SizedBox(height: 16),
                          const Text('Dịch vụ', style: AppTypography.label),
                          Wrap(spacing: 8, children: [
                            for (final s in homeServices)
                              ChoiceChip(
                                  label: Text(s.label, style: appText(11)),
                                  selected: service == s.id,
                                  onSelected: (_) =>
                                      update(() => service = s.id))
                          ]),
                          const SizedBox(height: 12),
                          const Text('Khoảng cách tối đa',
                              style: AppTypography.label),
                          Wrap(spacing: 8, children: [
                            for (final r in [1.0, 3.0, 5.0, 10.0])
                              ChoiceChip(
                                  label: Text('${r.toInt()} km',
                                      style: appText(12)),
                                  selected: radius == r,
                                  onSelected: (_) => update(() => radius = r))
                          ]),
                          SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title:
                                  Text('Yêu cầu mới nhất', style: appText(13)),
                              value: newest,
                              onChanged: (v) => update(() => newest = v)),
                          PrimaryButton(
                              label: 'Áp dụng bộ lọc',
                              onPressed: () => Navigator.pop(ctx, true)),
                          TextButton(
                              onPressed: () => update(() {
                                    service = 'all';
                                    radius = 10;
                                    newest = false;
                                  }),
                              child: const Text('Đặt lại bộ lọc')),
                        ])))));
    if (!mounted || result != true) return;
    setState(() {
      _serviceId = service;
      _radius = radius;
      _newest = newest;
    });
  }

  Future<void> _schedule() async {
    final action = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        builder: (ctx) => SafeArea(
            child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: ListenableBuilder(
                    listenable: appState,
                    builder: (_, __) {
                      final now = DateTime.now();
                      final today = appState.history.where((o) =>
                          o.time.year == now.year &&
                          o.time.month == now.month &&
                          o.time.day == now.day);
                      return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SheetHandle(),
                            const SizedBox(height: 16),
                            const Text('Lịch công việc',
                                style: AppTypography.title),
                            const SizedBox(height: 6),
                            Text('Hôm nay, ${formatDM(now)}/${now.year}',
                                style: AppTypography.label),
                            const SizedBox(height: 8),
                            const Text(
                                'Demo · Hiển thị đơn đang làm và công việc đã ghi nhận. Chưa có lịch hẹn.',
                                style: AppTypography.caption),
                            const SizedBox(height: 12),
                            if (appState.activeOrder != null)
                              ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(Icons.build_outlined),
                                  title: Text(appState.activeOrder!.orderId,
                                      style: AppTypography.label),
                                  subtitle: Text(
                                      'Đang làm · ${appState.activeOrder!.offer.issue}',
                                      style: AppTypography.caption),
                                  trailing:
                                      const Icon(Icons.chevron_right_rounded),
                                  onTap: () => Navigator.pop(ctx, 'active')),
                            for (final o in today)
                              ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(
                                      Icons.assignment_turned_in_outlined),
                                  title: Text(o.orderId,
                                      style: AppTypography.label),
                                  subtitle: Text(
                                      '${formatHm(o.time)} · ${o.issue}',
                                      style: AppTypography.caption),
                                  onTap: () => Navigator.pop(ctx, o.orderId)),
                            if (appState.activeOrder == null && today.isEmpty)
                              const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 20),
                                  child: Text('Chưa có công việc hôm nay.')),
                            const Divider(),
                            ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.bar_chart_rounded),
                                title: const Text('Thu nhập hôm nay',
                                    style: AppTypography.label),
                                trailing: Text(formatVnd(appState.todayIncome),
                                    style: AppTypography.label),
                                onTap: () => Navigator.pop(ctx, 'summary')),
                            PrimaryButton(
                                label: 'Xem lịch sử đơn',
                                onPressed: () => Navigator.pop(ctx, 'history')),
                          ]);
                    }))));
    if (!mounted || action == null) return;
    if (action == 'history') {
      appState.setTab(1);
      return;
    }
    if (action == 'summary') {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const WeeklySummaryScreen()));
      return;
    }
    if (action == 'active') {
      final order = appState.activeOrder;
      if (order != null) openActiveOrder(context, order);
      return;
    }
    final item = appState.history.where((o) => o.orderId == action);
    if (item.isNotEmpty) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => OrderHistoryDetailScreen(item: item.first)));
    }
  }

  String _actionLabel(HomeRequest r) => _feed.actionLabel(r);
  VoidCallback? _action(HomeRequest r) {
    final status = _feed.statusOf(r);
    if (status == HomeRequestStatus.active) {
      return () => openActiveOrder(context, appState.activeOrder!);
    }
    if (status == HomeRequestStatus.completed) {
      final items = appState.history.where((o) => o.orderId == r.offer.orderId);
      if (items.isEmpty) return null;
      return () {
        final item = items.first;
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => OrderHistoryDetailScreen(item: item)));
      };
    }
    return !_offerOpen && _feed.canOffer(r) ? () => _receive(request: r) : null;
  }

  void _openService(HomeService service) {
    FocusManager.instance.primaryFocus?.unfocus();
    if (service.id == 'all') {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => AllServicesScreen(repository: _feed)));
      return;
    }
    _allRequests(serviceId: service.id);
  }

  /// Opens the full nearby-jobs screen. From a service card only that service
  /// is preselected; otherwise Home's current carousel filters carry over.
  void _allRequests({String? serviceId}) {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => NearbyJobsScreen(
                repository: _feed,
                initialServiceId: serviceId ?? _serviceId,
                initialRadius: serviceId == null ? _radius : 10,
                initialQuery: serviceId == null ? _query : '')));
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final services = (_query.isEmpty ? popularHomeServices : homeServices)
            .where((s) => homeSearchKey('${s.label} ${s.description}')
                .contains(homeSearchKey(_query)))
            .toList();
        final requests = _requests;
        final ready = appState.demoEnabled &&
            appState.sessionActive &&
            appState.isOnline &&
            appState.networkAvailable &&
            appState.gpsEnabled &&
            !_offerOpen;
        return ColoredBox(
            color: HomePalette.background,
            child: SafeArea(
                bottom: false,
                child: SingleChildScrollView(
                    key: const PageStorageKey('mechanic-home-scroll'),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                              child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _header(),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                        height: math.max(
                                            50,
                                            MediaQuery.textScalerOf(context)
                                                        .scale(13) *
                                                    (MediaQuery.textScalerOf(
                                                                        context)
                                                                    .scale(1) >
                                                                1.2 &&
                                                            MediaQuery.sizeOf(
                                                                        context)
                                                                    .width <
                                                                380
                                                        ? 2.6
                                                        : 1) +
                                                24),
                                        child: TextField(
                                            controller: _search,
                                            key: const ValueKey('home-search'),
                                            onChanged: (_) => setState(() {}),
                                            style: appText(13),
                                            textInputAction:
                                                TextInputAction.search,
                                            onSubmitted: (_) => FocusManager
                                                .instance.primaryFocus
                                                ?.unfocus(),
                                            decoration: InputDecoration(
                                              hintText:
                                                  'Tìm đơn cứu hộ, dịch vụ...',
                                              hintMaxLines: 2,
                                              hintStyle: appText(12,
                                                  color: HomePalette.secondary),
                                              filled: true,
                                              fillColor:
                                                  const Color(0xFFEAF0F6),
                                              prefixIcon: const Icon(
                                                  Icons.search_rounded,
                                                  size: 24,
                                                  color: HomePalette.secondary),
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 12,
                                                      horizontal: 16),
                                              border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(15),
                                                  borderSide: BorderSide.none),
                                              enabledBorder: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(15),
                                                  borderSide: BorderSide.none),
                                              focusedBorder: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(15),
                                                  borderSide: BorderSide.none),
                                              suffixIcon: IconButton(
                                                  tooltip: 'Bộ lọc đơn gần bạn',
                                                  onPressed: _filters,
                                                  icon: Badge(
                                                      isLabelVisible: _radius !=
                                                              10 ||
                                                          _newest ||
                                                          _serviceId != 'all',
                                                      smallSize: 5,
                                                      child: const Icon(
                                                          Icons.tune_rounded,
                                                          size: 23,
                                                          color: HomePalette
                                                              .secondary))),
                                            ))),
                                    const SizedBox(height: 10),
                                    if (!appState.networkAvailable) ...[
                                      AppStatusView(
                                          kind: AppStatusKind.offline,
                                          compact: true,
                                          onAction: () => appState
                                              .setNetworkAvailable(true)),
                                      const SizedBox(height: 10)
                                    ],
                                    if (!appState.gpsEnabled) ...[
                                      AppStatusView(
                                          kind: AppStatusKind.gpsOff,
                                          compact: true,
                                          onAction: () =>
                                              appState.setGps(true)),
                                      const SizedBox(height: 10)
                                    ],
                                    HomeHeroCarousel(
                                        key: const ValueKey('revo_home_hero'),
                                        onReceive: _receive,
                                        onSchedule: _schedule,
                                        onServices: _services,
                                        onOrders: () => appState.setTab(1),
                                        hasActive: appState.activeOrder != null,
                                        canReceive: ready &&
                                            (_service.dispatchIndex == null ||
                                                appState
                                                    .services[
                                                        _service.dispatchIndex!]
                                                    .enabled)),
                                    _section('Dịch vụ phổ biến'),
                                    const SizedBox(height: 8),
                                    if (services.isEmpty)
                                      const Padding(
                                          padding: EdgeInsets.all(16),
                                          child: Text(
                                              'Không tìm thấy dịch vụ phù hợp.',
                                              style: AppTypography.caption))
                                    else
                                      LayoutBuilder(builder: (context, box) {
                                        final width = (box.maxWidth - 10) / 2;
                                        final scaler =
                                            MediaQuery.textScalerOf(context);
                                        final height = services
                                            .map((s) =>
                                                HomeServiceTile.heightFor(
                                                    s, width, scaler))
                                            .reduce(math.max);
                                        return Wrap(
                                            spacing: 10,
                                            runSpacing: 10,
                                            children: [
                                              for (final s in services)
                                                SizedBox(
                                                    width: width,
                                                    height: height,
                                                    child: HomeServiceTile(
                                                        key: ValueKey(
                                                            'home-service-${s.id}'),
                                                        service: s,
                                                        selected:
                                                            _serviceId == s.id,
                                                        imageHeight: width *
                                                            HomeServiceTile
                                                                .imageRatio,
                                                        onTap: () =>
                                                            _openService(s))),
                                            ]);
                                      }),
                                    const SizedBox(height: 16),
                                    _section('Đơn gần bạn',
                                        'Xem tất cả đơn gần bạn', _allRequests),
                                    const SizedBox(height: 8),
                                  ])),
                          if (requests.isEmpty)
                            Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 10, 16, 18),
                                child: SurfaceCard(
                                    color: HomePalette.card,
                                    child: Column(children: [
                                      const Icon(Icons.search_off_rounded,
                                          color: HomePalette.secondary),
                                      const SizedBox(height: 8),
                                      const Text('Chưa có đơn phù hợp.',
                                          style: AppTypography.label),
                                      const SizedBox(height: 4),
                                      Text(
                                          !_hasDemoOffers(_service)
                                              ? 'Chưa có yêu cầu nào cho dịch vụ này.'
                                              : 'Thử đổi dịch vụ, từ khóa hoặc khoảng cách.',
                                          style: AppTypography.caption),
                                      TextButton(
                                          onPressed: () => setState(() {
                                                _search.clear();
                                                _serviceId = 'all';
                                                _radius = 10;
                                                _newest = false;
                                              }),
                                          child: const Text('Xóa bộ lọc')),
                                    ])))
                          else
                            LayoutBuilder(builder: (context, box) {
                              final width =
                                  math.max(130.0, (box.maxWidth - 42) / 2);
                              final scaler = MediaQuery.textScalerOf(context);
                              final height = requests
                                  .map((r) => NearbyRequestCard.heightFor(
                                      r, width, scaler,
                                      footer: _action(r) != null &&
                                              _feed.statusOf(r) ==
                                                  HomeRequestStatus.waiting
                                          ? 'Dự kiến nhận: ${r.offer.etaMinutes} phút'
                                          : _actionLabel(r)))
                                  .reduce(math.max);
                              return SizedBox(
                                  height: height + 10,
                                  child: ListView.separated(
                                      key: const ValueKey(
                                          'home-nearby-carousel'),
                                      scrollDirection: Axis.horizontal,
                                      padding: const EdgeInsets.fromLTRB(
                                          16, 0, 16, 10),
                                      itemCount: requests.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(width: 10),
                                      itemBuilder: (context, i) {
                                        final r = requests[i];
                                        return SizedBox(
                                            width: width,
                                            child: NearbyRequestCard(
                                                request: r,
                                                status: _feed.statusOf(r),
                                                actionLabel: _actionLabel(r),
                                                onAction: _action(r),
                                                secondary: i != 0));
                                      }));
                            }),
                          const SizedBox(height: 8),
                        ]))));
      });

  Widget _section(String title, [String? tooltip, VoidCallback? onAll]) =>
      Row(children: [
        Expanded(
            child: Text(title,
                style: appText(MediaQuery.sizeOf(context).width < 360 ? 17 : 20,
                    weight: FontWeight.w700,
                    color: HomePalette.text,
                    height: 1.2))),
        if (onAll != null)
          Tooltip(
              message: tooltip,
              child: TextButton(
                  onPressed: onAll,
                  style: TextButton.styleFrom(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.only(left: 6),
                      minimumSize: const Size(0, 32)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('Xem tất cả',
                        style: appText(10.5,
                            weight: FontWeight.w500, color: HomePalette.text)),
                    const SizedBox(width: 3),
                    const Icon(Icons.chevron_right_rounded,
                        size: 17, color: HomePalette.text),
                  ]))),
      ]);

  Widget _header() => LayoutBuilder(builder: (context, box) {
        final compact = box.maxWidth < 325;
        return Row(children: [
          const Icon(Icons.location_on_rounded,
              size: 26, color: AppColors.primary),
          const SizedBox(width: 6),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                InkWell(
                    onTap: _area,
                    child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(children: [
                          Flexible(
                              child: Text(appState.profile.area,
                                  maxLines: 2,
                                  style: appText(compact ? 12.5 : 15,
                                      weight: FontWeight.w700,
                                      color: HomePalette.text))),
                          const SizedBox(width: 3),
                          const Icon(Icons.keyboard_arrow_down_rounded,
                              size: 15, color: HomePalette.secondary),
                        ]))),
                Semantics(
                    toggled: appState.isOnline,
                    button: true,
                    label: 'Trạng thái nhận đơn',
                    child: Tooltip(
                        message: appState.isOnline
                            ? 'Chuyển sang ngoại tuyến'
                            : 'Chuyển sang trực tuyến',
                        child: InkWell(
                            key: const ValueKey('home-online-toggle'),
                            onTap: () => _online(!appState.isOnline),
                            child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Row(children: [
                                  Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: appState.isOnline
                                              ? HomePalette.online
                                              : AppColors.textMuted)),
                                  const SizedBox(width: 4),
                                  Flexible(
                                      child: Text(
                                          !appState.isOnline
                                              ? 'Đang ngoại tuyến'
                                              : appState.activeOrder != null
                                                  ? 'Đang online · Đang thực hiện đơn'
                                                  : 'Đang online · Sẵn sàng nhận đơn',
                                          style: appText(compact ? 9 : 10.5,
                                              color: HomePalette.secondary,
                                              height: 1.25))),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.power_settings_new_rounded,
                                      size: 14, color: HomePalette.secondary),
                                ]))))),
              ])),
          const SizedBox(width: 8),
          RevoLogo(
              size: compact ? 15 : 18,
              color: HomePalette.text,
              eColor: AppColors.primary),
          const SizedBox(width: 8),
          SizedBox(
              width: 30,
              child: IconButton(
                  tooltip: 'Thông báo',
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const NotificationsScreen())),
                  icon: Badge(
                      isLabelVisible: appState.notificationsEnabled &&
                          appState.unreadCount > 0,
                      smallSize: 6,
                      child: const Icon(Icons.notifications_none_rounded,
                          color: HomePalette.secondary, size: 25)))),
        ]);
      });
}
