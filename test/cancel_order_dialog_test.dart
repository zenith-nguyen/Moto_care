import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revo/core/theme/app_theme.dart';
import 'package:revo/features/activity/models/order_cancellation_reason.dart';
import 'package:revo/features/activity/widgets/cancel_order_dialog.dart';

Finder _key(String value) => find.byKey(ValueKey(value));

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _open(
  WidgetTester tester,
  ValueChanged<OrderCancellationReason?> onResult,
) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light.copyWith(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: Colors.red),
        ),
      ),
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              onResult(
                await showDialog<OrderCancellationReason>(
                  context: context,
                  builder: (_) => const CancelOrderDialog(),
                ),
              );
            },
            child: const Text('Mở hộp hủy'),
          ),
        ),
      ),
    ),
  );
  await _tap(tester, find.text('Mở hộp hủy'));
}

void main() {
  testWidgets('Quick selection enables blue confirmation and retains notes', (
    tester,
  ) async {
    OrderCancellationReason? result;
    await _open(tester, (value) => result = value);
    final button = _key('cancel-confirm');
    expect(tester.widget<FilledButton>(button).onPressed, isNull);
    await _tap(tester, _key('cancel-reason-long_wait'));
    await _tap(tester, _key('cancel-reason-mechanic_unavailable'));
    expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
    expect(
      tester.widget<FilledButton>(button).style!.backgroundColor!.resolve({}),
      const Color(0xFF1976D2),
    );
    await tester.enterText(
      _key('cancel-custom-reason'),
      '  Không nhận cuộc gọi  ',
    );
    await _tap(tester, button);
    expect(find.byType(CancelOrderDialog), findsNothing);
    expect(result!.code, 'mechanic_unavailable');
    expect(result!.details, 'Không nhận cuộc gọi');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Other needs text and whitespace cannot enable confirmation', (
    tester,
  ) async {
    OrderCancellationReason? result;
    await _open(tester, (value) => result = value);
    await _tap(tester, _key('cancel-reason-other'));
    final input = _key('cancel-custom-reason');
    expect(tester.widget<TextField>(input).focusNode!.hasFocus, isTrue);
    await tester.enterText(input, '   \n  ');
    expect(
      tester.widget<FilledButton>(_key('cancel-confirm')).onPressed,
      isNull,
    );
    await tester.enterText(input, '  Bạn đã giúp tôi sửa xe  ');
    await tester.pump();
    expect(
      tester.widget<FilledButton>(_key('cancel-confirm')).onPressed,
      isNotNull,
    );
    await tester.enterText(input, '');
    await tester.pump();
    expect(
      tester.widget<FilledButton>(_key('cancel-confirm')).onPressed,
      isNull,
    );
    await tester.enterText(input, '  Bạn đã giúp tôi sửa xe  ');
    await _tap(tester, _key('cancel-confirm'));
    expect(result!.code, 'other');
    expect(result!.details, 'Bạn đã giúp tôi sửa xe');
  });

  testWidgets(
    'Typing alone is a valid custom reason and keeping order discards it',
    (tester) async {
      var dismissed = false;
      OrderCancellationReason? result;
      await _open(tester, (value) {
        dismissed = true;
        result = value;
      });
      await tester.enterText(
        _key('cancel-custom-reason'),
        'Tôi cần đổi vị trí',
      );
      await tester.pump();
      expect(
        tester.widget<FilledButton>(_key('cancel-confirm')).onPressed,
        isNotNull,
      );
      await _tap(tester, _key('cancel-keep-order'));
      expect(dismissed, isTrue);
      expect(result, isNull);
      await _tap(tester, find.text('Mở hộp hủy'));
      expect(
        tester.widget<TextField>(_key('cancel-custom-reason')).controller!.text,
        isEmpty,
      );
      expect(
        tester.widget<FilledButton>(_key('cancel-confirm')).onPressed,
        isNull,
      );
      await tester.enterText(
        _key('cancel-custom-reason'),
        'Tôi cần đổi vị trí',
      );
      await _tap(tester, _key('cancel-confirm'));
      expect(result!.code, 'other');
      expect(result!.details, 'Tôi cần đổi vị trí');
    },
  );

  testWidgets(
    '320px, large text and keyboard keep custom reason and actions reachable',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      OrderCancellationReason? result;
      await _open(tester, (value) => result = value);
      await _tap(tester, _key('cancel-reason-other'));
      tester.view.viewInsets = const FakeViewPadding(bottom: 240);
      await tester.pumpAndSettle();
      await _tap(tester, _key('cancel-custom-reason'));
      await tester.enterText(_key('cancel-custom-reason'), 'Cần đổi điểm đón');
      await _tap(tester, _key('cancel-confirm'));
      expect(result!.details, 'Cần đổi điểm đón');
      expect(tester.takeException(), isNull);
    },
  );
}
