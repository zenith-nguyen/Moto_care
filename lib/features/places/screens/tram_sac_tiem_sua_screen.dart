import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as osm_map;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart' as osm;
import 'package:url_launcher/url_launcher.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/services/service_actions.dart';
import '../../../core/widgets/service_scaffold.dart';
import '../../home/providers/home_provider.dart';
import '../models/service_place.dart';
import '../providers/service_place_provider.dart';
export '../providers/service_place_provider.dart' show servicePlacesProvider;

enum _PlaceView { map, list }

class TramSacTiemSuaScreen extends ConsumerStatefulWidget {
  const TramSacTiemSuaScreen({super.key});

  @override
  ConsumerState<TramSacTiemSuaScreen> createState() =>
      _TramSacTiemSuaScreenState();
}

class _TramSacTiemSuaScreenState extends ConsumerState<TramSacTiemSuaScreen> {
  String _query = '';
  final _search = TextEditingController();
  final _filters = <String>{};
  _PlaceView _view = _PlaceView.map;
  String? _selectedId;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final placesAsync = ref.watch(servicePlacesAsyncProvider);
    return ServiceScaffold(
      title: 'Trạm sạc & Tiệm sửa xe gần nhất',
      body: placesAsync.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(48),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (_, _) => _ErrorState(
          onRetry: () => ref.invalidate(servicePlacesAsyncProvider),
        ),
        data: (allPlaces) => _buildContent(context, allPlaces),
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<ServicePlace> allPlaces) {
    final live = ref.watch(runtimeApiIntegrationProvider);
    final places = filterServicePlaces(
      allPlaces,
      _query,
      Set.unmodifiable(_filters),
    );
    final selected = places.isEmpty
        ? null
        : places.firstWhere(
            (p) => p.id == _selectedId,
            orElse: () => places.first,
          );
    final userLocation = ref.watch(rescueLocationProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        ServiceSearchBar(
          controller: _search,
          hint: 'Tìm kiếm theo địa chỉ',
          onChanged: (value) =>
              setState(() => _query = normalizeServiceSearch(value)),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final (label, icon) in const [
                ('Trạm sạc', Icons.ev_station_outlined),
                ('Mở 24/7', Icons.schedule),
                ('Sửa xe xăng', Icons.two_wheeler),
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    avatar: Icon(
                      _filters.contains(label) ? Icons.check : icon,
                      size: 18,
                    ),
                    label: Text(label),
                    tooltip: _filters.contains(label)
                        ? 'Bỏ lọc $label'
                        : 'Lọc $label',
                    backgroundColor: _filters.contains(label)
                        ? ServiceColors.orange.withValues(alpha: .22)
                        : ServiceColors.surface,
                    side: BorderSide(
                      color: _filters.contains(label)
                          ? ServiceColors.orange
                          : ServiceColors.border,
                    ),
                    onPressed: () => setState(() {
                      if (!_filters.add(label)) _filters.remove(label);
                    }),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SegmentedButton<_PlaceView>(
          segments: const [
            ButtonSegment(
              value: _PlaceView.map,
              label: Text('Bản đồ'),
              icon: Icon(Icons.map_outlined),
            ),
            ButtonSegment(
              value: _PlaceView.list,
              label: Text('Danh sách'),
              icon: Icon(Icons.format_list_bulleted),
            ),
          ],
          selected: {_view},
          showSelectedIcon: false,
          onSelectionChanged: (value) => setState(() => _view = value.single),
        ),
        const SizedBox(height: 16),
        Text(
          live
              ? '${places.length} địa điểm gần bạn'
              : '${places.length} địa điểm • Khoảng cách minh họa',
          style: const TextStyle(color: ServiceColors.muted),
        ),
        const SizedBox(height: 12),
        if (places.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Không tìm thấy địa điểm phù hợp. Hãy thử địa chỉ khác hoặc bỏ bớt bộ lọc.',
              ),
            ),
          )
        else if (_view == _PlaceView.map) ...[
          _PlacesMap(
            places: places,
            selectedId: selected!.id,
            onSelected: (id) => setState(() => _selectedId = id),
            userLatitude: userLocation?.latitude,
            userLongitude: userLocation?.longitude,
          ),
          const SizedBox(height: 12),
          _PlaceCard(place: selected, live: live),
        ] else ...[
          for (final place in places)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _PlaceCard(place: place, live: live),
            ),
        ],
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline_rounded, size: 40),
        const SizedBox(height: 12),
        const Text('Không tải được danh sách địa điểm.'),
        const SizedBox(height: 12),
        OutlinedButton(onPressed: onRetry, child: const Text('Thử lại')),
      ],
    ),
  );
}

class _PlaceCard extends ConsumerWidget {
  const _PlaceCard({required this.place, required this.live});
  final ServicePlace place;
  final bool live;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                place.isCharging
                    ? Icons.ev_station
                    : Icons.build_circle_outlined,
                color: ServiceColors.orange,
                size: 30,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  place.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            place.address,
            style: const TextStyle(color: ServiceColors.muted),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              if (place.hasDistance)
                Text('${place.distanceKm.toStringAsFixed(1)} km'),
              if (place.is24Hours)
                const Text(
                  'Mở 24/7',
                  style: TextStyle(color: Color(0xFF69D49B)),
                ),
              if (place.hasRating)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: ServiceColors.gold,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(place.rating.toStringAsFixed(1)),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: () => launchServiceUri(
                  context,
                  ref,
                  Uri.https('www.google.com', '/maps/dir/', {
                    'api': '1',
                    'destination': place.hasCoordinates
                        ? '${place.latitude},${place.longitude}'
                        : place.address,
                  }),
                  'Không thể mở bản đồ. Địa chỉ: ${place.address}',
                ),
                icon: const Icon(Icons.directions_outlined),
                label: const Text('Chỉ đường'),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  final phone = place.phone?.trim();
                  if (phone == null || phone.isEmpty) {
                    showServiceMessage(
                      context,
                      live
                          ? 'Địa điểm này chưa có số điện thoại.'
                          : 'Địa điểm minh họa chưa có số điện thoại.',
                    );
                    return;
                  }
                  launchServiceUri(
                    context,
                    ref,
                    Uri(scheme: 'tel', path: phone),
                    'Không thể mở ứng dụng gọi điện. Số liên hệ: $phone',
                  );
                },
                icon: const Icon(Icons.phone_outlined),
                label: const Text('Gọi'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

/// A real OpenStreetMap view of the service places plus the user's location.
/// Uses OSM tiles (no API key needed), matching the rescue tracking map.
class _PlacesMap extends StatefulWidget {
  const _PlacesMap({
    required this.places,
    required this.selectedId,
    required this.onSelected,
    this.userLatitude,
    this.userLongitude,
  });
  final List<ServicePlace> places;
  final String selectedId;
  final ValueChanged<String> onSelected;
  final double? userLatitude;
  final double? userLongitude;

  @override
  State<_PlacesMap> createState() => _PlacesMapState();
}

class _PlacesMapState extends State<_PlacesMap> {
  final _controller = osm_map.MapController();

  List<ServicePlace> get _located =>
      widget.places.where((p) => p.hasCoordinates).toList(growable: false);

  List<osm.LatLng> get _points => [
    for (final p in _located) osm.LatLng(p.latitude!, p.longitude!),
    if (widget.userLatitude != null && widget.userLongitude != null)
      osm.LatLng(widget.userLatitude!, widget.userLongitude!),
  ];

  void _fit() {
    final points = _points;
    if (points.isEmpty) return;
    if (points.length == 1) {
      _controller.move(points.first, 15);
      return;
    }
    _controller.fitCamera(
      osm_map.CameraFit.bounds(
        bounds: osm_map.LatLngBounds.fromPoints(points),
        padding: const EdgeInsets.all(48),
      ),
    );
  }

  @override
  void didUpdateWidget(_PlacesMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.places.length != widget.places.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fit();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final located = _located;
    final center = located.isNotEmpty
        ? osm.LatLng(located.first.latitude!, located.first.longitude!)
        : const osm.LatLng(10.7769, 106.7009);
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: 300,
        child: osm_map.FlutterMap(
          mapController: _controller,
          options: osm_map.MapOptions(
            initialCenter: center,
            initialZoom: 13,
            minZoom: 5,
            maxZoom: 19,
            onMapReady: _fit,
          ),
          children: [
            osm_map.TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.motocare.app',
              maxNativeZoom: 19,
            ),
            osm_map.MarkerLayer(
              markers: [
                if (widget.userLatitude != null && widget.userLongitude != null)
                  osm_map.Marker(
                    point: osm.LatLng(
                      widget.userLatitude!,
                      widget.userLongitude!,
                    ),
                    width: 22,
                    height: 22,
                    child: const _UserDot(),
                  ),
                for (final place in located)
                  osm_map.Marker(
                    point: osm.LatLng(place.latitude!, place.longitude!),
                    width: 44,
                    height: 44,
                    alignment: Alignment.topCenter,
                    child: GestureDetector(
                      onTap: () => widget.onSelected(place.id),
                      child: Tooltip(
                        message: place.name,
                        child: _PlaceMarker(
                          selected: place.id == widget.selectedId,
                          isCharging: place.isCharging,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            osm_map.RichAttributionWidget(
              showFlutterMapAttribution: false,
              attributions: [
                osm_map.TextSourceAttribution(
                  'OpenStreetMap contributors',
                  onTap: () => launchUrl(
                    Uri.parse('https://www.openstreetmap.org/copyright'),
                    mode: LaunchMode.externalApplication,
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

class _PlaceMarker extends StatelessWidget {
  const _PlaceMarker({required this.selected, required this.isCharging});
  final bool selected;
  final bool isCharging;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: selected ? ServiceColors.orange : const Color(0xFF3E5351),
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 2),
      boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 6)],
    ),
    alignment: Alignment.center,
    child: Icon(
      isCharging ? Icons.ev_station : Icons.build,
      color: Colors.white,
      size: 22,
    ),
  );
}

class _UserDot extends StatelessWidget {
  const _UserDot();

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: const Color(0xFF2F80ED),
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 3),
      boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 4)],
    ),
  );
}
