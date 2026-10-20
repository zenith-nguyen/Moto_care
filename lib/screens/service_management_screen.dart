import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';
import '../widgets/revo_switch.dart';

class ServiceManagementScreen extends StatefulWidget {
  const ServiceManagementScreen({super.key});
  @override
  State<ServiceManagementScreen> createState() =>
      _ServiceManagementScreenState();
}

class _ServiceManagementScreenState extends State<ServiceManagementScreen> {
  late final List<bool> _values =
      appState.services.map((s) => s.enabled).toList();
  static const _icons = [
    Icons.battery_charging_full_outlined,
    Icons.tire_repair_outlined,
    Icons.water_outlined,
    Icons.build_outlined,
    Icons.local_shipping_outlined,
    Icons.local_gas_station_outlined,
    Icons.oil_barrel_outlined
  ];
  @override
  Widget build(BuildContext context) => Scaffold(
          body: SafeArea(
              child: Column(children: [
        const ScreenHeader(title: 'Quản lý dịch vụ'),
        Expanded(
            child: ListView(padding: AppSpace.pageInsets, children: [
          for (var i = 0; i < appState.services.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            Row(children: [
              Icon(_icons[i], size: 20),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(appState.services[i].name, style: appText(13))),
              RevoSwitch(
                  value: _values[i],
                  onChanged: (v) => setState(() => _values[i] = v),
                  label: appState.services[i].name),
            ]),
          ],
        ])),
        Padding(
            padding: AppSpace.footerInsets,
            child: PrimaryButton(
                label: 'Lưu thay đổi',
                onPressed: () {
                  if (!_values.contains(true)) {
                    showAppSnack(context, 'Vui lòng bật ít nhất một dịch vụ.');
                    return;
                  }
                  appState.saveServices(_values);
                  Navigator.pop(context);
                  showAppSnack(context, 'Đã cập nhật dịch vụ của bạn.');
                })),
      ])));
}
