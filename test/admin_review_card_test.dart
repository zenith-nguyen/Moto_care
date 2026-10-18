import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revo/features/admin/models/admin_models.dart';
import 'package:revo/features/admin/widgets/admin_common.dart';
import 'package:revo/features/admin/widgets/admin_review_card.dart';

void main() {
  setUpAll(() async {
    await (FontLoader('Montserrat')
          ..addFont(rootBundle.load('assets/fonts/Montserrat-Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Montserrat-Medium.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Montserrat-SemiBold.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Montserrat-Bold.ttf')))
        .load();
  });

  testWidgets(
    'Pending reviews never show completed processing; rejection is a final decision',
    (tester) async {
      for (final status in AdminReviewStatus.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AdminReviewCard(
                title: 'RF-01 • MC-2604',
                status: status,
                fields: const [],
              ),
            ),
          ),
        );
        expect(find.text(status.label), findsOneWidget);
        expect(
          find.byIcon(Icons.check_circle_rounded),
          findsNWidgets(status == AdminReviewStatus.pending ? 1 : 3),
        );
        expect(
          find.byKey(const ValueKey('admin-review-step-2-false')),
          status == AdminReviewStatus.pending ? findsOneWidget : findsNothing,
        );
        if (status == AdminReviewStatus.rejected) {
          expect(find.text('Đã duyệt'), findsNothing);
        }
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets(
    'Long review values retain two columns at 320px with large text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: AdminReviewCard(
                  title: 'RF-01 • MC-2604',
                  status: AdminReviewStatus.pending,
                  fields: [
                    AdminField.text('Nguồn yêu cầu', 'Điều chỉnh thanh toán'),
                    AdminField.text('Tiền hoàn', '1.350.000 đ'),
                    AdminField.text(
                      'Lý do',
                      'Điều chỉnh phí di chuyển và phụ phí thời tiết',
                    ),
                    AdminField.text('Mã Sandbox', 'SB-PAYMENT-ADJUSTMENT-01'),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      for (final (left, right) in [
        ('Nguồn yêu cầu', 'Tiền hoàn'),
        ('Lý do', 'Mã Sandbox'),
      ]) {
        expect(
          tester.getTopLeft(find.text(left)).dy,
          tester.getTopLeft(find.text(right)).dy,
        );
        expect(
          tester.getTopLeft(find.text(left)).dx,
          lessThan(tester.getTopLeft(find.text(right)).dx),
        );
      }
      await tester.ensureVisible(find.text('Đã xong'));
      await tester.pumpAndSettle();
      expect(find.text('SB-PAYMENT-ADJUSTMENT-01'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
