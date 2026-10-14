import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/service_actions.dart';
import '../../../core/widgets/service_scaffold.dart';
import '../models/rescue_station.dart';

abstract final class RescueStationActions {
  static Future<void> call(
    BuildContext context,
    WidgetRef ref,
    RescueStation station,
  ) async {
    final phone = station.phoneNumber.trim();
    if (phone.isEmpty) {
      showServiceMessage(context, 'Trạm này chưa cập nhật số điện thoại.');
      return;
    }
    await launchServiceUri(
      context,
      ref,
      Uri(scheme: 'tel', path: phone),
      'Không thể mở ứng dụng gọi điện. Số trạm: $phone',
    );
  }

  static Future<void> directions(
    BuildContext context,
    WidgetRef ref,
    RescueStation station,
  ) => launchServiceUri(
    context,
    ref,
    Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '${station.latitude},${station.longitude}',
    }),
    'Không thể mở Google Maps. Địa chỉ trạm: ${station.address}',
  );
}
