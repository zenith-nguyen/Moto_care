import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../home/models/home_weather.dart';
import '../../home/providers/home_weather_provider.dart';
import '../../home/widgets/weather_condition_icon.dart';
import '../providers/admin_account_provider.dart';

/// The shared User forecast with the Admin's saved weather price factor.
class AdminWeatherCard extends ConsumerWidget {
  const AdminWeatherCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final forecast = ref.watch(homeWeatherProvider);
    final factor = ref.watch(
      adminAccountProvider.select((state) => state.settings.weatherFactor),
    );
    return DecoratedBox(
      key: const ValueKey('admin-weather-card'),
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            forecast.when(
              data: (snapshot) => _WeatherReadout(snapshot: snapshot),
              loading: () => SizedBox(
                height: 72,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Đang tải thời tiết…',
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        color: const Color(0xFF175D91),
                        fontWeight: FontWeight.w400,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const LinearProgressIndicator(
                      color: Color(0xFF175D91),
                      backgroundColor: Color(0x33FFFFFF),
                    ),
                  ],
                ),
              ),
              error: (error, stack) => Row(
                children: [
                  Expanded(
                    child: Text(
                      'Chưa tải được thời tiết',
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF175D91),
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Tải lại thời tiết',
                    onPressed: () => ref.invalidate(homeWeatherProvider),
                    color: const Color(0xFF175D91),
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _PriceFactorBadge(factor: factor),
          ],
        ),
      ),
    );
  }
}

class _WeatherReadout extends StatelessWidget {
  const _WeatherReadout({required this.snapshot});

  final WeatherRescueSnapshot snapshot;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: snapshot.weather.isDemo ? 'Thời tiết mẫu' : 'Thời tiết hôm nay',
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${snapshot.weather.temperatureCelsius.round()}°',
                key: const ValueKey('admin-weather-temperature'),
                semanticsLabel:
                    '${snapshot.weather.temperatureCelsius.round()} độ C',
                style: GoogleFonts.montserrat(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                snapshot.riskAlert.replaceAll(' • ', ' · '),
                key: const ValueKey('admin-weather-risk'),
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  height: 1.45,
                  color: const Color(0xFF175D91),
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Transform.translate(
          offset: const Offset(4, -6),
          child: WeatherConditionIcon(
            condition: snapshot.weather.condition,
            size: 72,
          ),
        ),
      ],
    ),
  );
}

class _PriceFactorBadge extends StatelessWidget {
  const _PriceFactorBadge({required this.factor});

  final double factor;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          factor > 1
              ? 'Áp dụng phụ phí x$factor'
              : 'Hệ số giá: x$factor (Bình thường)',
          key: const ValueKey('admin-weather-price-factor'),
          style: GoogleFonts.montserrat(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            height: 1.4,
            color: const Color(0xFF175D91),
            letterSpacing: -0.2,
          ),
        ),
      ),
    ),
  );
}
