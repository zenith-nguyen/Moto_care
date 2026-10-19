import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motocare_mechanic/data/mock_data.dart';
import 'package:motocare_mechanic/state/app_state.dart';
import 'package:motocare_mechanic/theme/app_theme.dart';
import 'package:motocare_mechanic/utils/format.dart';
import 'package:motocare_mechanic/widgets/app_bottom_nav.dart';
import 'package:motocare_mechanic/widgets/order_identity.dart';
import 'package:motocare_mechanic/widgets/ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const key = AppState.showcasePreferenceKey;

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<bool?> stored() async =>
      (await SharedPreferences.getInstance()).getBool(key);

  /// A cold start: a brand-new AppState that restores its preferences.
  Future<AppState> coldStart() async {
    final state = AppState();
    await state.restorePreferences();
    return state;
  }

  test('defaults to off when nothing was saved, and writes nothing by itself',
      () async {
    final state = await coldStart();
    expect(state.showcaseOrdersEnabled, isFalse);
    expect(await stored(), isNull);
    state.dispose();
  });

  test('turning it on is saved and survives a restart', () async {
    final first = await coldStart();
    first.setShowcaseOrders(true);
    await pumpEventQueue();
    expect(await stored(), isTrue);
    first.dispose();
    final second = await coldStart();
    expect(second.showcaseOrdersEnabled, isTrue);
    expect(second.showcaseOrders.map((e) => e.code),
        ['#DEMO-S001', '#DEMO-S002', '#DEMO-S003', '#DEMO-S004', '#DEMO-S005']);
    expect(second.showcaseOrders.map((e) => orderServiceId(e.issue)).toSet(),
        hasLength(5));
    second.dispose();
  });

  test('turning it off is saved and survives a restart', () async {
    SharedPreferences.setMockInitialValues({key: true});
    final first = await coldStart();
    expect(first.showcaseOrdersEnabled, isTrue);
    first.setShowcaseOrders(false);
    await pumpEventQueue();
    expect(await stored(), isFalse);
    first.dispose();
    final second = await coldStart();
    expect(second.showcaseOrdersEnabled, isFalse);
    second.dispose();
  });

  test('the default never overwrites a saved value', () async {
    SharedPreferences.setMockInitialValues({key: true});
    final state = AppState();
    // Constructing (default off) must not write anything.
    await pumpEventQueue();
    expect(await stored(), isTrue);
    await state.restorePreferences();
    expect(state.showcaseOrdersEnabled, isTrue);
    expect(await stored(), isTrue);
    state.dispose();
  });

  test('unreadable storage keeps the safe default and does not throw',
      () async {
    SharedPreferences.resetStatic(); // no plugin/mock available
    final state = AppState();
    await state.restorePreferences();
    expect(state.showcaseOrdersEnabled, isFalse);
    // Writing also fails silently once preferences are "ready".
    state.setShowcaseOrders(true);
    await pumpEventQueue();
    expect(state.showcaseOrdersEnabled, isTrue);
    state.dispose();
  });

  test('saving the switch never touches orders, wallet or the active order',
      () async {
    SharedPreferences.setMockInitialValues({key: true});
    final state = AppState();
    final order = state.acceptOffer(state.nextOffer(serviceIndex: 4));
    final history = state.history.map((e) => e.code).toList();
    final transactions = state.transactions.length;
    final balance = state.balance;
    await state.restorePreferences();
    state.setShowcaseOrders(false);
    state.setShowcaseOrders(true);
    await pumpEventQueue();
    expect(state.activeOrder, same(order));
    expect(state.history.map((e) => e.code), history);
    expect(state.history.any((e) => e.code.startsWith('#DEMO-S')), isFalse);
    expect(state.transactions.length, transactions);
    expect(state.balance, balance);
    expect(state.history.map((e) => e.code),
        MockData.history().map((e) => e.code));
    state.dispose();
  });

  testWidgets(
      'Orders tab shows the five demo orders from the first frame after a '
      'restart, then the real history again when switched off', (t) async {
    SharedPreferences.setMockInitialValues({key: true});
    // Same order as main(): restore first, then build the UI.
    await appState.restorePreferences();
    expect(appState.showcaseOrdersEnabled, isTrue);
    appState.setTab(1);
    t.view.physicalSize = const Size(412, 2600);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(
        MaterialApp(theme: buildAppTheme(), home: const MechanicShell()));
    List<String> codes() => [
          for (final c in t.widgetList<ShadowCard>(find.byType(ShadowCard)))
            (c.key! as ValueKey<String>).value
        ];
    // First frame already shows the demo set (no flash of the 4 real orders).
    expect(codes(),
        ['#DEMO-S001', '#DEMO-S002', '#DEMO-S003', '#DEMO-S004', '#DEMO-S005']);
    expect(find.text('Xẹp lốp'), findsOneWidget);
    appState.setShowcaseOrders(false);
    await t.pumpAndSettle();
    expect(codes().toSet(), {'#RVO2298', '#RVO2287', '#RVO2279', '#RVO2271'});
    expect(find.text('Xẹp lốp'), findsNWidgets(2));
    expect(appState.balance, 1250000);
    expect(formatVnd(appState.balance), '1.250.000đ');
  });
}
