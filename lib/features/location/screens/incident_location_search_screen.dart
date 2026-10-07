import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/main_navigation.dart';
import '../../../core/widgets/service_scaffold.dart';
import '../../activity/models/rescue_order.dart';
import '../../home/models/home_destination.dart';
import '../../home/models/rescue_location.dart';
import '../../home/providers/home_provider.dart';
import '../../home/theme/home_theme.dart';
import '../../home/widgets/brand_backdrop.dart';
import '../../home/widgets/home_bottom_navigation.dart';
import '../../profile/providers/profile_provider.dart';
import '../data/mock_incident_places.dart';
import '../providers/incident_location_provider.dart';

class IncidentLocationSearchScreen extends ConsumerStatefulWidget {
  const IncidentLocationSearchScreen({super.key, this.initialLocation});
  final RescueLocation? initialLocation;

  @override
  ConsumerState<IncidentLocationSearchScreen> createState() =>
      _IncidentLocationSearchScreenState();
}

class _IncidentLocationSearchScreenState
    extends ConsumerState<IncidentLocationSearchScreen> {
  final _formKey = GlobalKey<FormState>();
  late final RescueLocation _initial =
      widget.initialLocation ??
      ref.read(rescueLocationProvider) ??
      ref.read(incidentCurrentLocationProvider);
  late final _address = TextEditingController(text: _initial.address);
  late final _landmark = TextEditingController(text: _initial.landmark);
  late RescueLocation _addressSource = _initial;
  String _query = '';
  bool _openingMap = false;

  @override
  void dispose() {
    _address.dispose();
    _landmark.dispose();
    super.dispose();
  }

  Future<void> _openMap([RescueLocation? place]) async {
    if (_openingMap) return;
    if (place != null) {
      _address.text = place.address;
      _addressSource = place;
      setState(() => _query = '');
    }
    if (!_formKey.currentState!.validate()) return;
    final source = _addressSource;
    final address = _address.text.trim();
    final sameAddress = address == source.address.trim();
    final location = RescueLocation(
      address: address,
      landmark: _landmark.text.trim(),
      latitude: sameAddress ? source.latitude : null,
      longitude: sameAddress ? source.longitude : null,
    );
    FocusScope.of(context).unfocus();
    setState(() => _openingMap = true);
    final order = await context.push<RescueOrder>(
      '/incident-map-picker',
      extra: location,
    );
    if (!mounted) return;
    setState(() => _openingMap = false);
    if (order != null) {
      if (context.canPop()) {
        context.pop(order);
      } else {
        context.go('/hoat-dong');
      }
    }
  }

  void _back() => context.canPop() ? context.pop() : context.go('/trang-chu');

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider).profile;
    final query = normalizeServiceSearch(_query);
    final places = ref
        .watch(recentIncidentPlacesProvider)
        .where(
          (place) =>
              normalizeServiceSearch('${place.name} ${place.location.address}')
                  .contains(query),
        )
        .toList();
    final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final compact = MediaQuery.sizeOf(context).width < 380 || scale > 1.2;
    final mapButton = TextButton(
      onPressed: _openingMap ? null : () => _openMap(),
      child: const Text('Chọn trên bản đồ', style: TextStyle(fontSize: 13)),
    );
    return Theme(
      data: HomeTheme.light,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          titleSpacing: 12,
          toolbarHeight: (compact ? 102 : 76) + (scale - 1) * 60,
          flexibleSpace: const BrandBackdrop(child: SizedBox.expand()),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Quay lại',
                    onPressed: _back,
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const Expanded(
                    child: Text(
                      'Vị trí gặp sự cố?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (!compact) mapButton,
                ],
              ),
              if (compact)
                Align(alignment: Alignment.centerRight, child: mapButton),
            ],
          ),
        ),
        body: SafeArea(
          top: false,
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Form(
                key: _formKey,
                child: ListView(
                  key: const ValueKey('incident-search-scroll'),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    TextFormField(
                      key: const ValueKey('incident-address'),
                      controller: _address,
                      minLines: 1,
                      maxLines: 3,
                      maxLength: 240,
                      textInputAction: TextInputAction.next,
                      style: const TextStyle(fontSize: 15, height: 1.5),
                      decoration:
                          _inputDecoration(
                            hint: 'Nhập địa chỉ gặp sự cố',
                            icon: Icons.location_on_rounded,
                            iconColor: HomeColors.red,
                          ).copyWith(
                            counterText: '',
                            suffixIcon: IconButton(
                              tooltip: 'Xóa địa chỉ',
                              onPressed: () {
                                _address.clear();
                                setState(() => _query = '');
                              },
                              icon: const Icon(Icons.close_rounded, size: 18),
                            ),
                          ),
                      onChanged: (value) => setState(() => _query = value),
                      validator: (value) => (value?.trim().length ?? 0) < 5
                          ? 'Vui lòng nhập địa chỉ ít nhất 5 ký tự.'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const ValueKey('incident-landmark'),
                      controller: _landmark,
                      minLines: 1,
                      maxLines: 3,
                      maxLength: 240,
                      textInputAction: TextInputAction.done,
                      style: const TextStyle(fontSize: 14, height: 1.5),
                      decoration: _inputDecoration(
                        hint: 'Mô tả điểm nhận diện (VD: Đối diện cây xăng, cổng trường...)',
                        icon: Icons.edit_outlined,
                        iconColor: HomeColors.secondary,
                      ).copyWith(counterText: ''),
                      onFieldSubmitted: (_) => _openMap(),
                    ),
                    const SizedBox(height: 16),
                    Material(
                      color: HomeColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        leading: const Icon(
                          Icons.my_location_rounded,
                          color: HomeColors.primary,
                        ),
                        title: const Text(
                          'Sử dụng vị trí hiện tại của tôi',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                          color: HomeColors.secondary,
                        ),
                        onTap: _openingMap
                            ? null
                            : () => _openMap(
                                ref.read(incidentCurrentLocationProvider),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Địa điểm và định vị đang dùng dữ liệu minh họa.',
                      style: TextStyle(
                        color: HomeColors.secondary,
                        fontSize: 12,
                      ),
                    ),
                    const ServiceSectionTitle('Địa điểm quen thuộc'),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        ActionChip(
                          avatar: const Icon(Icons.home_outlined, size: 20),
                          label: const Text('Gần Nhà'),
                          backgroundColor: HomeColors.surface,
                          side: const BorderSide(color: HomeColors.border),
                          onPressed: _openingMap
                              ? null
                              : () => _openMap(
                                  profile.defaultAddress.trim().isEmpty
                                      ? mockHomeIncidentLocation
                                      : RescueLocation(
                                          address: profile.defaultAddress,
                                        ),
                                ),
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.business_outlined, size: 20),
                          label: const Text('Gần Công ty'),
                          backgroundColor: HomeColors.surface,
                          side: const BorderSide(color: HomeColors.border),
                          onPressed: _openingMap
                              ? null
                              : () => _openMap(
                                  profile.workAddress.trim().isEmpty
                                      ? mockWorkIncidentLocation
                                      : RescueLocation(
                                          address: profile.workAddress,
                                        ),
                                ),
                        ),
                      ],
                    ),
                    const ServiceSectionTitle('Địa điểm gần đây'),
                    if (places.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          'Chưa tìm thấy địa điểm phù hợp. Bạn có thể nhập địa chỉ và chọn trên bản đồ.',
                          style: TextStyle(
                            color: HomeColors.secondary,
                            height: 1.5,
                          ),
                        ),
                      ),
                    for (final place in places) ...[
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 6),
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFE9ECEF),
                          child: Icon(
                            Icons.history_rounded,
                            color: HomeColors.secondary,
                          ),
                        ),
                        title: Text(
                          place.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          place.location.address,
                          style: const TextStyle(
                            color: HomeColors.secondary,
                            height: 1.5,
                          ),
                        ),
                        onTap: _openingMap
                            ? null
                            : () => _openMap(place.location),
                      ),
                      const Divider(height: 1),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        bottomNavigationBar: HomeBottomNavigation(
          selectedDestination: HomeDestination.home,
          onSelected: (destination) => navigateMainTab(context, destination),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    required Color iconColor,
  }) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: HomeColors.secondary, fontSize: 14),
    prefixIcon: Icon(icon, color: iconColor),
    filled: true,
    fillColor: HomeColors.surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFDEE2E6)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFDEE2E6)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: HomeColors.primary, width: 1.5),
    ),
  );
}
