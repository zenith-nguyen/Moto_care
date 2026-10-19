import 'package:flutter/material.dart';
import 'package:motocare_mechanic/utils/format.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motocare_mechanic/data/mock_data.dart';
import 'package:motocare_mechanic/models/models.dart';
import 'package:motocare_mechanic/services/otp_service.dart';
import 'package:motocare_mechanic/state/app_state.dart';
import 'package:motocare_mechanic/theme/app_theme.dart';
import 'package:motocare_mechanic/screens/order_arrived_screen.dart';
import 'package:motocare_mechanic/screens/order_in_progress_screen.dart';
import 'package:motocare_mechanic/screens/order_final_quote_screen.dart';
import 'package:motocare_mechanic/screens/customer_reviews_screen.dart';
import 'package:motocare_mechanic/screens/order_history_detail_screen.dart';
import 'package:motocare_mechanic/screens/terms_and_commitment_screen.dart';
import 'package:motocare_mechanic/widgets/app_bottom_nav.dart';
import 'package:motocare_mechanic/widgets/ui.dart';
import 'package:motocare_mechanic/widgets/code_input_boxes.dart';

class FailingOtpService extends DemoOtpService {
  @override
  Future<void> resend(String orderId, OtpChannel channel) async =>
      throw StateError('Kênh tạm thời lỗi');
}

void main() {
  group('Order-bound async OTP and demo isolation', () {
    late AppState state;
    setUp(() => state = AppState(
        demoEnabled: true, otpService: DemoOtpService(latency: Duration.zero)));
    tearDown(() => state.dispose());
    ActiveOrder arrived() {
      final o = state.acceptOffer(state.nextOffer(serviceIndex: 0));
      state.beginNavigation(orderId: o.orderId);
      state.markArrived(orderId: o.orderId);
      return o;
    }

    test('Empty, nonnumeric, short and wrong codes never advance', () async {
      final o = arrived();
      for (final code in ['', '28', 'abcd', '1111', '28478']) {
        expect(await state.verifyOtp(orderId: o.orderId, code: code), isFalse);
        expect(o.otp.status, OtpActionState.error);
        expect(o.step, OrderStep.arrived);
        expect(o.otpVerifiedAt, isNull);
      }
    });
    test(
        'Correct code verifies once, keeps order identity and starts only repair',
        () async {
      final o = arrived();
      final offer = o.offer;
      expect(state.demoCodeFor(o.orderId), '2847');
      final request = state.verifyOtp(orderId: o.orderId, code: '2847');
      expect(o.otp.status, OtpActionState.verifying);
      expect(await state.verifyOtp(orderId: o.orderId, code: '2847'), isFalse);
      expect(await request, isTrue);
      expect(state.activeOrder, same(o));
      expect(o.offer, same(offer));
      expect(o.step, OrderStep.repairing);
      expect(o.otpVerifiedAt, o.repairStartedAt);
      final verified = o.otpVerifiedAt;
      await expectLater(
          state.verifyOtp(orderId: o.orderId, code: '2847'), throwsStateError);
      expect(o.otpVerifiedAt, verified);
    });
    test('Neither OTP channel bypasses arrival or accepts another orderId',
        () async {
      final o = state.acceptOffer(state.nextOffer());
      await expectLater(
          state.verifyOtp(orderId: o.orderId, code: '2847'), throwsStateError);
      await expectLater(
          state.resendOtp(orderId: o.orderId, channel: OtpChannel.sms),
          throwsStateError);
      state.beginNavigation(orderId: o.orderId);
      state.markArrived(orderId: o.orderId);
      await expectLater(
          state.verifyOtp(orderId: '#another', code: '2847'), throwsStateError);
      expect(state.demoCodeFor('#another'), isNull);
      expect(o.step, OrderStep.arrived);
    });
    for (final channel in OtpChannel.values) {
      test('$channel resend is explicitly mocked, masked and rate limited',
          () async {
        final o = arrived();
        final code = state.demoCodeFor(o.orderId);
        final sending = state.resendOtp(orderId: o.orderId, channel: channel);
        expect(o.otp.status, OtpActionState.sending);
        expect(await state.resendOtp(orderId: o.orderId, channel: channel),
            isFalse);
        expect(await sending, isTrue);
        expect(o.otp.status, OtpActionState.sent);
        expect(o.otp.message, contains('Đã mô phỏng gửi mã qua'));
        expect(o.otp.message, isNot(contains(o.offer.customerPhone)));
        expect(o.otp.message, isNot(contains(o.offer.customerEmail!)));
        expect(o.otp.cooldownSeconds, greaterThan(0));
        expect(await state.resendOtp(orderId: o.orderId, channel: channel),
            isFalse);
        o.otp.resendAvailableAt =
            DateTime.now().subtract(const Duration(seconds: 1));
        expect(await state.resendOtp(orderId: o.orderId, channel: channel),
            isTrue);
        expect(state.demoCodeFor(o.orderId), code);
      });
    }
    test('Offline verification and resend keep the order at arrival', () async {
      final o = arrived();
      state.setNetworkAvailable(false);
      expect(await state.verifyOtp(orderId: o.orderId, code: '2847'), isFalse);
      expect(
          await state.resendOtp(orderId: o.orderId, channel: OtpChannel.email),
          isFalse);
      expect(o.step, OrderStep.arrived);
      expect(o.otp.message, contains('Mất kết nối'));
    });
    test('A network drop during verification never starts repair', () async {
      final o = arrived();
      final request = state.verifyOtp(orderId: o.orderId, code: '2847');
      state.setNetworkAvailable(false);
      expect(await request, isFalse);
      expect(o.otpVerifiedAt, isNull);
      expect(o.otp.busy, isFalse);
    });
    test('An old async result cannot advance a replacement order', () async {
      final o = arrived();
      final request = state.verifyOtp(orderId: o.orderId, code: '2847');
      state.activeOrder = null;
      final other = state.acceptOffer(state.nextOffer());
      expect(await request, isFalse);
      expect(state.activeOrder, same(other));
      expect(other.step, OrderStep.received);
    });
    test('Missing customer email shows an error and allows SMS fallback',
        () async {
      final b = MockData.offers.first;
      final o = state.acceptOffer(OrderOffer(
          code: '#no-email',
          issue: b.issue,
          description: b.description,
          vehicle: b.vehicle,
          plate: b.plate,
          customerName: b.customerName,
          customerPhone: b.customerPhone,
          address: b.address,
          distanceKm: b.distanceKm,
          etaMinutes: b.etaMinutes,
          price: b.price,
          platformFee: b.platformFee));
      state.beginNavigation(orderId: o.orderId);
      state.markArrived(orderId: o.orderId);
      expect(
          await state.resendOtp(orderId: o.orderId, channel: OtpChannel.email),
          isFalse);
      expect(o.otp.message, contains('chưa có email'));
      expect(await state.resendOtp(orderId: o.orderId, channel: OtpChannel.sms),
          isTrue);
    });
    test('Service failure clears busy state and exposes an actionable error',
        () async {
      final failure =
          AppState(demoEnabled: true, otpService: FailingOtpService());
      addTearDown(failure.dispose);
      final o = failure.acceptOffer(failure.nextOffer());
      failure.beginNavigation(orderId: o.orderId);
      failure.markArrived(orderId: o.orderId);
      expect(
          await failure.resendOtp(orderId: o.orderId, channel: OtpChannel.sms),
          isFalse);
      expect(o.otp.busy, isFalse);
      expect(o.otp.status, OtpActionState.error);
    });
    test(
        'Demo off never reveals or accepts a client-side code, offer or bank simulation',
        () async {
      final o = arrived();
      final production =
          AppState(demoEnabled: false, otpService: DemoOtpService());
      addTearDown(production.dispose);
      production.activeOrder = o;
      expect(production.demoCodeFor(o.orderId), isNull);
      expect(await production.verifyOtp(orderId: o.orderId, code: '2847'),
          isFalse);
      expect(o.step, OrderStep.arrived);
      expect(() => production.startRepair(orderId: o.orderId, code: '2847'),
          throwsStateError);
      expect(() => production.nextOffer(), throwsStateError);
      expect(production.requestWithdraw(50000, requestId: 'off-mode'), isNull);
      expect(() => production.startDemoSession(), throwsStateError);
    });
    test('Logout is blocked during a rescue and preserves all business data',
        () {
      final o = arrived();
      final balance = state.balance;
      final history = state.history.length;
      expect(state.signOut(), isFalse);
      expect(state.sessionActive, isTrue);
      expect(state.activeOrder, same(o));
      expect(state.balance, balance);
      expect(state.history.length, history);
    });
    test('Logout stops offers; re-entry preserves wallet, profile and history',
        () {
      final balance = state.balance;
      final history = state.history.length;
      final p = state.profile;
      expect(state.signOut(), isTrue);
      expect(state.isOnline, isFalse);
      state.setOnline(true);
      expect(state.isOnline, isFalse);
      expect(() => state.nextOffer(), throwsStateError);
      state.startDemoSession();
      expect(state.isOnline, isTrue);
      expect(state.balance, balance);
      expect(state.history.length, history);
      expect(state.profile, same(p));
    });
    test(
        'Professional profile validation is atomic and cannot grant verification',
        () {
      final p = state.profile;
      final name = p.name;
      final status = p.verificationStatus;
      void save(
              {String email = 'hung@example.test',
              List<String> vehicles = const ['Xe máy']}) =>
          state.saveProfessionalProfile(
              name: 'Thợ Hùng',
              bio: 'Sửa xe tại chỗ',
              phone: '',
              email: email,
              experienceYears: 4,
              specialty: 'Kích bình',
              area: 'Quận 1, TP.HCM',
              vehicles: vehicles);
      expect(() => save(email: 'invalid'), throwsFormatException);
      expect(p.name, name);
      expect(() => save(vehicles: []), throwsFormatException);
      expect(p.name, name);
      save();
      expect(p.name, 'Thợ Hùng');
      expect(p.email, 'hung@example.test');
      expect(p.experienceYears, 4);
      expect(p.supportedVehicles, ['Xe máy']);
      expect(p.verificationStatus, status);
    });
    test(
        'Monthly income uses credit ledger only; debit and refunds are excluded',
        () {
      final n = DateTime.now();
      final expected = state.transactions
          .where((t) =>
              t.isCredit && t.time.year == n.year && t.time.month == n.month)
          .fold(0, (a, t) => a + t.amount);
      expect(state.monthIncome, expected);
      final tx = state.requestWithdraw(50000, requestId: 'month-test')!;
      state.resolveWithdraw(tx.txnId, approved: false);
      expect(state.monthIncome, expected);
    });
  });

  group('Quality upgrade UI', () {
    setUp(() {
      appState.activeOrder = null;
      appState.startDemoSession();
      appState.profile = MockData.profile();
      appState.setNetworkAvailable(true);
      appState.setGps(true);
      appState.setOnline(true);
    });
    Future<void> host(WidgetTester t, Widget screen) async {
      t.view.physicalSize = const Size(390, 844);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      await t.pumpWidget(MaterialApp(theme: buildAppTheme(), home: screen));
      await t.pumpAndSettle();
    }

    ActiveOrder arrive() {
      final o = appState.acceptOffer(appState.nextOffer(serviceIndex: 0));
      appState.beginNavigation(orderId: o.orderId);
      appState.markArrived(orderId: o.orderId);
      return o;
    }

    Future<void> tap(WidgetTester t, String label) async {
      final f = find.text(label);
      if (f.evaluate().isEmpty) {
        await t.scrollUntilVisible(f, 150,
            scrollable: find.byType(Scrollable).last);
      }
      await t.ensureVisible(f.last);
      await t.pumpAndSettle();
      await t.tap(f.last);
      await t.pumpAndSettle();
    }

    Future<void> close(WidgetTester t) => t.pumpWidget(const SizedBox());
    testWidgets(
        'OTP persists input on Back, supports paste/delete, validates and opens repair',
        (t) async {
      final o = arrive();
      await host(
          t,
          Builder(
              builder: (c) => Scaffold(
                  body: TextButton(
                      onPressed: () => Navigator.push(
                          c,
                          MaterialPageRoute(
                              builder: (_) => OrderArrivedScreen(order: o))),
                      child: const Text('OTP')))));
      await tap(t, 'OTP');
      await t.enterText(find.byType(TextField), '12a34');
      await t.pumpAndSettle();
      expect(o.otp.draft, '1234');
      await t.enterText(find.byType(TextField), '123');
      await t.pump();
      expect(o.otp.draft, '123');
      FocusManager.instance.primaryFocus?.unfocus();
      await t.pumpAndSettle();
      await t.tap(find.byTooltip('Quay lại'));
      await t.pumpAndSettle();
      await tap(t, 'OTP');
      expect(
          t.widget<TextField>(find.byType(TextField)).controller!.text, '123');
      await t.enterText(find.byType(TextField), '1111');
      await tap(t, 'Xác nhận');
      expect(find.textContaining('Mã không chính xác'), findsOneWidget);
      await t.enterText(find.byType(TextField), '2847');
      await tap(t, 'Xác nhận');
      expect(find.byType(OrderInProgressScreen), findsOneWidget);
      expect(o.step, OrderStep.repairing);
      await close(t);
    });
    testWidgets(
        'Demo helper copies the actual order code and Email resend is labelled mock',
        (t) async {
      String? copied;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.getData') return {'text': copied};
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }
        return null;
      });
      addTearDown(() => TestDefaultBinaryMessengerBinding
          .instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null));
      final o = arrive();
      await host(t, OrderArrivedScreen(order: o));
      FocusManager.instance.primaryFocus?.unfocus();
      await t.pumpAndSettle();
      copied = '123';
      await tap(t, 'Dán mã');
      expect(o.otp.draft, isEmpty);
      expect(
          find.text('Nội dung sao chép cần có đúng 4 chữ số.'), findsOneWidget);
      await tap(t, 'Sao chép mã');
      expect(copied, appState.demoCodeFor(o.orderId));
      await tap(t, 'Dán mã');
      expect(o.otp.draft, copied);
      expect(
          t.widget<TextField>(find.byType(TextField)).controller!.text, copied);
      await tap(t, 'Email');
      await tap(t, 'Gửi lại mã');
      expect(o.otp.message, contains('Đã mô phỏng gửi mã qua Email'));
      expect(o.otp.cooldownSeconds, greaterThan(0));
      await close(t);
    });
    testWidgets(
        'Code boxes remain usable above an open keyboard on a small phone',
        (t) async {
      final o = arrive();
      await host(t, OrderArrivedScreen(order: o));
      t.view.physicalSize = const Size(320, 568);
      t.view.viewInsets = const FakeViewPadding(bottom: 220);
      addTearDown(t.view.resetViewInsets);
      await t.pumpAndSettle();
      await t.scrollUntilVisible(find.byType(CodeInputBoxes), 120,
          scrollable: find.byType(Scrollable).last);
      await t.enterText(find.byType(TextField), '2847');
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      final cta = t.getRect(find.widgetWithText(PrimaryButton, 'Xác nhận'));
      expect(cta.bottom, lessThanOrEqualTo(348));
      await close(t);
    });
    testWidgets(
        'Quote confirmation can cancel without sending or losing its draft',
        (t) async {
      final o = arrive();
      appState.startRepair(orderId: o.orderId, code: '2847');
      appState.setQuoteQuantity(orderId: o.orderId, index: 0, quantity: 1);
      await host(t, OrderFinalQuoteScreen(order: o));
      await tap(t, 'Gửi báo giá');
      await tap(t, 'Xem lại');
      expect(o.quoteStatus, QuoteStatus.none);
      expect(o.draftExtra, 450000);
      await tap(t, 'Gửi báo giá');
      await tap(t, 'Xác nhận gửi');
      expect(o.quoteStatus, QuoteStatus.pending);
      await close(t);
    });
    testWidgets(
        'Account logout cancels safely then clears navigation and keeps wallet',
        (t) async {
      final balance = appState.balance;
      final count = appState.history.length;
      appState.setTab(3);
      await host(t, const MechanicShell());
      await tap(t, 'Đăng xuất');
      await tap(t, 'Ở lại');
      expect(appState.sessionActive, isTrue);
      await tap(t, 'Đăng xuất');
      await tap(t, 'Đăng xuất');
      expect(find.byType(TermsEntryScreen), findsOneWidget);
      expect(find.byType(MechanicShell), findsNothing);
      expect(appState.isOnline, isFalse);
      expect(appState.balance, balance);
      expect(appState.history.length, count);
      expect(Navigator.of(t.element(find.byType(TermsEntryScreen))).canPop(),
          isFalse);
      await close(t);
    });
    testWidgets('Active order logout is blocked in the account UI', (t) async {
      final o = arrive();
      appState.setTab(3);
      await host(t, const MechanicShell());
      await tap(t, 'Đăng xuất');
      expect(find.textContaining('Hãy hoàn thành đơn'), findsOneWidget);
      expect(appState.activeOrder, same(o));
      expect(find.byType(TermsEntryScreen), findsNothing);
      await close(t);
    });
    testWidgets('Order detail shows its own customer and vehicle illustration',
        (t) async {
      final item =
          appState.history.firstWhere((o) => o.vehicle.contains('Toyota'));
      await host(t, OrderHistoryDetailScreen(item: item));
      expect(find.text(item.customerName), findsOneWidget);
      // The vehicle card shows the icon of this order's own vehicle class.
      expect(vehicleLabel(item.vehicle), 'Ô tô');
      expect(find.byIcon(Icons.directions_car_rounded), findsOneWidget);
      expect(find.byIcon(Icons.two_wheeler_rounded), findsNothing);
      expect(find.text(vehicleLabel(item.vehicle)), findsOneWidget);
      await t.tap(find.byTooltip('Lịch sử trò chuyện'));
      await t.pumpAndSettle();
      expect(find.text(item.customerName), findsWidgets);
      expect(find.byType(TextField), findsNothing);
      await close(t);
    });

    testWidgets('Customer reviews use customer-to-mechanic fields only',
        (t) async {
      final item = appState.history.first;
      item.rating = 1;
      item.ratingComment = 'Mechanic rating must stay separate';
      await host(t, const CustomerReviewsScreen());
      expect(find.text('Mechanic rating must stay separate'), findsNothing);
      for (final o
          in appState.history.where((o) => o.customerRating != null).take(1)) {
        expect(find.text(o.customerName), findsWidgets);
      }
      await close(t);
    });
  });
}
