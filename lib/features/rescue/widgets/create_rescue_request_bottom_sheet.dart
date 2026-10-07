import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../activity/data/mock_rescue_orders.dart';
import '../../activity/models/rescue_order.dart';
import '../../activity/providers/activity_provider.dart';
import '../../activity/widgets/order_summary.dart';
import '../../home/providers/home_provider.dart';
import '../../home/theme/home_theme.dart';
import '../../home/widgets/home_sheets.dart';
import '../../vehicle/providers/vehicle_provider.dart';
import '../../vehicle/widgets/them_sua_xe_bottom_sheet.dart';

class CreateRescueRequestBottomSheet extends ConsumerStatefulWidget {
  const CreateRescueRequestBottomSheet({super.key});

  @override
  ConsumerState<CreateRescueRequestBottomSheet> createState() =>
      _CreateRescueRequestBottomSheetState();
}

class _CreateRescueRequestBottomSheetState
    extends ConsumerState<CreateRescueRequestBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _description = TextEditingController();
  RescueServiceType _service = RescueServiceType.engineFailure;
  String? _error;
  bool _submitted = false;

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  void _submit() {
    if (_submitted || !_formKey.currentState!.validate()) return;
    final location = ref.read(rescueLocationProvider);
    final vehicle = ref.read(defaultVehicleProvider);
    if (location == null || vehicle == null) return;
    try {
      final order = ref
          .read(activityProvider.notifier)
          .createOrder(
            serviceType: _service,
            userVehicle: '${vehicle.name} (${vehicle.licensePlate})',
            locationAddress: location.address,
            locationLandmark: location.landmark,
            locationLatitude: location.latitude,
            locationLongitude: location.longitude,
            incidentDescription: _description.text,
          );
      _submitted = true;
      Navigator.pop(context, order);
    } on StateError {
      setState(
        () => _error = 'Bạn đang có đơn cứu hộ. Hãy kiểm tra trong Hoạt động.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = ref.watch(rescueLocationProvider);
    final vehicle = ref.watch(defaultVehicleProvider);
    final vehicles = ref.watch(vehicleProvider);
    final hasActiveOrder = ref.watch(activityProvider).activeOrders.isNotEmpty;
    final canSubmit =
        location != null && vehicle != null && !hasActiveOrder && !_submitted;
    return Form(
      key: _formKey,
      child: HomeSheetContent(
        title: 'Chi tiết sự cố cứu hộ',
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: HomeColors.selected,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_rounded, color: HomeColors.red),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Vị trí đã xác nhận',
                        style: TextStyle(
                          color: HomeColors.secondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        location?.address ?? 'Chưa chọn vị trí',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          height: 1.5,
                        ),
                      ),
                      if (location?.landmark.isNotEmpty == true) ...[
                        const SizedBox(height: 6),
                        Text(
                          location!.landmark,
                          style: const TextStyle(
                            color: HomeColors.secondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (vehicles.isNotEmpty)
            DropdownButtonFormField<String>(
              key: ValueKey('incident-request-vehicle-${vehicle?.id}'),
              initialValue: vehicle?.id,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Xe cần cứu hộ',
                prefixIcon: Icon(
                  Icons.two_wheeler_rounded,
                  color: HomeColors.primary,
                ),
              ),
              items: [
                for (final item in vehicles)
                  DropdownMenuItem(
                    value: item.id,
                    child: Text(
                      '${item.name} (${item.licensePlate})',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (id) {
                if (id != null) {
                  ref.read(vehicleProvider.notifier).setDefault(id);
                }
              },
            )
          else ...[
            const Text(
              'Thêm xe của bạn để gửi yêu cầu cứu hộ.',
              style: TextStyle(color: HomeColors.secondary),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => showThemSuaXeBottomSheet(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Thêm xe cần cứu hộ'),
            ),
          ],
          const SizedBox(height: 16),
          DropdownButtonFormField<RescueServiceType>(
            key: const ValueKey('incident-request-service'),
            initialValue: _service,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Sự cố cần hỗ trợ',
              prefixIcon: Icon(Icons.build_outlined, color: HomeColors.primary),
            ),
            items: [
              for (final service in RescueServiceType.values.where(
                (service) =>
                    service != RescueServiceType.maintenance &&
                    service != RescueServiceType.charging,
              ))
                DropdownMenuItem(value: service, child: Text(service.label)),
            ],
            onChanged: (service) {
              if (service != null) setState(() => _service = service);
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const ValueKey('incident-request-description'),
            controller: _description,
            minLines: 2,
            maxLines: 4,
            maxLength: 500,
            decoration: const InputDecoration(
              labelText: 'Mô tả sự cố (không bắt buộc)',
              hintText: 'VD: Xe không đề được, có tiếng kêu lạ...',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Chi phí tham khảo: ${formatOrderPrice(mockBasePrice(_service))}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'Yêu cầu thử nghiệm, chỉ lưu trong phiên. Chưa điều phối thợ hoặc thu phí.',
            style: TextStyle(
              color: HomeColors.secondary,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          if (hasActiveOrder || _error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error ?? 'Bạn đang có đơn cứu hộ. Hãy kiểm tra trong Hoạt động.',
              style: const TextStyle(color: HomeColors.red),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            key: const ValueKey('incident-request-submit'),
            onPressed: canSubmit ? _submit : null,
            icon: const Icon(Icons.sos_rounded),
            label: const Text('GỬI YÊU CẦU CỨU HỘ'),
          ),
        ],
      ),
    );
  }
}
