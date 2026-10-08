import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/home_theme.dart';
import '../models/promo_banner.dart';
import '../data/promo_banners.dart';

class PromoBannerSlider extends StatefulWidget {
  const PromoBannerSlider({super.key});

  @override
  State<PromoBannerSlider> createState() => _PromoBannerSliderState();
}

class _PromoBannerSliderState extends State<PromoBannerSlider>
    with WidgetsBindingObserver {
  static const _autoScrollInterval = Duration(seconds: 4);

  final _pageController = PageController();
  Timer? _autoScrollTimer;
  int _currentPage = 0;
  bool _tickerEnabled = true;
  bool _isForeground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _isForeground = lifecycle == null || lifecycle == AppLifecycleState.resumed;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tickerEnabled = TickerMode.valuesOf(context).enabled;
    _restartAutoScroll();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isForeground = state == AppLifecycleState.resumed;
    _restartAutoScroll();
  }

  void _restartAutoScroll() {
    _autoScrollTimer?.cancel();
    if (mounted && _tickerEnabled && _isForeground) {
      _autoScrollTimer = Timer(_autoScrollInterval, _advancePage);
    }
  }

  void _advancePage() {
    if (!_pageController.hasClients ||
        _pageController.position.isScrollingNotifier.value) {
      _restartAutoScroll();
      return;
    }
    unawaited(
      _pageController.animateToPage(
        (_currentPage + 1) % promoBanners.length,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      ),
    );
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification.depth == 0) {
      if (notification is ScrollStartNotification) {
        _autoScrollTimer?.cancel();
      } else if (notification is ScrollEndNotification) {
        _restartAutoScroll();
      }
    }
    return false;
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AspectRatio(
          aspectRatio: 736 / 414,
          child: NotificationListener<ScrollNotification>(
            onNotification: _onScrollNotification,
            child: PageView.builder(
              controller: _pageController,
              itemCount: promoBanners.length,
              onPageChanged: (page) => setState(() => _currentPage = page),
              itemBuilder: (context, index) => _PromoBanner(
                key: ValueKey('promo-banner-$index'),
                data: promoBanners[index],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Semantics(
          label: 'Banner ${_currentPage + 1} trên ${promoBanners.length}',
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var index = 0; index < promoBanners.length; index++)
                AnimatedContainer(
                  key: ValueKey('promo-dot-$index'),
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index == _currentPage
                        ? HomeColors.red
                        : const Color(0xFFD1D5DB),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PromoBanner extends StatelessWidget {
  const _PromoBanner({super.key, required this.data});

  final PromoBannerData data;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.asset(
        data.imageAsset,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.contain,
        semanticLabel: data.title,
      ),
    );
  }
}
