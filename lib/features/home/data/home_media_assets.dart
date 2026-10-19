import '../models/home_weather.dart';

abstract final class HomeMediaAssets {
  // Byte-identical to the supplied "vid trang chủ.mp4". An ASCII bundle key
  // avoids native URI decoding of spaces and Vietnamese accents on Android.
  static const heroVideo = 'assets/images/home-video.mp4';
  static const heroPoster = 'assets/images/home-video-poster.jpg';
  static const weatherBackground = 'assets/images/Thời tiết.png';
  static const rainWeatherBackground = 'assets/images/Trời mưa.png';
  static const rainWeatherIcon = 'assets/images/Thời tiết mưa.png';

  static String weatherBackgroundFor(HomeWeatherCondition? condition) =>
      condition?.hasRain == true ? rainWeatherBackground : weatherBackground;
}
