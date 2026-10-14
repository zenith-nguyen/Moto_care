import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Finder homePageScrollable() => find
    .descendant(
      of: find.byKey(const ValueKey('home-scroll')),
      matching: find.byType(Scrollable),
    )
    .first;

Future<void> scrollHomeToStations(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.text('Trạm gần bạn'),
    120,
    scrollable: homePageScrollable(),
  );
  await tester.pumpAndSettle();
}

Future<void> scrollHomeToSearch(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.byKey(const ValueKey('home-search')),
    -120,
    scrollable: homePageScrollable(),
  );
  await tester.pumpAndSettle();
}
