import 'package:flutter/material.dart';

import '../models/order_details.dart';
import '../theme/order_details_theme.dart';

class RescueDetailsCard extends StatelessWidget {
  const RescueDetailsCard({super.key, required this.details});
  final OrderDetails details;

  @override
  Widget build(BuildContext context) {
    final order = details.order;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: OrderDetailsTheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.assignment_outlined,
                size: 19,
                color: OrderDetailsTheme.muted,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Thông tin cứu hộ',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _DetailLine(
                  label: 'Người yêu cầu',
                  value: '${details.requesterName}\n${details.requesterPhone}',
                ),
                const Divider(height: 1, color: OrderDetailsTheme.surface),
                _DetailLine(
                  label: 'Vị trí sự cố',
                  value: order.locationAddress,
                ),
                if (order.locationLandmark.isNotEmpty)
                  _DetailLine(
                    label: 'Điểm nhận diện',
                    value: order.locationLandmark,
                  ),
                const Divider(height: 1, color: OrderDetailsTheme.surface),
                _DetailLine(
                  label: 'Dịch vụ / Xe',
                  value: '${order.userVehicle}\n${order.serviceType.label}',
                ),
                if (order.serviceOption.isNotEmpty)
                  _DetailLine(label: 'Gói dịch vụ', value: order.serviceOption),
                const Divider(height: 1, color: OrderDetailsTheme.surface),
                _DetailLine(
                  label: 'Ghi chú',
                  value: order.incidentDescription.trim().isEmpty
                      ? 'Không có ghi chú'
                      : order.incidentDescription.trim(),
                  warning: order.incidentDescription.trim().isNotEmpty,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({
    required this.label,
    required this.value,
    this.warning = false,
  });
  final String label;
  final String value;
  final bool warning;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final stacked =
          constraints.maxWidth < 270 ||
          MediaQuery.textScalerOf(context).scale(12) > 16;
      final labelWidget = Text(
        label,
        style: const TextStyle(fontSize: 11, color: OrderDetailsTheme.muted),
      );
      final valueWidget = warning
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: OrderDetailsTheme.redTint,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 15,
                    color: OrderDetailsTheme.red,
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontSize: 11,
                        height: 1.5,
                        color: OrderDetailsTheme.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                height: 1.6,
                fontWeight: FontWeight.w500,
              ),
            );
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: stacked
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [labelWidget, const SizedBox(height: 5), valueWidget],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 100, child: labelWidget),
                  const SizedBox(width: 8),
                  Expanded(child: valueWidget),
                ],
              ),
      );
    },
  );
}
