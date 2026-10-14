import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../models/station_model.dart';

final stationShareServiceProvider = Provider<StationShareService>(
  (ref) => StationShareService(),
);

class StationShareService {
  StationShareService({Future<void> Function(ShareParams)? share})
    : _share =
          share ??
          ((params) async {
            await SharePlus.instance.share(params);
          });

  final Future<void> Function(ShareParams) _share;

  Future<void> share(StationModel station, Rect origin) => _share(
    ShareParams(
      title: station.name,
      subject: station.name,
      text: [
        station.name,
        station.address,
        if (station.station.phoneNumber.trim().isNotEmpty)
          'Liên hệ: ${station.station.phoneNumber}',
        station.mapUri.toString(),
      ].join('\n'),
      sharePositionOrigin: origin,
    ),
  );
}
