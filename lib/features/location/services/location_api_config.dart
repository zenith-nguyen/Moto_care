import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final locationApiConfigProvider = Provider<LocationApiConfig>(
  (ref) => const LocationApiConfig(),
);

class LocationApiConfig {
  const LocationApiConfig({
    this.placesKey = const String.fromEnvironment('GOOGLE_PLACES_API_KEY'),
    this.geocodingKey = const String.fromEnvironment(
      'GOOGLE_GEOCODING_API_KEY',
    ),
    this.androidMapsKey = const String.fromEnvironment(
      'GOOGLE_MAPS_ANDROID_API_KEY',
    ),
    this.iosMapsKey = const String.fromEnvironment('GOOGLE_MAPS_IOS_API_KEY'),
    this.placesProxyUrl = const String.fromEnvironment('PLACES_PROXY_URL'),
    this.geocodingProxyUrl = const String.fromEnvironment(
      'GEOCODING_PROXY_URL',
    ),
    this.androidCertificate = const String.fromEnvironment(
      'GOOGLE_ANDROID_CERT_SHA1',
    ),
  });
  final String placesKey, geocodingKey, androidMapsKey, iosMapsKey;
  final String placesProxyUrl, geocodingProxyUrl, androidCertificate;
  bool get placesConfigured =>
      placesKey.isNotEmpty || placesProxyUrl.isNotEmpty;
  bool get geocodingConfigured =>
      geocodingKey.isNotEmpty ||
      placesKey.isNotEmpty ||
      geocodingProxyUrl.isNotEmpty;
  bool get mapConfigured =>
      !kIsWeb &&
      switch (defaultTargetPlatform) {
        TargetPlatform.android => androidMapsKey.isNotEmpty,
        TargetPlatform.iOS => iosMapsKey.isNotEmpty,
        _ => false,
      };
  Map<String, String> get applicationHeaders =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android
      ? {
          'X-Android-Package': 'com.motocare.app',
          if (androidCertificate.isNotEmpty)
            'X-Android-Cert': androidCertificate
                .replaceAll(':', '')
                .toUpperCase(),
        }
      : !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS
      ? {'X-Ios-Bundle-Identifier': 'com.motocare.app'}
      : {};
}
