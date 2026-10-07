import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/rescue_order.dart';
import '../theme/activity_theme.dart';
import 'order_summary.dart';

class ActiveOrderCard extends StatelessWidget {
  const ActiveOrderCard({
    super.key,
    required this.order,
    required this.onMap,
    required this.onCall,
    required this.onChat,
    required this.onCancel,
  });
  final RescueOrder order;
  final VoidCallback onMap;
  final VoidCallback onCall;
  final VoidCallback onChat;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    const steps = [
      ('Đã gửi', 'Yêu cầu cứu hộ đã được ghi nhận.'),
      ('Thợ nhận', 'Thợ đã nhận yêu cầu của bạn.'),
      ('Đang đến', 'Thợ đang di chuyển đến vị trí cứu hộ.'),
      ('Đang sửa', 'Thợ đang kiểm tra và xử lý sự cố.'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.orderCode,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                OrderStatusBadge(status: order.status),
                const SizedBox(height: 12),
                Text(
                  '${order.serviceType.label} • ${order.userVehicle}',
                  style: const TextStyle(
                    color: ActivityTheme.mutedText,
                    height: 1.5,
                  ),
                ),
                Stepper(
                  currentStep: order.progressStep,
                  connectorColor: WidgetStateProperty.resolveWith(
                    (states) => states.contains(WidgetState.selected)
                        ? ActivityTheme.red
                        : const Color(0xFF555555),
                  ),
                  physics: const NeverScrollableScrollPhysics(),
                  margin: EdgeInsets.zero,
                  controlsBuilder: (context, details) =>
                      const SizedBox.shrink(),
                  steps: [
                    for (var index = 0; index < steps.length; index++)
                      Step(
                        title: Text(steps[index].$1),
                        content: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            steps[index].$2,
                            style: const TextStyle(
                              color: ActivityTheme.mutedText,
                            ),
                          ),
                        ),
                        isActive: index <= order.progressStep,
                        state: index < order.progressStep
                            ? StepState.complete
                            : StepState.indexed,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: ActivityTheme.background,
                      child: Icon(
                        Icons.engineering_rounded,
                        color: ActivityTheme.red,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.hasProvider
                                ? order.providerName!
                                : 'Đang tìm thợ gần bạn',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            order.providerPlate ??
                                'Thông tin thợ sẽ được cập nhật khi nhận đơn.',
                            style: const TextStyle(
                              color: ActivityTheme.mutedText,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _InfoLine(
                  icon: Icons.location_on_outlined,
                  text: order.locationAddress,
                ),
                if (order.locationLandmark.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Điểm nhận diện: ${order.locationLandmark}',
                    style: const TextStyle(color: ActivityTheme.mutedText),
                  ),
                ],
                if (order.incidentDescription.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Mô tả sự cố: ${order.incidentDescription}',
                    style: const TextStyle(color: ActivityTheme.mutedText),
                  ),
                ],
                const SizedBox(height: 12),
                _InfoLine(
                  icon: Icons.route_rounded,
                  text:
                      order.providerDistanceKm != null &&
                          order.etaMinutes != null
                      ? '${NumberFormat('0.#', 'vi').format(order.providerDistanceKm)} km • '
                            '${order.etaMinutes == 0 ? 'Sắp đến' : 'Khoảng ${order.etaMinutes} phút'}'
                      : 'Lộ trình và thời gian đến sẽ cập nhật khi có thông tin thợ.',
                ),
                const SizedBox(height: 12),
                _InfoLine(
                  icon: Icons.payments_outlined,
                  text:
                      'Chi phí dự kiến: ${formatOrderPrice(order.totalPrice)}',
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: onMap,
                      icon: const Icon(Icons.map_outlined),
                      label: const Text('Mở bản đồ'),
                    ),
                    OutlinedButton.icon(
                      onPressed: order.providerPhone?.trim().isNotEmpty == true
                          ? onCall
                          : null,
                      icon: const Icon(Icons.phone_outlined),
                      label: const Text('Gọi điện'),
                    ),
                    FilledButton.icon(
                      onPressed: order.hasProvider ? onChat : null,
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text('Chat'),
                    ),
                    OutlinedButton.icon(
                      onPressed: onCancel,
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Hủy đơn'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, color: ActivityTheme.red, size: 22),
      const SizedBox(width: 10),
      Expanded(child: Text(text, style: const TextStyle(height: 1.5))),
    ],
  );
}
