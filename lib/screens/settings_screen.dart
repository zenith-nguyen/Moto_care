import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/revo_switch.dart';
import '../widgets/ui.dart';
import 'terms_and_commitment_screen.dart';
import 'demo_controls_screen.dart';

import 'support_screen.dart';
export 'support_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  void _info(BuildContext context, String title, String body) => showDialog<
          void>(
      context: context,
      builder: (ctx) => AlertDialog(
              title: Text(title, style: appText(18, weight: FontWeight.w700)),
              content: Text(body, style: appText(13, color: AppColors.textSub)),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Đã hiểu'))
              ]));
  void _gps(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
              child: ListenableBuilder(
            listenable: appState,
            builder: (_, __) => Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('Định vị', style: appText(16, weight: FontWeight.w600)),
                  SwitchListTile(
                      title: Text('Định vị', style: appText(13)),
                      subtitle: Text('Mô phỏng quyền định vị khi hoạt động',
                          style: appText(12, color: AppColors.textSub)),
                      value: appState.gpsEnabled,
                      onChanged: appState.setGps),
                ])),
          )));
  @override
  Widget build(BuildContext context) => ListenableBuilder(
      listenable: appState,
      builder: (context, _) => Scaffold(
            body: SafeArea(
                child: Column(children: [
              ScreenHeader(
                  title: 'Cài đặt',
                  trailing: !appState.demoEnabled
                      ? null
                      : IconButton(
                          tooltip: 'Chế độ demo',
                          icon: const Icon(Icons.science_outlined, size: 20),
                          onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const DemoControlsScreen())))),
              Expanded(
                  child: ListView(padding: AppSpace.pageInsets, children: [
                _row(Icons.lock_outline, 'Tài khoản & bảo mật',
                    onTap: () => _info(context, 'Tài khoản & bảo mật',
                        'Hồ sơ đã xác minh: ${appState.profile.name}.\n\nThông tin khách hàng chỉ dùng để xử lý đơn cứu hộ. Không chia sẻ mã xác nhận với người khác.')),
                Row(children: [
                  const Icon(Icons.notifications_none_rounded, size: 20),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Thông báo', style: appText(13))),
                  RevoSwitch(
                      value: appState.notificationsEnabled,
                      onChanged: appState.setNotifications,
                      label: 'Thông báo'),
                ]),
                _row(Icons.language_outlined, 'Ngôn ngữ',
                    value: 'Tiếng Việt · cố định',
                    onTap: () => _info(context, 'Ngôn ngữ',
                        'Bản hiện tại chỉ hỗ trợ tiếng Việt. Chưa có bộ ngôn ngữ khác.')),
                _row(Icons.location_on_outlined, 'Định vị',
                    value: appState.gpsEnabled ? 'Luôn cho phép' : 'Đang tắt',
                    onTap: () => _gps(context)),
                _row(Icons.dark_mode_outlined, 'Giao diện',
                    value: 'Sáng · cố định',
                    onTap: () => _info(context, 'Giao diện sáng',
                        'Bản hiện tại chỉ hỗ trợ giao diện sáng. Chưa hỗ trợ đổi chủ đề.')),
                const SizedBox(height: 8),
                _row(Icons.help_outline, 'Hỗ trợ',
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SupportScreen()))),
                _row(Icons.info_outline, 'Giới thiệu Revo',
                    onTap: () => showRevoAbout(context)),
              ])),
            ])),
          ));
  Widget _row(IconData icon, String label,
          {String? value, required VoidCallback onTap}) =>
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, size: 20),
        title: Text(label, style: appText(13)),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          if (value != null)
            Text(value, style: appText(11, color: AppColors.textSub)),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right_rounded,
              size: 18, color: AppColors.textSub),
        ]),
        onTap: onTap,
      );
}

void showRevoAbout(BuildContext context) => showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
          title: Text('REVO · Phiên bản 1.0.0',
              style: appText(17, weight: FontWeight.w600)),
          content: Text(
              'Kết nối · Cứu hộ · Đồng hành\n\nỨng dụng dành cho thợ sửa xe. Bản trình diễn sử dụng dữ liệu mẫu.',
              style: appText(13, color: AppColors.textSub)),
          actions: [
            TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              const TermsAndCommitmentScreen(readOnly: true)));
                },
                child: const Text('Điều khoản & Cam kết')),
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
          ],
        ));
