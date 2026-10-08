import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/service_scaffold.dart';
import '../providers/rescue_station_provider.dart';
import '../widgets/rescue_station_card.dart';
import '../widgets/rescue_station_mock_map.dart';

enum _StationView { list, map }

class TramCuuHoScreen extends ConsumerStatefulWidget {
  const TramCuuHoScreen({super.key});

  @override
  ConsumerState<TramCuuHoScreen> createState() => _TramCuuHoScreenState();
}

class _TramCuuHoScreenState extends ConsumerState<TramCuuHoScreen> {
  final _search = TextEditingController();
  final _filters = <StationFilter>{};
  String _query = '';
  String? _selectedId;
  _StationView _view = _StationView.list;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stations = filterRescueStations(
      ref.watch(rescueStationsProvider),
      query: _query,
      filters: _filters,
    );
    final selected = stations.isEmpty
        ? null
        : stations.firstWhere(
            (station) => station.id == _selectedId,
            orElse: () => stations.first,
          );
    return ServiceScaffold(
      title: 'Trạm cứu hộ',
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ServiceSearchBar(
                    controller: _search,
                    hint: 'Tìm địa chỉ hoặc tên tiệm',
                    onChanged: (value) => setState(() => _query = value),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final filter in StationFilter.values)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ActionChip(
                              label: Text(filter.label),
                              avatar: Icon(
                                _filters.contains(filter)
                                    ? Icons.check
                                    : switch (filter) {
                                        StationFilter.open24h => Icons.schedule,
                                        StationFilter.verified =>
                                          Icons.verified_outlined,
                                        StationFilter.official =>
                                          Icons.store_outlined,
                                        StationFilter.nearest =>
                                          Icons.near_me_outlined,
                                      },
                                size: 18,
                              ),
                              backgroundColor: _filters.contains(filter)
                                  ? ServiceColors.navy
                                  : ServiceColors.surface,
                              side: BorderSide(
                                color: _filters.contains(filter)
                                    ? ServiceColors.orange
                                    : ServiceColors.border,
                              ),
                              tooltip:
                                  '${_filters.contains(filter) ? 'Bỏ chọn' : 'Chọn'} ${filter.label}',
                              onPressed: () => setState(() {
                                if (!_filters.add(filter)) {
                                  _filters.remove(filter);
                                }
                              }),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<_StationView>(
                    segments: const [
                      ButtonSegment(
                        value: _StationView.list,
                        label: Text('Danh sách'),
                        icon: Icon(Icons.list),
                      ),
                      ButtonSegment(
                        value: _StationView.map,
                        label: Text('Bản đồ'),
                        icon: Icon(Icons.map_outlined),
                      ),
                    ],
                    selected: {_view},
                    showSelectedIcon: false,
                    onSelectionChanged: (values) =>
                        setState(() => _view = values.single),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${stations.length} trạm • ${_filters.contains(StationFilter.nearest) ? 'Gần nhất trước' : 'Đánh giá cao trước'}',
                    style: const TextStyle(color: ServiceColors.muted),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Thông tin trạm và khoảng cách minh họa',
                    style: TextStyle(color: ServiceColors.muted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
        body: stations.isEmpty
            ? const SingleChildScrollView(
                padding: EdgeInsets.all(28),
                child: Text(
                  'Không tìm thấy trạm phù hợp. Hãy thử từ khóa khác hoặc bỏ bớt bộ lọc.',
                  textAlign: TextAlign.center,
                ),
              )
            : _view == _StationView.list
            ? ListView.builder(
                key: const PageStorageKey('rescue-station-list'),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: stations.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: RescueStationCard(
                    key: ValueKey(stations[index].id),
                    station: stations[index],
                  ),
                ),
              )
            : ListView(
                key: const PageStorageKey('rescue-station-map'),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  RescueStationMockMap(
                    stations: stations,
                    selectedId: selected!.id,
                    onSelected: (id) => setState(() => _selectedId = id),
                  ),
                  const SizedBox(height: 14),
                  RescueStationCard(station: selected),
                ],
              ),
      ),
    );
  }
}
