import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moto_care/features/rescue_station/widgets/station_services_catalog.dart';

void main() {
  testWidgets('An empty catalog offers contact guidance without price cards', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: StationServicesCatalog(services: [])),
      ),
    );
    expect(find.text('Dịch vụ cứu hộ chính'), findsOneWidget);
    expect(find.text('Liên hệ trạm để được tư vấn dịch vụ.'), findsOneWidget);
    expect(find.byType(ServiceCatalogItemCard), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
