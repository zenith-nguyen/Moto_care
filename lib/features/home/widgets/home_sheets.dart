import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../activity/data/mock_rescue_orders.dart';
import '../../activity/providers/activity_provider.dart';
import '../../activity/widgets/order_summary.dart';
import '../../vehicle/providers/vehicle_provider.dart';
import '../providers/home_provider.dart';
import '../theme/home_theme.dart';
import 'home_service_grid.dart';

Future<T?> showHomeSheet<T>(BuildContext context, Widget child) =>
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: HomeColors.surface,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      builder: (context) => Theme(data: HomeTheme.light, child: child),
    );

class HomeSheetContent extends StatelessWidget {
  const HomeSheetContent({
    super.key,
    required this.title,
    required this.children,
  });
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: SingleChildScrollView(
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Đóng',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...children,
            ],
          ),
        ),
      ),
    ),
  );
}

class HomeVehicleSheet extends ConsumerWidget {
  const HomeVehicleSheet({super.key});
  static const manageVehicles = 'manage-vehicles';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicles = ref.watch(vehicleProvider);
    return HomeSheetContent(
      title: 'Chọn xe khẩn cấp',
      children: [
        if (vehicles.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 20),
            child: Text(
              'Bạn chưa có xe. Thêm xe để tạo yêu cầu cứu hộ.',
              style: TextStyle(color: HomeColors.secondary),
            ),
          ),
        for (final vehicle in vehicles)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(
              Icons.two_wheeler_rounded,
              color: HomeColors.primary,
            ),
            title: Text(
              vehicle.name,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(vehicle.licensePlate),
            trailing: Icon(
              vehicle.isDefault
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: vehicle.isDefault
                  ? HomeColors.primary
                  : HomeColors.secondary,
            ),
            onTap: () => Navigator.pop(context, vehicle.id),
          ),
        const SizedBox(height: 12),
        const Text(
          'Xe đã chọn sẽ được dùng làm xe mặc định.',
          style: TextStyle(color: HomeColors.secondary, fontSize: 12),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => Navigator.pop(context, manageVehicles),
          icon: const Icon(Icons.add_rounded),
          label: Text(vehicles.isEmpty ? 'Thêm xe của tôi' : 'Quản lý xe'),
        ),
      ],
    );
  }
}

class HomeRescueConfirmationSheet extends ConsumerStatefulWidget {
  const HomeRescueConfirmationSheet({super.key, required this.service});
  final HomeService service;

  @override
  ConsumerState<HomeRescueConfirmationSheet> createState() =>
      _HomeRescueConfirmationSheetState();
}

class _HomeRescueConfirmationSheetState
    extends ConsumerState<HomeRescueConfirmationSheet> {
  String? _error;
  bool _submitted = false;

  void _confirm() {
    if (_submitted) return;
    final vehicle = ref.read(defaultVehicleProvider);
    final location = ref.read(rescueLocationProvider);
    if (vehicle == null ||
        location == null ||
        location.address.trim().isEmpty) {
      return;
    }
    try {
      final order = ref
          .read(activityProvider.notifier)
          .createOrder(
            serviceType: widget.service.orderType!,
            userVehicle: '${vehicle.name} (${vehicle.licensePlate})',
            locationAddress: location.address,
            locationLandmark: location.landmark,
            locationLatitude: location.latitude,
            locationLongitude: location.longitude,
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
    final vehicle = ref.watch(defaultVehicleProvider);
    final location = ref.watch(rescueLocationProvider);
    final hasActiveOrder = ref.watch(activityProvider).activeOrders.isNotEmpty;
    final canSubmit =
        vehicle != null &&
        location != null &&
        location.address.trim().isNotEmpty &&
        !hasActiveOrder &&
        !_submitted;
    return HomeSheetContent(
      title: widget.service == HomeService.maintenance
          ? 'Xác nhận yêu cầu bảo dưỡng'
          : 'Xác nhận cứu hộ khẩn cấp',
      children: [
        Row(
          children: [
            Icon(widget.service.icon, size: 32, color: widget.service.color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.service.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _ConfirmationInfo(
          icon: Icons.two_wheeler_rounded,
          title: 'Xe cứu hộ',
          value: vehicle == null
              ? 'Chưa chọn xe'
              : '${vehicle.name} (${vehicle.licensePlate})',
        ),
        const Divider(height: 24),
        _ConfirmationInfo(
          icon: Icons.location_on_rounded,
          title: 'Vị trí sự cố',
          value: location?.address ?? 'Chưa chọn vị trí',
        ),
        if (location?.landmark.isNotEmpty == true) ...[
          const SizedBox(height: 8),
          Text(
            location!.landmark,
            style: const TextStyle(color: HomeColors.secondary, height: 1.5),
          ),
        ],
        if (location?.hasCoordinates == true) ...[
          const SizedBox(height: 8),
          Text(
            'GPS: ${location!.latitude!.toStringAsFixed(6)}, ${location.longitude!.toStringAsFixed(6)}',
            style: const TextStyle(color: HomeColors.secondary, fontSize: 12),
          ),
        ],
        const SizedBox(height: 20),
        Text(
          'Chi phí tham khảo: ${formatOrderPrice(mockBasePrice(widget.service.orderType!))}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        const Text(
          'Đây là yêu cầu thử nghiệm, chỉ lưu trong phiên. Chưa điều phối thợ hoặc thu phí. Giá thực tế cần được xác nhận với trạm cứu hộ.',
          style: TextStyle(
            color: HomeColors.secondary,
            fontSize: 12,
            height: 1.5,
          ),
        ),
        if (hasActiveOrder || _error != null) ...[
          const SizedBox(height: 16),
          Text(
            _error ?? 'Bạn đang có đơn cứu hộ. Hãy kiểm tra trong Hoạt động trước khi tạo đơn mới.',
            style: const TextStyle(color: HomeColors.primary),
          ),
        ],
        if (vehicle == null || location == null) ...[
          const SizedBox(height: 16),
          const Text(
            'Vui lòng chọn xe và vị trí ở Trang chủ trước khi xác nhận.',
            style: TextStyle(color: HomeColors.primary),
          ),
        ],
        const SizedBox(height: 24),
        FilledButton(
          onPressed: canSubmit ? _confirm : null,
          child: const Text('Xác nhận tạo yêu cầu'),
        ),
      ],
    );
  }
}

class _ConfirmationInfo extends StatelessWidget {
  const _ConfirmationInfo({
    required this.icon,
    required this.title,
    required this.value,
  });
  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, color: HomeColors.primary),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(color: HomeColors.secondary, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, height: 1.5),
            ),
          ],
        ),
      ),
    ],
  );
}
