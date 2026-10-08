import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/session_controller.dart';

class SessionErrorPage extends ConsumerWidget {
  const SessionErrorPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Moto Care')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 48),
              const SizedBox(height: 16),
              Text(
                'Không thể khôi phục phiên đăng nhập.',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Kiểm tra kết nối tới backend rồi thử lại. Token và chi tiết '
                'nội bộ không được hiển thị trên màn hình này.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () =>
                    ref.read(sessionControllerProvider.notifier).bootstrap(),
                child: const Text('Thử lại'),
              ),
              TextButton(
                onPressed: () =>
                    ref.read(sessionControllerProvider.notifier).signOut(),
                child: const Text('Xóa phiên và đăng nhập lại'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
