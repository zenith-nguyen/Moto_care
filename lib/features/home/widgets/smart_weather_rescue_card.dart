import 'package:flutter/material.dart';

import '../models/home_rescue_quick_action.dart';
import '../models/home_weather.dart';
import 'weather_condition_icon.dart';

class SmartWeatherRescueCard extends StatefulWidget {
  const SmartWeatherRescueCard({
    super.key,
    required this.onSearch,
    required this.onFilter,
    required this.onQuickAction,
    required this.onRetryWeather,
    this.weather,
    this.isLoading = false,
    this.hasWeatherError = false,
    this.selectedAction = HomeRescueQuickAction.all,
    this.activeFilterCount = 0,
  });

  final WeatherRescueSnapshot? weather;
  final bool isLoading;
  final bool hasWeatherError;
  final VoidCallback onSearch;
  final VoidCallback onFilter;
  final ValueChanged<HomeRescueQuickAction> onQuickAction;
  final VoidCallback onRetryWeather;
  final HomeRescueQuickAction selectedAction;
  final int activeFilterCount;

  static const blue = Color(0xFF175D91);
  static const searchHint = 'Bạn cần hỗ trợ gì? (Thủng lốp, hết bình...)';

  @override
  State<SmartWeatherRescueCard> createState() => _SmartWeatherRescueCardState();
}

class _SmartWeatherRescueCardState extends State<SmartWeatherRescueCard> {
  final _chips = ScrollController();

  @override
  void dispose() {
    _chips.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DecoratedBox(
    key: const ValueKey('smart-weather-rescue-card'),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF91C8EF), Color(0xFF80B3E6)],
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x10557891),
          blurRadius: 16,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _weather(),
          _search(),
          SingleChildScrollView(
            key: const ValueKey('weather-quick-actions'),
            controller: _chips,
            scrollDirection: Axis.horizontal,
            // RawChip paints its ink over a canvas Material; keep it transparent
            // so translucent fills blend with the card's sky-blue gradient.
            child: Theme(
              data: Theme.of(context).copyWith(canvasColor: Colors.transparent),
              child: Row(
                children: [
                  for (final action in HomeRescueQuickAction.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        key: ValueKey('weather-action-${action.name}'),
                        label: Text(action.label),
                        selected: action == widget.selectedAction,
                        showCheckmark: true,
                        checkmarkColor: Colors.white,
                        selectedColor: SmartWeatherRescueCard.blue,
                        backgroundColor: const Color(0xFF2D78AD)
                            .withValues(alpha: .15),
                        surfaceTintColor: Colors.transparent,
                        elevation: 0,
                        pressElevation: 0,
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                        visualDensity: VisualDensity.compact,
                        labelStyle: TextStyle(
                          color: action == widget.selectedAction
                              ? Colors.white
                              : const Color(0xFF354F65),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          fontFamilyFallback: const [
                            'Apple Color Emoji',
                            'Noto Color Emoji',
                            'Segoe UI Emoji',
                          ],
                        ),
                        onSelected: (_) => widget.onQuickAction(action),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _weather() {
    final snapshot = widget.weather;
    if (snapshot == null) {
      return Row(
        children: [
          const Icon(Icons.cloud_outlined, color: Color(0xFF688399), size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.hasWeatherError
                      ? 'Chưa tải được thời tiết'
                      : 'Đang cập nhật thời tiết…',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF354B60),
                  ),
                ),
                if (widget.isLoading) ...[
                  const SizedBox(height: 8),
                  const LinearProgressIndicator(
                    minHeight: 2,
                    color: SmartWeatherRescueCard.blue,
                  ),
                ],
              ],
            ),
          ),
          if (widget.hasWeatherError)
            IconButton(
              tooltip: 'Tải lại thời tiết',
              onPressed: widget.onRetryWeather,
              icon: const Icon(Icons.refresh_rounded),
            ),
        ],
      );
    }
    final weather = snapshot.weather;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Semantics(
            label: weather.isDemo ? 'Thời tiết mẫu' : 'Thời tiết hôm nay',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  label: '${weather.temperatureCelsius.round()} độ C',
                  excludeSemantics: true,
                  child: Text(
                    '${weather.temperatureCelsius.round()}°',
                    key: const ValueKey('weather-temperature'),
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  snapshot.riskAlert,
                  key: const ValueKey('weather-risk-alert'),
                  style: const TextStyle(
                    fontSize: 11,
                    height: 1.4,
                    color: Color(0xFF354F65),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Semantics(
          label: weather.description,
          child: WeatherConditionIcon(condition: weather.condition, size: 72),
        ),
      ],
    );
  }

  Widget _search() => Container(
    key: const ValueKey('weather-search-bar'),
    margin: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    padding: const EdgeInsets.fromLTRB(12, 2, 4, 2),
    child: Row(
      children: [
        Expanded(
          child: InkWell(
            key: const ValueKey('home-search'),
            onTap: widget.onSearch,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: const Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    color: Color(0xFF8693A0),
                    size: 22,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      SmartWeatherRescueCard.searchHint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: Color(0xFF8794A1)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        IconButton(
          key: const ValueKey('weather-filter'),
          tooltip: 'Bộ lọc',
          onPressed: widget.onFilter,
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFFEAF4FD),
            foregroundColor: SmartWeatherRescueCard.blue,
            minimumSize: const Size(44, 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          icon: Badge(
            isLabelVisible: widget.activeFilterCount > 0,
            label: Text('${widget.activeFilterCount}'),
            backgroundColor: SmartWeatherRescueCard.blue,
            child: const Icon(Icons.tune_rounded, size: 20),
          ),
        ),
      ],
    ),
  );
}
