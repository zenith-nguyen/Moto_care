import 'dart:async';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:moto_care/core/router/app_router.dart';
import 'package:moto_care/core/theme/app_theme.dart';
import 'package:moto_care/features/activity/models/rescue_order.dart';
import 'package:moto_care/features/activity/providers/activity_provider.dart';
import 'package:moto_care/features/chat/screens/chat_detail_screen.dart';
import 'package:moto_care/features/home/screens/home_screen.dart';
import 'package:moto_care/features/home/models/home_discovery.dart';
import 'package:moto_care/features/home/providers/home_discovery_provider.dart';
import 'package:moto_care/features/partner/screens/partner_detail_screen.dart';
import 'package:moto_care/features/partner/providers/partner_cart_provider.dart';
import 'package:moto_care/features/rescue/providers/service_rating_provider.dart';
import 'package:moto_care/features/rescue_station/models/station_model.dart';
import 'package:moto_care/features/rescue_station/providers/station_details_provider.dart';
import 'package:moto_care/features/rescue_station/screens/mechanic_reviews_screen.dart';
import 'package:moto_care/features/rescue_station/screens/station_detail_screen.dart';
import 'package:moto_care/features/rescue_station/services/station_share_service.dart';
import 'package:moto_care/features/rescue_station/theme/station_detail_theme.dart';
import 'package:moto_care/features/rescue_station/widgets/station_photo_carousel.dart';
import 'package:moto_care/features/rescue_station/widgets/service_catalog_details_sheet.dart';

import 'fixtures/home_scroll_helpers.dart';

Finder _key(String name) => find.byKey(ValueKey(name));

RescueOrder _completed(String id, String partnerId) => RescueOrder(
  id: id,
  orderCode: id,
  status: RescueOrderStatus.completed,
  serviceType: RescueServiceType.flatTire,
  userVehicle: 'Honda Vision',
  locationAddress: 'Quận 1',
  basePrice: 50000,
  extraPartPrice: 0,
  discount: 0,
  createdAt: DateTime(2026, 10, 9),
  partnerId: partnerId,
);

Future<GoRouter> _open(
  WidgetTester tester, {
  String path = '/stations/station-mobile',
  Future<void> Function(ShareParams)? share,
  Map<String, StationProfile>? profiles,
  List<RescueOrder> orders = const [],
}) async {
  final router = createAppRouter();
  addTearDown(router.dispose);
  addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        initialRescueOrdersProvider.overrideWithValue(orders),
        if (profiles != null)
          stationProfilesProvider.overrideWithValue(profiles),
        stationShareServiceProvider.overrideWithValue(
          StationShareService(share: share ?? (_) async {}),
        ),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light,
        locale: const Locale('vi'),
        supportedLocales: const [Locale('vi')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        routerConfig: router,
      ),
    ),
  );
  router.go(path);
  await tester.pumpAndSettle();
  return router;
}

ProviderContainer _state(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(StationDetailScreen)));

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'Home opens a typed station profile and Back preserves browsing',
    (tester) async {
      final router = await _open(tester, path: '/trang-chu');
      await _tap(tester, _key('home-category-fastest'));
      await scrollHomeToStations(tester);
      await _tap(tester, _key('home-station-station-mobile'));
      expect(router.state.uri.path, '/stations/station-mobile');
      expect(
        tester
            .widget<StationDetailScreen>(find.byType(StationDetailScreen))
            .station
            .id,
        'station-mobile',
      );
      expect(_state(tester).read(activityProvider).orders, isEmpty);
      await _tap(tester, _key('station-back'));
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(
        ProviderScope.containerOf(tester.element(find.byType(HomeScreen)))
            .read(homeDiscoveryProvider)
            .category,
        HomeStationCategory.fastest,
      );
    },
  );

  testWidgets('Directory cards open the same selected station', (tester) async {
    final router = await _open(tester, path: '/tram-cuu-ho');
    await _tap(tester, find.text('Cứu hộ Minh Tuấn'));
    expect(router.state.uri.path, '/stations/station-tuan');
    expect(
      tester
          .widget<StationDetailScreen>(find.byType(StationDetailScreen))
          .station
          .id,
      'station-tuan',
    );
  });

  testWidgets('Route identity takes precedence over a mismatched model extra', (
    tester,
  ) async {
    final router = await _open(tester);
    final other = _state(tester).read(stationModelProvider('station-mobile'))!;
    router.push('/stations/station-tuan', extra: other);
    await tester.pumpAndSettle();
    expect(find.text('Cứu hộ Minh Tuấn'), findsOneWidget);
    expect(
      tester
          .widget<StationDetailScreen>(find.byType(StationDetailScreen))
          .station
          .id,
      'station-tuan',
    );
  });

  testWidgets('Profile renders directory metadata and real booking prices', (
    tester,
  ) async {
    await _open(tester);
    final state = _state(tester);
    final model = state.read(stationModelProvider('station-mobile'))!;
    expect(find.text(model.name), findsOneWidget);
    expect(find.text(model.address), findsOneWidget);
    expect(find.text('Đã xác minh'), findsOneWidget);
    expect(find.text('4.7 (214)'), findsOneWidget);
    expect(find.text('12 Thợ'), findsOneWidget);
    expect(find.text('Bảo hành'), findsOneWidget);
    expect(find.byType(CarouselSlider), findsOneWidget);
    expect(find.text('1/1'), findsOneWidget);
    await tester.ensureVisible(_key('station-service-battery-jump'));
    await tester.pumpAndSettle();
    expect(find.text('40.000 đ'), findsOneWidget);
    expect(find.text('50.000 đ'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(_key('station-book'))
          .style!
          .backgroundColor!
          .resolve({}),
      StationDetailColors.red,
    );
    expect(state.read(activityProvider).orders, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Service cards show their own details without selecting or booking',
    (tester) async {
      final router = await _open(
        tester,
        orders: [_completed('existing', 'station-mobile')],
      );
      final state = _state(tester);
      final model = state.read(stationModelProvider('station-mobile'))!;
      final cart = partnerCartProvider((Object(), model.id, 'Vá xe'));
      final keepCart = state.listen(cart, (_, _) {});
      addTearDown(keepCart.close);
      state.read(cart.notifier).setQuantity('tire-tubeless', 2);
      final orders = state.read(activityProvider).orders;
      for (final service in model.serviceCatalog) {
        final card = _key('station-service-${service.id}');
        await tester.ensureVisible(card);
        await tester.pumpAndSettle();
        final scroll = tester
            .state<ScrollableState>(
              find
                  .descendant(
                    of: _key('station-detail-scroll'),
                    matching: find.byType(Scrollable),
                  )
                  .first,
            )
            .position;
        final offset = scroll.pixels;
        await tester.tap(card);
        await tester.pumpAndSettle();
        final sheet = find.byType(ServiceCatalogDetailsSheet);
        expect(sheet, findsOneWidget);
        expect(find.text('Chi tiết Quy trình Dịch vụ'), findsOneWidget);
        for (final text in [
          service.name,
          ...service.details!.procedureSteps,
          service.details!.materialsCommitment,
          service.details!.warranty,
        ]) {
          expect(
            find.descendant(of: sheet, matching: find.text(text)),
            findsOneWidget,
          );
        }
        expect(state.read(cart), {'tire-tubeless': 2});
        expect(state.read(activityProvider).orders, orders);
        expect(router.state.uri.path, '/stations/station-mobile');
        await tester.tap(find.byTooltip('Đóng chi tiết dịch vụ'));
        await tester.pumpAndSettle();
        expect(sheet, findsNothing);
        expect(scroll.pixels, offset);
        expect(tester.takeException(), isNull);
      }
      await _tap(tester, _key('station-book'));
      expect(find.byType(PartnerDetailScreen), findsOneWidget);
    },
  );

  testWidgets(
    'Unconfigured services ask the station instead of inventing a warranty',
    (tester) async {
      await _open(tester, path: '/stations/station-tuan');
      await _tap(tester, _key('station-service-tire-tubeless'));
      expect(
        find.text('Bảo hành miếng vá 30 ngày tại vị trí đã vá.'),
        findsNothing,
      );
      expect(
        find.text(
          'Trạm chưa công bố quy trình chi tiết. Liên hệ trạm để được tư vấn phương án xử lý.',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'Trạm chưa công bố thời hạn bảo hành cho dịch vụ này. Vui lòng xác nhận trực tiếp với trạm.',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Booking preserves station and selected Home service category', (
    tester,
  ) async {
    final router = await _open(
      tester,
      path: '/stations/station-tuan?service=Vá%20xe',
    );
    await _tap(tester, _key('station-book'));
    expect(router.state.uri.path, '/partners/station-tuan');
    final detail = tester.widget<PartnerDetailScreen>(
      find.byType(PartnerDetailScreen),
    );
    expect(detail.partnerId, 'station-tuan');
    expect(detail.serviceType, 'Vá xe');
    expect(_key('package-tire-tubeless'), findsOneWidget);
    expect(_key('package-battery-jump'), findsNothing);
  });

  testWidgets('Closed stations disable booking while chat remains available', (
    tester,
  ) async {
    await _open(tester, path: '/stations/station-thanh');
    expect(find.text('Đang đóng cửa'), findsOneWidget);
    expect(find.text('Đã xác minh'), findsNothing);
    expect(tester.widget<FilledButton>(_key('station-book')).onPressed, isNull);
    expect(_key('station-chat').hitTestable(), findsOneWidget);
    expect(find.text('12 Thợ'), findsNothing);
  });

  testWidgets('Bookmarks survive other routes and stay scoped to station ID', (
    tester,
  ) async {
    final router = await _open(tester);
    final state = _state(tester);
    await _tap(tester, _key('station-favorite'));
    expect(state.read(stationFavoritesProvider), {'station-mobile'});
    await _tap(tester, _key('station-reviews'));
    expect(find.byType(MechanicReviewsScreen), findsOneWidget);
    // Station profiles always show community reviews now, so the empty-state
    // message is no longer rendered.
    expect(find.text('Chưa có nhận xét để hiển thị.'), findsNothing);
    await _tap(tester, find.byTooltip('Quay lại'));
    await tester.drag(_key('station-detail-scroll'), const Offset(0, 500));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Bỏ lưu trạm'), findsOneWidget);
    router.push('/stations/station-tuan');
    await tester.pumpAndSettle();
    expect(find.byTooltip('Lưu trạm'), findsOneWidget);
    router.pop();
    await tester.pumpAndSettle();
    await _tap(tester, _key('station-favorite'));
    expect(state.read(stationFavoritesProvider), isEmpty);
  });

  testWidgets('Review list includes only confirmed reviews for this partner', (
    tester,
  ) async {
    await _open(
      tester,
      orders: [
        _completed('own-review', 'station-mobile'),
        _completed('other-review', 'station-tuan'),
      ],
    );
    final state = _state(tester);
    await state
        .read(serviceRatingsProvider.notifier)
        .submit(
          'own-review',
          stars: 5,
          tagIds: {},
          comment: 'Thợ hỗ trợ rất nhanh',
        );
    await state
        .read(serviceRatingsProvider.notifier)
        .submit('other-review', stars: 2, tagIds: {}, comment: 'Một trạm khác');
    await _tap(tester, _key('station-reviews'));
    expect(_key('station-review-own-review'), findsOneWidget);
    expect(find.text('Thợ hỗ trợ rất nhanh'), findsOneWidget);
    expect(find.text('Một trạm khác'), findsNothing);
  });

  testWidgets(
    'Chat receives the selected station contact without a fake assignment',
    (tester) async {
      final router = await _open(tester, path: '/stations/station-tuan');
      final station = _state(tester)
          .read(stationModelProvider('station-tuan'))!;
      await _tap(tester, _key('station-chat'));
      expect(router.state.uri.path, '/chat-detail');
      final chat = tester
          .widget<ChatDetailScreen>(find.byType(ChatDetailScreen))
          .conversation!;
      expect(chat.mechanicName, station.name);
      expect(chat.phoneNumber, station.station.phoneNumber);
      expect(chat.statusLabel, station.openingLabel);
      expect(chat.licensePlate, 'Chưa có đơn cứu hộ');
    },
  );

  testWidgets(
    'Share sends this station and a valid button origin; errors allow retry',
    (tester) async {
      ShareParams? params;
      var attempts = 0;
      await _open(
        tester,
        share: (value) async {
          params = value;
          if (++attempts == 1) throw Exception('Unavailable');
        },
      );
      final station = _state(tester)
          .read(stationModelProvider('station-mobile'))!;
      await _tap(tester, _key('station-share'));
      expect(params!.text, contains(station.address));
      expect(params!.text, contains(station.station.phoneNumber));
      expect(params!.text, contains(station.mapUri.toString()));
      expect(params!.sharePositionOrigin!.width, greaterThan(0));
      expect(
        find.text('Không thể chia sẻ thông tin trạm. Vui lòng thử lại.'),
        findsOneWidget,
      );
      await _tap(tester, _key('station-share'));
      expect(attempts, 2);
      expect(find.byType(StationDetailScreen), findsOneWidget);
    },
  );

  testWidgets(
    'Pending share prevents duplicate launches and tolerates leaving the route',
    (tester) async {
      final pending = Completer<void>();
      var count = 0;
      final router = await _open(
        tester,
        share: (_) {
          count++;
          return pending.future;
        },
      );
      await tester.tap(_key('station-share'));
      await tester.pump();
      expect(
        tester.widget<IconButton>(_key('station-share')).onPressed,
        isNull,
      );
      expect(count, 1);
      router.go('/trang-chu');
      await tester.pumpAndSettle();
      pending.complete();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Gallery swipes update the photo counter; empty galleries recover',
    (tester) async {
      await _open(
        tester,
        profiles: {
          'station-mobile': StationProfile(
            description: 'Trạm có hai ảnh',
            imageAssets: [
              'assets/images/repair-shop-1.png',
              'assets/images/repair-shop-2.png',
            ],
          ),
        },
      );
      expect(find.text('1/2'), findsOneWidget);
      await tester.drag(find.byType(CarouselSlider), const Offset(-550, 0));
      await tester.pumpAndSettle();
      expect(find.text('2/2'), findsOneWidget);
      await tester.pumpWidget(
        MaterialApp(
          home: StationPhotoCarousel(
            images: const [],
            height: 300,
            favorite: false,
            onBack: () {},
            onFavorite: () {},
            onShare: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.storefront_outlined), findsOneWidget);
      expect(find.byType(CarouselSlider), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Unknown station deep links recover without borrowing another station',
    (tester) async {
      final router = await _open(tester, path: '/stations/missing/reviews');
      expect(find.text('Trạm không còn trong danh sách.'), findsOneWidget);
      expect(find.byType(StationDetailScreen), findsNothing);
      await _tap(tester, find.text('Về Trang chủ'));
      expect(router.state.uri.path, '/trang-chu');
    },
  );

  testWidgets(
    '320px and large text keep both actions accessible while content scrolls',
    (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _open(tester);
      expect(_key('station-book').hitTestable(), findsOneWidget);
      expect(_key('station-chat').hitTestable(), findsOneWidget);
      await tester.scrollUntilVisible(
        _key('station-service-towing'),
        180,
        scrollable: find
            .descendant(
              of: _key('station-detail-scroll'),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      expect(_key('station-service-towing').hitTestable(), findsOneWidget);
      expect(_key('station-book').hitTestable(), findsOneWidget);
      await tester.tap(_key('station-service-towing'));
      await tester.pumpAndSettle();
      expect(
        find.byTooltip('Đóng chi tiết dịch vụ').hitTestable(),
        findsOneWidget,
      );
      await tester.ensureVisible(find.text('Thời gian bảo hành'));
      await tester.pumpAndSettle();
      expect(find.text('Thời gian bảo hành').hitTestable(), findsOneWidget);
      await tester.tap(find.byTooltip('Đóng chi tiết dịch vụ'));
      await tester.pumpAndSettle();
      expect(_key('station-book').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
