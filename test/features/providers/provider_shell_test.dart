import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moto_care/core/money/money_amount.dart';
import 'package:moto_care/features/auth/application/session_controller.dart';
import 'package:moto_care/features/auth/application/session_state.dart';
import 'package:moto_care/features/auth/domain/app_user.dart';
import 'package:moto_care/features/auth/domain/auth_session.dart';
import 'package:moto_care/features/orders/domain/geo_point.dart';
import 'package:moto_care/features/orders/domain/order_models.dart';
import 'package:moto_care/features/orders/domain/order_pricing.dart';
import 'package:moto_care/features/orders/domain/order_status.dart';
import 'package:moto_care/features/providers/application/provider_location_tracking_controller.dart';
import 'package:moto_care/features/providers/application/provider_location_tracking_state.dart';
import 'package:moto_care/features/providers/application/provider_work_controller.dart';
import 'package:moto_care/features/providers/application/provider_work_state.dart';
import 'package:moto_care/features/providers/application/professional_profile_provider.dart';
import 'package:moto_care/features/providers/domain/provider_models.dart';
import 'package:moto_care/features/providers/domain/professional_profile.dart';
import 'package:moto_care/features/providers/presentation/provider_shell.dart';
import 'package:moto_care/features/wallet/application/provider_wallet_controller.dart';
import 'package:moto_care/features/wallet/application/provider_wallet_state.dart';
import 'package:moto_care/features/wallet/domain/wallet_models.dart';

void main() {
  testWidgets('provider account shows server profile and edit action', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionControllerProvider.overrideWith(_StubSessionController.new),
          providerWorkControllerProvider.overrideWith(
            _StubProviderWorkController.new,
          ),
          providerLocationTrackingControllerProvider.overrideWith(
            _StubProviderLocationController.new,
          ),
          providerWalletControllerProvider.overrideWith(
            _StubProviderWalletController.new,
          ),
          professionalProfileProvider.overrideWith(
            (ref) async => const ProfessionalProfile(
              bio: 'Cứu hộ xe máy tại TP.HCM',
              yearsOfExperience: 4,
              serviceRadiusKm: 12,
              tier: 'STANDARD',
              skills: ['Vá lốp'],
            ),
          ),
        ],
        child: const MaterialApp(home: ProviderShell()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tài khoản').last);
    await tester.pumpAndSettle();
    expect(find.text('Hồ sơ nghề nghiệp'), findsOneWidget);
    expect(find.text('Cứu hộ xe máy tại TP.HCM'), findsOneWidget);
    expect(find.text('4 năm'), findsOneWidget);
    expect(find.text('Vá lốp'), findsOneWidget);
    expect(find.byTooltip('Chỉnh sửa hồ sơ Thợ'), findsOneWidget);
  });

  testWidgets('pending provider sees the saved approval state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionControllerProvider.overrideWith(_PendingSessionController.new),
        ],
        child: const MaterialApp(home: ProviderShell()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hồ sơ Thợ đang chờ duyệt'), findsOneWidget);
    expect(find.textContaining('đã được lưu vào hệ thống'), findsOneWidget);
    expect(find.text('provider@example.test'), findsOneWidget);
    expect(find.text('Kiểm tra trạng thái'), findsOneWidget);
    expect(find.text('Đang sẵn sàng'), findsNothing);
  });

  testWidgets('renders server-backed offer and active provider order', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionControllerProvider.overrideWith(_StubSessionController.new),
          providerWorkControllerProvider.overrideWith(
            _StubProviderWorkController.new,
          ),
          providerLocationTrackingControllerProvider.overrideWith(
            _StubProviderLocationController.new,
          ),
          providerWalletControllerProvider.overrideWith(
            _StubProviderWalletController.new,
          ),
          professionalProfileProvider.overrideWith(
            (ref) async => const ProfessionalProfile(
              bio: 'Cứu hộ xe máy tại TP.HCM',
              yearsOfExperience: 4,
              serviceRadiusKm: 12,
              tier: 'STANDARD',
              skills: ['Vá lốp'],
            ),
          ),
        ],
        child: const MaterialApp(home: ProviderShell()),
      ),
    );
    await tester.pumpAndSettle();

    // Job-board home: availability toggle + hero CTA visible at the top.
    expect(find.text('Sẵn sàng nhận đơn'), findsOneWidget);
    expect(find.text('Nhận đơn'), findsWidgets);

    // The dispatched offer renders in the "Đơn gần bạn" feed (scroll to it).
    await tester.scrollUntilVisible(
      find.text('Thủng lốp'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Thủng lốp'), findsOneWidget);
    expect(find.text('MC-42'), findsWidgets);

    // The active order is reachable on the Đơn hàng tab.
    await tester.tap(find.text('Đơn hàng').last);
    await tester.pumpAndSettle();
    expect(find.text('Đang đến khách'), findsOneWidget);
  });

  testWidgets('shows wallet sandbox disclosure and server balances', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionControllerProvider.overrideWith(_StubSessionController.new),
          providerWorkControllerProvider.overrideWith(
            _StubProviderWorkController.new,
          ),
          providerLocationTrackingControllerProvider.overrideWith(
            _StubProviderLocationController.new,
          ),
          providerWalletControllerProvider.overrideWith(
            _StubProviderWalletController.new,
          ),
          professionalProfileProvider.overrideWith(
            (ref) async => const ProfessionalProfile(
              bio: 'Cứu hộ xe máy tại TP.HCM',
              yearsOfExperience: 4,
              serviceRadiusKm: 12,
              tier: 'STANDARD',
              skills: ['Vá lốp'],
            ),
          ),
        ],
        child: const MaterialApp(home: ProviderShell()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ví'));
    await tester.pumpAndSettle();

    expect(find.text('Số dư khả dụng • Sandbox'), findsOneWidget);
    expect(
      find.textContaining('không phải tiền ngân hàng thật'),
      findsOneWidget,
    );
    expect(find.text('250.000 đ'), findsOneWidget);
  });
}

class _StubSessionController extends SessionController {
  @override
  SessionState build() => const SessionSignedIn(
    AuthSession(
      accessToken: 'test-token',
      user: AppUser(
        id: 8,
        name: 'Nguyễn Minh Tuấn',
        email: 'tho@example.test',
        phone: '0900000000',
        role: AppRole.provider,
        status: AppUserStatus.active,
      ),
    ),
  );
}

class _PendingSessionController extends SessionController {
  @override
  SessionState build() => const SessionSignedIn(
    AuthSession(
      accessToken: 'pending-token',
      user: AppUser(
        id: 8,
        name: 'Zenith Provider',
        email: 'provider@example.test',
        phone: '0900000000',
        role: AppRole.provider,
        status: AppUserStatus.pendingApproval,
      ),
    ),
  );
}

class _StubProviderWorkController extends ProviderWorkController {
  @override
  Future<ProviderWorkState> build() async => ProviderWorkState(
    pendingOffers: [
      PendingOffer(
        id: 9,
        orderId: 42,
        expiresAt: DateTime.utc(2099, 10, 20),
        order: PendingOfferOrder(
          code: 'MC-42',
          incidentType: IncidentSummary(id: 1, name: 'Thủng lốp'),
          estimatedPrice: _money100,
          pricing: _pricing,
          customerLocation: GeoPoint(
            latitude: 10.763811,
            longitude: 106.666282,
          ),
        ),
      ),
    ],
    orders: [
      OrderSummary(
        id: 42,
        code: 'MC-42',
        status: OrderStatus.accepted,
        customerId: 7,
        providerId: 8,
        incidentTypeId: 1,
        estimatedPrice: _money100,
        extraCost: _money0,
        discountAmount: _money0,
        finalPrice: null,
        createdAt: DateTime.utc(2026, 10, 20, 1),
        pricing: _pricing,
      ),
    ],
  );
}

class _StubProviderLocationController
    extends ProviderLocationTrackingController {
  @override
  Future<ProviderLocationTrackingState> build() async =>
      ProviderLocationTrackingState(
        mode: ProviderLocationMode.waiting,
        lastLocation: GeoPoint(latitude: 10.763811, longitude: 106.666282),
        lastSentAt: DateTime.utc(2026, 10, 20, 1, 30),
      );
}

class _StubProviderWalletController extends ProviderWalletController {
  @override
  Future<ProviderWalletState> build() async => ProviderWalletState(
    wallet: ProviderWallet(
      providerId: 8,
      summary: WalletSummary(
        balance: _money250,
        lockedBalance: _money0,
        availableBalance: _money250,
        currency: 'VND',
      ),
      demoOnly: true,
      transactions: const [],
    ),
    withdrawals: WithdrawalHistory(
      providerId: 8,
      wallet: WalletSummary(
        balance: _money250,
        lockedBalance: _money0,
        availableBalance: _money250,
        currency: 'VND',
      ),
      sandboxOnly: true,
      items: [],
    ),
  );
}

final _money0 = MoneyAmount.parse('0.00');
final _money100 = MoneyAmount.parse('100000.00');
final _money250 = MoneyAmount.parse('250000.00');

final _pricing = OrderPricing(
  basePrice: _money100,
  weatherSurcharge: _money0,
  weatherMultiplier: '1.0000',
  weatherCategory: WeatherCategory.disabled,
  weatherSource: WeatherSource.fallback,
  weatherObservedAt: null,
  weatherCode: null,
  precipitationMm: null,
  windSpeedKmh: null,
  windGustKmh: null,
  attribution: null,
);
