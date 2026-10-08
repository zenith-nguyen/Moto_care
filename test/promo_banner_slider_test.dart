import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:moto_care/features/home/theme/home_theme.dart';
import 'package:moto_care/features/home/widgets/promo_banner_slider.dart';

Future<void> _openSlider(WidgetTester tester, {bool enabled = true}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 360,
            child: TickerMode(
              enabled: enabled,
              child: const PromoBannerSlider(),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void _expectPage(WidgetTester tester, int page) {
  final controller = tester.widget<PageView>(find.byType(PageView)).controller!;
  expect(controller.page, closeTo(page.toDouble(), 0.01));
  expect(find.bySemanticsLabel('Banner ${page + 1} trên 3'), findsOneWidget);
  for (var index = 0; index < 3; index++) {
    final dot = tester.widget<AnimatedContainer>(
      find.byKey(ValueKey('promo-dot-$index')),
    );
    expect(
      (dot.decoration! as BoxDecoration).color,
      index == page ? HomeColors.red : isNot(HomeColors.red),
    );
  }
}

Future<void> _swipe(WidgetTester tester, {bool forward = true}) async {
  await tester.drag(find.byType(PageView), Offset(forward ? -300 : 300, 0));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Swiping shows all three promotions and updates the dots', (
    tester,
  ) async {
    await _openSlider(tester);
    _expectPage(tester, 0);
    expect(
      find.image(const AssetImage('assets/images/Banner1.png')),
      findsOneWidget,
    );
    expect(find.text('CỨU HỘ 24/7'), findsNothing);
    expect(find.text('Phục vụ xuyên đêm khẩn cấp'), findsNothing);

    await _swipe(tester);
    _expectPage(tester, 1);
    expect(
      find.image(const AssetImage('assets/images/Banner2.png')),
      findsOneWidget,
    );
    expect(find.text('ƯU ĐÃI THÁNG NÀY'), findsNothing);
    expect(find.text('Giảm 20k đơn cứu hộ đầu tiên'), findsNothing);

    await _swipe(tester);
    _expectPage(tester, 2);
    expect(
      find.image(const AssetImage('assets/images/Banner3.png')),
      findsOneWidget,
    );
    expect(find.text('BẢO DƯỠNG XE MÁY'), findsNothing);
    expect(find.text('Đội ngũ thợ uy tín tận nơi'), findsNothing);

    await _swipe(tester, forward: false);
    _expectPage(tester, 1);
  });

  testWidgets('Auto scroll waits four seconds and loops back to the first', (
    tester,
  ) async {
    await _openSlider(tester);
    await tester.pump(const Duration(milliseconds: 3800));
    _expectPage(tester, 0);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    _expectPage(tester, 1);

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    _expectPage(tester, 2);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    _expectPage(tester, 0);
  });

  testWidgets('A manual swipe restarts the four-second interval', (
    tester,
  ) async {
    await _openSlider(tester);
    await tester.pump(const Duration(seconds: 3));
    await _swipe(tester);
    _expectPage(tester, 1);

    await tester.pump(const Duration(seconds: 3));
    _expectPage(tester, 1);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    _expectPage(tester, 2);
  });

  testWidgets('Tapping a banner or dot keeps the same page', (tester) async {
    await _openSlider(tester);
    await tester.tap(find.image(const AssetImage('assets/images/Banner1.png')));
    await tester.tap(find.byKey(const ValueKey('promo-dot-2')));
    await tester.pumpAndSettle();

    _expectPage(tester, 0);
    expect(find.byType(PromoBannerSlider), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Auto scroll pauses in the background and resumes on return', (
    tester,
  ) async {
    addTearDown(
      () => tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      ),
    );
    await _openSlider(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 10));
    _expectPage(tester, 0);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    _expectPage(tester, 1);
  });

  testWidgets('Auto scroll pauses when the home route is hidden', (
    tester,
  ) async {
    await _openSlider(tester);
    await _openSlider(tester, enabled: false);
    await tester.pump(const Duration(seconds: 10));
    _expectPage(tester, 0);

    await _openSlider(tester);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    _expectPage(tester, 1);
  });

  testWidgets('Small screens and large text preserve the banner aspect ratio', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await _openSlider(tester);
    for (var page = 0; page < 3; page++) {
      _expectPage(tester, page);
      final size = tester.getSize(find.byType(PageView));
      expect(size.width / size.height, closeTo(736 / 414, 0.01));
      expect(tester.takeException(), isNull);
      if (page < 2) await _swipe(tester);
    }
  });

  testWidgets('Removing the slider cancels pending auto scroll', (
    tester,
  ) async {
    await _openSlider(tester);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 12));
    expect(tester.takeException(), isNull);
  });
}
