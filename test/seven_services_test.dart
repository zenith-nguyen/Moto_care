import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motocare_mechanic/data/home_catalog.dart';
import 'package:motocare_mechanic/data/mock_data.dart';
import 'package:motocare_mechanic/screens/service_management_screen.dart';
import 'package:motocare_mechanic/services/home_feed_repository.dart';
import 'package:motocare_mechanic/state/app_state.dart';
import 'package:motocare_mechanic/theme/app_theme.dart';
import 'package:motocare_mechanic/widgets/home_components.dart';
import 'package:motocare_mechanic/widgets/revo_switch.dart';

void main() {
  const oldIds = ['battery', 'tire', 'flood', 'tow', 'repair'];
  setUp(() {
    appState.activeOrder = null;
    appState.profile = MockData.profile();
    appState.balance = 1250000;
    appState.startDemoSession();
    appState.setNetworkAvailable(true);
    appState.setGps(true);
    appState.setOnline(true);
    appState.saveServices([true, true, true, true, true, false, false]);
    appState.setTab(0);
  });

  group('catalog', () {
    test('has exactly seven unique services plus the all shortcut', () {
      final real = homeServices.where((s) => s.id != 'all').toList();
      expect(real, hasLength(7));
      expect(homeServiceCount, 7);
      expect(homeServices.map((s) => s.id).toSet(),
          hasLength(homeServices.length));
      expect(real.map((s) => s.id).toSet(), {...oldIds, 'fuel', 'maintenance'});
    });

    test('the original five keep their ids and dispatch indexes', () {
      int index(String id) =>
          homeServices.firstWhere((s) => s.id == id).dispatchIndex!;
      expect([for (final id in oldIds) index(id)], [0, 1, 2, 4, 3]);
      expect(appState.services.take(5).map((s) => s.name), [
        'Kích bình (12V, 24V)',
        'Thay lốp',
        'Cứu hộ ngập nước',
        'Sửa xe tại chỗ',
        'Kéo xe',
      ]);
      expect(index('fuel'), 5);
      expect(index('maintenance'), 6);
    });

    test('new services use the approved names and short descriptions', () {
      final fuel = homeServices.firstWhere((s) => s.id == 'fuel');
      final care = homeServices.firstWhere((s) => s.id == 'maintenance');
      expect([fuel.label, fuel.description],
          ['Tiếp nhiên liệu', 'Xe hết nhiên liệu?']);
      expect([care.label, care.description],
          ['Thay nhớt, bảo dưỡng', 'Đến lịch chăm sóc xe?']);
      expect(appState.services[5].name, 'Tiếp nhiên liệu');
      expect(appState.services[6].name, 'Thay nhớt, bảo dưỡng');
    });

    test('Home still shows four cards and counts services from the catalog',
        () {
      expect(popularHomeServices.map((s) => s.id),
          ['battery', 'tire', 'repair', 'all']);
      final all = homeServices.firstWhere((s) => s.id == 'all');
      expect(HomeServiceTile.description(all), 'Khám phá 7 dịch vụ');
    });
  });

  group('registration state', () {
    test('new services are off by default and toggle independently', () {
      expect(AppStateProbe.fresh().services.map((s) => s.enabled),
          [true, true, true, true, true, false, false]);
      appState.saveServices([true, true, true, true, true, true, false]);
      expect(appState.services.map((s) => s.enabled),
          [true, true, true, true, true, true, false]);
      appState.saveServices([true, false, true, true, true, true, true]);
      expect(appState.services.map((s) => s.enabled),
          [true, false, true, true, true, true, true]);
    });

    test('a list with the wrong length is rejected instead of misaligned', () {
      expect(() => appState.saveServices([true, true, true, true, true]),
          throwsArgumentError);
      expect(() => appState.saveServices(List.filled(7, false)),
          throwsArgumentError);
    });

    test('the demo dispatcher never invents offers for the new services', () {
      appState.saveServices(List.filled(7, true));
      for (final index in [5, 6]) {
        expect(() => appState.nextOffer(serviceIndex: index), throwsStateError);
      }
      final seq = appState.offerSeq;
      for (var i = 0; i < 10; i++) {
        final offer = appState.nextOffer();
        expect(
            offer.issue,
            isIn([
              'Hết bình',
              'Xẹp lốp',
              'Ngập nước',
              'Chết máy',
              'Xe cần kéo'
            ]));
      }
      expect(appState.offerSeq, seq + 10);
      expect(appState.balance, 1250000);
    });

    test('old service offers keep their issue and price', () {
      const prices = [150000, 120000, 350000, 100000, 500000];
      for (var i = 0; i < 5; i++) {
        final offer = appState.nextOffer(serviceIndex: i);
        expect(offer.price, prices[i]);
      }
    });

    test('a disabled new service is never offerable by the feed', () {
      final repo = HomeFeedRepository(appState);
      expect(repo.serviceEnabled('fuel'), isFalse);
      expect(repo.serviceEnabled('maintenance'), isFalse);
      appState.saveServices([true, true, true, true, true, true, true]);
      expect(repo.serviceEnabled('fuel'), isTrue);
      expect(repo.requests.where((r) => r.serviceId == 'fuel'), isEmpty);
      expect(repo.requests.where((r) => r.serviceId == 'maintenance'), isEmpty);
    });
  });

  testWidgets('Service management shows seven switches and saves them',
      (t) async {
    t.view.physicalSize = const Size(412, 915);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(MaterialApp(
        theme: buildAppTheme(), home: const ServiceManagementScreen()));
    await t.pumpAndSettle();
    expect(find.byType(RevoSwitch), findsNWidgets(7));
    expect(find.text('Tiếp nhiên liệu'), findsOneWidget);
    expect(find.text('Thay nhớt, bảo dưỡng'), findsOneWidget);
    bool on(int i) => t.widget<RevoSwitch>(find.byType(RevoSwitch).at(i)).value;
    expect([for (var i = 0; i < 7; i++) on(i)],
        [true, true, true, true, true, false, false]);
    await t.ensureVisible(find.byType(RevoSwitch).at(5));
    await t.tap(find.byType(RevoSwitch).at(5));
    await t.pumpAndSettle();
    expect([for (var i = 0; i < 7; i++) on(i)],
        [true, true, true, true, true, true, false]);
    await t.tap(find.text('Lưu thay đổi'));
    await t.pumpAndSettle();
    expect(appState.services.map((s) => s.enabled),
        [true, true, true, true, true, true, false]);
    expect(appState.balance, 1250000);
  });
}

/// A pristine AppState to read defaults without touching the shared singleton.
class AppStateProbe {
  static AppState fresh() => AppState();
}
