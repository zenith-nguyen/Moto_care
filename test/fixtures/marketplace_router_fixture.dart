import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moto_care/core/router/app_router.dart';

GoRouter marketplaceTestRouter(Widget home) {
  final appRouter = createAppRouter();
  final routes = List<RouteBase>.of(appRouter.configuration.routes);
  appRouter.dispose();
  return GoRouter(
    initialLocation: '/trang-chu',
    routes: [
      for (final route in routes)
        if (route is! GoRoute || route.path != '/trang-chu') route,
      GoRoute(path: '/trang-chu', builder: (context, state) => home),
    ],
  );
}

Widget freezeMarketplaceMotion(BuildContext context, Widget? child) =>
    MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: true),
      child: child ?? const SizedBox.shrink(),
    );

Future<void> tapMarketplace(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      120,
      scrollable: find
          .byWidgetPredicate(
            (widget) =>
                widget is Scrollable &&
                widget.axisDirection == AxisDirection.down,
          )
          .hitTestable()
          .last,
    );
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
