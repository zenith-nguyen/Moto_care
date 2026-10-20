import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_dependencies.dart';
import '../../auth/application/session_controller.dart';
import '../../auth/application/session_state.dart';
import '../domain/professional_profile.dart';

final professionalProfileProvider =
    FutureProvider.autoDispose<ProfessionalProfile>((ref) async {
      if (ref.watch(sessionControllerProvider) is! SessionSignedIn) {
        throw StateError('Chưa đăng nhập tài khoản Thợ.');
      }
      return ProfessionalProfile.fromJson(
        await ref.read(jsonApiProvider).getObject('/providers/me/profile'),
      );
    });

Future<void> updateProfessionalProfile(
  WidgetRef ref, {
  required String bio,
  required int yearsOfExperience,
  required double serviceRadiusKm,
}) async {
  await ref
      .read(jsonApiProvider)
      .patchObject(
        '/providers/me/profile',
        data: {
          'bio': bio.trim(),
          'yearsOfExperience': yearsOfExperience,
          'serviceRadiusKm': serviceRadiusKm,
        },
      );
}
