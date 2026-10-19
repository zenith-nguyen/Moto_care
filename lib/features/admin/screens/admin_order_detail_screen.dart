import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/service_actions.dart';
import '../../../core/theme/admin_tokens.dart';
import '../models/admin_models.dart';
import '../providers/admin_providers.dart';
import '../services/admin_order_details_service.dart';
import '../theme/admin_order_theme.dart';
import '../widgets/admin_common.dart';
import '../widgets/admin_order_detail_cards.dart';
import '../widgets/admin_order_support_sections.dart';
import '../widgets/admin_page_header.dart';

class AdminOrderDetailScreen extends ConsumerWidget {
  const AdminOrderDetailScreen({super.key, required this.orderId});
  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => AdminPage(
    title: 'Chi tiết đơn $orderId',
    header: AdminPageHeader(
      title: 'Chi tiết đơn',
      fontSize: 16,
      fontWeight: FontWeight.w600,
      centerTitle: true,
      onBack: () => context.go('/admin/orders'),
    ),
    children: [
      AdminAsyncSection<AdminOrder?>(
        value: ref.watch(adminOrderDetailProvider(orderId)),
        onRetry: () => ref.invalidate(adminOrdersProvider),
        isEmpty: (order) => order == null,
        builder: (value) => _OrderDetails(order: value!),
      ),
    ],
  );
}

class _OrderDetails extends ConsumerWidget {
  const _OrderDetails({required this.order});
  final AdminOrder order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const service = AdminOrderDetailsService();
    final telephone = service.mechanicTelephone(order);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminOrderProgressCard(order: order, steps: service.progress(order)),
        const SizedBox(height: 16),
        AdminOrderInformationCard(order: order),
        const SizedBox(height: 16),
        AdminOrderMechanicCard(
          order: order,
          onChat: order.provider == null ? null : () => _openChat(context),
          onCall: telephone == null
              ? null
              : () => launchServiceUri(
                  context,
                  ref,
                  telephone,
                  'Không thể mở ứng dụng gọi điện. Vui lòng thử lại.',
                ),
        ),
        const SizedBox(height: 16),
        AdminOrderHistoryCard(events: service.history(order)),
        const SizedBox(height: 16),
        AdminOrderSupportSections(order: order),
      ],
    );
  }

  void _openChat(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AdminTokens.surface,
    showDragHandle: true,
    builder: (context) => SafeArea(
      top: false,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .65,
        child: Consumer(
          builder: (context, ref, _) {
            if (ref.watch(adminSessionProvider)?.isAdmin != true) {
              return const AdminStateView.forbidden();
            }
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Chat history • Chỉ xem',
                          style: AdminOrderTheme.title,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Đóng lịch sử trao đổi',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: AdminOrderChatLog(order: order),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ),
  );
}
