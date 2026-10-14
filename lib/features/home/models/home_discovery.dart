import 'package:flutter/foundation.dart';

import '../../activity/models/rescue_order.dart';
import '../../rescue_station/models/rescue_station.dart';
import 'home_rescue_quick_action.dart';

enum HomeStationCategory {
  all('Tất cả trạm'),
  fastest('Đến nhanh nhất'),
  topRated('Đánh giá cao'),
  towing('Xe cẩu kéo'),
  tire24h('Vá xe 24/7');

  const HomeStationCategory(this.label);
  final String label;
}

@immutable
class HomeDiscoveryFilters {
  const HomeDiscoveryFilters({
    this.open24h = false,
    this.verified = false,
    this.maxDistanceKm,
  });

  final bool open24h;
  final bool verified;
  final int? maxDistanceKm;
  int get activeCount =>
      (open24h ? 1 : 0) + (verified ? 1 : 0) + (maxDistanceKm == null ? 0 : 1);
}

@immutable
class HomeDiscoveryState {
  const HomeDiscoveryState({
    this.query = '',
    this.category = HomeStationCategory.all,
    this.filters = const HomeDiscoveryFilters(),
    this.quickAction = HomeRescueQuickAction.all,
  });

  final String query;
  final HomeStationCategory category;
  final HomeDiscoveryFilters filters;
  final HomeRescueQuickAction quickAction;
}

@immutable
class HomeStationDetails {
  const HomeStationDetails({
    required this.imageAsset,
    this.area,
    this.reviewCount,
    this.responseMinutes,
  });

  final String imageAsset;
  final String? area;
  final int? reviewCount;
  final int? responseMinutes;
}

@immutable
class HomeStationListing {
  const HomeStationListing({
    required this.station,
    required this.services,
    required this.details,
    required this.distanceKm,
  });

  final RescueStation station;
  final List<RescueServiceType> services;
  final HomeStationDetails details;
  final double distanceKm;

  String get responseLabel {
    if (!station.isOpen) return 'Đóng cửa';
    final minutes = details.responseMinutes;
    if (minutes != null) return '$minutes–${minutes + 5} phút';
    return station.isOpen24h ? 'Phục vụ 24/7' : 'Đang mở cửa';
  }
}
