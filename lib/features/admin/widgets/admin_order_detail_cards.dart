import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/admin_tokens.dart';
import '../models/admin_models.dart';
import '../models/admin_order_progress.dart';
import '../theme/admin_order_theme.dart';
import 'admin_common.dart';
import 'admin_order_common.dart';

class AdminOrderProgressCard extends StatelessWidget {
  const AdminOrderProgressCard({
    super.key,
    required this.order,
    required this.steps,
  });
  final AdminOrder order;
  final List<AdminOrderProgressStep> steps;

  @override
  Widget build(BuildContext context) => AdminOrderSurface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminOrderIdentity(order: order),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < steps.length; i++)
              Expanded(
                child: Semantics(
                  label:
                      '${steps[i].milestone.label}: ${steps[i].at == null ? 'Chưa ghi nhận' : adminDate(steps[i].at!)}',
                  child: ExcludeSemantics(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _ProgressLine(
                                visible: i > 0,
                                reached:
                                    i > 0 &&
                                    steps[i - 1].reached &&
                                    steps[i].reached,
                              ),
                            ),
                            Icon(
                              steps[i].reached
                                  ? Icons.check_circle_rounded
                                  : Icons.circle,
                              key: ValueKey(
                                'admin-order-step-${steps[i].milestone.name}-${steps[i].reached}',
                              ),
                              color: steps[i].reached
                                  ? AdminTokens.text
                                  : const Color(0xFFDDE0E4),
                              size: 26,
                            ),
                            Expanded(
                              child: _ProgressLine(
                                visible: i < steps.length - 1,
                                reached:
                                    i < steps.length - 1 &&
                                    steps[i].reached &&
                                    steps[i + 1].reached,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          steps[i].milestone.label,
                          textAlign: TextAlign.center,
                          style: AdminOrderTheme.value.copyWith(fontSize: 10),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          steps[i].at == null
                              ? '—'
                              : DateFormat('HH:mm').format(steps[i].at!),
                          style: AdminOrderTheme.label.copyWith(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (order.warning case final warning?) ...[
          const SizedBox(height: 16),
          Text(
            'Cảnh báo: $warning',
            style: AdminOrderTheme.label.copyWith(
              color: AdminTokens.primaryRed,
            ),
          ),
        ],
      ],
    ),
  );
}

class _ProgressLine extends StatelessWidget {
  const _ProgressLine({required this.visible, required this.reached});
  final bool visible;
  final bool reached;
  @override
  Widget build(BuildContext context) => Container(
    height: 2,
    color: !visible
        ? Colors.transparent
        : reached
        ? AdminTokens.text
        : const Color(0xFFDDE0E4),
  );
}

class AdminOrderInformationCard extends StatelessWidget {
  const AdminOrderInformationCard({super.key, required this.order});
  final AdminOrder order;
  @override
  Widget build(BuildContext context) => AdminOrderSurface(
    color: AdminTokens.card,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Thông tin chi tiết', style: AdminOrderTheme.title),
        const SizedBox(height: 12),
        _InformationRow('Khách hàng', order.customer),
        _InformationRow('Địa chỉ cứu hộ', order.address),
        _InformationRow(
          'Số điện thoại',
          order.customerPhone ?? 'Chưa cập nhật',
        ),
        _InformationRow('Loại sự cố', order.incident),
        _InformationRow(
          'Giá dịch vụ',
          '${adminMoney(order.finalPrice ?? order.estimatedPrice)}\n'
              '(${order.finalPrice == null ? 'Tạm tính · ' : ''}${order.payment.label})',
        ),
      ],
    ),
  );
}

class _InformationRow extends StatelessWidget {
  const _InformationRow(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 4, child: Text(label, style: AdminOrderTheme.label)),
        const SizedBox(width: 16),
        Expanded(
          flex: 6,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: AdminOrderTheme.value,
          ),
        ),
      ],
    ),
  );
}

class AdminOrderMechanicCard extends StatelessWidget {
  const AdminOrderMechanicCard({
    super.key,
    required this.order,
    this.onChat,
    this.onCall,
  });
  final AdminOrder order;
  final VoidCallback? onChat;
  final VoidCallback? onCall;
  @override
  Widget build(BuildContext context) => AdminOrderSurface(
    color: AdminTokens.card,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Thông tin Thợ cứu hộ', style: AdminOrderTheme.title),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final identity = Row(
              children: [
                const CircleAvatar(
                  radius: 22,
                  backgroundColor: AdminTokens.inactivePill,
                  child: Icon(
                    Icons.person_outline_rounded,
                    color: AdminTokens.text,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.provider ?? 'Chưa phân công',
                        style: AdminOrderTheme.value.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.providerPhone ?? 'Chưa có số điện thoại',
                        style: AdminOrderTheme.label,
                      ),
                    ],
                  ),
                ),
              ],
            );
            final actions = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ContactButton(
                  key: const ValueKey('admin-order-chat'),
                  icon: Icons.chat_bubble_outline_rounded,
                  tooltip: 'Tin nhắn đơn hàng',
                  onPressed: onChat,
                ),
                const SizedBox(width: 8),
                _ContactButton(
                  key: const ValueKey('admin-order-call'),
                  icon: Icons.phone_outlined,
                  tooltip: onCall == null
                      ? 'Chưa có số điện thoại thợ'
                      : 'Gọi thợ cứu hộ',
                  onPressed: onCall,
                ),
              ],
            );
            if (constraints.maxWidth < 300 ||
                MediaQuery.textScalerOf(context).scale(1) > 1.2) {
              return Column(
                children: [
                  identity,
                  const SizedBox(height: 12),
                  Align(alignment: Alignment.centerRight, child: actions),
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: identity),
                const SizedBox(width: 12),
                actions,
              ],
            );
          },
        ),
      ],
    ),
  );
}

class _ContactButton extends StatelessWidget {
  const _ContactButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onPressed,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => IconButton.filled(
    tooltip: tooltip,
    onPressed: onPressed,
    icon: Icon(icon, size: 20),
    style: IconButton.styleFrom(
      backgroundColor: AdminTokens.text,
      foregroundColor: Colors.white,
      disabledBackgroundColor: AdminTokens.inactivePill,
      disabledForegroundColor: AdminTokens.muted,
      minimumSize: const Size(44, 44),
      shape: const CircleBorder(),
    ),
  );
}

class AdminOrderHistoryCard extends StatelessWidget {
  const AdminOrderHistoryCard({super.key, required this.events});
  final List<AdminTimelineEvent> events;
  @override
  Widget build(BuildContext context) => AdminOrderSurface(
    color: AdminTokens.card,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Lịch sử trạng thái', style: AdminOrderTheme.title),
        const SizedBox(height: 20),
        if (events.isEmpty) const AdminStateView.empty(),
        for (var i = 0; i < events.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 78,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('HH:mm').format(events[i].at),
                        style: AdminOrderTheme.value.copyWith(fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd/MM/yyyy').format(events[i].at),
                        style: AdminOrderTheme.label.copyWith(fontSize: 10),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AdminTokens.text,
                      size: 22,
                    ),
                    if (i < events.length - 1)
                      Expanded(
                        child: Container(
                          width: 1.5,
                          color: const Color(0xFFDDE0E4),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: i == events.length - 1 ? 0 : 24,
                    ),
                    child: Text(
                      events[i].label,
                      style: AdminOrderTheme.value.copyWith(fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}
