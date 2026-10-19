import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';
import 'package:revo/features/home/data/home_media_assets.dart';
import 'package:revo/features/home/widgets/home_video_hero.dart';

import 'fixtures/home_video_platform.dart';

Future<void> _unmount(WidgetTester tester, FakeHomeVideoPlatform video) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  // Native stream cancellation crosses the fake-frame and platform async zones.
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pumpAndSettle();
  expect(video.disposals.values.every((done) => done.isCompleted), isTrue);
}

Widget _hero(
  TextEditingController search, {
  bool active = true,
  bool reducedMotion = false,
  VoidCallback? emergency,
  ValueChanged<String>? onSearch,
}) => MaterialApp(
  home: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reducedMotion),
      child: TickerMode(
        enabled: active,
        child: Scaffold(
          body: SingleChildScrollView(
            child: HomeVideoHero(
              searchController: search,
              onSearchChanged: onSearch ?? (_) {},
              onEmergency: emergency ?? () {},
            ),
          ),
        ),
      ),
    ),
  ),
);

void main() {
  late FakeHomeVideoPlatform video;
  late TextEditingController search;
  setUp(() {
    final previous = VideoPlayerPlatform.instance;
    video = FakeHomeVideoPlatform();
    VideoPlayerPlatform.instance = video;
    search = TextEditingController();
    addTearDown(() {
      VideoPlayerPlatform.instance = previous;
      search.dispose();
    });
  });

  testWidgets(
    'The exact bundled video initializes muted, loops and autoplays',
    (tester) async {
      video.initializeImmediately = false;
      await tester.pumpWidget(_hero(search));
      await tester.pump();
      expect(
        find.byKey(const ValueKey('home-video-placeholder')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('home-video-cover')), findsNothing);
      expect(video.sources.values.single.asset, HomeMediaAssets.heroVideo);
      video.initialize(1);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('home-video-cover')), findsOneWidget);
      expect(video.volumes, isNotEmpty);
      expect(video.volumes, everyElement(0.0));
      expect(video.looping, everyElement(isTrue));
      expect(video.playing, {1});
      await _unmount(tester, video);
      expect(video.disposed, [1]);
    },
  );

  testWidgets('The lower half of the floating SOS remains tappable', (
    tester,
  ) async {
    var emergency = 0;
    await tester.pumpWidget(_hero(search, emergency: () => emergency++));
    await tester.pumpAndSettle();
    final cover = tester.widget<FittedBox>(
      find.byKey(const ValueKey('home-video-cover')),
    );
    expect(cover.fit, BoxFit.cover);
    final videoRect = tester.getRect(find.byType(ClipRRect));
    final searchRect = tester.getRect(
      find.byKey(const ValueKey('home-floating-search')),
    );
    expect(searchRect.center.dy, videoRect.bottom);
    final sos = tester.getRect(find.byKey(const ValueKey('home-sos')));
    await tester.tapAt(Offset(sos.center.dx, videoRect.bottom + 8));
    expect(emergency, 1);
    await _unmount(tester, video);
  });

  testWidgets('Search forwards the query and retains the supplied controller', (
    tester,
  ) async {
    var query = '';
    await tester.pumpWidget(_hero(search, onSearch: (value) => query = value));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('home-search')), 'Vá lốp');
    expect(query, 'Vá lốp');
    expect(search.text, 'Vá lốp');
    await _unmount(tester, video);
  });

  testWidgets('A controller still initializing is released on exit', (
    tester,
  ) async {
    video.initializeImmediately = false;
    await tester.pumpWidget(_hero(search));
    await tester.pump();
    await _unmount(tester, video);
    expect(video.disposed, [1]);
    expect(video.playing, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Video failure keeps search usable and retry creates one player',
    (tester) async {
      video.initializeImmediately = false;
      await tester.pumpWidget(_hero(search));
      await tester.pump();
      video.events[1]!.addError(
        PlatformException(code: 'video-load', message: 'Cannot load video'),
      );
      await tester.pumpAndSettle();
      expect(find.byTooltip('Tải lại video'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('home-search')),
        'Hết bình',
      );
      video.initializeImmediately = true;
      await tester.tap(find.byTooltip('Tải lại video'));
      await tester.tap(find.byTooltip('Tải lại video'));
      await tester.pumpAndSettle();
      expect(search.text, 'Hết bình');
      expect(video.sources, hasLength(2));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();
      expect(video.disposals[1]!.isCompleted, isTrue);
      expect(video.disposed, [1]);
      expect(video.playing, {2});
      expect(find.byTooltip('Tải lại video'), findsNothing);
      await _unmount(tester, video);
      expect(video.disposed, [1, 2]);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Lifecycle and covered routes pause and restore silent playback',
    (tester) async {
      await tester.pumpWidget(_hero(search));
      await tester.pumpAndSettle();
      expect(video.playing, {1});
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(video.playing, isEmpty);
      await tester.pumpWidget(_hero(search, active: false));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(video.playing, isEmpty);
      await tester.pumpWidget(_hero(search));
      await tester.pumpAndSettle();
      expect(video.playing, {1});
      await tester.pumpWidget(_hero(search, reducedMotion: true));
      await tester.pumpAndSettle();
      expect(video.playing, isEmpty);
      expect(video.volumes, everyElement(0.0));
      await _unmount(tester, video);
    },
  );

  testWidgets('320 px, large text and the keyboard retain search and SOS', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(_hero(search));
    await tester.pumpAndSettle();
    expect(find.text(HomeVideoHero.headline), findsOneWidget);
    expect(
      find.byKey(const ValueKey('home-sos')).hitTestable(),
      findsOneWidget,
    );
    await tester.enterText(find.byKey(const ValueKey('home-search')), 'Vá lốp');
    tester.view.viewInsets = const FakeViewPadding(bottom: 240);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('home-sos')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('home-sos')).hitTestable(),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await _unmount(tester, video);
  });
}
