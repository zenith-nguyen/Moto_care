import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motocare_mechanic/data/mock_data.dart';
import 'package:motocare_mechanic/main.dart';
import 'package:motocare_mechanic/screens/mechanic_home_screen.dart';
import 'package:motocare_mechanic/screens/terms_and_commitment_screen.dart';
import 'package:motocare_mechanic/state/app_state.dart';
import 'package:motocare_mechanic/widgets/app_bottom_nav.dart';

void main() {
  final boundary = GlobalKey();
  setUp(() {
    appState.activeOrder = null;
    appState.history
      ..clear()
      ..addAll(MockData.history());
    appState.transactions
      ..clear()
      ..addAll(MockData.transactions());
    appState.balance = 1250000;
    appState.setNetworkAvailable(true);
    appState.setGps(true);
    appState.setShowcaseOrders(false);
    appState.setTab(0);
  });

  Future<void> boot(WidgetTester t) async {
    t.view.physicalSize = const Size(412, 915);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(
        RepaintBoundary(key: boundary, child: const RevoMechanicApp()));
    await t.pumpAndSettle();
  }

  testWidgets(
      'App opens directly on Terms: no welcome, no Continue step, no back',
      (t) async {
    await boot(t);
    expect(find.byType(TermsEntryScreen), findsOneWidget);
    expect(find.text('Điều khoản & cam kết'), findsOneWidget);
    expect(find.text('Cùng Revo'), findsNothing);
    expect(find.text('Tiếp tục'), findsNothing);
    expect(find.byTooltip('Quay lại'), findsNothing);
    expect(find.byType(MechanicShell), findsNothing);
    // Consent is never pre-ticked and Đồng ý is disabled until it is.
    expect(find.byKey(const ValueKey('terms-consent')), findsOneWidget);
    expect(
        t
            .widget<FilledButton>(find.byKey(const ValueKey('terms-agree')))
            .onPressed,
        isNull);
    // The system back key leaves nothing to pop to.
    expect(Navigator.of(t.element(find.byType(TermsEntryScreen))).canPop(),
        isFalse);
    const output = String.fromEnvironment('REVO_HOME_PIXELS_CAPTURE');
    if (output.isNotEmpty) {
      await t.runAsync(() async {
        final r = boundary.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
        final png = await r.toImage(pixelRatio: 2);
        final b = await png.toByteData(format: ui.ImageByteFormat.png);
        Directory(output).createSync(recursive: true);
        File('$output/first-screen.png')
            .writeAsBytesSync(b!.buffer.asUint8List());
      });
    }
  });

  testWidgets('Consent is required; agreeing starts one session and opens Home',
      (t) async {
    await boot(t);
    await t.tap(find.text('Đồng ý'), warnIfMissed: false);
    await t.pumpAndSettle();
    expect(find.byType(MechanicShell), findsNothing);
    await t.tap(find.byKey(const ValueKey('terms-consent')));
    await t.pumpAndSettle();
    final history = appState.history.length;
    await t.tap(find.text('Đồng ý'));
    await t.pumpAndSettle();
    expect(find.byType(MechanicShell), findsOneWidget);
    expect(find.byType(MechanicHomeScreen), findsOneWidget);
    expect(find.byType(TermsEntryScreen), findsNothing);
    expect(find.byType(TermsAndCommitmentScreen), findsNothing);
    expect(appState.sessionActive, isTrue);
    // Nothing below Home to go back to (no terms, no welcome in the stack).
    expect(
        Navigator.of(t.element(find.byType(MechanicShell))).canPop(), isFalse);
    expect(appState.history.length, history);
    expect(appState.balance, 1250000);
  });
}
