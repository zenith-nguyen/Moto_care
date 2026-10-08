import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
import '../models/place_suggestion.dart';
import '../services/device_location_service.dart';
import '../services/location_api_config.dart';
import '../services/places_service.dart';
import '../providers/incident_location_provider.dart';

class SelectLocationScreen extends ConsumerStatefulWidget {
  const SelectLocationScreen({
    super.key,
    this.initialLocation,
    this.returnSelection = false,
  });
  final RescueLocation? initialLocation;
  final bool returnSelection;

  @override
  ConsumerState<SelectLocationScreen> createState() =>
      _SelectLocationScreenState();
}

class _SelectLocationScreenState extends ConsumerState<SelectLocationScreen> {
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
  bool _searching = false;
  bool _resolving = false;
  String? _error;
  List<PlaceSuggestion> _suggestions = [];
  Timer? _debounce;
  CancelToken? _searchCancel;
  CancelToken? _detailCancel;
  int _revision = 0;
  String _sessionToken = newPlacesSessionToken();

  bool _current(int revision) => mounted && revision == _revision;

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _searchCancel?.cancel();
    _detailCancel?.cancel();
    final revision = ++_revision;
    setState(() {
      _query = value.trim();
      _addressSource = RescueLocation(address: value.trim());
      _suggestions = [];
      _searching = false;
      _resolving = false;
      _openingMap = false;
      _error = null;
    });
    if (_query.isEmpty) {
      _sessionToken = newPlacesSessionToken();
      return;
    }
    _debounce = Timer(
      const Duration(milliseconds: 300),
      () => unawaited(_search(_query, revision)),
    );
  }

  Future<void> _search(String query, int revision) async {
    if (!_current(revision)) return;
    final cancel = _searchCancel = CancelToken();
    setState(() => _searching = true);
    try {
      final suggestions = await ref
          .read(placesServiceProvider)
          .autocomplete(
            query,
            sessionToken: _sessionToken,
            bias: _initial.hasCoordinates
                ? LatLng(_initial.latitude!, _initial.longitude!)
                : null,
            cancelToken: cancel,
          );
      if (_current(revision)) setState(() => _suggestions = suggestions);
    } on Exception catch (error) {
      if (_current(revision) &&
          !(error is DioException && CancelToken.isCancel(error))) {
        setState(
          () => _error = error is PlacesException
              ? error.message
              : 'Không tìm được địa điểm. Vui lòng thử lại.',
        );
      }
    } finally {
      if (_current(revision)) setState(() => _searching = false);
    }
  }

  Future<void> _selectSuggestion(PlaceSuggestion suggestion) async {
    if (_resolving || _openingMap) return;
    _debounce?.cancel();
    _searchCancel?.cancel();
    final revision = ++_revision;
    final cancel = _detailCancel = CancelToken();
    setState(() {
      _resolving = true;
      _searching = false;
      _error = null;
    });
    try {
      final token = _sessionToken;
      _sessionToken = newPlacesSessionToken();
      final location = await ref
          .read(placesServiceProvider)
          .detail(suggestion.id, sessionToken: token, cancelToken: cancel);
      if (!_current(revision)) return;
      await _openMap(location);
    } on Exception catch (error) {
      if (_current(revision) &&
          !(error is DioException && CancelToken.isCancel(error))) {
        setState(
          () => _error = error is PlacesException
              ? error.message
              : 'Chưa lấy được tọa độ. Vui lòng chọn lại địa điểm.',
        );
      }
    } finally {
      if (_current(revision)) setState(() => _resolving = false);
    }
  }

  Future<void> _useGps() async {
    if (_resolving || _openingMap) return;
    _debounce?.cancel();
    _searchCancel?.cancel();
    final revision = ++_revision;
    setState(() {
      _resolving = true;
      _error = null;
      _searching = false;
    });
    try {
      final location = await ref
          .read(deviceLocationProvider)()
          .timeout(const Duration(seconds: 24));
      if (_current(revision)) await _openMap(location);
    } on Exception catch (error) {
      if (_current(revision)) {
        setState(
          () => _error = error is LocationLookupException
              ? error.message
              : 'Chưa lấy được GPS. Bạn có thể nhập địa chỉ.',
        );
      }
    } finally {
      if (_current(revision)) setState(() => _resolving = false);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCancel?.cancel();
    _detailCancel?.cancel();
    _address.dispose();
    _landmark.dispose();
    super.dispose();
  }

  Future<void> _openMap([RescueLocation? place, bool pickOnMap = false]) async {
    if (_openingMap) return;
    if (pickOnMap && widget.returnSelection && context.canPop()) {
      context.pop();
      return;
    }
    if (place != null) {
      _address.text = place.address;
      _addressSource = place;
      setState(() => _query = '');
    }
    if (!(pickOnMap && _address.text.trim().isEmpty) &&
        !_formKey.currentState!.validate()) {
      return;
    }
    FocusScope.of(context).unfocus();
    _debounce?.cancel();
    _searchCancel?.cancel();
    setState(() {
      _openingMap = true;
      _error = null;
    });
    final revision = _revision;
    final source = _addressSource;
    final address = _address.text.trim();
    var resolved = address == source.address.trim()
        ? source
        : RescueLocation(address: address);
    try {
      if (!pickOnMap &&
          !resolved.hasCoordinates &&
          ref.read(locationApiConfigProvider).geocodingConfigured) {
        final cancel = _detailCancel = CancelToken();
        resolved = await ref
            .read(placesServiceProvider)
            .geocode(address, cancelToken: cancel);
      }
    } on Exception catch (error) {
      if (_current(revision)) {
        setState(() {
          _openingMap = false;
          _error = error is PlacesException ? error.message : 'Chưa tìm được tọa độ địa chỉ này. Hãy chọn một kết quả tìm kiếm.';
        });
      }
      return;
    }
    if (!mounted) return;
    if (revision != _revision) return;
    final location = RescueLocation(
      address: resolved.address,
      landmark: _landmark.text.trim(),
      latitude: resolved.latitude,
      longitude: resolved.longitude,
    );
    if (widget.returnSelection && context.canPop()) {
      context.pop(location);
      return;
    }
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
    final places = ref.watch(recentIncidentPlacesProvider);
    final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final compact = MediaQuery.sizeOf(context).width < 380 || scale > 1.2;
    final mapButton = TextButton(
      onPressed: _openingMap || _resolving ? null : () => _openMap(null, true),
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
                                _onQueryChanged('');
                              },
                              icon: const Icon(Icons.close_rounded, size: 18),
                            ),
                          ),
                      onChanged: _onQueryChanged,
                      validator: (value) => (value?.trim().length ?? 0) < 5
                          ? 'Vui lòng nhập địa chỉ ít nhất 5 ký tự.'
                          : null,
                    ),
                    if ((_resolving && _query.isEmpty) || _openingMap)
                      const Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: LinearProgressIndicator(),
                      ),
                    if (_query.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        spacing: 16,
                        children: [
                          Text(
                            'Kết quả tìm kiếm',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            'Google Maps',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 12,
                              color: Color(0xFF1F1F1F),
                            ),
                          ),
                        ],
                      ),
                      if (_searching || _resolving)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: LinearProgressIndicator(),
                        ),
                      ListView.builder(
                        key: const ValueKey('place-suggestions'),
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _suggestions.length,
                        itemBuilder: (context, index) {
                          final suggestion = _suggestions[index];
                          return ListTile(
                            key: ValueKey('place-${suggestion.id}'),
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(
                              Icons.location_on_outlined,
                              color: HomeColors.red,
                            ),
                            title: Text(
                              suggestion.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(suggestion.address),
                            onTap: _resolving || _openingMap
                                ? null
                                : () => _selectSuggestion(suggestion),
                          );
                        },
                      ),
                      if (!_searching &&
                          !_resolving &&
                          _suggestions.isEmpty &&
                          _error == null)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'Chưa có gợi ý. Nhập tên hoặc địa chỉ chi tiết hơn.',
                          ),
                        ),
                    ],
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: HomeColors.red),
                        ),
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
                      onFieldSubmitted: _resolving || _openingMap
                          ? null
                          : (_) => _openMap(),
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
                        onTap: _openingMap || _resolving ? null : _useGps,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Tìm theo tên địa điểm, đường hoặc địa chỉ đầy đủ.',
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
                          onPressed:
                              _openingMap ||
                                  _resolving ||
                                  profile.defaultAddress.trim().isEmpty
                              ? null
                              : () => _openMap(
                                  RescueLocation(
                                    address: profile.defaultAddress,
                                  ),
                                ),
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.business_outlined, size: 20),
                          label: const Text('Gần Công ty'),
                          backgroundColor: HomeColors.surface,
                          side: const BorderSide(color: HomeColors.border),
                          onPressed:
                              _openingMap ||
                                  _resolving ||
                                  profile.workAddress.trim().isEmpty
                              ? null
                              : () => _openMap(
                                  RescueLocation(address: profile.workAddress),
                                ),
                        ),
                      ],
                    ),
                    if (_query.isEmpty) ...[
                      const ServiceSectionTitle('Địa điểm gần đây'),
                      if (places.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            'Chưa có địa điểm gần đây. Hãy tìm kiếm hoặc dùng GPS.',
                            style: TextStyle(
                              color: HomeColors.secondary,
                              height: 1.5,
                            ),
                          ),
                        ),
                      for (final place in places) ...[
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 6,
                          ),
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
                          onTap: _openingMap || _resolving
                              ? null
                              : () => _openMap(place.location),
                        ),
                        const Divider(height: 1),
                      ],
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
