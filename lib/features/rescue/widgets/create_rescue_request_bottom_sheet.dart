import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/photo_attachment_field.dart';
import '../../activity/models/rescue_order.dart';
import '../../activity/providers/activity_provider.dart';
import '../providers/rescue_request_provider.dart';
import '../../activity/widgets/order_summary.dart';
import '../../home/providers/home_provider.dart';
import '../../home/theme/home_theme.dart';
import '../../home/widgets/home_sheets.dart';
import '../../vehicle/providers/vehicle_provider.dart';
import '../../vehicle/widgets/them_sua_xe_bottom_sheet.dart';

class CreateRescueRequestBottomSheet extends ConsumerStatefulWidget {
  const CreateRescueRequestBottomSheet({
    super.key,
    required this.serviceType,
    this.allowServiceSelection = false,
  });

  final String serviceType;
  final bool allowServiceSelection;

  @override
  ConsumerState<CreateRescueRequestBottomSheet> createState() =>
      _CreateRescueRequestBottomSheetState();
}

class _CreateRescueRequestBottomSheetState
    extends ConsumerState<CreateRescueRequestBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _description = TextEditingController();
  final _draftKey = Object();
  RescueRequestController get _controller =>
      ref.read(rescueRequestProvider((_draftKey, widget.serviceType)).notifier);

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final order = _controller.submit(_description.text);
    if (order != null) Navigator.pop(context, order);
  }

  @override
  Widget build(BuildContext context) {
    final location = ref.watch(rescueLocationProvider);
    final vehicle = ref.watch(defaultVehicleProvider);
    final vehicles = ref.watch(vehicleProvider);
    final hasActiveOrder = ref.watch(activityProvider).activeOrders.isNotEmpty;
    final draft = ref.watch(
      rescueRequestProvider((_draftKey, widget.serviceType)),
    );
    final configuration = draft.configuration;
    final options = configuration.options;
    final canSubmit = ref.watch(
      rescueRequestReadyProvider((_draftKey, widget.serviceType)),
    );
    return Theme(
      data: HomeTheme.red,
      child: Form(
        key: _formKey,
        child: HomeSheetContent(
          title: widget.allowServiceSelection
              ? 'Chi tiết sự cố cứu hộ'
              : draft.serviceName,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: HomeColors.redSelected,
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
                        if (location?.hasCoordinates == true) ...[
                          const SizedBox(height: 6),
                          Text(
                            'GPS: ${location!.latitude!.toStringAsFixed(6)}, '
                            '${location.longitude!.toStringAsFixed(6)}',
                            style: const TextStyle(
                              color: HomeColors.secondary,
                              fontSize: 12,
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
                    color: HomeColors.red,
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
            DropdownButtonFormField<String>(
              key: const ValueKey('rescue-request-vehicle-type'),
              initialValue: draft.vehicleType,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Loại xe'),
              items: [
                for (final type in rescueVehicleTypes)
                  DropdownMenuItem(value: type, child: Text(type)),
              ],
              onChanged: (type) {
                if (type != null) _controller.selectVehicleType(type);
              },
            ),
            const SizedBox(height: 16),
            if (widget.allowServiceSelection) ...[
              DropdownButtonFormField<RescueServiceType>(
                key: const ValueKey('incident-request-service'),
                initialValue: configuration.type,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Sự cố cần hỗ trợ',
                  prefixIcon: Icon(Icons.build_outlined, color: HomeColors.red),
                ),
                items: [
                  for (final service in incidentServiceTypes)
                    DropdownMenuItem(
                      value: service,
                      child: Text(service.label),
                    ),
                ],
                onChanged: (service) {
                  if (service != null) {
                    _controller.selectService(service.label);
                  }
                },
              ),
              const SizedBox(height: 16),
            ],
            const Text(
              'Tùy chọn dịch vụ',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < options.length; i++)
                  ChoiceChip(
                    key: ValueKey('rescue-request-option-$i'),
                    label: Text(options[i].label),
                    selected: draft.selectedOption == i,
                    selectedColor: HomeColors.redSelected,
                    checkmarkColor: HomeColors.red,
                    onSelected: (selected) {
                      if (selected) _controller.selectOption(i);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 20),
            PhotoAttachmentField(
              label: 'Chụp ảnh hiện trường khẩn cấp',
              useCamera: true,
              onChanged: _controller.attachPhoto,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Flexible(
                  child: Text(
                    'Tổng tiền',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
                Flexible(
                  child: Text(
                    formatOrderPrice(options[draft.selectedOption].price),
                    key: const ValueKey('rescue-request-total'),
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      color: HomeColors.red,
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                    ),
                  ),
                ),
              ],
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
            if (hasActiveOrder || draft.error != null) ...[
              const SizedBox(height: 12),
              Text(
                draft.error ??
                    'Bạn đang có đơn cứu hộ. Hãy kiểm tra trong Hoạt động.',
                style: const TextStyle(color: HomeColors.red),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              key: const ValueKey('incident-request-submit'),
              onPressed: canSubmit ? _submit : null,
              style: FilledButton.styleFrom(
                backgroundColor: HomeColors.red,
                foregroundColor: Colors.white,
                disabledBackgroundColor: HomeColors.redSelected,
              ),
              icon: const Icon(Icons.sos_rounded),
              label: const Text(
                'TÌM THỢ CỨU HỘ NGAY',
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
