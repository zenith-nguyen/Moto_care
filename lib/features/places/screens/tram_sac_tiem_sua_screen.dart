import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/service_actions.dart';
import '../../../core/widgets/service_scaffold.dart';
import '../models/service_place.dart';

final servicePlacesProvider = Provider<List<ServicePlace>>(
  (ref) => demoServicePlaces,
);

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
    final places = ref.watch(servicePlacesProvider).where((place) {
      return normalizeServiceSearch('${place.name} ${place.address}')
              .contains(_query) &&
          (!_filters.contains('Trạm sạc') || place.isCharging) &&
          (!_filters.contains('Mở 24/7') || place.is24Hours) &&
          (!_filters.contains('Sửa xe xăng') || place.repairsPetrol);
    }).toList()..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    final selected = places.isEmpty
        ? null
        : places.firstWhere(
            (p) => p.id == _selectedId,
            orElse: () => places.first,
          );
    return ServiceScaffold(
      title: 'Trạm sạc & Tiệm sửa xe gần nhất',
      body: ListView(
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
            '${places.length} địa điểm • Khoảng cách minh họa',
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
            _MockMap(
              places: places,
              selectedId: selected!.id,
              onSelected: (id) => setState(() => _selectedId = id),
            ),
            const SizedBox(height: 12),
            _PlaceCard(place: selected),
          ] else ...[
            for (final place in places)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _PlaceCard(place: place),
              ),
          ],
        ],
      ),
    );
  }
}

class _PlaceCard extends ConsumerWidget {
  const _PlaceCard({required this.place});
  final ServicePlace place;

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
              Text('${place.distanceKm.toStringAsFixed(1)} km'),
              Text(
                place.isOpen ? 'Mở cửa' : 'Đóng cửa',
                style: TextStyle(
                  color: place.isOpen
                      ? const Color(0xFF69D49B)
                      : ServiceColors.orange,
                ),
              ),
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
                    'destination': place.address,
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
                      'Địa điểm minh họa chưa có số điện thoại.',
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

class _MockMap extends StatelessWidget {
  const _MockMap({
    required this.places,
    required this.selectedId,
    required this.onSelected,
  });
  final List<ServicePlace> places;
  final String selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(18),
    child: SizedBox(
      height: 300,
      child: LayoutBuilder(
        builder: (context, constraints) => Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _MapPainter())),
            for (final place in places)
              Positioned(
                left:
                    constraints.maxWidth *
                        switch (place.id) {
                          '1' => .22,
                          '2' => .65,
                          '3' => .38,
                          _ => .75,
                        } -
                    24,
                top:
                    300 *
                        switch (place.id) {
                          '1' => .3,
                          '2' => .22,
                          '3' => .6,
                          _ => .64,
                        } -
                    24,
                child: IconButton.filled(
                  tooltip: place.name,
                  style: IconButton.styleFrom(
                    backgroundColor: place.id == selectedId
                        ? ServiceColors.orange
                        : const Color(0xFF3E5351),
                  ),
                  onPressed: () => onSelected(place.id),
                  icon: Icon(place.isCharging ? Icons.ev_station : Icons.build),
                ),
              ),
            const Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Google Map • Mô phỏng',
                  style: TextStyle(
                    fontSize: 12,
                    color: ServiceColors.text,
                    backgroundColor: ServiceColors.surface,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFE8F1E9),
    );
    final river = Path()
      ..moveTo(size.width * .8, 0)
      ..cubicTo(
        size.width * .4,
        size.height * .4,
        size.width * .95,
        size.height * .7,
        size.width * .62,
        size.height,
      );
    canvas.drawPath(
      river,
      Paint()
        ..color = const Color(0xFFB9DFF3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 35,
    );
    final road = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..strokeWidth = 12;
    for (var i = 1; i <= 4; i++) {
      canvas.drawLine(
        Offset(0, size.height * i / 5),
        Offset(size.width, size.height * (i / 5 + .1)),
        road,
      );
      canvas.drawLine(
        Offset(size.width * i / 5, 0),
        Offset(size.width * (i / 5 - .1), size.height),
        road,
      );
    }
  }

  @override
  bool shouldRepaint(_MapPainter oldDelegate) => false;
}
