import 'dart:io';
import 'dart:ui' as ui;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:revo/core/router/app_router.dart';
import 'package:revo/core/services/service_actions.dart';
import 'package:revo/features/admin/admin_routes.dart';
import 'package:revo/features/admin/models/admin_models.dart';
import 'package:revo/features/admin/models/admin_account_models.dart';
import 'package:revo/features/admin/providers/admin_providers.dart';
import 'package:revo/features/admin/providers/admin_account_provider.dart';
import 'package:revo/features/admin/services/mock_admin_repository.dart';
import 'package:revo/features/admin/theme/admin_theme.dart';
import 'package:revo/features/admin/widgets/admin_common.dart';
import 'package:revo/features/admin/widgets/admin_date_range_picker_dialog.dart';
import 'package:revo/features/admin/widgets/admin_floating_bottom_nav.dart';
import 'package:revo/features/admin/widgets/admin_health_card.dart';
import 'package:revo/features/admin/widgets/admin_finance_cards.dart';
import 'package:revo/features/admin/widgets/admin_invoice_activity.dart';
import 'package:revo/features/admin/widgets/admin_navigation_shell.dart';
import 'package:revo/features/admin/widgets/admin_page_header.dart';
import 'package:revo/features/admin/widgets/admin_order_card.dart';
import 'package:revo/features/admin/widgets/admin_order_detail_cards.dart';
import 'package:revo/features/admin/widgets/admin_weather_card.dart';
import 'package:revo/features/admin/widgets/admin_review_card.dart';
import 'package:revo/features/admin/presentation/screens/admin_mechanic_detail_screen.dart';
import 'package:revo/features/admin/widgets/admin_mechanic_detail_cards.dart';
import 'package:revo/features/home/data/home_media_assets.dart';
import 'package:revo/features/profile/services/profile_device_service.dart';

final _now = DateTime(2026, 10, 13, 14);
const _session = AdminSession(
  id: 'admin-1',
  name: 'Quản trị viên',
  email: 'admin@example.test',
  role: 'ADMIN',
);
const _captureKey = ValueKey('admin-capture');

class _AvatarDevice extends NativeProfileDeviceService {
  @override
  Future<Uint8List?> pickAvatar() async =>
      (await rootBundle.load('assets/images/REVO.png')).buffer
          .asUint8List();
}

class _MechanicPhotoRepository extends MockAdminRepository {
  _MechanicPhotoRepository(this.application) : super(clock: () => _now);
  final AdminProviderApplication application;

  @override
  Future<List<AdminProviderApplication>> pendingProviders() async => [
    application,
  ];
}

Future<GoRouter> _open(
  WidgetTester tester, {
  String path = '/admin/dashboard',
  Size size = const Size(390, 844),
  double scale = 1,
  MockAdminRepository? repository,
  AdminSession? session = _session,
  bool settle = true,
  DateTime? now,
  bool productionRouter = false,
  Future<void> Function()? signOut,
  Future<bool> Function(Uri)? launchUri,
  ProfileDeviceService? device,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final router = productionRouter
      ? createAppRouter()
      : GoRouter(
          initialLocation: path,
          routes: [
            ...adminRoutes,
            GoRoute(
              path: '/login',
              builder: (context, state) =>
                  const Scaffold(body: Text('Login fixture')),
            ),
          ],
        );
  addTearDown(router.dispose);
  if (productionRouter) router.go(path);
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: [
        adminSessionProvider.overrideWith(
          () => AdminSessionController(initialSession: session),
        ),
        adminClockProvider.overrideWithValue(() => now ?? _now),
        if (repository != null)
          adminRepositoryProvider.overrideWithValue(repository),
        if (signOut != null)
          adminSignOutServiceProvider.overrideWithValue(signOut),
        if (launchUri != null)
          serviceUrlLauncherProvider.overrideWithValue(launchUri),
        if (device != null)
          profileDeviceServiceProvider.overrideWithValue(device),
      ],
      child: RepaintBoundary(
        key: _captureKey,
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          theme: AdminTheme.light,
          routerConfig: router,
          locale: const Locale('vi'),
          supportedLocales: const [Locale('vi')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
        ),
      ),
    ),
  );
  if (settle) {
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
  }
  return router;
}

ProviderContainer _container(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(MaterialApp).first));
Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _selectDashboardFilter(WidgetTester tester, int index) =>
    _tap(tester, find.byKey(ValueKey('admin-dashboard-filter-$index')));

Future<void> _capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('CAPTURE_ADMIN')) return;
  await tester.runAsync(
    () => Future.wait([
      for (final asset in [
        'assets/images/REVO.png',
        HomeMediaAssets.weatherBackground,
        AdminFinanceStyle.escrowAsset,
        'assets/images/Tiemsua1.png',
        'assets/images/Ảnh_thợ.png',
      ])
        precacheImage(
          AssetImage(asset),
          tester.element(find.byType(MaterialApp).first),
        ),
    ]),
  );
  await tester.pump();
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_captureKey),
  );
  final previousDisableShadows = debugDisableShadows;
  debugDisableShadows = false;
  // Nested repaint boundaries also need fresh paints with shadow blur enabled.
  void repaint(RenderObject object) {
    object.markNeedsPaint();
    object.visitChildren(repaint);
  }

  try {
    repaint(boundary);
    await tester.pump();
    await tester.runAsync(() async {
      final image = await boundary.toImage();
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('docs/screenshots/$name.png')
          .writeAsBytes(data!.buffer.asUint8List());
      image.dispose();
    });
  } finally {
    debugDisableShadows = previousDisableShadows;
    repaint(boundary);
    await tester.pump();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final fonts = FontLoader('Montserrat')
      ..addFont(rootBundle.load('assets/fonts/Montserrat-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Montserrat-Medium.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Montserrat-SemiBold.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Montserrat-Bold.ttf'));
    // Render finance's ExtraBold amounts with the bundled production weight.
    fonts.addFont(rootBundle.load('assets/fonts/Montserrat-ExtraBold.ttf'));
    await fonts.load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  testWidgets('Only the Admin dashboard shows the avatar and notifications', (
    tester,
  ) async {
    final router = await _open(tester);
    for (final path in [
      '/admin/dashboard',
      '/admin/orders',
      '/admin/providers',
      '/admin/finance',
      '/admin/requests',
      '/admin/account',
    ]) {
      router.go(path);
      await tester.pumpAndSettle();
      expect(find.byType(AdminPageHeader), findsOneWidget);
      final isDashboard = path == '/admin/dashboard';
      expect(
        find.byKey(const ValueKey('admin-header-avatar')),
        isDashboard ? findsOneWidget : findsNothing,
      );
      expect(
        find.byKey(const ValueKey('admin-header-notifications')),
        isDashboard ? findsOneWidget : findsNothing,
      );
      expect(
        find.byKey(const ValueKey('admin-header-notification-dot')),
        isDashboard ? findsOneWidget : findsNothing,
      );
      expect(find.byKey(const ValueKey('admin-header-account')), findsNothing);
      expect(find.byTooltip('Hồ sơ Admin'), findsNothing);
      await _capture(tester, 'admin-header-${path.split('/').last}-mobile');
      if (isDashboard) {
        await _tap(
          tester,
          find.byKey(const ValueKey('admin-header-notifications')),
        );
        expect(router.state.uri.path, '/admin/requests');
      }
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets(
    'Dashboard avatar reflects the saved Admin photo and opens the account',
    (tester) async {
      final router = await _open(tester, device: _AvatarDevice());
      final avatar = find.byKey(const ValueKey('admin-header-avatar'));
      final image = find.descendant(of: avatar, matching: find.byType(Image));
      expect(tester.getSize(avatar), const Size(44, 44));
      expect(image, findsNothing);
      expect(
        tester.getCenter(avatar).dx,
        lessThan(tester.getCenter(find.text('Tổng quan')).dx),
      );
      final result = await tester.runAsync(
        () =>
            _container(tester).read(adminAccountProvider.notifier).pickAvatar(),
      );
      expect(result!.success, isTrue);
      await tester.pumpAndSettle();
      expect(image, findsOneWidget);
      expect(
        (tester.widget<Image>(image).image as MemoryImage).bytes,
        orderedEquals(
          _container(tester).read(adminAccountProvider).avatarBytes!,
        ),
      );
      await _tap(tester, avatar);
      expect(router.state.uri.path, '/admin/account');
      router.go('/admin/dashboard');
      await tester.pumpAndSettle();
      expect(image, findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Admin weather sits above the pills without User booking content',
    (tester) async {
      await _open(tester);
      final weather = find.byType(AdminWeatherCard);
      expect(weather, findsOneWidget);
      expect(find.text('32°'), findsOneWidget);
      expect(find.text('Nắng nóng · Dễ nổ lốp'), findsOneWidget);
      expect(find.text('Áp dụng phụ phí x1.2'), findsOneWidget);
      expect(
        tester.getBottomLeft(weather).dy,
        lessThan(
          tester
              .getTopLeft(
                find.byKey(const PageStorageKey('admin-dashboard-filters')),
              )
              .dy,
        ),
      );
      expect(
        tester
            .getBottomLeft(
              find.byKey(const PageStorageKey('admin-dashboard-filters')),
            )
            .dy,
        lessThan(
          tester
              .getTopLeft(find.byKey(const ValueKey('admin-sos-overview')))
              .dy,
        ),
      );
      expect(find.byType(TextField), findsNothing);
      for (final text in [
        'Vị trí của tôi',
        'Trạm cứu hộ',
        'Dịch vụ',
        'Kích bình',
        'Ngập nước',
      ]) {
        expect(find.text(text), findsNothing);
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Header notification dot clears when no requests are pending', (
    tester,
  ) async {
    await _open(
      tester,
      repository: MockAdminRepository(clock: () => _now, empty: true),
    );
    expect(find.byType(AdminPageHeader), findsOneWidget);
    expect(
      find.byKey(const ValueKey('admin-header-notification-dot')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('admin-header-notifications')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Health overview cards show the requested palette, live metrics and daily revenue',
    (tester) async {
      await _open(tester, size: const Size(1440, 1000));
      expect(find.widgetWithText(AdminPageTitle, 'Tổng quan'), findsOneWidget);
      expect(find.byType(AppBar), findsNothing);
      expect(find.byType(ChoiceChip), findsNWidgets(5));
      expect(find.byType(AdminHealthCard), findsNWidgets(3));
      for (final (key, color) in [
        ('admin-sos-overview', const Color(0xFF0A192F)),
        ('admin-people-overview', const Color(0xFFEBF3FE)),
        ('admin-revenue-overview', const Color(0xFFF8F9FA)),
      ]) {
        final card = tester.widget<AdminHealthCard>(find.byKey(ValueKey(key)));
        expect(card.backgroundColor, color);
        final surface = tester.widget<Material>(
          find
              .descendant(
                of: find.byKey(ValueKey(key)),
                matching: find.byType(Material),
              )
              .first,
        );
        expect(surface.borderRadius, BorderRadius.circular(24));
      }
      expect(find.byType(VerticalDivider), findsNWidgets(3));
      expect(find.text('Ca cứu hộ SOS & Đơn hàng'), findsOneWidget);
      expect(find.text('Trạng thái hệ thống'), findsOneWidget);
      expect(find.text('7 ngày gần nhất • 8 ca đã ghi nhận'), findsOneWidget);
      expect(find.text('1.248', findRichText: true), findsOneWidget);
      expect(find.text('24/86', findRichText: true), findsOneWidget);
      expect(find.text(adminMoney(1350000)), findsOneWidget);
      expect(find.byType(LineChart), findsNothing);
      expect(find.byType(BarChart), findsOneWidget);
      expect(
        tester.widget<BarChart>(find.byType(BarChart)).data.barGroups,
        hasLength(7),
      );
      expect(
        tester
            .widget<BarChart>(find.byType(BarChart))
            .data
            .barGroups
            .fold<int>(
              0,
              (total, group) => total + group.barRods.single.toY.round(),
            ),
        1350000,
      );
      expect(find.text('SOS Đơn hàng khẩn cấp'), findsNothing);
      expect(find.text('Yêu cầu Rút tiền / Hoàn tiền'), findsNothing);
      expect(find.text('Tài khoản quản trị'), findsNothing);
      expect(
        tester.widget<Badge>(find.byType(Badge)).label,
        isA<Text>().having((t) => t.data, 'count', '7'),
      );
      await _capture(tester, 'admin-dashboard-desktop');
      await _tap(tester, find.byType(DropdownButton<String>));
      await _tap(tester, find.text('Hôm nay').last);
      expect(
        _container(tester)
            .read(
              adminSummaryProvider(
                AdminDateRange(DateTime(2026, 10, 13), DateTime(2026, 10, 14)),
              ),
            )
            .hasValue,
        true,
      );
      expect(
        tester.widget<BarChart>(find.byType(BarChart)).data.barGroups,
        hasLength(1),
      );
      expect(find.textContaining('Hôm nay •'), findsOneWidget);
      await _selectDashboardFilter(tester, 3);
      expect(
        tester.widget<BarChart>(find.byType(BarChart)).data.barGroups,
        hasLength(1),
      );
      expect(
        tester
            .widget<DropdownButton<String>>(find.byType(DropdownButton<String>))
            .value,
        'Hôm nay',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Dashboard chips isolate charts, people and the live request queue',
    (tester) async {
      await _open(tester);
      await _selectDashboardFilter(tester, 1);
      expect(find.byType(LineChart), findsOneWidget);
      expect(find.byType(BarChart), findsNothing);
      expect(find.text('8 ca', findRichText: true), findsOneWidget);
      expect(find.text('0 ca', findRichText: true), findsOneWidget);
      expect(find.text('Trung bình 1,1 ca/ngày'), findsOneWidget);
      expect(find.text('MC-2603 · Phạm Thanh Hà'), findsOneWidget);
      expect(find.text('MC-2604 · Trần Bảo Ngọc'), findsOneWidget);
      expect(find.text('Xem đơn hàng (2)'), findsOneWidget);
      expect(find.text('Trạng thái hệ thống'), findsNothing);
      await _capture(tester, 'admin-dashboard-sos-mobile');

      await _selectDashboardFilter(tester, 2);
      expect(find.byType(LineChart), findsNothing);
      expect(find.byType(BarChart), findsNothing);
      expect(find.text('1.248', findRichText: true), findsOneWidget);
      expect(find.text('24/86', findRichText: true), findsOneWidget);
      expect(
        tester.widget<Text>(find.text('3')).style?.color,
        const Color(0xFFE57373),
      );
      expect(find.text('2 đơn'), findsOneWidget);
      expect(find.text('SOS Đơn hàng khẩn cấp'), findsNothing);
      await _capture(tester, 'admin-dashboard-people-mobile');

      await _selectDashboardFilter(tester, 3);
      expect(find.byType(LineChart), findsNothing);
      expect(find.byType(BarChart), findsOneWidget);
      expect(find.text(adminMoney(1350000)), findsOneWidget);
      expect(
        find.text('Trung bình ${adminMoney(192857)}/ngày'),
        findsOneWidget,
      );
      final chart = tester.widget<BarChart>(find.byType(BarChart));
      expect(chart.data.barGroups, hasLength(7));
      expect(chart.data.extraLinesData.horizontalLines.single.y, 1350000 / 7);
      expect(find.text('Trạng thái hệ thống'), findsNothing);
      await _capture(tester, 'admin-dashboard-revenue-mobile');

      await _selectDashboardFilter(tester, 4);
      expect(find.byType(LineChart), findsNothing);
      expect(find.byType(BarChart), findsNothing);
      expect(find.byType(DropdownButton<String>), findsNothing);
      expect(find.text('Rút tiền · Trần Quốc Huy'), findsOneWidget);
      expect(find.text('Rút tiền · Lê Văn Phúc'), findsOneWidget);
      expect(find.text('Hoàn tiền · Trần Bảo Ngọc'), findsOneWidget);
      expect(find.text('Hoàn tiền · Bùi Gia Hân'), findsOneWidget);
      expect(find.text('Xem yêu cầu (5)'), findsOneWidget);
      await _capture(tester, 'admin-dashboard-pending-mobile');

      await _selectDashboardFilter(tester, 0);
      expect(find.byType(AdminHealthCard), findsNWidgets(3));
      expect(find.text('Yêu cầu Rút tiền / Hoàn tiền'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Icon-only Admin bar keeps six destinations, the request badge and direct account access',
    (tester) async {
      final router = await _open(tester);
      final nav = find.byType(AdminFloatingBottomNav);
      expect(nav, findsOneWidget);
      expect(
        find.descendant(of: nav, matching: find.byType(InkWell)),
        findsNWidgets(6),
      );
      expect(
        tester
            .widgetList<Text>(
              find.descendant(of: nav, matching: find.byType(Text)),
            )
            .map((text) => text.data),
        ['7'],
      );
      for (final label in AdminFloatingBottomNav.labels) {
        expect(find.byTooltip(label), findsOneWidget);
      }
      final position = tester.getTopLeft(nav);
      await _capture(tester, 'admin-dashboard-mobile');
      final revenueCard = find.widgetWithText(
        AdminHealthCard,
        'Doanh thu & Dòng tiền',
      );
      await tester.ensureVisible(revenueCard);
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(nav).dy, position.dy);
      expect(tester.getBottomLeft(revenueCard).dy, lessThan(position.dy));
      await tester.tap(
        find.descendant(
          of: revenueCard,
          matching: find.text('Doanh thu & Dòng tiền'),
        ),
      );
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/admin/finance');
      expect(tester.getTopLeft(nav).dy, position.dy);
      await _tap(tester, find.byTooltip('Tài khoản'));
      expect(router.state.uri.path, '/admin/account');
      expect(tester.widget<AdminFloatingBottomNav>(nav).selectedIndex, 5);
      await _tap(tester, find.byTooltip('Tổng quan'));
      expect(router.state.uri.path, '/admin/dashboard');
      expect(find.text('Tài khoản quản trị'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Dashboard withdrawal shortcut opens the withdrawal queue', (
    tester,
  ) async {
    final router = await _open(tester);
    await _selectDashboardFilter(tester, 4);
    await _tap(tester, find.textContaining('Rút tiền ·').first);
    expect(router.state.uri.queryParameters['tab'], 'withdrawals');
    expect(find.text('Lịch sử ví'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Cancelling custom dates keeps the selected period', (
    tester,
  ) async {
    await _open(tester);
    await _tap(tester, find.byType(DropdownButton<String>));
    await _tap(tester, find.text('Tùy chọn').last);
    expect(find.byType(AdminDateRangePickerDialog), findsOneWidget);
    await tester.tap(find.byTooltip('Đóng'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<DropdownButton<String>>(find.byType(DropdownButton<String>))
          .value,
      '7 ngày',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Order date picker applies inclusive dates, restores them and discards cancelled edits',
    (tester) async {
      await _open(tester, path: '/admin/orders');
      await tester.enterText(find.byType(TextField), 'MC-2602');
      final container = _container(tester);
      container
          .read(adminOrderFilterProvider.notifier)
          .update(
            const AdminOrderFilter(
              search: 'MC-2602',
              status: AdminOrderStatus.working,
              payment: AdminPaymentStatus.held,
            ),
          );
      await tester.pumpAndSettle();
      await _tap(tester, find.text('Khoảng ngày'));
      await _tap(tester, find.byKey(const ValueKey('admin-date-2026-10-11')));
      await _tap(tester, find.byKey(const ValueKey('admin-date-2026-10-13')));
      expect(container.read(adminOrderFilterProvider).range, isNull);
      expect(find.text('11 thg 10 – 13 thg 10'), findsOneWidget);
      await _capture(tester, 'admin-orders-date-range-mobile');
      await _tap(tester, find.text('Áp dụng'));
      final filter = container.read(adminOrderFilterProvider);
      expect(
        filter.range,
        AdminDateRange(DateTime(2026, 10, 11), DateTime(2026, 10, 14)),
      );
      expect(filter.range!.contains(DateTime(2026, 10, 13, 23, 59)), isTrue);
      expect(filter.range!.contains(DateTime(2026, 10, 14)), isFalse);
      expect(filter.search, 'MC-2602');
      expect(filter.status, AdminOrderStatus.working);
      expect(filter.payment, AdminPaymentStatus.held);
      expect(find.text('MC-2602'), findsWidgets);

      await _tap(tester, find.text('11/10 – 13/10'));
      expect(find.text('11 thg 10 – 13 thg 10'), findsOneWidget);
      await _tap(tester, find.byKey(const ValueKey('admin-date-2026-10-12')));
      await _tap(tester, find.byTooltip('Đóng'));
      expect(container.read(adminOrderFilterProvider).range, filter.range);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Orders search, status/payment/date filters combine and detail remains read only',
    (tester) async {
      final router = await _open(tester, path: '/admin/orders');
      await tester.enterText(find.byType(TextField), 'MC-2601');
      await tester.pumpAndSettle();
      expect(find.text('MC-2601'), findsWidgets);
      expect(find.text('MC-2602'), findsNothing);
      final container = _container(tester);
      container
          .read(adminOrderFilterProvider.notifier)
          .update(
            AdminOrderFilter(
              search: 'MC-2601',
              status: AdminOrderStatus.working,
              payment: AdminPaymentStatus.held,
              range: AdminDateRange(
                DateTime(2026, 10, 13),
                DateTime(2026, 10, 14),
              ),
            ),
          );
      await tester.pumpAndSettle();
      expect(find.text('Không có dữ liệu'), findsOneWidget);
      await _tap(tester, find.text('Xóa bộ lọc'));
      await _tap(tester, find.text('Chi tiết').first);
      expect(router.state.uri.path, '/admin/orders/MC-2601');
      expect(find.text('Lịch sử trạng thái'), findsOneWidget);
      expect(find.text('Lịch sử thanh toán / hoàn tiền'), findsOneWidget);
      expect(find.text('Chat history • Chỉ xem'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Order cards pair fields and preserve search on detail Back', (
    tester,
  ) async {
    final router = await _open(tester, path: '/admin/orders');
    await tester.enterText(find.byType(TextField), 'MC-2601');
    await tester.pumpAndSettle();
    final card = find.byType(AdminOrderCard);
    expect(card, findsOneWidget);
    final customer = find.descendant(
      of: card,
      matching: find.text('Khách hàng'),
    );
    final incident = find.descendant(
      of: card,
      matching: find.text('Loại sự cố'),
    );
    expect(tester.getTopLeft(customer).dy, tester.getTopLeft(incident).dy);
    expect(
      tester.getTopLeft(customer).dx,
      lessThan(tester.getTopLeft(incident).dx),
    );
    await _capture(tester, 'admin-orders-cards-mobile');
    await tester.ensureVisible(card);
    await tester.pumpAndSettle();
    await _capture(tester, 'admin-order-card-mobile');
    await _tap(tester, find.text('Chi tiết'));
    expect(router.state.uri.path, '/admin/orders/MC-2601');
    expect(find.byType(AdminOrderProgressCard), findsOneWidget);
    expect(
      find.byKey(const ValueKey('admin-order-step-completed-true')),
      findsOneWidget,
    );
    expect(find.text('12 Nguyễn Huệ, Quận 1, TP. Hồ Chí Minh'), findsOneWidget);
    await _capture(tester, 'admin-order-detail-mobile');
    await tester.ensureVisible(find.byType(AdminOrderMechanicCard));
    await tester.pumpAndSettle();
    await _capture(tester, 'admin-order-detail-history-mobile');
    await _tap(tester, find.byKey(const ValueKey('admin-order-back')));
    expect(router.state.uri.path, '/admin/orders');
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'MC-2601',
    );
    await _tap(tester, find.text('Xóa bộ lọc'));
    tester.view.physicalSize = const Size(1440, 1000);
    await tester.pumpAndSettle();
    final cards = find.byType(AdminOrderCard);
    expect(cards, findsNWidgets(8));
    expect(
      tester.getTopLeft(cards.at(0)).dy,
      tester.getTopLeft(cards.at(1)).dy,
    );
    expect(
      tester.getTopLeft(cards.at(0)).dx,
      lessThan(tester.getTopLeft(cards.at(1)).dx),
    );
    await _capture(tester, 'admin-orders-cards-desktop');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Tracking header copies the displayed order ID and reports clipboard failure',
    (tester) async {
      String? copied;
      var fail = false;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            if (fail) throw PlatformException(code: 'clipboard-unavailable');
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
      final router = await _open(tester, path: '/admin/orders/MC-2601');
      expect(find.text('Mã đơn hàng:'), findsOneWidget);
      final copy = find.byKey(const ValueKey('admin-order-copy-id'));
      expect(
        find.descendant(of: copy, matching: find.text('MC-2601')),
        findsOneWidget,
      );
      await _tap(tester, copy);
      expect(copied, 'MC-2601');
      expect(find.text('Đã sao chép mã đơn.'), findsOneWidget);
      fail = true;
      await _tap(tester, copy);
      expect(
        find.text('Không thể sao chép mã đơn. Vui lòng thử lại.'),
        findsOneWidget,
      );
      expect(router.state.uri.path, '/admin/orders/MC-2601');
      expect(
        find.byKey(const ValueKey('admin-order-step-completed-true')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Mechanic contact opens recorded chat and the correct dialer with failure feedback',
    (tester) async {
      final launched = <Uri>[];
      var canOpen = true;
      await _open(
        tester,
        path: '/admin/orders/MC-2601',
        launchUri: (uri) async {
          launched.add(uri);
          return canOpen;
        },
      );
      await _tap(tester, find.byKey(const ValueKey('admin-order-chat')));
      expect(
        find.text('Tôi đã nhận vị trí và đang di chuyển đến.'),
        findsOneWidget,
      );
      expect(find.byType(TextField), findsNothing);
      await _tap(tester, find.byTooltip('Đóng lịch sử trao đổi'));
      await _tap(tester, find.byKey(const ValueKey('admin-order-call')));
      expect(launched.single.toString(), 'tel:0900000101');
      canOpen = false;
      await _tap(tester, find.byKey(const ValueKey('admin-order-call')));
      expect(
        find.text('Không thể mở ứng dụng gọi điện. Vui lòng thử lại.'),
        findsOneWidget,
      );
      expect(_container(tester).read(adminAuditTrailProvider), isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Unassigned and cancelled orders keep future milestones pending at 320px',
    (tester) async {
      for (final id in ['MC-2603', 'MC-2605']) {
        await _open(
          tester,
          path: '/admin/orders/$id',
          size: const Size(320, 568),
          scale: 1.5,
        );
        expect(
          find.byKey(const ValueKey('admin-order-step-completed-false')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('admin-order-step-started-false')),
          findsOneWidget,
        );
        if (id == 'MC-2603') {
          final call = find.descendant(
            of: find.byKey(const ValueKey('admin-order-call')),
            matching: find.byType(IconButton),
          );
          expect(tester.widget<IconButton>(call).onPressed, isNull);
        }
        await tester.ensureVisible(find.byType(AdminOrderHistoryCard));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets(
    'Provider rejection validates note, confirms before sending and supports retry',
    (tester) async {
      final repo = MockAdminRepository(clock: () => _now);
      await _open(tester, path: '/admin/providers', repository: repo);
      await _tap(tester, find.text('Chi tiết').first);
      await _tap(tester, find.text('Từ chối'));
      await _tap(tester, find.text('Tiếp tục'));
      expect(find.text('Vui lòng nhập lý do / ghi chú.'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), 'Thiếu thông tin xe');
      await _tap(tester, find.text('Tiếp tục'));
      expect(find.text('Xác nhận từ chối hồ sơ thợ'), findsOneWidget);
      expect(
        _container(tester).read(adminProvidersProvider).requireValue,
        hasLength(3),
      );
      repo.nextError = const AdminException('Mạng đang gián đoạn');
      await tester.tap(find.text('Xác nhận'));
      await tester.pump();
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('Mạng đang gián đoạn'), findsOneWidget);
      expect(find.text('Ghi chú: Thiếu thông tin xe'), findsOneWidget);
      await _tap(tester, find.text('Thử lại / Retry'));
      expect(find.byType(AlertDialog), findsNothing);
      expect(
        _container(tester).read(adminProvidersProvider).requireValue,
        hasLength(2),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Provider approval cancellation preserves pending application', (
    tester,
  ) async {
    await _open(tester, path: '/admin/providers');
    await _capture(tester, 'admin-providers-mobile');
    await _tap(tester, find.text('Chi tiết').first);
    await _tap(tester, find.byKey(const ValueKey('admin-mechanic-approve')));
    expect(find.text('Xác nhận duyệt hồ sơ thợ'), findsOneWidget);
    await _tap(tester, find.text('Hủy'));
    expect(
      _container(tester).read(adminProvidersProvider).requireValue,
      hasLength(3),
    );
    await _tap(tester, find.byTooltip('Quay lại hồ sơ thợ'));
    tester.view.physicalSize = const Size(1440, 1000);
    await tester.pumpAndSettle();
    await _capture(tester, 'admin-providers-desktop');
  });

  testWidgets(
    'Mechanic detail replaces the dialog and keeps its action bar fixed',
    (tester) async {
      final router = await _open(
        tester,
        path: '/admin/providers',
        now: DateTime(2026, 10, 18, 13, 55),
      );
      await _tap(tester, find.text('Chi tiết').first);
      expect(router.state.uri.path, '/admin/providers/P-101');
      expect(find.byType(AdminMechanicDetailScreen), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(AdminFloatingBottomNav), findsNothing);
      expect(find.text('Võ Thành Đạt'), findsOneWidget);
      expect(find.text('Chờ duyệt'), findsOneWidget);
      expect(find.text('dat@example.test'), findsOneWidget);
      expect(find.text('12 Nguyễn Huệ, Q.1, TP.HCM'), findsOneWidget);
      expect(find.text('Chưa xác minh CCCD'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('admin-mechanic-thumbnail-front')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('admin-mechanic-thumbnail-back')),
        findsOneWidget,
      );
      await _capture(tester, 'admin-mechanic-detail-mobile');
      await _tap(tester, find.byTooltip('Đánh dấu hồ sơ'));
      expect(find.byTooltip('Bỏ đánh dấu hồ sơ'), findsOneWidget);
      await _tap(
        tester,
        find.byKey(const ValueKey('admin-mechanic-thumbnail-portrait')),
      );
      expect(
        find.byKey(const ValueKey('admin-mechanic-photo-viewer')),
        findsOneWidget,
      );
      expect(find.text('Chân dung thợ'), findsOneWidget);
      expect(find.byType(InteractiveViewer), findsWidgets);
      await tester.drag(find.byType(PageView), const Offset(350, 0));
      await tester.pumpAndSettle();
      expect(find.text('Tiệm sửa xe'), findsOneWidget);
      await _capture(tester, 'admin-mechanic-gallery-mobile');
      await _tap(tester, find.byTooltip('Đóng ảnh hồ sơ'));
      final bar = find.byType(AdminMechanicActionBar);
      final barTop = tester.getTopLeft(bar).dy;
      await tester.ensureVisible(find.byType(AdminMechanicDocuments));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(bar).dy, barTop);
      expect(find.text('079xxxxxxxxx'), findsOneWidget);
      expect(find.text('59-X1 101.01'), findsOneWidget);
      expect(
        tester
            .widget<InkWell>(
              find.byKey(const ValueKey('admin-mechanic-document-front')),
            )
            .onTap,
        isNull,
      );
      await _capture(tester, 'admin-mechanic-documents-mobile');
      await _tap(tester, find.byKey(const ValueKey('admin-mechanic-approve')));
      await _tap(tester, find.text('Xác nhận'));
      expect(router.state.uri.path, '/admin/providers');
      expect(
        _container(tester).read(adminProvidersProvider).requireValue,
        hasLength(2),
      );
      expect(
        _container(tester).read(adminAuditTrailProvider).first.target,
        'P-101',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Mechanic photo parameters open documents and additional images',
    (tester) async {
      final application = AdminProviderApplication(
        id: 'P-CUSTOM',
        name: 'Thợ kiểm thử',
        email: 'custom@example.test',
        phone: '0900 000 999',
        vehicle: 'Xe kiểm thử • Bộ dụng cụ riêng',
        plate: 'TEST-999',
        registeredAt: _now,
        workshopAddress: 'Địa chỉ xưởng kiểm thử',
        citizenIdMasked: 'TESTxxxxxxxx',
        identityVerified: true,
        workshopPhoto: const AdminMechanicPhoto.asset(
          'assets/images/Tiemsua2.png',
          label: 'Xưởng kiểm thử',
        ),
        identityFrontPhoto: const AdminMechanicPhoto.asset(
          'assets/images/REVO.png',
          label: 'Mặt trước CCCD kiểm thử',
        ),
        identityBackPhoto: const AdminMechanicPhoto.asset(
          'assets/images/REVO.png',
          label: 'Mặt sau CCCD kiểm thử',
        ),
        portraitPhoto: const AdminMechanicPhoto.asset(
          'assets/images/missing-avatar-test.png',
          label: 'Ảnh lỗi kiểm thử',
        ),
        additionalPhotos: const [
          AdminMechanicPhoto.asset(
            'assets/images/REVO.png',
            label: 'Giấy phép kiểm thử',
          ),
          AdminMechanicPhoto.asset(
            'assets/images/REVO.png',
            label: 'Chứng chỉ kiểm thử',
          ),
        ],
      );
      await _open(
        tester,
        path: '/admin/providers/P-CUSTOM',
        repository: _MechanicPhotoRepository(application),
      );
      expect(find.text('Thợ kiểm thử'), findsOneWidget);
      expect(find.text('Địa chỉ xưởng kiểm thử'), findsOneWidget);
      expect(find.text('Đã xác minh CCCD'), findsOneWidget);
      expect(find.text('+2'), findsOneWidget);
      await _tap(
        tester,
        find.byKey(const ValueKey('admin-mechanic-document-front')),
      );
      expect(find.text('Mặt trước CCCD kiểm thử'), findsOneWidget);
      expect(find.text('2/6'), findsOneWidget);
      await tester.drag(find.byType(PageView), const Offset(-350, 0));
      await tester.pumpAndSettle();
      expect(find.text('Mặt sau CCCD kiểm thử'), findsOneWidget);
      await _tap(tester, find.byTooltip('Đóng ảnh hồ sơ'));
      final container = _container(tester);
      await _tap(
        tester,
        find.byKey(const ValueKey('admin-mechanic-document-back')),
      );
      container.read(adminSessionProvider.notifier).signOut();
      await tester.pumpAndSettle();
      expect(
        find.text('Bạn không có quyền truy cập khu vực này'),
        findsWidgets,
      );
      expect(find.byType(InteractiveViewer), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Mechanic direct links handle missing data, retry and permission',
    (tester) async {
      await _open(tester, path: '/admin/providers/P-MISSING');
      expect(find.text('Không có dữ liệu'), findsOneWidget);
      await _open(
        tester,
        path: '/admin/providers/P-101',
        repository: MockAdminRepository(clock: () => _now)
          ..nextErrors['/admin/providers/pending'] = const AdminException(
            'Lỗi tải hồ sơ',
          ),
      );
      expect(find.text('Không thể tải dữ liệu'), findsOneWidget);
      await _tap(tester, find.text('Thử lại / Retry'));
      expect(find.byType(AdminMechanicDetailScreen), findsOneWidget);
      await _open(tester, path: '/admin/providers/P-101', session: null);
      expect(
        find.text('Bạn không có quyền truy cập khu vực này'),
        findsOneWidget,
      );
      expect(find.text('Võ Thành Đạt'), findsNothing);
      expect(find.byType(AdminMechanicActionBar), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Mechanic detail supports 320px large text and desktop', (
    tester,
  ) async {
    await _open(
      tester,
      path: '/admin/providers/P-101',
      size: const Size(320, 568),
      scale: 1.5,
    );
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.byType(AdminMechanicDocuments));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await _tap(tester, find.byKey(const ValueKey('admin-mechanic-approve')));
    expect(find.text('Xác nhận duyệt hồ sơ thợ'), findsOneWidget);
    await _tap(tester, find.text('Hủy'));
    expect(tester.takeException(), isNull);
    await _open(
      tester,
      path: '/admin/providers/P-101',
      size: const Size(1440, 1000),
      now: DateTime(2026, 10, 18, 13, 55),
    );
    await _capture(tester, 'admin-mechanic-detail-desktop');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Accepting a dispute refreshes pending badge and order price', (
    tester,
  ) async {
    await _open(tester, path: '/admin/requests');
    await _tap(tester, find.text('Tranh chấp giá (2)'));
    await _tap(tester, find.text('Chấp nhận giá đề xuất').first);
    await tester.enterText(
      find.byType(TextFormField),
      'Đã xác minh quãng đường',
    );
    await _tap(tester, find.text('Tiếp tục'));
    expect(find.text('Xác nhận chấp nhận giá đề xuất'), findsOneWidget);
    await _tap(tester, find.text('Xác nhận'));
    expect(find.text('Tranh chấp giá (1)'), findsOneWidget);
    expect(
      _container(tester).read(adminAuditTrailProvider).single.action,
      'Duyệt đề xuất giá',
    );
    expect(
      tester.widget<Badge>(find.byType(Badge)).label,
      isA<Text>().having((t) => t.data, 'count', '6'),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Withdrawal history, required rejection note and wallet unlocking work',
    (tester) async {
      await _open(tester, path: '/admin/requests');
      await _tap(tester, find.text('Rút tiền (2)'));
      await _tap(tester, find.text('Lịch sử ví').first);
      expect(find.textContaining('Số dư mở đầu phiên sandbox'), findsOneWidget);
      expect(find.textContaining('Đang khóa:'), findsOneWidget);
      await _tap(tester, find.text('Đóng'));
      await _tap(tester, find.text('Từ chối').first);
      await _tap(tester, find.text('Tiếp tục'));
      expect(find.text('Vui lòng nhập lý do / ghi chú.'), findsOneWidget);
      await tester.enterText(
        find.byType(TextFormField),
        'Sai thông tin nhận tiền',
      );
      await _tap(tester, find.text('Tiếp tục'));
      await _tap(tester, find.text('Xác nhận'));
      expect(find.text('Rút tiền (1)'), findsOneWidget);
      final wallet = _container(tester)
          .read(adminWalletProvider('P-01'))
          .requireValue;
      expect(wallet.locked, 0);
      expect(wallet.available, 680000);
      expect(tester.takeException(), isNull);
    },
  );

  const accountSession = AdminSession(
    id: 'ADM-2026-88',
    name: 'Quản trị viên',
    email: 'admin@revo.vn',
    role: 'ADMIN',
    canManageAdmins: true,
  );

  testWidgets(
    'Admin account profile validates, saves and survives navigation',
    (tester) async {
      final router = await _open(
        tester,
        path: '/admin/account',
        session: accountSession,
      );
      expect(find.text('Tài khoản Quản trị'), findsOneWidget);
      expect(find.text('SUPER ADMIN'), findsOneWidget);
      expect(find.byType(AppBar), findsNothing);
      await _capture(tester, 'admin-account-mobile');
      await tester.ensureVisible(find.text('Quản lý & Cấu hình Vận hành'));
      await tester.pumpAndSettle();
      await _capture(tester, 'admin-account-settings-mobile');
      await _tap(tester, find.text('Chỉnh sửa hồ sơ'));
      await tester.enterText(
        find.byKey(const ValueKey('admin-profile-name')),
        '',
      );
      await _tap(tester, find.text('Lưu thay đổi'));
      expect(find.text('Vui lòng nhập họ tên'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('admin-profile-name')),
        'Điều phối viên',
      );
      await tester.enterText(
        find.byKey(const ValueKey('admin-profile-phone')),
        '0901234567',
      );
      await _tap(tester, find.text('Lưu thay đổi'));
      expect(find.byType(AlertDialog), findsNothing);
      router.go('/admin/dashboard');
      await tester.pumpAndSettle();
      router.go('/admin/account');
      await tester.pumpAndSettle();
      expect(find.text('Điều phối viên'), findsOneWidget);
      expect(find.text('0901234567'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Fees validate ranges, persist decimals and appear in the audit trail',
    (tester) async {
      await _open(tester, path: '/admin/account', session: accountSession);
      await _tap(tester, find.text('Cấu hình Phí & Hệ số'));
      await tester.enterText(
        find.byKey(const ValueKey('admin-fees-fee')),
        '101',
      );
      await _tap(tester, find.text('Lưu thay đổi'));
      expect(find.text('Nhập giá trị từ 0.0 đến 100.0'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('admin-fees-fee')),
        '12,5',
      );
      await tester.enterText(
        find.byKey(const ValueKey('admin-fees-weather')),
        '1,4',
      );
      await _tap(tester, find.text('Lưu thay đổi'));
      expect(
        _container(tester).read(adminAccountProvider).settings.feePercent,
        12.5,
      );
      expect(find.textContaining('Thời tiết ×1.4'), findsOneWidget);
      await _tap(tester, find.text('Nhật ký thao tác (Audit Trail)'));
      expect(find.text('Cập nhật cấu hình vận hành'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'SOS sound cancellation and Sandbox confirmation retain or commit settings',
    (tester) async {
      await _open(tester, path: '/admin/account', session: accountSession);
      await _tap(tester, find.text('Cài đặt Cảnh báo SOS'));
      await _tap(tester, find.text('Âm thanh đơn SOS mới'));
      await _tap(tester, find.text('Hủy'));
      expect(
        _container(tester).read(adminAccountProvider).settings.sosSound,
        true,
      );
      await _tap(tester, find.text('Cài đặt Cảnh báo SOS'));
      await _tap(tester, find.text('Âm thanh đơn SOS mới'));
      await _tap(tester, find.text('Lưu thay đổi'));
      expect(find.text('Âm thanh chuông đã tắt'), findsOneWidget);
      await _tap(tester, find.byType(Switch));
      await _tap(tester, find.text('Hủy'));
      expect(
        _container(tester).read(adminAccountProvider).settings.sandbox,
        true,
      );
      await _tap(tester, find.byType(Switch));
      await _tap(tester, find.text('Xác nhận'));
      expect(
        _container(tester).read(adminAccountProvider).settings.sandbox,
        false,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Admin account guide, login history and support requests open with usable content',
    (tester) async {
      await _open(tester, path: '/admin/account', session: accountSession);
      await _tap(tester, find.text('Tài liệu Hướng dẫn Vận hành Admin'));
      expect(find.text('Theo dõi vận hành'), findsOneWidget);
      await _tap(tester, find.byTooltip('Đóng'));
      await _tap(tester, find.text('Lịch sử đăng nhập & Thiết bị'));
      expect(find.text('Phiên quản trị hiện tại'), findsOneWidget);
      await _tap(tester, find.byTooltip('Đóng'));
      await _tap(tester, find.text('Liên hệ Kỹ thuật (Dev Team Support)'));
      await _tap(tester, find.text('Lưu thay đổi'));
      expect(find.text('Vui lòng nhập tiêu đề'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('admin-support-subject')),
        'Lỗi đối soát',
      );
      await tester.enterText(
        find.byKey(const ValueKey('admin-support-message')),
        'Không mở được bảng đối soát hôm nay.',
      );
      await _tap(tester, find.text('Lưu thay đổi'));
      expect(
        _container(tester).read(adminAccountProvider).requests.single.id,
        'HT-0001',
      );
      await tester.ensureVisible(find.text('Nhật ký & Bảo mật'));
      await tester.pumpAndSettle();
      ScaffoldMessenger.of(tester.element(find.byType(AdminNavigationShell)))
          .hideCurrentSnackBar();
      await tester.ensureVisible(find.text('Đăng xuất'));
      await tester.pumpAndSettle();
      await _capture(tester, 'admin-account-security-mobile');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Admin account editors fit 320px with large text and the keyboard',
    (tester) async {
      await _open(
        tester,
        path: '/admin/account',
        session: accountSession,
        size: const Size(320, 568),
        scale: 1.5,
      );
      tester.view.viewInsets = const FakeViewPadding(bottom: 180);
      addTearDown(tester.view.resetViewInsets);
      for (final label in [
        'Chỉnh sửa hồ sơ',
        'Đổi mật khẩu',
        'Cấu hình Phí & Hệ số',
        'Cài đặt Cảnh báo SOS',
        'Liên hệ Kỹ thuật (Dev Team Support)',
      ]) {
        await _tap(tester, find.text(label));
        expect(tester.takeException(), isNull);
        await _tap(tester, find.text('Hủy'));
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets('Admin staff roles and shift changes commit through the editor', (
    tester,
  ) async {
    await _open(tester, path: '/admin/account', session: accountSession);
    await _tap(tester, find.text('Phân quyền Quản trị'));
    await _tap(tester, find.text('Chỉnh quyền / ca trực').first);
    await _tap(tester, find.byType(DropdownButtonFormField<AdminStaffRole>));
    await _tap(tester, find.text('Nhân viên ca trực').last);
    await _tap(tester, find.text('Đang trực').last);
    await _tap(tester, find.text('Lưu thay đổi'));
    final member = _container(tester).read(adminAccountProvider).staff.first;
    expect(member.role, AdminStaffRole.shiftStaff);
    expect(member.onDuty, false);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Password service errors retain the draft and never claim success',
    (tester) async {
      await _open(tester, path: '/admin/account', session: accountSession);
      await _tap(tester, find.text('Đổi mật khẩu'));
      final current = List.filled(12, 'a').join();
      final replacement = List.filled(12, 'b').join();
      await tester.enterText(
        find.byKey(const ValueKey('admin-password-current')),
        current,
      );
      await tester.enterText(
        find.byKey(const ValueKey('admin-password-new')),
        replacement,
      );
      await tester.enterText(
        find.byKey(const ValueKey('admin-password-confirm')),
        replacement,
      );
      await _tap(tester, find.text('Cập nhật mật khẩu'));
      expect(
        find.text('Chưa thể đổi mật khẩu. Dịch vụ tài khoản chưa sẵn sàng.'),
        findsOneWidget,
      );
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(_container(tester).read(adminAuditTrailProvider), isEmpty);
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const ValueKey('admin-password-new')),
            )
            .controller!
            .text,
        replacement,
      );
      await _tap(tester, find.text('Hủy'));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Logout requires confirmation and clears session before login', (
    tester,
  ) async {
    final router = await _open(tester, path: '/admin/account');
    final container = _container(tester);
    await _tap(tester, find.text('Đăng xuất'));
    await _tap(tester, find.text('Hủy'));
    expect(container.read(adminSessionProvider), isNotNull);
    await _tap(tester, find.text('Đăng xuất'));
    await _tap(tester, find.text('Xác nhận'));
    expect(container.read(adminSessionProvider), isNull);
    expect(router.state.uri.path, '/login');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Failed logout keeps the session and can be retried', (
    tester,
  ) async {
    var attempts = 0;
    await _open(
      tester,
      path: '/admin/account',
      signOut: () async {
        await Future<void>.delayed(const Duration(milliseconds: 300));
        if (attempts++ == 0) throw const AdminException('Lỗi đăng xuất');
      },
    );
    final container = _container(tester);
    await _tap(tester, find.text('Đăng xuất'));
    await tester.tap(find.text('Xác nhận'));
    await tester.pump();
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('Không thể đăng xuất. Vui lòng thử lại.'), findsOneWidget);
    expect(container.read(adminSessionProvider), isNotNull);
    await _tap(tester, find.text('Thử lại / Retry'));
    expect(find.text('Login fixture'), findsOneWidget);
  });

  testWidgets('Backend permission denial renders the permission state', (
    tester,
  ) async {
    await _open(
      tester,
      path: '/admin/providers',
      repository: MockAdminRepository(clock: () => _now)
        ..nextErrors['/admin/providers/pending'] = const AdminException(
          'Không có quyền',
          forbidden: true,
        ),
    );
    expect(
      find.text('Bạn không có quyền truy cập khu vực này'),
      findsOneWidget,
    );
    expect(find.text('Chi tiết'), findsNothing);
  });

  for (final role in ['CUSTOMER', 'PROVIDER', 'ADMIN-MISSING']) {
    testWidgets('$role cannot open admin via direct route or URL role claim', (
      tester,
    ) async {
      await _open(
        tester,
        path: '/admin/orders/MC-2601?role=ADMIN',
        session: role == 'ADMIN-MISSING'
            ? null
            : AdminSession(
                id: 'other',
                name: 'Other',
                email: 'other@example.test',
                role: role,
              ),
      );
      expect(
        find.text('Bạn không có quyền truy cập khu vực này'),
        findsOneWidget,
      );
      expect(find.text('Nguyễn Minh Anh'), findsNothing);
      expect(find.byType(NavigationRail), findsNothing);
    });
  }

  testWidgets('Production router registers admin without granting a session', (
    tester,
  ) async {
    await _open(tester, path: '/admin', session: null, productionRouter: true);
    expect(
      find.text('Bạn không có quyền truy cập khu vực này'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  for (final path in [
    '/admin/dashboard',
    '/admin/orders',
    '/admin/orders/MC-2601',
    '/admin/providers',
    '/admin/finance',
    '/admin/requests',
  ]) {
    testWidgets('$path displays loading and empty states', (tester) async {
      await _open(
        tester,
        path: path,
        settle: false,
        repository: MockAdminRepository(clock: () => _now, empty: true),
      );
      expect(find.byType(CircularProgressIndicator), findsWidgets);
      if (path == '/admin/dashboard') {
        expect(find.byType(DropdownButton<String>), findsOneWidget);
      }
      await tester.pumpAndSettle();
      expect(find.text('Không có dữ liệu'), findsWidgets);
      if (path == '/admin/dashboard') {
        await _tap(tester, find.byType(DropdownButton<String>));
        await _tap(tester, find.text('30 ngày').last);
        expect(
          tester
              .widget<DropdownButton<String>>(
                find.byType(DropdownButton<String>),
              )
              .value,
          '30 ngày',
        );
      }
      expect(tester.takeException(), isNull);
    });
    testWidgets('$path displays network error and recovers with retry', (
      tester,
    ) async {
      await _open(
        tester,
        path: path,
        repository: MockAdminRepository(clock: () => _now)
          ..nextErrors[path == '/admin/dashboard'
              ? '/admin/dashboard/summary'
              : path == '/admin/providers'
              ? '/admin/providers/pending'
              : path == '/admin/finance'
              ? '/admin/reconciliation'
              : path == '/admin/requests'
              ? '/admin/refunds/pending'
              : '/admin/orders'] = const AdminException(
            'Mất kết nối thử nghiệm',
          ),
      );
      expect(find.text('Không thể tải dữ liệu'), findsWidgets);
      if (path == '/admin/dashboard') {
        expect(find.byType(DropdownButton<String>), findsOneWidget);
      }
      await _tap(tester, find.text('Thử lại / Retry').first);
      expect(find.text('Không thể tải dữ liệu'), findsNothing);
      if (path == '/admin/dashboard') {
        expect(find.byType(DropdownButton<String>), findsOneWidget);
        expect(find.text('Trạng thái hệ thống'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }

  for (final path in [
    '/admin/dashboard',
    '/admin/orders',
    '/admin/orders/MC-2604',
    '/admin/providers',
    '/admin/finance',
    '/admin/requests',
    '/admin/account',
  ]) {
    testWidgets('$path supports 320 px with large text', (tester) async {
      await _open(tester, path: path, size: const Size(320, 568), scale: 1.5);
      expect(tester.takeException(), isNull);
      if (path == '/admin/dashboard') {
        for (var index = 1; index < 5; index++) {
          await _selectDashboardFilter(tester, index);
          expect(tester.takeException(), isNull);
        }
        await _tap(tester, find.byTooltip('Tài khoản'));
        expect(find.text('Tài khoản Quản trị'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
      if (path == '/admin/requests') {
        await _tap(tester, find.text('Tranh chấp giá (2)'));
        expect(tester.takeException(), isNull);
        await _tap(tester, find.text('Rút tiền (2)'));
        expect(tester.takeException(), isNull);
      }
      if (path == '/admin/finance') {
        for (final name in ['held', 'credited', 'collected']) {
          await _tap(
            tester,
            find.byKey(ValueKey('admin-finance-filter-$name')),
          );
          expect(tester.takeException(), isNull);
        }
        final last = find.byKey(const ValueKey('admin-invoice-MC-2608'));
        await tester.ensureVisible(last);
        await tester.pumpAndSettle();
        final bar = find.byType(AdminFloatingBottomNav);
        expect(
          tester.getBottomLeft(last).dy,
          lessThan(tester.getTopLeft(bar).dy),
        );
        expect(tester.takeException(), isNull);
      }
    });
  }

  testWidgets('Finance balance pills animate repository totals and selection', (
    tester,
  ) async {
    await _open(
      tester,
      path: '/admin/finance',
      now: DateTime(2026, 10, 18, 14, 29),
    );
    final card = find.byType(AdminBalanceCard);
    Finder amount(int value) =>
        find.descendant(of: card, matching: find.text(adminMoney(value)));
    Finder filter(String name) =>
        find.byKey(ValueKey('admin-finance-filter-$name'));
    expect(amount(1350000), findsOneWidget);
    expect(find.text('Tổng tiền khách chuyển'), findsOneWidget);
    expect(find.text('Giao dịch gần nhất: 18/10/2026 • 14:05'), findsOneWidget);
    await _capture(tester, 'admin-finance-mobile');

    await tester.tap(filter('held'));
    await tester.pump(const Duration(milliseconds: 80));
    expect(amount(910000), findsOneWidget);
    await tester.tap(filter('credited'));
    await tester.pumpAndSettle();
    expect(amount(280000), findsOneWidget);
    expect(amount(1350000), findsNothing);
    expect(amount(910000), findsNothing);
    expect(find.text('Đã quyết toán ví thợ'), findsOneWidget);
    expect(
      tester.widget<Semantics>(filter('credited')).properties.selected,
      isTrue,
    );
    expect(
      tester.widget<Semantics>(filter('held')).properties.selected,
      isFalse,
    );
    await _tap(tester, filter('collected'));
    expect(amount(1350000), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Invoice activity keeps payment states and reconciliation details',
    (tester) async {
      await _open(
        tester,
        path: '/admin/finance',
        now: DateTime(2026, 10, 18, 14, 29),
      );
      Finder row(String id) => find.byKey(ValueKey('admin-invoice-$id'));
      Finder state(String id, String label) =>
          find.descendant(of: row(id), matching: find.text(label));
      expect(state('MC-2601', 'Đã thanh toán'), findsOneWidget);
      expect(state('MC-2602', 'Chờ quyết toán'), findsOneWidget);
      expect(state('MC-2603', 'Chờ thanh toán'), findsOneWidget);
      expect(state('MC-2605', 'Đã hoàn tiền'), findsOneWidget);
      expect(state('MC-2606', 'Cần đối soát'), findsOneWidget);
      expect(state('MC-2608', 'Không áp dụng'), findsOneWidget);
      await Scrollable.ensureVisible(
        tester.element(find.byType(AdminInvoiceActivity)),
        alignment: 0,
      );
      await tester.pumpAndSettle();
      await _capture(tester, 'admin-finance-invoices-mobile');
      await _tap(tester, row('MC-2606'));
      expect(find.text('Đối soát MC-2606'), findsOneWidget);
      expect(find.text('SB-PAY-2606'), findsOneWidget);
      expect(find.text('Tổng thu'), findsOneWidget);
      expect(find.text('Tổng cộng ví thợ'), findsOneWidget);
      expect(find.text('Bất thường'), findsOneWidget);
      await _tap(tester, find.text('Lý do / Ghi chú'));
      expect(find.textContaining('Tổng thu − hoàn − cộng ví'), findsOneWidget);
      await _tap(tester, find.byTooltip('Đóng chi tiết đối soát'));
      expect(find.text('Đối soát MC-2606'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Finance list and tablet rail render all six destinations', (
    tester,
  ) async {
    await _open(
      tester,
      path: '/admin/finance',
      size: const Size(1440, 1000),
      now: DateTime(2026, 10, 18, 14, 29),
    );
    expect(find.byType(AdminInvoiceActivity), findsOneWidget);
    expect(find.text('MC-2601'), findsOneWidget);
    expect(
      tester.widget<NavigationRail>(find.byType(NavigationRail)).destinations,
      hasLength(6),
    );
    await _capture(tester, 'admin-finance-desktop');
    expect(tester.takeException(), isNull);
    tester.view.physicalSize = const Size(800, 900);
    await tester.pumpAndSettle();
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(AdminInvoiceActivity), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Request cards retain source and amounts without customer identity',
    (tester) async {
      await _open(tester, path: '/admin/requests');
      expect(find.text('Khách hàng'), findsNothing);
      expect(find.text('Trần Bảo Ngọc'), findsNothing);
      expect(find.text('Mã đơn hàng:'), findsNWidgets(3));
      expect(find.text('Trạng thái'), findsNothing);
      final refund = find.byKey(const ValueKey('admin-refund-RF-01'));
      Finder field(String label) =>
          find.descendant(of: refund, matching: find.text(label));
      expect(field('SB-RF-01'), findsOneWidget);
      expect(field(adminMoney(50000)), findsOneWidget);
      expect(
        tester.getTopLeft(field('Nguồn yêu cầu')).dy,
        tester.getTopLeft(field('Tiền hoàn')).dy,
      );
      expect(
        tester.getTopLeft(field('Lý do')).dy,
        tester.getTopLeft(field('Mã Sandbox')).dy,
      );
      await _capture(tester, 'admin-requests-refunds-mobile');
      await _tap(tester, find.text('Tranh chấp giá (2)'));
      await _capture(tester, 'admin-requests-disputes-mobile');
      await _tap(tester, find.text('Rút tiền (2)'));
      await _capture(tester, 'admin-requests-mobile');
      tester.view.physicalSize = const Size(1440, 1000);
      await tester.pumpAndSettle();
      final cards = find.byType(AdminReviewCard);
      expect(
        tester.getTopLeft(cards.at(0)).dy,
        tester.getTopLeft(cards.at(1)).dy,
      );
      expect(
        tester.getTopLeft(cards.at(0)).dx,
        lessThan(tester.getTopLeft(cards.at(1)).dx),
      );
      await _capture(tester, 'admin-requests-desktop');
      expect(tester.takeException(), isNull);
    },
  );
}
