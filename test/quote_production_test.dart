import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motocare_mechanic/config/app_config.dart';
import 'package:motocare_mechanic/data/mock_data.dart';
import 'package:motocare_mechanic/models/models.dart';
import 'package:motocare_mechanic/screens/order_final_quote_screen.dart';
import 'package:motocare_mechanic/theme/app_theme.dart';

void main() {
  testWidgets('Customer simulation controls follow REVO_DEMO compile flag',
      (t) async {
    final o = ActiveOrder(
        offer: MockData.offers.first, acceptedAt: DateTime.now(), messages: [])
      ..quoteStatus = QuoteStatus.pending
      ..quoteSentAt = DateTime.now()
      ..submittedQuote = [const QuoteLine('Thay ắc quy', 450000, quantity: 1)];
    await t.pumpWidget(MaterialApp(
        theme: buildAppTheme(), home: OrderFinalQuoteScreen(order: o)));
    await t.pumpAndSettle();
    const expected = AppConfig.demoEnabled ? findsOneWidget : findsNothing;
    expect(find.text('Mô phỏng phản hồi khách hàng'), expected);
    expect(find.text('Khách đồng ý báo giá'), expected);
    expect(find.text('Khách từ chối báo giá'), expected);
    await t.tap(find.byTooltip('Tùy chọn báo giá'));
    await t.pumpAndSettle();
    expect(find.text('Mô phỏng đồng ý'), findsNothing);
    expect(find.text('Mô phỏng từ chối'), findsNothing);
    await t.pumpWidget(const SizedBox());
  });
}
