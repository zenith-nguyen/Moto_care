import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motocare_mechanic/data/mock_data.dart';
import 'package:motocare_mechanic/models/models.dart';
import 'package:motocare_mechanic/screens/incoming_order_popup.dart';
import 'package:motocare_mechanic/screens/mechanic_account_screen.dart';
import 'package:motocare_mechanic/screens/customer_reviews_screen.dart';
import 'package:motocare_mechanic/screens/notifications_screen.dart';
import 'package:motocare_mechanic/screens/order_arrived_screen.dart';
import 'package:motocare_mechanic/screens/order_chat_screen.dart';
import 'package:motocare_mechanic/screens/order_completed_screen.dart';
import 'package:motocare_mechanic/screens/order_final_quote_screen.dart';
import 'package:motocare_mechanic/screens/order_history_detail_screen.dart';
import 'package:motocare_mechanic/screens/order_in_progress_screen.dart';
import 'package:motocare_mechanic/screens/order_received_screen.dart';
import 'package:motocare_mechanic/screens/service_management_screen.dart';
import 'package:motocare_mechanic/screens/settings_screen.dart';
import 'package:motocare_mechanic/screens/terms_and_commitment_screen.dart';
import 'package:motocare_mechanic/screens/withdraw_screen.dart';
import 'package:motocare_mechanic/screens/demo_controls_screen.dart';
import 'package:motocare_mechanic/screens/weekly_summary_screen.dart';
import 'package:motocare_mechanic/screens/wallet_transaction_detail_screen.dart';
import 'package:motocare_mechanic/state/app_state.dart';
import 'package:motocare_mechanic/theme/app_theme.dart';
import 'package:motocare_mechanic/widgets/app_bottom_nav.dart';
import 'package:motocare_mechanic/widgets/app_status.dart';

/// Optional: flutter test test/visual_audit_test.dart
/// --dart-define=REVO_CAPTURE_DIR=/absolute/path/to/renders
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final text = FontLoader('Montserrat')
      ..addFont(rootBundle.load('assets/fonts/Montserrat.ttf'));
    await text.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });

  for (final config in [
    (const Size(390, 844), 1.0),
    (const Size(320, 568), 1.6)
  ]) {
    testWidgets(
        'All reference screens render at ${config.$1.width}px, text scale ${config.$2}',
        (tester) async {
      tester.view.physicalSize = config.$1;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final boundary = GlobalKey();
      const output = String.fromEnvironment('REVO_CAPTURE_DIR');
      Future<void> capture(String name, Widget screen,
          {Future<void> Function()? setup}) async {
        await tester.pumpWidget(RepaintBoundary(
            key: boundary,
            child: MaterialApp(
              key: UniqueKey(),
              debugShowCheckedModeBanner: false,
              theme: buildAppTheme(),
              home: screen,
              builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(config.$2),
                    padding: const EdgeInsets.only(top: 24, bottom: 24),
                    viewPadding: const EdgeInsets.only(top: 24, bottom: 24),
                  ),
                  child: child!),
            )));
        await tester.pump();
        await tester.runAsync(() async {
          for (final asset in [
            'revo_sedan.png',
            'reference_welcome.png',
            'reference_profile.png',
            'reference_customer.png',
            'reference_vehicles.png'
          ]) {
            await precacheImage(
                AssetImage('assets/images/$asset'), boundary.currentContext!);
          }
        });
        await tester.pump(const Duration(milliseconds: 200));
        if (setup != null) await setup();
        await tester.pump(const Duration(milliseconds: 700));
        expect(tester.takeException(), isNull, reason: name);
        if (output.isNotEmpty && config.$2 == 1) {
          await tester.runAsync(() async {
            final render = boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
            final picture = await render.toImage(pixelRatio: 2);
            final bytes =
                await picture.toByteData(format: ui.ImageByteFormat.png);
            final file = File('$output/$name.png');
            await file.parent.create(recursive: true);
            await file.writeAsBytes(bytes!.buffer.asUint8List());
            picture.dispose();
          });
        }
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
      }

      ActiveOrder order({bool repairing = true}) {
        appState.activeOrder = null;
        final active =
            appState.acceptOffer(appState.nextOffer(serviceIndex: 0));
        if (!repairing) return active;
        appState.beginNavigation(orderId: active.orderId);
        appState.markArrived(orderId: active.orderId);
        appState.startRepair(
            orderId: active.orderId, code: active.offer.verificationCode);
        active.repairStartedAt =
            DateTime.now().subtract(const Duration(minutes: 15, seconds: 32));
        return active;
      }

      appState.setNetworkAvailable(true);
      appState.setGps(true);
      appState.setOnline(true);
      appState.setTab(0);
      await capture('B1-home', const MechanicShell());
      await capture(
          'C1-incoming', IncomingOrderPopup(offer: MockData.offers.first));
      var active = order(repairing: false);
      await capture('C2-route', OrderReceivedScreen(order: active));
      appState.setNetworkAvailable(false);
      await capture('C2-offline', OrderReceivedScreen(order: active));
      appState.setNetworkAvailable(true);
      appState.setGps(false);
      await capture('C2-gps-disabled', OrderReceivedScreen(order: active));
      appState.setGps(true);
      appState.setOnline(true);
      appState.beginNavigation(orderId: active.orderId);
      appState.markArrived(orderId: active.orderId);
      await capture('C3-confirmation', OrderArrivedScreen(order: active),
          setup: () async {
        await tester.scrollUntilVisible(find.byType(TextField), 160,
            scrollable: find.byType(Scrollable).last);
        await tester.enterText(find.byType(TextField), '2847');
        FocusManager.instance.primaryFocus?.unfocus();
      });
      appState.startRepair(
          orderId: active.orderId, code: active.offer.verificationCode);
      active.repairStartedAt =
          DateTime.now().subtract(const Duration(minutes: 15, seconds: 32));
      appState.advanceRepair(orderId: active.orderId);
      await capture('C4-repair', OrderInProgressScreen(order: active));
      await capture('C5-quote', OrderFinalQuoteScreen(order: active),
          setup: () async {
        for (final label in [
          'Thêm Thay ắc quy',
          'Thêm Vá lốp',
          'Thêm Công dịch vụ'
        ]) {
          await tester.tap(find.byTooltip(label));
          await tester.pump();
        }
      });
      appState.sendQuote(orderId: active.orderId);
      await capture('C6-waiting', OrderFinalQuoteScreen(order: active));
      appState.resolveQuote(true, orderId: active.orderId);
      await capture('C7-accepted', OrderFinalQuoteScreen(order: active));
      active = order();
      appState.setQuoteQuantity(orderId: active.orderId, index: 0, quantity: 1);
      appState.sendQuote(orderId: active.orderId);
      appState.resolveQuote(false, orderId: active.orderId);
      await capture('C7-rejected', OrderFinalQuoteScreen(order: active));
      appState.continueWithoutRejectedQuote(orderId: active.orderId);
      while (active.repairStage < 3) {
        appState.advanceRepair(orderId: active.orderId);
      }
      final completed = appState.completeOrder(orderId: active.orderId);
      await capture('C8-completed', OrderCompletedScreen(item: completed));
      final chatOrder = order(repairing: false);
      await capture(
          'C9-chat',
          OrderChatScreen(
              orderId: chatOrder.orderId,
              customerName: 'Thùy An',
              customerPhone: '0905551298',
              messages: chatOrder.messages));
      active = order();
      appState.setTab(1);
      await capture('D1-orders', const MechanicShell());
      await capture('D2-detail', OrderHistoryDetailScreen(item: completed));
      appState.setTab(2);
      await capture('E1-wallet', const MechanicShell());
      await capture('E2-withdraw', const WithdrawScreen());
      appState.setTab(3);
      await capture('F1-account', const MechanicShell());
      await capture('F1-account-system', const MechanicShell(),
          setup: () async {
        await tester.drag(find.byType(ListView).last, const Offset(0, -2200));
        await tester.pump();
      });
      await capture('F1-customer-reviews', const CustomerReviewsScreen());
      await capture('F2-services', const ServiceManagementScreen());
      await capture('F3-notifications', const NotificationsScreen());
      await capture('F4-settings', const SettingsScreen());
      for (final kind in AppStatusKind.values) {
        await capture(
            'F5-${kind.name}',
            Scaffold(
                backgroundColor: AppColors.light,
                body: Center(
                    child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: AppStatusView(kind: kind, compact: true)))));
      }
      await capture('A2-terms', const TermsAndCommitmentScreen());
      await capture('F1-profile-edit', const ProfileEditScreen());
      await capture('F1-documents', const DocumentsScreen());
      await capture('F4-support', const SupportScreen());
      await capture('F5-demo-controls', const DemoControlsScreen());
      await capture('B5-weekly-summary', const WeeklySummaryScreen());
      final tx =
          appState.requestWithdraw(200000, requestId: 'capture-${config.$2}')!;
      await capture('E3-pending', WalletTransactionDetailScreen(tx: tx));
      appState.resolveWithdraw(tx.txnId, approved: false);
      await capture('E3-failed', WalletTransactionDetailScreen(tx: tx));
      final approved = appState.requestWithdraw(200000,
          requestId: 'capture-approved-${config.$2}')!;
      appState.resolveWithdraw(approved.txnId, approved: true);
      await capture('E3-success', WalletTransactionDetailScreen(tx: approved));

      appState.activeOrder = null;
    });
  }
}
