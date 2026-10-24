import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_dependencies.dart';
import '../../auth/application/session_controller.dart';
import '../../auth/application/session_state.dart';
import '../domain/provider_models.dart';

/// Real weekly operations/rating/wallet statistics from
/// GET /providers/me/statistics/weekly (Asia/Ho_Chi_Minh).
final providerWeeklyStatsProvider =
    FutureProvider.autoDispose<ProviderWeeklyStats>((ref) async {
      if (ref.watch(sessionControllerProvider) is! SessionSignedIn) {
        throw StateError('Chưa đăng nhập tài khoản Thợ.');
      }
      return ProviderWeeklyStats.fromJson(
        await ref
            .read(jsonApiProvider)
            .getObject('/providers/me/statistics/weekly'),
      );
    });
