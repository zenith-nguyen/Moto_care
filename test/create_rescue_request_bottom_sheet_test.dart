import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:moto_care/core/widgets/photo_attachment_field.dart';
import 'package:moto_care/features/activity/models/rescue_order.dart';
import 'package:moto_care/features/activity/providers/activity_provider.dart';
import 'package:moto_care/features/activity/widgets/order_summary.dart';
import 'package:moto_care/features/home/models/rescue_location.dart';
import 'package:moto_care/features/home/providers/home_provider.dart';
import 'package:moto_care/features/home/theme/home_theme.dart';
import 'package:moto_care/features/home/widgets/home_sheets.dart';
import 'package:moto_care/features/rescue/widgets/create_rescue_request_bottom_sheet.dart';
import 'package:moto_care/features/vehicle/models/vehicle.dart';
import 'package:moto_care/features/vehicle/providers/vehicle_provider.dart';

const _vehicle = Vehicle(
  id: 'vision',
  name: 'Honda Vision',
  brand: 'Honda',
  licensePlate: '59-A1 123.45',
  tireType: TireType.tubeless,
  engineType: EngineType.gas,
  isDefault: true,
);

Future<ProviderContainer> _open(
  WidgetTester tester,
  String service, {
  Future<Uint8List?> Function()? camera,
  bool allowServiceSelection = false,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: [
        initialVehiclesProvider.overrideWithValue([_vehicle]),
        initialRescueOrdersProvider.overrideWithValue([]),
        initialRescueLocationProvider.overrideWithValue(
          const RescueLocation(address: '273 An Dương Vương, Quận 5'),
        ),
        cameraAttachmentPickerProvider.overrideWithValue(
          camera ?? () async => null,
        ),
      ],
      child: MaterialApp(
        theme: HomeTheme.red,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showHomeSheet<RescueOrder>(
                context,
                CreateRescueRequestBottomSheet(
                  serviceType: service,
                  allowServiceSelection: allowServiceSelection,
                ),
              ),
              child: const Text('Mở yêu cầu'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Mở yêu cầu'));
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(
    tester.element(find.byType(CreateRescueRequestBottomSheet)),
  );
}

Future<void> _tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Finder get _submit => find.byKey(const ValueKey('incident-request-submit'));
Finder get _total => find.byKey(const ValueKey('rescue-request-total'));
Finder get _camera =>
    find.widgetWithText(OutlinedButton, 'Chụp ảnh hiện trường khẩn cấp');

void main() {
  for (final (name, type, options) in const [
    (
      'Kích bình điện',
      RescueServiceType.batteryJump,
      [
        ('Kích bình ắc quy (40k)', 40000),
        ('Thay bình ắc quy mới (280k)', 280000),
      ],
    ),
    (
      'Cứu hộ Hết xăng',
      RescueServiceType.outOfFuel,
      [('Giao 2 Lít A95 (45k)', 45000), ('Giao 4 Lít A95 (85k)', 85000)],
    ),
    (
      'Sửa ngập nước',
      RescueServiceType.floodedEngine,
      [
        ('Sấy bugi & Xả xăng con (60k)', 60000),
        ('Thay nhớt ngập nước (120k)', 120000),
      ],
    ),
    (
      'Vá xe / Săm',
      RescueServiceType.flatTire,
      [
        ('Vá lốp có ruột (30k)', 30000),
        ('Vá lốp không ruột (50k)', 50000),
        ('Thay ruột mới (90k)', 90000),
      ],
    ),
    (
      'Vá xe',
      RescueServiceType.flatTire,
      [
        ('Vá lốp có ruột (30k)', 30000),
        ('Vá lốp không ruột (50k)', 50000),
        ('Thay ruột mới (90k)', 90000),
      ],
    ),
    (
      'Dịch vụ khác',
      RescueServiceType.engineFailure,
      [('Kiểm tra & Cứu hộ tận nơi (50k)', 50000)],
    ),
  ]) {
    testWidgets('$name updates total and saves the chosen option price', (
      tester,
    ) async {
      final container = await _open(tester, name);
      expect(find.byType(ChoiceChip), findsNWidgets(options.length));
      expect(
        tester.widget<Text>(_total).data,
        formatOrderPrice(options.first.$2),
      );
      for (final (label, price) in options) {
        await _tap(tester, find.text(label));
        expect(tester.widget<Text>(_total).data, formatOrderPrice(price));
        expect(
          tester
              .widgetList<ChoiceChip>(find.byType(ChoiceChip))
              .where((chip) => chip.selected),
          hasLength(1),
        );
      }
      await _tap(tester, _submit);
      final order = container.read(activityProvider).orders.single;
      expect(order.serviceType, type);
      expect(order.serviceOption, options.last.$1);
      expect(order.totalPrice, options.last.$2);
      expect(order.vehicleType, 'Xe tay ga');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'Vehicle categories and captured photo are retained with the request',
    (tester) async {
      final photo = (await rootBundle.load('assets/images/Logo_motocare.png'))
          .buffer
          .asUint8List();
      final container = await _open(
        tester,
        'Kích bình điện',
        camera: () async => photo,
      );
      for (final category in ['Xe côn tay / PKL', 'Xe tay ga', 'Xe số']) {
        await _tap(
          tester,
          find.byKey(const ValueKey('rescue-request-vehicle-type')),
        );
        await _tap(tester, find.text(category).last);
      }
      await _tap(tester, _camera);
      expect(find.byType(Image), findsOneWidget);
      await _tap(tester, find.text('Xóa ảnh'));
      expect(find.byType(Image), findsNothing);
      await _tap(tester, _camera);
      await _tap(tester, _submit);
      final order = container.read(activityProvider).orders.single;
      expect(order.vehicleType, 'Xe số');
      expect(order.incidentPhotoBytes, orderedEquals(photo));
      expect(
        order.copyWith(status: RescueOrderStatus.repairing).incidentPhotoBytes,
        orderedEquals(photo),
      );
      expect(order.toJson().containsKey('incidentPhotoBytes'), isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Camera cancellation and failures leave the request usable', (
    tester,
  ) async {
    var calls = 0;
    await _open(
      tester,
      'Vá xe',
      camera: () async {
        if (++calls == 1) return null;
        throw StateError('Không thể chụp ảnh thử nghiệm.');
      },
    );
    await _tap(tester, _camera);
    expect(find.byType(Image), findsNothing);
    await _tap(tester, _camera);
    expect(find.text('Không thể chụp ảnh thử nghiệm.'), findsOneWidget);
    expect(tester.widget<FilledButton>(_submit).onPressed, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Closing the sheet while the camera is pending creates no order',
    (tester) async {
      final pending = Completer<Uint8List?>();
      final container = await _open(
        tester,
        'Vá xe',
        camera: () => pending.future,
      );
      await _tap(tester, _camera);
      await _tap(tester, find.byTooltip('Đóng'));
      pending.complete(null);
      await tester.pumpAndSettle();
      expect(container.read(activityProvider).orders, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Changing services resets the option and total', (tester) async {
    await _open(tester, 'Vá xe', allowServiceSelection: true);
    await _tap(tester, find.text('Thay ruột mới (90k)'));
    await _tap(tester, find.byKey(const ValueKey('incident-request-service')));
    await _tap(tester, find.text('Chết máy').last);
    expect(find.text('Thay ruột mới (90k)'), findsNothing);
    expect(find.text('Kiểm tra & Cứu hộ tận nơi (50k)'), findsOneWidget);
    expect(tester.widget<Text>(_total).data, formatOrderPrice(50000));
    expect(tester.widget<ChoiceChip>(find.byType(ChoiceChip)).selected, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Small screens support all chip labels, camera and keyboard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    for (final service in [
      'Vá xe',
      'Kích bình điện',
      'Cứu hộ Hết xăng',
      'Sửa ngập nước',
    ]) {
      await _open(tester, service);
      await _tap(tester, find.byType(ChoiceChip).last);
      await tester.ensureVisible(_camera);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final description = find.byKey(
        const ValueKey('incident-request-description'),
      );
      await _tap(tester, description);
      tester.view.viewInsets = const FakeViewPadding(bottom: 240);
      await tester.enterText(description, 'Xe cần hỗ trợ');
      await tester.pumpAndSettle();
      await tester.ensureVisible(_submit);
      await tester.pumpAndSettle();
      expect(_submit.hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      tester.view.resetViewInsets();
      await tester.pumpAndSettle();
      await _tap(tester, find.byTooltip('Đóng'));
    }
  });
}
