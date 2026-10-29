import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../data/home_media_assets.dart';

class HomeVideoHero extends StatefulWidget {
  const HomeVideoHero({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.onEmergency,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onEmergency;

  static const headline = 'Cứu Hộ Xe Máy 24/7.';
  static const subtitle = 'Kết nối thợ gần nhất trong 30s.';
  static const searchHint = 'Bạn gặp sự cố gì? (Vá lốp, hết bình...)';
  static const red = Color(0xFFE53935);
  static const _radius = BorderRadius.vertical(bottom: Radius.circular(32));
  static const _headlineStyle = TextStyle(
    fontFamily: 'Montserrat',
    color: Colors.white,
    fontSize: 28,
    height: 1.15,
    fontWeight: FontWeight.w800,
  );
  static const _subtitleStyle = TextStyle(
    fontFamily: 'Montserrat',
    color: Color(0xD9FFFFFF),
    fontSize: 14,
    height: 1.5,
  );

  @override
  State<HomeVideoHero> createState() => _HomeVideoHeroState();
}

class _HomeVideoHeroState extends State<HomeVideoHero>
    with WidgetsBindingObserver {
  late VideoPlayerController _controller;
  bool _failed = false;
  bool _foreground = true;
  bool _visibleRoute = true;
  bool _reducedMotion = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _foreground =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    _createController();
  }

  void _createController() {
    // The widget owns playback lifetime, including routes covering Home.
    _controller = VideoPlayerController.asset(
      HomeMediaAssets.heroVideo,
      videoPlayerOptions: VideoPlayerOptions(allowBackgroundPlayback: true),
    )..addListener(_onVideoChanged);
    unawaited(_initialize(_controller));
  }

  Future<void> _initialize(VideoPlayerController controller) async {
    try {
      // Store mute/loop before initialization so even the first playback is silent.
      await controller.setVolume(0.0);
      if (!_isCurrent(controller)) return;
      await controller.setLooping(true);
      if (!_isCurrent(controller)) return;
      await controller.initialize();
      if (!_isCurrent(controller)) return;
      await controller.setPreventsDisplaySleepDuringVideoPlayback(false);
      if (_isCurrent(controller)) await _syncPlayback();
    } catch (error) {
      assert(() {
        debugPrint('Home hero video initialization: $error');
        return true;
      }());
      if (_isCurrent(controller)) setState(() => _failed = true);
    }
  }

  bool _isCurrent(VideoPlayerController controller) =>
      mounted && identical(controller, _controller);

  void _onVideoChanged() {
    if (mounted && _controller.value.hasError && !_failed) {
      setState(() => _failed = true);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _visibleRoute = TickerMode.valuesOf(context).enabled;
    _reducedMotion = MediaQuery.disableAnimationsOf(context);
    unawaited(_syncPlayback());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    unawaited(_syncPlayback());
  }

  Future<void> _syncPlayback() async {
    final controller = _controller;
    if (!mounted || !controller.value.isInitialized || _failed) return;
    try {
      final shouldPlay = _foreground && _visibleRoute && !_reducedMotion;
      if (shouldPlay && !controller.value.isPlaying) {
        await controller.play();
      } else if (!shouldPlay && controller.value.isPlaying) {
        await controller.pause();
      }
    } catch (_) {
      if (_isCurrent(controller)) setState(() => _failed = true);
    }
  }

  void _retry() {
    if (!_failed) return;
    final previous = _controller;
    previous.removeListener(_onVideoChanged);
    unawaited(previous.dispose());
    setState(() {
      _failed = false;
      _createController();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_onVideoChanged);
    unawaited(_controller.dispose());
    super.dispose();
  }

  double _textHeight(String text, TextStyle style, double width) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: math.max(1, width));
    final height = painter.height;
    painter.dispose();
    return height;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      // Grow with wrapped Vietnamese text; reserve the search's entire touch area.
      final contentWidth = constraints.maxWidth - 40;
      final heroHeight = math.max(
        320.0,
        176 +
            _textHeight(
              HomeVideoHero.headline,
              HomeVideoHero._headlineStyle,
              contentWidth,
            ) +
            _textHeight(
              HomeVideoHero.subtitle,
              HomeVideoHero._subtitleStyle,
              contentWidth,
            ),
      );
      final searchHeight = math.max(
        64.0,
        MediaQuery.textScalerOf(context).scale(14) * 1.5 + 32,
      );
      return SizedBox(
        height: heroHeight + searchHeight / 2 + 8,
        child: Stack(
          children: [
            SizedBox(
              height: heroHeight,
              width: double.infinity,
              child: Container(
                decoration: const BoxDecoration(
                  borderRadius: HomeVideoHero._radius,
                ),
                child: ClipRRect(
                  borderRadius: HomeVideoHero._radius,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Layer 1: cover crops the video while preserving its aspect ratio.
                      ExcludeSemantics(
                        child: ValueListenableBuilder<VideoPlayerValue>(
                          valueListenable: _controller,
                          builder: (context, value, _) => Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.asset(
                                HomeMediaAssets.heroPoster,
                                key: const ValueKey('home-video-placeholder'),
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) =>
                                    const ColoredBox(color: Color(0xFF242424)),
                              ),
                              if (value.isInitialized &&
                                  !value.hasError &&
                                  !_failed)
                                FittedBox(
                                  key: const ValueKey('home-video-cover'),
                                  fit: BoxFit.cover,
                                  clipBehavior: Clip.hardEdge,
                                  child: SizedBox(
                                    width: value.size.width,
                                    height: value.size.height,
                                    child: VideoPlayer(_controller),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      // Layer 2: a bottom gradient keeps white copy readable.
                      IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.6),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Layer 3: copy stays above the decorative video.
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 64),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Spacer(),
                            const Text(
                              HomeVideoHero.headline,
                              style: HomeVideoHero._headlineStyle,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              HomeVideoHero.subtitle,
                              style: HomeVideoHero._subtitleStyle,
                            ),
                          ],
                        ),
                      ),
                      if (_failed)
                        Positioned(
                          right: 20,
                          bottom: 40,
                          child: IconButton(
                            tooltip: 'Tải lại video',
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black.withValues(
                                alpha: .3,
                              ),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: _retry,
                            icon: const Icon(Icons.refresh_rounded, size: 20),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            // Keep the overlap inside this Stack's bounds so its bottom half is tappable.
            Positioned(
              top: heroHeight - searchHeight / 2,
              left: 20,
              right: 20,
              height: searchHeight,
              child: Container(
                key: const ValueKey('home-floating-search'),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x18000000),
                      blurRadius: 20,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF85858B),
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        key: const ValueKey('home-search'),
                        controller: widget.searchController,
                        onChanged: widget.onSearchChanged,
                        textInputAction: TextInputAction.search,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF171717),
                        ),
                        decoration: const InputDecoration(
                          hintText: HomeVideoHero.searchHint,
                          hintMaxLines: 1,
                          hintStyle: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF85858B),
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: IconButton(
                        key: const ValueKey('home-sos'),
                        tooltip: 'Cứu hộ khẩn cấp',
                        style: IconButton.styleFrom(
                          backgroundColor: HomeVideoHero.red,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(48, 48),
                          shape: const CircleBorder(),
                        ),
                        onPressed: widget.onEmergency,
                        icon: const Text(
                          'SOS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
