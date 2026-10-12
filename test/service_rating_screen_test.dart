import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moto_care/core/router/app_router.dart';
import 'package:moto_care/core/services/attachment_service.dart';
import 'package:moto_care/core/theme/app_theme.dart';
import 'package:moto_care/features/activity/models/rescue_order.dart';
import 'package:moto_care/features/activity/providers/activity_provider.dart';
import 'package:moto_care/features/home/screens/home_screen.dart';
import 'package:moto_care/features/rescue/models/service_rating.dart';
import 'package:moto_care/features/rescue/providers/service_rating_provider.dart';
import 'package:moto_care/features/rescue/services/service_rating_service.dart';
import 'package:moto_care/features/rescue/widgets/rating_stars.dart';

Uint8List _photo() => base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+a5i8AAAAASUVORK5CYII=',
);
RescueOrder _order({RescueOrderStatus status = RescueOrderStatus.completed}) =>
    RescueOrder(
      id: 'rated-001',
      orderCode: 'MC-RATING-001',
      status: status,
      serviceType: RescueServiceType.flatTire,
      userVehicle: 'Honda Vision',
      locationAddress: '273 An Dương Vương, Quận 5',
      providerName: 'Nguyễn Văn A',
      partnerName: 'Cứu hộ Siêu Tốc 24/7',
      basePrice: 50000,
      extraPartPrice: 0,
      discount: 0,
      createdAt: DateTime(2026, 10, 9),
      items: [
        RescueOrderItem(
          packageId: 'tire',
          name: 'Vá lốp không ruột',
          unitPrice: 50000,
          quantity: 1,
          serviceType: RescueServiceType.flatTire,
        ),
      ],
    );

Future<GoRouter> _open(
  WidgetTester tester, {
  RescueOrder? order,
  Future<Uint8List?> Function()? picker,
  Future<void> Function(ServiceRating)? submitter,
  String path = '/service-rating?id=rated-001',
}) async {
  final router = createAppRouter();
  addTearDown(router.dispose);
  addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        initialRescueOrdersProvider.overrideWithValue([order ?? _order()]),
        attachmentPickerProvider.overrideWithValue(
          picker ?? () async => _photo(),
        ),
        if (submitter != null)
          serviceRatingSubmitterProvider.overrideWithValue(submitter),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light,
        routerConfig: router,
        locale: const Locale('vi'),
        supportedLocales: const [Locale('vi')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
      ),
    ),
  );
  router.go(path);
  await tester.pumpAndSettle();
  return router;
}

Finder _key(String name) => find.byKey(ValueKey(name));
ProviderContainer _state(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
Future<void> _tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Completed invoices open a rating screen for the same order', (
    tester,
  ) async {
    final router = await _open(tester, path: '/chi-tiet-don-hang?id=rated-001');
    await tester.scrollUntilVisible(
      _key('open-service-rating'),
      160,
      scrollable: find.byType(Scrollable).last,
    );
    await _tap(tester, _key('open-service-rating'));
    expect(router.state.uri.path, '/service-rating');
    expect(router.state.uri.queryParameters['id'], 'rated-001');
    expect(find.text('Nguyễn Văn A'), findsOneWidget);
    expect(find.text('Cứu hộ Siêu Tốc 24/7'), findsOneWidget);
    expect(find.text('Vá lốp không ruột • 50.000đ'), findsOneWidget);
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      Colors.white,
    );
    expect(
      Theme.of(tester.element(find.byType(RatingStars)))
          .textTheme
          .bodyMedium!
          .fontFamily,
      'Montserrat',
    );
    await _tap(tester, find.byTooltip('Quay lại'));
    expect(router.state.uri.path, '/chi-tiet-don-hang');
  });

  testWidgets(
    'Stars select 1–5 and quick tags independently toggle red styling',
    (tester) async {
      await _open(tester);
      await _tap(tester, _key('service-rating-star-5'));
      expect(
        find.descendant(
          of: find.byType(RatingStars),
          matching: find.byIcon(Icons.star_rounded),
        ),
        findsNWidgets(5),
      );
      await _tap(tester, _key('service-rating-star-2'));
      expect(
        find.descendant(
          of: find.byType(RatingStars),
          matching: find.byIcon(Icons.star_rounded),
        ),
        findsNWidgets(2),
      );
      await _tap(tester, _key('service-rating-tag-fast'));
      await _tap(tester, _key('service-rating-tag-careful'));
      final selected = tester.widget<FilterChip>(
        _key('service-rating-tag-fast'),
      );
      expect(selected.selected, isTrue);
      expect(selected.selectedColor, const Color(0xFFFFEBEE));
      expect(selected.side!.color, const Color(0xFFE53935));
      expect(selected.labelStyle!.color, const Color(0xFFE53935));
      await _tap(tester, _key('service-rating-tag-fast'));
      expect(
        tester.widget<FilterChip>(_key('service-rating-tag-fast')).selected,
        isFalse,
      );
      expect(
        tester.widget<FilterChip>(_key('service-rating-tag-careful')).selected,
        isTrue,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Submit retains stars, tags, trimmed comment and image and returns Home with thanks',
    (tester) async {
      final sourcePhoto = _photo();
      ServiceRating? payload;
      final router = await _open(
        tester,
        picker: () async => sourcePhoto,
        submitter: (review) async => payload = review,
      );
      final state = _state(tester);
      await _tap(tester, _key('service-rating-star-4'));
      await _tap(tester, _key('service-rating-tag-skilled'));
      await _tap(tester, _key('service-rating-tag-transparent'));
      await tester.enterText(
        _key('service-rating-comment'),
        '  Xe chạy ổn, thợ sửa rất kỹ.  ',
      );
      await _tap(tester, _key('service-rating-add-photo'));
      expect(_key('service-rating-photo'), findsOneWidget);
      await _tap(tester, _key('service-rating-submit'));
      expect(router.state.uri.path, '/trang-chu');
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('Cảm ơn bạn đã đánh giá!'), findsOneWidget);
      final review = state.read(serviceRatingsProvider)['rated-001']!;
      expect(identical(payload, review), isTrue);
      expect(review.stars, 4);
      expect(review.tagIds, {'skilled', 'transparent'});
      expect(review.comment, 'Xe chạy ổn, thợ sửa rất kỹ.');
      expect(review.photo, sourcePhoto);
      expect(state.read(activityProvider).orderById('rated-001')!.rating, 4);
      sourcePhoto[0] = 0;
      expect(review.photo![0], 137);
      expect(() => review.photo![0] = 0, throwsUnsupportedError);
      router.push('/service-rating?id=rated-001');
      await tester.pumpAndSettle();
      expect(
        tester.widget<RatingStars>(find.byType(RatingStars)).selectedStars,
        4,
      );
      expect(
        tester
            .widget<TextField>(_key('service-rating-comment'))
            .controller!
            .text,
        review.comment,
      );
      expect(_key('service-rating-photo'), findsOneWidget);
    },
  );

  testWidgets(
    'No stars cannot submit, while optional comment and image may stay empty',
    (tester) async {
      final router = await _open(tester);
      final state = _state(tester);
      await _tap(tester, _key('service-rating-submit'));
      expect(router.state.uri.path, '/service-rating');
      expect(find.text('Vui lòng chọn từ 1 đến 5 sao.'), findsOneWidget);
      expect(state.read(serviceRatingsProvider), isEmpty);
      await _tap(tester, _key('service-rating-star-1'));
      await _tap(tester, _key('service-rating-submit'));
      expect(state.read(serviceRatingsProvider)['rated-001']!.stars, 1);
      expect(state.read(serviceRatingsProvider)['rated-001']!.comment, isEmpty);
      expect(state.read(serviceRatingsProvider)['rated-001']!.photo, isNull);
      expect(router.state.uri.path, '/trang-chu');
    },
  );

  testWidgets(
    'Skip returns Home without changing the order or saving a draft',
    (tester) async {
      final router = await _open(tester);
      final state = _state(tester);
      await _tap(tester, _key('service-rating-star-5'));
      await _tap(tester, _key('service-rating-skip'));
      expect(router.state.uri.path, '/trang-chu');
      expect(state.read(serviceRatingsProvider), isEmpty);
      expect(
        state.read(activityProvider).orderById('rated-001')!.rating,
        isNull,
      );
    },
  );

  testWidgets(
    'Photo cancellation preserves the thumbnail; remove clears it and picker errors remain recoverable',
    (tester) async {
      var attempts = 0;
      await _open(
        tester,
        picker: () async {
          attempts++;
          if (attempts == 1) return _photo();
          if (attempts == 2) return null;
          throw StateError('Vui lòng chọn ảnh nhỏ hơn 5 MB.');
        },
      );
      await _tap(tester, _key('service-rating-add-photo'));
      await _tap(tester, _key('service-rating-add-photo'));
      expect(_key('service-rating-photo'), findsOneWidget);
      await _tap(tester, _key('service-rating-remove-photo'));
      expect(_key('service-rating-photo'), findsNothing);
      await _tap(tester, _key('service-rating-add-photo'));
      expect(find.text('Vui lòng chọn ảnh nhỏ hơn 5 MB.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Failure preserves the draft and permits retry without a saved rating',
    (tester) async {
      var attempts = 0;
      final router = await _open(
        tester,
        submitter: (_) async {
          if (++attempts == 1) throw Exception('offline');
        },
      );
      await _tap(tester, _key('service-rating-star-3'));
      await tester.enterText(_key('service-rating-comment'), 'Đã sửa xong');
      await _tap(tester, _key('service-rating-submit'));
      expect(router.state.uri.path, '/service-rating');
      expect(
        find.text('Không thể gửi đánh giá. Vui lòng thử lại.'),
        findsOneWidget,
      );
      expect(_state(tester).read(serviceRatingsProvider), isEmpty);
      expect(
        tester
            .widget<TextField>(_key('service-rating-comment'))
            .controller!
            .text,
        'Đã sửa xong',
      );
      await _tap(tester, _key('service-rating-submit'));
      expect(attempts, 2);
      expect(router.state.uri.path, '/trang-chu');
    },
  );

  testWidgets('Pending submission disables repeated send and skip', (
    tester,
  ) async {
    final pending = Completer<void>();
    var attempts = 0;
    await _open(
      tester,
      submitter: (_) async {
        attempts++;
        await pending.future;
      },
    );
    await _tap(tester, _key('service-rating-star-5'));
    await tester.tap(_key('service-rating-submit'));
    await tester.pump();
    expect(
      tester.widget<FilledButton>(_key('service-rating-submit')).onPressed,
      isNull,
    );
    expect(
      tester.widget<TextButton>(_key('service-rating-skip')).onPressed,
      isNull,
    );
    expect(attempts, 1);
    pending.complete();
    await tester.pumpAndSettle();
    expect(_state(tester).read(serviceRatingsProvider).length, 1);
  });

  testWidgets(
    'Unknown IDs and unfinished orders never show a submission form',
    (tester) async {
      await _open(tester, path: '/service-rating?id=missing');
      expect(find.text('Không tìm thấy đơn cứu hộ.'), findsOneWidget);
      expect(_key('service-rating-submit'), findsNothing);
      await _open(tester, order: _order(status: RescueOrderStatus.enRoute));
      expect(
        find.text('Bạn có thể đánh giá sau khi đơn cứu hộ hoàn thành.'),
        findsOneWidget,
      );
      expect(_key('service-rating-submit'), findsNothing);
    },
  );

  testWidgets(
    'A late photo result after leaving the route cannot modify state',
    (tester) async {
      final pending = Completer<Uint8List?>();
      final router = await _open(tester, picker: () => pending.future);
      await tester.ensureVisible(_key('service-rating-add-photo'));
      await tester.tap(_key('service-rating-add-photo'));
      await tester.pump();
      router.go('/trang-chu');
      await tester.pumpAndSettle();
      pending.complete(_photo());
      await tester.pumpAndSettle();
      expect(_state(tester).read(serviceRatingsProvider), isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    '320px, large text and keyboard keep the form scrollable and actions usable',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final router = await _open(tester);
      await _tap(tester, _key('service-rating-star-5'));
      await tester.ensureVisible(_key('service-rating-comment'));
      await tester.enterText(_key('service-rating-comment'), 'Thợ đến nhanh');
      tester.view.viewInsets = const FakeViewPadding(bottom: 240);
      await tester.pumpAndSettle();
      expect(_key('service-rating-submit').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _tap(tester, _key('service-rating-submit'));
      expect(router.state.uri.path, '/trang-chu');
      tester.view.resetViewInsets();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'The service rejects invalid stars, unfinished orders and unknown tags',
    () {
      final service = ServiceRatingService(
        clock: () => DateTime.utc(2026, 10, 9),
      );
      for (final stars in [0, 6]) {
        expect(
          () => service.create(_order(), stars: stars, tagIds: {}, comment: ''),
          throwsStateError,
        );
      }
      expect(
        () => service.create(
          _order(status: RescueOrderStatus.cancelled),
          stars: 5,
          tagIds: {},
          comment: '',
        ),
        throwsStateError,
      );
      expect(
        () => service.create(
          _order(),
          stars: 5,
          tagIds: {'unknown'},
          comment: '',
        ),
        throwsStateError,
      );
      final tags = {'fast'};
      final review = service.create(
        _order(),
        stars: 5,
        tagIds: tags,
        comment: '  Cảm ơn!  ',
      );
      tags.clear();
      expect(review.tagIds, {'fast'});
      expect(() => review.tagIds.clear(), throwsUnsupportedError);
      expect(review.createdAt, DateTime.utc(2026, 10, 9));
      expect(
        service
            .create(
              _order(),
              stars: 5,
              tagIds: {},
              comment: List.filled(1000, '😊').join(),
            )
            .comment
            .length,
        2000,
      );
      expect(
        () => service.create(
          _order(),
          stars: 5,
          tagIds: {},
          comment: List.filled(1001, 'a').join(),
        ),
        throwsStateError,
      );
    },
  );
}
