import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/service_scaffold.dart';
import '../../auth/application/session_controller.dart';
import '../../auth/application/session_state.dart';
import '../../home/models/home_destination.dart';
import '../models/vehicle.dart';
import '../providers/vehicle_provider.dart';
import '../widgets/them_sua_xe_bottom_sheet.dart';
import '../widgets/vehicle_card.dart';

class XeCuaToiScreen extends ConsumerStatefulWidget {
  const XeCuaToiScreen({super.key});

  @override
  ConsumerState<XeCuaToiScreen> createState() => _XeCuaToiScreenState();
}

class _XeCuaToiScreenState extends ConsumerState<XeCuaToiScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final session = ref.read(sessionControllerProvider);
      if (session is! SessionSignedIn) return;
      try {
        await ref
            .read(vehicleProvider.notifier)
            .refreshFromApi(session.session.user.id.toString());
      } on Exception {
        if (mounted) {
          showServiceMessage(context, 'Chưa tải được danh sách xe từ máy chủ.');
        }
      }
    });
  }

  Future<void> _edit(BuildContext context, {Vehicle? vehicle}) async {
    final saved = await showThemSuaXeBottomSheet(context, vehicle: vehicle);
    if (context.mounted && saved != null) {
      showServiceMessage(
        context,
        vehicle == null ? 'Đã thêm xe của bạn.' : 'Đã cập nhật thông tin xe.',
      );
    }
  }

  Future<void> _action(
    BuildContext context,
    WidgetRef ref,
    Vehicle vehicle,
    VehicleAction action,
  ) async {
    switch (action) {
      case VehicleAction.setDefault:
        bool saved;
        try {
          saved = await ref
              .read(vehicleProvider.notifier)
              .setDefaultPersisted(vehicle.id);
        } on Exception {
          if (context.mounted) {
            showServiceMessage(
              context,
              'Chưa đổi được xe mặc định trên máy chủ.',
            );
          }
          return;
        }
        if (!context.mounted) return;
        showServiceMessage(
          context,
          saved
              ? 'Đã đặt ${vehicle.name} làm xe mặc định cứu hộ.'
              : 'Xe không còn trong danh sách.',
        );
      case VehicleAction.edit:
        await _edit(context, vehicle: vehicle);
      case VehicleAction.delete:
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Xóa xe này?'),
            content: Text(
              'Bạn muốn xóa ${vehicle.name} (${vehicle.licensePlate}) khỏi danh sách xe cứu hộ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Giữ lại'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Xóa xe'),
              ),
            ],
          ),
        );
        if (!context.mounted || confirmed != true) return;
        bool deleted;
        try {
          deleted = await ref
              .read(vehicleProvider.notifier)
              .deletePersisted(vehicle.id);
        } on Exception {
          if (context.mounted) {
            showServiceMessage(context, 'Chưa xóa được xe trên máy chủ.');
          }
          return;
        }
        if (!context.mounted) return;
        showServiceMessage(
          context,
          deleted
              ? 'Đã xóa xe khỏi danh sách.'
              : 'Xe không còn trong danh sách.',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehicles = ref.watch(vehicleProvider);
    return ServiceScaffold(
      title: 'Danh sách xe cứu hộ',
      selectedDestination: HomeDestination.account,
      actions: [
        IconButton(
          tooltip: 'Thêm xe mới',
          onPressed: () => _edit(context),
          icon: const Icon(Icons.add_rounded),
        ),
      ],
      body: Builder(
        builder: (context) => vehicles.isEmpty
            ? Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.two_wheeler_outlined,
                        size: 76,
                        color: ServiceColors.orange,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Bạn chưa thêm xe nào. Thêm xe ngay để cứu hộ nhanh hơn.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, height: 1.5),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: () => _edit(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Thêm xe mới'),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: vehicles.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: VehicleCard(
                    key: ValueKey(vehicles[index].id),
                    vehicle: vehicles[index],
                    onAction: (action) =>
                        _action(context, ref, vehicles[index], action),
                  ),
                ),
              ),
      ),
    );
  }
}
