import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../theme/rank_theme.dart';
import '../theme/app_theme.dart';
import '../widgets/app_status.dart';
import '../widgets/ui.dart';

/// Điều khiển mô phỏng phục vụ kiểm thử; không thay quyền hoặc mạng hệ điều hành.
class DemoControlsScreen extends StatelessWidget {
  const DemoControlsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
            child: Column(children: [
          const ScreenHeader(title: 'Chế độ demo'),
          Expanded(
              child: ListenableBuilder(
                  listenable: appState,
                  builder: (context, _) =>
                      ListView(padding: AppSpace.pageInsets, children: [
                        Text(
                            'Dữ liệu mô phỏng trong bộ nhớ. Các tùy chọn dưới đây không thay đổi mạng hoặc quyền của điện thoại.',
                            style: appText(12, color: AppColors.textSub)),
                        const SizedBox(height: 16),
                        SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            title: Text('Kết nối mạng mô phỏng',
                                style: appText(13, weight: FontWeight.w600)),
                            subtitle: Text(
                                appState.networkAvailable
                                    ? 'Đang có mạng'
                                    : 'Mất mạng · đơn hiện tại được giữ lại',
                                style: appText(11)),
                            value: appState.networkAvailable,
                            onChanged: appState.setNetworkAvailable),
                        SwitchListTile.adaptive(
                            key: const ValueKey('demo-showcase-orders'),
                            contentPadding: EdgeInsets.zero,
                            title: Text('Đơn hàng trình diễn',
                                style: appText(13, weight: FontWeight.w600)),
                            subtitle: Text(
                                'Tab Đơn hàng hiển thị 5 đơn mẫu khác dịch vụ. Không thay đổi lịch sử, Ví hay đơn đang làm.',
                                style: appText(11)),
                            value: appState.showcaseOrdersEnabled,
                            onChanged: appState.setShowcaseOrders),
                        const Divider(height: 24),
                        const _RankDemoSection(),
                        const Divider(height: 24),
                        Text('Xem các trạng thái giao diện',
                            style: appText(14, weight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        for (final kind in AppStatusKind.values)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: AppStatusView(
                                kind: kind,
                                compact: true,
                                onAction: () => showModalBottomSheet<void>(
                                    context: context,
                                    builder: (ctx) => SafeArea(
                                        child: Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                                16, 0, 16, 20),
                                            child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                      'Xem trước trạng thái · Demo',
                                                      style: appText(12,
                                                          color: AppColors
                                                              .textSub)),
                                                  const SizedBox(height: 12),
                                                  AppStatusView(
                                                      kind: kind,
                                                      compact: true),
                                                  const SizedBox(height: 16),
                                                  PrimaryButton(
                                                      label: 'Đóng',
                                                      onPressed: () =>
                                                          Navigator.pop(ctx)),
                                                ]))))),
                          ),
                      ]))),
        ])),
      );
}

/// "Trình diễn hạng thợ": picks a simulated rank for the weekly banner. It is
/// UI-only and never touches the real profile, orders or wallet.
class _RankDemoSection extends StatelessWidget {
  const _RankDemoSection();
  @override
  Widget build(BuildContext context) => ListenableBuilder(
      listenable: rankPreview,
      builder: (context, _) {
        final current = rankPreview.state?.tierName;
        Widget chip(String label, RankPreviewState state) => ChoiceChip(
            key: ValueKey('demo-rank-$label'),
            label: Text(label, style: appText(12)),
            selected: current == label,
            onSelected: (_) => rankPreview.show(state));
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Trình diễn hạng thợ',
              style: appText(13, weight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
              'Xem thử khung Hạng Thợ trong Tổng kết tuần. Chỉ là mô phỏng giao diện, không đổi hạng thật.',
              style: appText(11)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 4, children: [
            chip('Đồng', rankPreviewBronze),
            chip('Bạc', rankPreviewSilver),
            chip('Vàng', rankPreviewGold),
          ]),
          const SizedBox(height: 6),
          Wrap(spacing: 8, children: [
            TextButton(
                key: const ValueKey('demo-rank-run'),
                onPressed: rankPreview.runDemo,
                child: const Text('Chạy demo chuyển hạng')),
            TextButton(
                key: const ValueKey('demo-rank-end'),
                onPressed: rankPreview.state == null ? null : rankPreview.clear,
                child: const Text('Kết thúc xem trước')),
          ]),
        ]);
      });
}
