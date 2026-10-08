import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/service_scaffold.dart';
import '../models/vehicle.dart';
import '../models/vehicle_validation.dart';
import '../providers/vehicle_provider.dart';

Future<Vehicle?> showThemSuaXeBottomSheet(
  BuildContext context, {
  Vehicle? vehicle,
}) => showModalBottomSheet<Vehicle>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  backgroundColor: ServiceColors.surface,
  builder: (context) => Theme(
    data: Theme.of(context).copyWith(
      colorScheme: Theme.of(context).colorScheme.copyWith(
        primary: ServiceColors.orange,
        secondaryContainer: ServiceColors.navy,
        onSecondaryContainer: ServiceColors.text,
      ),
    ),
    child: ThemSuaXeBottomSheet(vehicle: vehicle),
  ),
);

class ThemSuaXeBottomSheet extends ConsumerStatefulWidget {
  const ThemSuaXeBottomSheet({super.key, this.vehicle});
  final Vehicle? vehicle;

  @override
  ConsumerState<ThemSuaXeBottomSheet> createState() =>
      _ThemSuaXeBottomSheetState();
}

class _ThemSuaXeBottomSheetState extends ConsumerState<ThemSuaXeBottomSheet> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.vehicle?.name ?? '');
  late final _plate = TextEditingController(
    text: widget.vehicle?.licensePlate ?? '',
  );
  late final _color = TextEditingController(text: widget.vehicle?.color ?? '');
  late String? _brand = widget.vehicle?.brand;
  late TireType _tire = widget.vehicle?.tireType ?? TireType.tubed;
  late EngineType _engine = widget.vehicle?.engineType ?? EngineType.gas;
  bool _saved = false;

  @override
  void dispose() {
    _name.dispose();
    _plate.dispose();
    _color.dispose();
    super.dispose();
  }

  void _save() {
    if (_saved || !_form.currentState!.validate()) return;
    try {
      final vehicle = ref
          .read(vehicleProvider.notifier)
          .save(
            id: widget.vehicle?.id,
            name: _name.text,
            brand: _brand!,
            licensePlate: _plate.text,
            tireType: _tire,
            engineType: _engine,
            color: _color.text,
          );
      _saved = true;
      FocusScope.of(context).unfocus();
      Navigator.of(context).pop(vehicle);
    } on VehicleSaveException catch (error) {
      showServiceMessage(context, error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final brands = <String>{...ref.watch(vehicleBrandsProvider), ?_brand};
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Form(
              key: _form,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.vehicle == null
                              ? 'Thêm xe mới'
                              : 'Chỉnh sửa xe',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Đóng thông tin xe',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const ValueKey('vehicle-name'),
                    controller: _name,
                    decoration: const InputDecoration(
                      labelText: 'Tên xe',
                      hintText: 'Ví dụ: Wave đi làm',
                    ),
                    textInputAction: TextInputAction.next,
                    maxLength: 80,
                    validator: VehicleValidation.name,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    key: const ValueKey('vehicle-plate'),
                    controller: _plate,
                    decoration: const InputDecoration(
                      labelText: 'Biển số xe',
                      hintText: '59-X1 123.45',
                    ),
                    textCapitalization: TextCapitalization.characters,
                    textInputAction: TextInputAction.next,
                    maxLength: 20,
                    validator: (value) =>
                        VehicleValidation.licensePlate(value) ??
                        ref
                            .read(vehicleProvider.notifier)
                            .duplicatePlateError(
                              value ?? '',
                              excludingId: widget.vehicle?.id,
                            ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    key: const ValueKey('vehicle-brand'),
                    initialValue: _brand,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Hãng xe'),
                    items: [
                      for (final brand in brands)
                        DropdownMenuItem(value: brand, child: Text(brand)),
                    ],
                    onChanged: (value) => setState(() => _brand = value),
                    validator: (value) =>
                        value == null ? 'Vui lòng chọn hãng xe.' : null,
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    key: const ValueKey('vehicle-color'),
                    controller: _color,
                    decoration: const InputDecoration(
                      labelText: 'Màu xe (không bắt buộc)',
                    ),
                    maxLength: 40,
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Loại lốp',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  SegmentedButton<TireType>(
                    segments: [
                      for (final type in TireType.values)
                        ButtonSegment(value: type, label: Text(type.label)),
                    ],
                    selected: {_tire},
                    showSelectedIcon: false,
                    onSelectionChanged: (values) =>
                        setState(() => _tire = values.single),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Loại động cơ',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  SegmentedButton<EngineType>(
                    segments: [
                      for (final type in EngineType.values)
                        ButtonSegment(value: type, label: Text(type.label)),
                    ],
                    selected: {_engine},
                    showSelectedIcon: false,
                    onSelectionChanged: (values) =>
                        setState(() => _engine = values.single),
                  ),
                  const SizedBox(height: 26),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: ServiceColors.orange,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _saved ? null : _save,
                    child: const Text('Lưu thông tin xe'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
