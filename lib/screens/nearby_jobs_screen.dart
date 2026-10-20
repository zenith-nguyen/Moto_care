import 'dart:async';

import 'package:flutter/material.dart';

import '../data/home_catalog.dart';
import '../services/home_feed_repository.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/home_components.dart';
import '../widgets/ui.dart';
import 'incoming_order_popup.dart';
import 'order_received_screen.dart';

enum NearbySort { nearest, newest, income }

enum NearbyStatusFilter { all, waiting, expired }

/// Full "Đơn gần bạn" list. It reads the same [HomeFeedRepository] as Home, so
/// statuses, expiry and the accept flow are never duplicated or hardcoded here.
class NearbyJobsScreen extends StatefulWidget {
  const NearbyJobsScreen({
    super.key,
    required this.repository,
    this.initialServiceId = 'all',
    this.initialRadius = 10,
    this.initialQuery = '',
  });
  final HomeFeedRepository repository;
  final String initialServiceId;
  final double initialRadius;
  final String initialQuery;
  @override
  State<NearbyJobsScreen> createState() => _NearbyJobsScreenState();
}

class _NearbyJobsScreenState extends State<NearbyJobsScreen> {
  static const _serviceIds = [
    'all',
    'battery',
    'tire',
    'flood',
    'repair',
    'tow',
    'fuel',
    'maintenance'
  ];
  static const _radii = [1.0, 3.0, 5.0, 10.0];
  late final _search = TextEditingController(text: widget.initialQuery);
  late final Timer _clock;
  late String _serviceId = _serviceIds.contains(widget.initialServiceId)
      ? widget.initialServiceId
      : 'all';
  late double _radius =
      _radii.contains(widget.initialRadius) ? widget.initialRadius : 10;
  var _sort = NearbySort.nearest;
  var _status = NearbyStatusFilter.all;
  var _offerOpen = false;
  var _clockKey = '';

  HomeFeedRepository get _feed => widget.repository;
  String get _query => _search.text.trim();

  @override
  void initState() {
    super.initState();
    // Re-evaluate expiry only when a minute or a request status changes.
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      final key = '${DateTime.now().millisecondsSinceEpoch ~/ 60000}'
          '${_feed.requests.map((r) => _feed.statusOf(r).name).join()}';
      if (mounted && key != _clockKey) setState(() => _clockKey = key);
    });
  }

  @override
  void dispose() {
    _clock.cancel();
    _search.dispose();
    super.dispose();
  }

  bool _listed(HomeRequest r) {
    final s = _feed.statusOf(r);
    return s != HomeRequestStatus.completed && s != HomeRequestStatus.cancelled;
  }

  int _income(HomeRequest r) => r.offer.price - r.offer.platformFee;

  /// Requests that match search, service and distance (before the status filter).
  List<HomeRequest> get _matches {
    final list = _feed
        .search(
            query: _query,
            serviceId: _serviceId,
            radiusKm: _radius,
            newestFirst: _sort == NearbySort.newest)
        .where(_listed)
        .toList();
    if (_sort == NearbySort.income) {
      list.sort((a, b) => _income(b).compareTo(_income(a)));
    }
    return list;
  }

  List<HomeRequest> _byStatus(List<HomeRequest> list) => switch (_status) {
        NearbyStatusFilter.all => list,
        NearbyStatusFilter.waiting => list
            .where((r) => _feed.statusOf(r) == HomeRequestStatus.waiting)
            .toList(),
        NearbyStatusFilter.expired => list
            .where((r) => _feed.statusOf(r) == HomeRequestStatus.expired)
            .toList(),
      };

  bool get _hasFilters =>
      _serviceId != 'all' ||
      _query.isNotEmpty ||
      _radius != 10 ||
      _sort != NearbySort.nearest ||
      _status != NearbyStatusFilter.all;

  int get _advancedCount =>
      (_radius != 10 ? 1 : 0) +
      (_sort != NearbySort.nearest ? 1 : 0) +
      (_status != NearbyStatusFilter.all ? 1 : 0);

  void _clear() => setState(() {
        _serviceId = 'all';
        _search.clear();
        _radius = 10;
        _sort = NearbySort.nearest;
        _status = NearbyStatusFilter.all;
      });

  VoidCallback? _action(HomeRequest r) {
    if (_feed.statusOf(r) == HomeRequestStatus.active) {
      final order = appState.activeOrder;
      return order == null ? null : () => openActiveOrder(context, order);
    }
    return !_offerOpen && _feed.canOffer(r) ? () => _receive(r) : null;
  }

  /// Opens the existing incoming-order confirmation; nothing is accepted here.
  Future<void> _receive(HomeRequest request) async {
    if (_offerOpen) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _offerOpen = true);
    try {
      await showIncomingOrder(context, _feed.proposalFor(request));
    } on StateError catch (error) {
      if (mounted) showAppSnack(context, error.message);
    } finally {
      if (mounted) setState(() => _offerOpen = false);
    }
  }

  Future<void> _openFilters() async {
    var radius = _radius;
    var sort = _sort;
    var status = _status;
    final applied = await showModalBottomSheet<bool>(
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
                          const Text('Khoảng cách tối đa',
                              style: AppTypography.label),
                          Wrap(spacing: 8, children: [
                            for (final r in _radii)
                              ChoiceChip(
                                  label: Text('${r.toInt()} km',
                                      style: appText(12)),
                                  selected: radius == r,
                                  onSelected: (_) => update(() => radius = r))
                          ]),
                          const SizedBox(height: 12),
                          const Text('Trạng thái', style: AppTypography.label),
                          Wrap(spacing: 8, children: [
                            for (final (value, label) in const [
                              (NearbyStatusFilter.all, 'Tất cả'),
                              (NearbyStatusFilter.waiting, 'Đang chờ'),
                              (NearbyStatusFilter.expired, 'Hết hạn'),
                            ])
                              ChoiceChip(
                                  label: Text(label, style: appText(12)),
                                  selected: status == value,
                                  onSelected: (_) =>
                                      update(() => status = value))
                          ]),
                          const SizedBox(height: 12),
                          const Text('Sắp xếp', style: AppTypography.label),
                          Wrap(spacing: 8, children: [
                            for (final (value, label) in const [
                              (NearbySort.nearest, 'Gần nhất'),
                              (NearbySort.newest, 'Mới nhất'),
                              (NearbySort.income, 'Thu nhập cao nhất'),
                            ])
                              ChoiceChip(
                                  label: Text(label, style: appText(12)),
                                  selected: sort == value,
                                  onSelected: (_) => update(() => sort = value))
                          ]),
                          const SizedBox(height: 16),
                          PrimaryButton(
                              label: 'Áp dụng bộ lọc',
                              onPressed: () => Navigator.pop(ctx, true)),
                          TextButton(
                              onPressed: () => update(() {
                                    radius = 10;
                                    sort = NearbySort.nearest;
                                    status = NearbyStatusFilter.all;
                                  }),
                              child: const Text('Đặt lại bộ lọc')),
                        ])))));
    if (!mounted || applied != true) return;
    setState(() {
      _radius = radius;
      _sort = sort;
      _status = status;
    });
  }

  String get _sortLabel => switch (_sort) {
        NearbySort.nearest => 'Gần nhất',
        NearbySort.newest => 'Mới nhất',
        NearbySort.income => 'Thu nhập cao nhất',
      };

  Widget _serviceChips() => SingleChildScrollView(
        key: const ValueKey('nearby-service-chips'),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          for (final id in _serviceIds) ...[
            if (id != _serviceIds.first) const SizedBox(width: 8),
            _serviceChip(id),
          ],
        ]),
      );

  Widget _serviceChip(String id) {
    final label = id == 'all'
        ? 'Tất cả'
        : homeServices.firstWhere((s) => s.id == id).label;
    final selected = _serviceId == id;
    return ChoiceChip(
        key: ValueKey('nearby-chip-$id'),
        label: Text(label,
            style: appText(11.5,
                weight: FontWeight.w600,
                color: selected ? Colors.white : HomePalette.text)),
        showCheckmark: false,
        selected: selected,
        selectedColor: AppColors.primary,
        backgroundColor: Colors.white,
        side: BorderSide(
            color: selected ? AppColors.primary : HomePalette.border),
        onSelected: (_) => setState(() => _serviceId = id));
  }

  Widget _activeFilters() {
    final chips = <Widget>[
      if (_radius != 10)
        _removable(
            '≤ ${_radius.toInt()} km', () => setState(() => _radius = 10)),
      if (_status != NearbyStatusFilter.all)
        _removable(
            _status == NearbyStatusFilter.waiting ? 'Đang chờ' : 'Hết hạn',
            () => setState(() => _status = NearbyStatusFilter.all)),
      if (_sort != NearbySort.nearest)
        _removable(
            _sortLabel, () => setState(() => _sort = NearbySort.nearest)),
    ];
    if (!_hasFilters) return const SizedBox.shrink();
    return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ...chips,
              TextButton(
                  onPressed: _clear,
                  style: TextButton.styleFrom(
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  child: Text('Xóa bộ lọc',
                      style: appText(11.5, weight: FontWeight.w600))),
            ]));
  }

  Widget _removable(String label, VoidCallback onDeleted) => InputChip(
      label: Text(label, style: appText(11, color: AppColors.primary)),
      backgroundColor: const Color(0xFFEAF4FC),
      side: BorderSide.none,
      deleteIconColor: AppColors.primary,
      onDeleted: onDeleted,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap);

  Widget _empty({
    required String description,
    String? actionLabel,
    VoidCallback? onAction,
  }) =>
      ListView(padding: const EdgeInsets.all(16), children: [
        Container(
            key: const ValueKey('nearby-empty'),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: HomePalette.border, width: .7)),
            child: Column(children: [
              const Icon(Icons.search_off_rounded,
                  size: 28, color: HomePalette.secondary),
              const SizedBox(height: 8),
              Text('Chưa có đơn phù hợp',
                  textAlign: TextAlign.center,
                  style: appText(14,
                      weight: FontWeight.w700, color: HomePalette.text)),
              const SizedBox(height: 4),
              Text(description,
                  textAlign: TextAlign.center,
                  style:
                      appText(12, color: HomePalette.secondary, height: 1.4)),
              if (actionLabel != null) ...[
                const SizedBox(height: 8),
                TextButton(
                    onPressed: onAction,
                    child: Text(actionLabel,
                        style: appText(12.5, weight: FontWeight.w600))),
              ],
            ])),
      ]);

  Widget _body(List<HomeRequest> matches, List<HomeRequest> shown) {
    if (shown.isNotEmpty) {
      final scaler = MediaQuery.textScalerOf(context);
      return ListView.separated(
          key: const ValueKey('nearby-list'),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          itemCount: shown.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final r = shown[i];
            final action = _action(r);
            final status = _feed.statusOf(r);
            final label = _feed.actionLabel(r);
            return LayoutBuilder(
                builder: (context, box) => SizedBox(
                    height: NearbyRequestCard.heightFor(r, box.maxWidth, scaler,
                        footer: action != null &&
                                status == HomeRequestStatus.waiting
                            ? null
                            : label),
                    child: NearbyRequestCard(
                        request: r,
                        status: status,
                        actionLabel: label,
                        onAction: action)));
          });
    }
    final hasAny = _feed.requests.any(_listed);
    if (!hasAny) {
      return _empty(
          description: appState.demoEnabled
              ? 'Hiện chưa có đơn nào để nhận trong khu vực của bạn.'
              : 'Chưa có nguồn điều phối đơn.');
    }
    if (matches.isEmpty) {
      return _empty(
          description: 'Thử thay đổi dịch vụ, từ khóa hoặc khoảng cách.',
          actionLabel: 'Xóa bộ lọc',
          onAction: _clear);
    }
    return _empty(
        description: _status == NearbyStatusFilter.waiting
            ? 'Các đơn khớp bộ lọc đã hết hạn hoặc đã có người nhận.'
            : 'Không có đơn hết hạn khớp bộ lọc này.',
        actionLabel: 'Xem mọi trạng thái',
        onAction: () => setState(() => _status = NearbyStatusFilter.all));
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final matches = _matches;
        final shown = _byStatus(matches);
        return Scaffold(
            backgroundColor: HomePalette.background,
            body: SafeArea(
                child: Column(children: [
              ScreenHeader(
                  title: 'Đơn gần bạn',
                  subtitle: '${shown.length} đơn phù hợp'),
              Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                  child: TextField(
                      key: const ValueKey('nearby-search'),
                      controller: _search,
                      onChanged: (_) => setState(() {}),
                      style: appText(13),
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                          hintText: 'Tìm theo dịch vụ, địa chỉ...',
                          hintMaxLines: 2,
                          hintStyle: appText(12, color: HomePalette.secondary),
                          filled: true,
                          fillColor: const Color(0xFFEAF0F6),
                          prefixIcon: const Icon(Icons.search_rounded,
                              size: 22, color: HomePalette.secondary),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none),
                          suffixIcon: IconButton(
                              tooltip: 'Bộ lọc đơn gần bạn',
                              onPressed: _openFilters,
                              icon: Badge(
                                  isLabelVisible: _advancedCount > 0,
                                  label: Text('$_advancedCount'),
                                  child: const Icon(Icons.tune_rounded,
                                      size: 22,
                                      color: HomePalette.secondary)))))),
              _serviceChips(),
              _activeFilters(),
              Expanded(child: _body(matches, shown)),
            ])));
      });
}
