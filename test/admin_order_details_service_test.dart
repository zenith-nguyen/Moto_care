import 'package:flutter_test/flutter_test.dart';
import 'package:revo/features/admin/models/admin_models.dart';
import 'package:revo/features/admin/services/admin_order_details_service.dart';

final _created = DateTime(2026, 10, 16, 17, 55);
AdminOrder _order({
  AdminOrderStatus status = AdminOrderStatus.completed,
  List<AdminTimelineEvent> timeline = const [],
  String? provider = 'Thợ đã phân công',
  String? phone = '+84 900-000-101',
}) => AdminOrder(
  id: 'test-order',
  customer: 'Khách hàng',
  incident: 'Thủng lốp',
  provider: provider,
  estimatedPrice: 180000,
  finalPrice: 180000,
  status: status,
  payment: AdminPaymentStatus.settled,
  createdAt: _created,
  collected: 180000,
  refunded: 0,
  credited: 180000,
  paymentId: 'test-payment',
  customerPhone: '0900 100 201',
  providerPhone: phone,
  timeline: timeline,
);

void main() {
  const service = AdminOrderDetailsService();

  test(
    'Missing observations never invent accepted, started or completion times',
    () {
      final steps = service.progress(_order());
      expect(steps.first.at, _created);
      expect(steps.skip(1).every((step) => !step.reached), isTrue);
      expect(service.history(_order()), isEmpty);
    },
  );

  test(
    'Typed milestones survive label changes and use the earliest observation',
    () {
      final accepted = _created.add(const Duration(minutes: 3));
      final steps = service.progress(
        _order(
          timeline: [
            AdminTimelineEvent(
              'Localized accepted label',
              accepted,
              milestone: AdminOrderMilestone.accepted,
            ),
            AdminTimelineEvent(
              'Repeated acceptance',
              accepted.add(const Duration(minutes: 2)),
              milestone: AdminOrderMilestone.accepted,
            ),
            AdminTimelineEvent(
              'Observation predating order creation',
              _created.subtract(const Duration(minutes: 1)),
              milestone: AdminOrderMilestone.started,
            ),
          ],
        ),
      );
      expect(steps[1].at, accepted);
      expect(steps[2].reached, isFalse);
      expect(steps[3].reached, isFalse);
    },
  );

  test('Legacy timeline labels remain compatible', () {
    final completed = _created.add(const Duration(minutes: 35));
    final steps = service.progress(
      _order(
        timeline: [
          AdminTimelineEvent(
            'Thợ nhận đơn',
            _created.add(const Duration(minutes: 3)),
          ),
          AdminTimelineEvent(
            'Bắt đầu cứu hộ',
            _created.add(const Duration(minutes: 12)),
          ),
          AdminTimelineEvent('Hoàn thành', completed),
        ],
      ),
    );
    expect(steps.every((step) => step.reached), isTrue);
    expect(steps.last.at, completed);
  });

  test('Cancellation and dispute records never advance rescue completion', () {
    final order =
        _order(
          status: AdminOrderStatus.cancelled,
          timeline: [
            AdminTimelineEvent(
              'Đã hủy theo yêu cầu khách',
              _created.add(const Duration(minutes: 8)),
            ),
          ],
        ).withFinalPrice(
          160000,
          resolution: 'Đã đối chiếu',
          resolvedAt: _created.add(const Duration(hours: 1)),
        );
    expect(
      service.progress(order).skip(1).every((step) => !step.reached),
      isTrue,
    );
    expect(
      service.history(order).last.label,
      'Admin giải quyết tranh chấp giá',
    );
  });

  test('History is chronological without mutating source observations', () {
    final late = AdminTimelineEvent(
      'Hoàn thành',
      _created.add(const Duration(minutes: 35)),
    );
    final early = AdminTimelineEvent('Đã tạo yêu cầu', _created);
    final input = [late, early];
    final sorted = service.history(_order(timeline: input));
    expect(sorted, [early, late]);
    expect(input, [late, early]);
    expect(() => sorted.clear(), throwsUnsupportedError);
  });

  test('Telephone URIs normalize verified formats and reject missing or masked contacts', () {
    expect(service.mechanicTelephone(_order()).toString(), 'tel:0900000101');
    for (final phone in [null, '', '0908 xxx xxx', 'tel:0900123456;other']) {
      expect(service.mechanicTelephone(_order(phone: phone)), isNull);
    }
    expect(service.mechanicTelephone(_order(provider: null)), isNull);
  });

  test('Price resolution retains requester and mechanic contact snapshots', () {
    final original = _order();
    final updated = original.withFinalPrice(200000);
    expect(updated.customerPhone, original.customerPhone);
    expect(updated.providerPhone, original.providerPhone);
    expect(updated.collected, original.collected);
  });
}
