import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/session_controller.dart';
import '../../auth/application/session_state.dart';
import '../../auth/domain/app_user.dart';

class RoleIntegrationPage extends ConsumerWidget {
  const RoleIntegrationPage({required this.role, super.key});

  final AppRole role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sessionControllerProvider);
    final user = state is SessionSignedIn ? state.session.user : null;

    return Scaffold(
      appBar: AppBar(
        title: Text('Moto Care · ${_roleLabel(role)}'),
        actions: [
          IconButton(
            tooltip: 'Đăng xuất',
            onPressed: () =>
                ref.read(sessionControllerProvider.notifier).signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_outline, size: 56),
                const SizedBox(height: 16),
                Text(
                  'Đã kết nối vai trò ${_roleLabel(role)}',
                  key: const Key('role-integration-title'),
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  user == null
                      ? 'Đang tải hồ sơ…'
                      : '${user.name} · ${user.status.wireValue}',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Đây là điểm gắn UI tạm thời. Màn hình do nhóm UX/UI bàn '
                  'giao sẽ thay nội dung này nhưng giữ nguyên session, router '
                  'và repository.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _roleLabel(AppRole role) {
    return switch (role) {
      AppRole.customer => 'Khách hàng',
      AppRole.provider => 'Thợ',
      AppRole.admin => 'Admin',
    };
  }
}
