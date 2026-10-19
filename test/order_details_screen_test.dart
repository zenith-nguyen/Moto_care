import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:revo/core/router/app_router.dart';
import 'package:revo/core/theme/app_theme.dart';
import 'package:revo/features/activity/models/order_details.dart';
import 'package:revo/features/activity/models/rescue_order.dart';
import 'package:revo/features/activity/providers/activity_provider.dart';
import 'package:revo/features/activity/providers/order_details_provider.dart';
import 'package:revo/features/activity/screens/order_details_screen.dart';
import 'package:revo/features/activity/services/activity_actions.dart';
import 'package:revo/features/activity/services/order_details_service.dart';
import 'package:revo/features/activity/services/rescue_order_service.dart';
import 'package:revo/features/activity/widgets/activity_order_card.dart';
import 'package:revo/features/activity/widgets/rescue_progress_stepper.dart';
import 'package:revo/features/chat/screens/chat_detail_screen.dart';
import 'package:revo/features/profile/models/user_profile.dart';
import 'package:revo/features/profile/providers/profile_provider.dart';
import 'package:revo/features/rescue/screens/order_tracking_screen.dart';
import 'package:revo/features/rescue/widgets/order_tracking_map.dart';

final _created = DateTime(2026, 10, 9, 10, 30);
final _arriving = DateTime(2026, 10, 9, 10, 32);
const _profile = UserProfile(
  id: 'customer',
  fullName: 'Khách hiện tại',
  phoneNumber: '0912345678',
);
RescueOrder _order({
  String id = 'detail-001',
  RescueOrderStatus status = RescueOrderStatus.enRoute,
  bool contact = true,
  bool snapshot = true,
  List<RescueOrderEvent>? events,
}) => RescueOrder(
  id: id,
  orderCode: 'MC-2026-8899',
  status: status,
  serviceType: RescueServiceType.flatTire,
  userVehicle: 'Honda SH 150i',
  locationAddress: '273 An Dương Vương, Phường 3, Quận 5, TP.HCM',
  locationLatitude: 10.757,
  locationLongitude: 106.668,
  incidentDescription: 'Cần vá khẩn cấp',
  requesterName: snapshot ? 'Trần Hoàng Anh' : '',
  requesterPhone: snapshot ? '0987654321' : '',
  providerName: contact ? 'Nguyễn Minh Tuấn' : null,
  providerPhone: contact ? '0901234567' : null,
  providerPlate: contact ? '59-X1 123.45' : null,
  basePrice: 50000,
  extraPartPrice: 0,
  discount: 0,
  createdAt: _created,
  statusEvents:
      events ??
      [
        RescueOrderEvent(
          status: RescueOrderStatus.pending,
          occurredAt: _created,
        ),
        if (status != RescueOrderStatus.pending)
          RescueOrderEvent(
            status: RescueOrderStatus.enRoute,
            occurredAt: _arriving,
          ),
      ],
);

Future<GoRouter> _open(
  WidgetTester tester, {
  RescueOrder? order,
  String path = '/order-details?id=detail-001',
  Future<bool> Function(Uri)? launcher,
}) async {
  final router = createAppRouter();
  addTearDown(router.dispose);
  addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        initialRescueOrdersProvider.overrideWithValue([order ?? _order()]),
        initialUserProfileProvider.overrideWithValue(_profile),
        rescueOrderClockProvider.overrideWithValue(
          () => DateTime(2026, 10, 9, 10, 40),
        ),
        activityUrlLauncherProvider.overrideWithValue(
          launcher ?? (_) async => true,
        ),
        orderTrackingMapBuilderProvider.overrideWithValue(
          (context, data) => SimulatedTrackingMap(data: data),
        ),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light,
        routerConfig: router,
        locale: const Locale('vi'),
        supportedLocales: const [Locale('vi')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
      ),
    ),
  );
  router.go(path);
  await tester.pumpAndSettle();
  return router;
}

Finder _key(String id) => find.byKey(ValueKey('order-details-$id'));
ProviderContainer _state(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
Future<void> _tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Legacy rescue tracking opens progress for the selected order', (
    tester,
  ) async {
    const id = 'detail &001';
    final router = await _open(
      tester,
      order: _order(id: id, status: RescueOrderStatus.pending, contact: false),
      path: '/rescue-tracking?id=${Uri.encodeQueryComponent(id)}',
    );
    await tester.scrollUntilVisible(
      find.text('Xem chi tiết đơn'),
      160,
      scrollable: find.byType(Scrollable).last,
    );
    await _tap(tester, find.text('Xem chi tiết đơn'));
    expect(router.state.uri.path, '/order-details');
    expect(router.state.uri.queryParameters['id'], id);
    expect(find.byType(OrderDetailsScreen), findsOneWidget);
    expect(find.text('MC-2026-8899'), findsOneWidget);
    expect(
      tester
          .widget<RescueProgressStepper>(find.byType(RescueProgressStepper))
          .steps
          .first
          .state,
      RescueProgressState.active,
    );
    await _tap(tester, find.byTooltip('Quay lại'));
    expect(router.state.uri.path, '/rescue-tracking');
    expect(router.state.uri.queryParameters['id'], id);
  });

  test('Progress derives every status and never invents transition times', () {
    const service = OrderDetailsService();
    for (final status in RescueOrderStatus.values) {
      final details = service.resolve(
        _order(status: status, events: []),
        _profile,
      );
      expect(details.steps.length, 4);
      expect(details.steps.first.time, '10:30');
      expect(details.steps.skip(1).map((step) => step.time), everyElement('—'));
      if (status == RescueOrderStatus.cancelled) {
        expect(
          details.steps.where(
            (step) => step.state == RescueProgressState.active,
          ),
          isEmpty,
        );
        expect(details.steps.last.state, RescueProgressState.upcoming);
      } else if (status == RescueOrderStatus.completed) {
        expect(
          details.steps.map((step) => step.state),
          everyElement(RescueProgressState.done),
        );
      } else {
        expect(
          details.steps.indexWhere(
            (step) => step.state == RescueProgressState.active,
          ),
          switch (status) {
            RescueOrderStatus.pending => 0,
            RescueOrderStatus.enRoute => 1,
            _ => 2,
          },
        );
      }
      if (status != RescueOrderStatus.pending) {
        expect(details.timeline.first.time, '—');
        expect(details.timeline.first.isCurrent, isTrue);
      }
    }
  });

  test('Backend events sort, filter impossible steps, round-trip and stay immutable', () {
    final events = <RescueOrderEvent>[
      RescueOrderEvent(
        status: RescueOrderStatus.enRoute,
        occurredAt: _arriving,
        description: 'Thợ đã khởi hành.',
      ),
      RescueOrderEvent(status: RescueOrderStatus.pending, occurredAt: _created),
      RescueOrderEvent(
        status: RescueOrderStatus.completed,
        occurredAt: _arriving.add(const Duration(minutes: 10)),
      ),
      RescueOrderEvent(
        status: RescueOrderStatus.repairing,
        occurredAt: _created.subtract(const Duration(minutes: 1)),
      ),
    ];
    final order = _order(events: events);
    events.clear();
    expect(order.statusEvents.length, 4);
    expect(() => order.statusEvents.clear(), throwsUnsupportedError);
    final restored = RescueOrder.fromJson(order.toJson()).copyWith(rating: 4);
    expect(restored.toJson(), order.copyWith(rating: 4).toJson());
    final details = const OrderDetailsService().resolve(restored, _profile);
    expect(details.timeline.length, 2);
    expect(details.timeline.first.description, 'Thợ đã khởi hành.');
    expect(details.steps[1].time, '10:32');
    expect(details.steps[2].time, '—');
    expect(details.requesterName, 'Trần Hoàng Anh');
    expect(details.requesterPhone, '0987654321');
    expect(() => details.steps.clear(), throwsUnsupportedError);
    final legacyJson = order.toJson()
      ..remove('requesterName')
      ..remove('requesterPhone')
      ..remove('statusEvents');
    final legacy = const OrderDetailsService().resolve(
      RescueOrder.fromJson(legacyJson),
      UserProfile.empty,
    );
    expect(legacy.requesterName, 'Chưa cập nhật tên');
    expect(legacy.requesterPhone, 'Chưa cập nhật số điện thoại');
  });

  test(
    'Creating and cancelling orders snapshots the requester and actual clock',
    () {
      final container = ProviderContainer(
        overrides: [
          initialRescueOrdersProvider.overrideWithValue([]),
          initialUserProfileProvider.overrideWithValue(_profile),
          rescueOrderClockProvider.overrideWithValue(() => _created),
        ],
      );
      addTearDown(container.dispose);
      final controller = container.read(activityProvider.notifier);
      final order = controller.createOrder(
        serviceType: RescueServiceType.flatTire,
        userVehicle: 'Honda',
        locationAddress: 'Quận 5',
      );
      expect(order.requesterName, _profile.fullName);
      expect(order.requesterPhone, _profile.phoneNumber);
      expect(order.statusEvents.single.occurredAt, _created);
      expect(controller.cancelOrder(order.id), isTrue);
      final cancelled = container.read(activityProvider).orderById(order.id)!;
      expect(cancelled.statusEvents.last.status, RescueOrderStatus.cancelled);
      expect(cancelled.statusEvents.last.occurredAt, _created);
      expect(cancelled.requesterName, _profile.fullName);
    },
  );

  testWidgets(
    'Active Activity cards open selected progress and preserve invoice access',
    (tester) async {
      final router = await _open(tester, path: '/hoat-dong');
      await _tap(
        tester,
        find.descendant(
          of: find.byType(ActivityOrderCard),
          matching: find.text('Chi tiết đơn'),
        ),
      );
      expect(router.state.uri.path, '/order-details');
      expect(router.state.uri.queryParameters['id'], 'detail-001');
      expect(find.byType(OrderDetailsScreen), findsOneWidget);
      await _tap(tester, _key('invoice'));
      expect(router.state.uri.path, '/chi-tiet-don-hang');
      expect(router.state.uri.queryParameters['id'], 'detail-001');
      await _tap(tester, find.byKey(const ValueKey('open-order-details')));
      expect(router.state.uri.path, '/order-details');
    },
  );

  testWidgets(
    'Header keeps actual data and clipboard feedback with navy Montserrat styling',
    (tester) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await _open(tester);
      expect(find.text('Chi tiết đơn cứu hộ'), findsOneWidget);
      expect(find.text('MC-2026-8899'), findsOneWidget);
      final stepper = tester.widget<RescueProgressStepper>(
        find.byType(RescueProgressStepper),
      );
      expect(stepper.steps[0].state, RescueProgressState.done);
      expect(stepper.steps[1].state, RescueProgressState.active);
      expect(
        stepper.steps.skip(2).map((step) => step.state),
        everyElement(RescueProgressState.upcoming),
      );
      expect(
        Theme.of(tester.element(find.byType(RescueProgressStepper)))
            .textTheme
            .bodyMedium!
            .fontFamily,
        startsWith('Montserrat'),
      );
      expect(
        Theme.of(tester.element(_key('tracking')))
            .filledButtonTheme
            .style!
            .backgroundColor!
            .resolve({}),
        const Color(0xFF0F172A),
      );
      await _tap(tester, _key('copy'));
      expect(copied, 'MC-2026-8899');
      expect(find.text('Đã sao chép mã đơn.'), findsOneWidget);
      expect(find.text('Trần Hoàng Anh\n0987654321'), findsOneWidget);
      expect(find.text('Cần vá khẩn cấp'), findsOneWidget);
    },
  );

  testWidgets('Tracking CTA and map details retain the same ID', (
    tester,
  ) async {
    final router = await _open(tester);
    await _tap(tester, _key('tracking'));
    expect(router.state.uri.path, '/order-tracking');
    expect(router.state.uri.queryParameters['id'], 'detail-001');
    expect(find.byType(OrderTrackingScreen), findsOneWidget);
    await _tap(tester, find.byTooltip('Chi tiết đơn hàng'));
    expect(router.state.uri.path, '/order-details');
    expect(router.state.uri.queryParameters['id'], 'detail-001');
    router.pop();
    await tester.pumpAndSettle();
    router.pop();
    await tester.pumpAndSettle();
    expect(find.byType(OrderDetailsScreen), findsOneWidget);
  });

  testWidgets('Chat opens the selected mechanic and order context', (
    tester,
  ) async {
    final router = await _open(tester);
    await _tap(tester, _key('chat'));
    expect(router.state.uri.path, '/chat-detail');
    expect(find.byType(ChatDetailScreen), findsOneWidget);
    expect(find.text('Nguyễn Minh Tuấn'), findsOneWidget);
    expect(find.textContaining('MC-2026-8899'), findsOneWidget);
    router.pop();
    await tester.pumpAndSettle();
    expect(find.byType(OrderDetailsScreen), findsOneWidget);
  });

  testWidgets(
    'Call launches the actual tel URI and reports launcher failures',
    (tester) async {
      Uri? launched;
      await _open(
        tester,
        launcher: (uri) async {
          launched = uri;
          return false;
        },
      );
      await _tap(tester, _key('call'));
      expect(launched, Uri(scheme: 'tel', path: '0901234567'));
      expect(
        find.textContaining(
          'Không thể mở ứng dụng gọi điện. Số thợ: 0901234567',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Unassigned orders disable contacts and use confirmed profile fallback',
    (tester) async {
      await _open(
        tester,
        order: _order(
          contact: false,
          snapshot: false,
          status: RescueOrderStatus.pending,
        ),
      );
      expect(find.text('Đang tìm thợ'), findsOneWidget);
      expect(find.text('Khách hiện tại\n0912345678'), findsOneWidget);
      expect(tester.widget<IconButton>(_key('chat')).onPressed, isNull);
      expect(tester.widget<IconButton>(_key('call')).onPressed, isNull);
      expect(
        _state(tester).read(orderDetailsProvider('detail-001'))!.steps[1].time,
        '—',
      );
    },
  );

  testWidgets(
    'Cancellation saves the reason and timestamp and returns to Home',
    (tester) async {
      final router = await _open(tester);
      await _tap(tester, _key('cancel'));
      await _tap(tester, find.text('Tiếp tục cứu hộ'));
      expect(
        _state(tester).read(activityProvider).orders.single.status,
        RescueOrderStatus.enRoute,
      );
      await _tap(tester, _key('cancel'));
      await _tap(tester, find.byKey(const ValueKey('cancel-reason-long_wait')));
      await tester.enterText(
        find.byKey(const ValueKey('cancel-custom-reason')),
        '  Đợi hơn 30 phút  ',
      );
      await _tap(tester, find.byKey(const ValueKey('cancel-confirm')));
      expect(router.state.uri.path, '/trang-chu');
      expect(find.text('Đã hủy đơn thành công'), findsOneWidget);
      expect(_key('cancel'), findsNothing);
      final order = _state(tester).read(activityProvider).orders.single;
      expect(order.status, RescueOrderStatus.cancelled);
      expect(order.cancellationReason!.code, 'long_wait');
      expect(order.cancellationReason!.details, 'Đợi hơn 30 phút');
      expect(order.statusEvents.last.occurredAt, DateTime(2026, 10, 9, 10, 40));
      final progress = _state(tester).read(orderDetailsProvider(order.id))!;
      expect(progress.steps.last.state, RescueProgressState.upcoming);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'A terminal order cannot be cancelled again from an open dialog',
    (tester) async {
      final router = await _open(tester);
      final container = _state(tester);
      await _tap(tester, _key('cancel'));
      await _tap(tester, find.byKey(const ValueKey('cancel-reason-long_wait')));
      expect(
        container.read(activityProvider.notifier).cancelOrder('detail-001'),
        isTrue,
      );
      await tester.pump();
      final cancelled = container.read(activityProvider).orders.single;
      await _tap(tester, find.byKey(const ValueKey('cancel-confirm')));
      expect(router.state.uri.path, '/order-details');
      expect(
        find.text('Đơn không còn ở trạng thái có thể hủy.'),
        findsOneWidget,
      );
      expect(find.text('Đã hủy đơn thành công'), findsNothing);
      expect(container.read(activityProvider).orders.single, same(cancelled));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Completed details show done steps and allow the invoice/rating route',
    (tester) async {
      await _open(tester, order: _order(status: RescueOrderStatus.completed));
      expect(tester.widget<FilledButton>(_key('tracking')).onPressed, isNull);
      expect(
        tester
            .widget<RescueProgressStepper>(find.byType(RescueProgressStepper))
            .steps
            .map((step) => step.state),
        everyElement(RescueProgressState.done),
      );
      expect(find.text('Xem hóa đơn & đánh giá'), findsOneWidget);
    },
  );

  testWidgets('320px and large text keep all data and controls reachable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final router = await _open(tester);
    expect(tester.takeException(), isNull);
    for (final target in [
      find.text('Cần vá khẩn cấp'),
      _key('chat'),
      find.text('Nhật ký trạng thái'),
      _key('invoice'),
    ]) {
      await tester.ensureVisible(target);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    await _tap(tester, _key('tracking'));
    expect(router.state.uri.path, '/order-tracking');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Missing and unknown IDs show empty states with a safe back action',
    (tester) async {
      final router = await _open(tester, path: '/order-details');
      for (final path in ['/order-details', '/order-details?id=unknown']) {
        router.go(path);
        await tester.pumpAndSettle();
        expect(
          find.text('Không tìm thấy đơn hàng. Vui lòng quay lại Hoạt động.'),
          findsOneWidget,
        );
        expect(find.byType(RescueProgressStepper), findsNothing);
        expect(_key('tracking'), findsNothing);
      }
      await _tap(tester, find.byTooltip('Quay lại'));
      expect(router.state.uri.path, '/hoat-dong');
    },
  );
}
