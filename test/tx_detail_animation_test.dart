import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motocare_mechanic/data/mock_data.dart';
import 'package:motocare_mechanic/models/models.dart';
import 'package:motocare_mechanic/screens/wallet_transaction_detail_screen.dart';
import 'package:motocare_mechanic/state/app_state.dart';
import 'package:motocare_mechanic/theme/app_theme.dart';

void main() {
  final boundary = GlobalKey();
  var haptics = 0;

  setUp(() {
    appState.activeOrder = null;
    appState.history
      ..clear()
      ..addAll(MockData.history());
    appState.transactions
      ..clear()
      ..addAll(MockData.transactions());
    appState.balance = 1250000;
    haptics = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'HapticFeedback.vibrate') haptics++;
      return null;
    });
  });
  tearDown(() => TestDefaultBinaryMessengerBinding
      .instance.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.platform, null));

  WalletTransaction credit() =>
      appState.transactions.firstWhere((x) => x.code == '#RVO2298');

  Future<void> open(WidgetTester t, WalletTransaction tx,
      {bool reduce = false,
      Size size = const Size(412, 915),
      double scale = 1}) async {
    t.view.physicalSize = size;
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(RepaintBoundary(
        key: boundary,
        child: MaterialApp(
          theme: buildAppTheme(),
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                  disableAnimations: reduce,
                  textScaler: TextScaler.linear(scale)),
              child: child!),
          home: Scaffold(
              body: Builder(
                  builder: (context) => Center(
                      child: TextButton(
                          onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      WalletTransactionDetailScreen(tx: tx))),
                          child: const Text('open'))))),
        )));
    await t.tap(find.text('open'));
  }

  Future<void> shot(WidgetTester t, String name) async {
    const output = String.fromEnvironment('REVO_HOME_PIXELS_CAPTURE');
    if (output.isEmpty) return;
    await t.runAsync(() async {
      final r =
          boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final png = await r.toImage(pixelRatio: 2);
      final b = await png.toByteData(format: ui.ImageByteFormat.png);
      Directory(output).createSync(recursive: true);
      File('$output/$name.png').writeAsBytesSync(b!.buffer.asUint8List());
    });
  }

  Animation<double> scale(WidgetTester t) =>
      t.widget<ScaleTransition>(find.byKey(const ValueKey('tx-circle'))).scale;
  double fade(WidgetTester t, Finder f) => t
      .widget<FadeTransition>(
          find.ancestor(of: f, matching: find.byType(FadeTransition)).first)
      .opacity
      .value;
  final burst = find.byKey(const ValueKey('tx-burst'));

  testWidgets('Check pops, rays burst and vanish, content builds in order',
      (t) async {
    await open(t, credit());
    await t.pump();
    await t.pump(const Duration(milliseconds: 16));
    expect(scale(t).value, inInclusiveRange(.69, .8));
    expect(fade(t, find.text('+ 112.000đ')), 0);
    expect(fade(t, find.text('Giao dịch thành công')), 0);
    expect(fade(t, find.text('Sao chép biên nhận')), 0);
    await t.pump(const Duration(milliseconds: 290)); // ~300ms: peak
    expect(scale(t).value, inInclusiveRange(1.05, 1.0801));
    await shot(t, 'tx-300ms');
    expect(burst, findsOneWidget);
    await t.pump(const Duration(milliseconds: 300)); // ~600ms: settled
    expect(scale(t).value, inInclusiveRange(.99, 1.03));
    expect(fade(t, find.text('+ 112.000đ')), 0); // starts after the check
    await t.pump(const Duration(milliseconds: 300)); // ~900ms
    final amount = fade(t, find.text('+ 112.000đ'));
    expect(amount, inExclusiveRange(0, 1));
    await shot(t, 'tx-900ms');
    // Stagger: earlier items are always at least as visible as later ones.
    final order = [
      fade(t, find.text('Giao dịch thành công')),
      fade(t, find.text('Trần Văn Khách')),
      fade(t, find.text('Đơn hàng liên quan')),
      fade(t, find.text('Sao chép biên nhận')),
    ];
    for (var i = 1; i < order.length; i++) {
      expect(order[i - 1], greaterThanOrEqualTo(order[i]));
    }
    await t.pump(const Duration(milliseconds: 700));
    await t.pumpAndSettle();
    expect(scale(t).value, 1);
    expect(burst, findsNothing);
    for (final text in [
      '+ 112.000đ',
      'Giao dịch thành công',
      'Đơn hàng liên quan',
      'Sao chép biên nhận'
    ]) {
      expect(fade(t, find.text(text)), 1, reason: text);
    }
    expect(t.hasRunningAnimations, isFalse);
    await shot(t, 'tx-final');
  });

  testWidgets('Haptic fires once; amount/IDs are untouched; buttons work',
      (t) async {
    final tx = credit();
    final balance = appState.balance;
    final count = appState.transactions.length;
    await open(t, tx);
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
    expect(haptics, 1);
    await t.pumpAndSettle();
    expect(haptics, 1);
    expect(find.text('+ 112.000đ'), findsOneWidget);
    expect(find.text(tx.txnId), findsOneWidget);
    expect(find.text(tx.orderCode!), findsWidgets);
    await t.tap(find.text('Sao chép biên nhận'));
    await t.pump();
    expect(find.text('Đã sao chép biên nhận.'), findsOneWidget);
    expect(appState.balance, balance);
    expect(appState.transactions.length, count);
  });

  testWidgets('Opening it again plays the animation again', (t) async {
    await open(t, credit());
    await t.pumpAndSettle();
    await t.tap(find.byTooltip('Quay lại'));
    await t.pumpAndSettle();
    await t.tap(find.text('open'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 16));
    expect(scale(t).value, lessThan(.8));
    expect(haptics, 2);
    await t.pumpAndSettle();
    expect(scale(t).value, 1);
  });

  testWidgets('Reduced motion: static from the first frame, no haptic',
      (t) async {
    await open(t, credit(), reduce: true);
    await t.pumpAndSettle();
    expect(scale(t).value, 1);
    expect(burst, findsNothing);
    expect(fade(t, find.text('+ 112.000đ')), 1);
    expect(haptics, 0);
    expect(t.hasRunningAnimations, isFalse);
  });

  testWidgets('Pending and failed withdrawals are not celebrated', (t) async {
    final pending = appState.transactions
        .firstWhere((x) => x.withdrawStatus == WithdrawStatus.pending);
    await open(t, pending);
    await t.pump();
    await t.pump(const Duration(milliseconds: 16));
    expect(find.byKey(const ValueKey('tx-circle')), findsNothing);
    expect(burst, findsNothing);
    expect(haptics, 0);
    expect(find.text('Đang chờ duyệt'), findsOneWidget);
  });

  testWidgets('Leaving mid-animation disposes cleanly', (t) async {
    await open(t, credit());
    await t.pump();
    await t.pump(const Duration(milliseconds: 200));
    await t.tap(find.byTooltip('Quay lại'));
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
  });

  for (final c in [
    (const Size(412, 915), 1.0),
    (const Size(360, 780), 1.3),
    (const Size(320, 568), 1.0),
    (const Size(320, 568), 1.6),
  ]) {
    testWidgets('No overflow mid and end ${c.$1} at ${c.$2}', (t) async {
      await open(t, credit(), size: c.$1, scale: c.$2);
      await t.pump();
      await t.pump(const Duration(milliseconds: 500));
      expect(t.takeException(), isNull);
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    });
  }
}
