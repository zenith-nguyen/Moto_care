import 'dart:async';

import 'package:flutter/material.dart';

/// Visual theme of the rank panel, chosen from the current tier name. It only
/// colours the panel; it adds no tiers and no rules. Unknown tiers fall back to
/// [RankVisualTheme.standard] (white on the REVO blue banner).
class RankVisualTheme {
  const RankVisualTheme({
    required this.name,
    required this.gradient,
    required this.border,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.badge,
    required this.track,
    required this.progress,
    required this.link,
  });

  final String name;

  /// null = no panel fill: the blue banner shows through.
  final List<Color>? gradient;
  final Color? border;
  final Color title, subtitle, icon, badge, track, progress, link;

  static const silver = RankVisualTheme(
    name: 'silver',
    gradient: [Color(0xFFE8EDF2), Color(0xFFDCE2E9)],
    border: Color(0xFFCBD5DF),
    title: Color(0xFF172638),
    subtitle: Color(0xFF52657A),
    icon: Color(0xFF66788B),
    badge: Color(0xFFF1F4F7),
    track: Color(0xFFB9C6D3),
    progress: Color(0xFF317CBB),
    link: Color(0xFF317CBB),
  );

  static const gold = RankVisualTheme(
    name: 'gold',
    gradient: [Color(0xFFFFF3D6), Color(0xFFFBE6B0)],
    border: Color(0xFFF0D58A),
    title: Color(0xFF5C4300),
    subtitle: Color(0xFF80651D),
    icon: Color(0xFFC69427),
    badge: Color(0xFFFFF9E8),
    track: Color(0xFFEAD59C),
    progress: Color(0xFFC69427),
    link: Color(0xFF5C4300),
  );

  static const bronze = RankVisualTheme(
    name: 'bronze',
    gradient: [Color(0xFFF6E4D7), Color(0xFFEFD3BE)],
    border: Color(0xFFE5C2A6),
    title: Color(0xFF5A341C),
    subtitle: Color(0xFF8A5A3C),
    icon: Color(0xFFC98952),
    badge: Color(0xFFFBEFE6),
    track: Color(0xFFE8CDB8),
    progress: Color(0xFFB87945),
    link: Color(0xFF5A341C),
  );

  static final standard = RankVisualTheme(
    name: 'standard',
    gradient: null,
    border: null,
    title: Colors.white,
    subtitle: Colors.white,
    icon: Colors.white,
    badge: Colors.white.withValues(alpha: .1),
    track: Colors.white.withValues(alpha: .25),
    progress: Colors.white,
    link: Colors.white,
  );
}

/// Theme for the profile's current tier name ("Bạc", "Vàng", "Đồng").
RankVisualTheme rankThemeFor(String tierName) => switch (tierName) {
      'Bạc' => RankVisualTheme.silver,
      'Vàng' => RankVisualTheme.gold,
      'Đồng' => RankVisualTheme.bronze,
      _ => RankVisualTheme.standard,
    };

/// One simulated rank state used only for the UI preview. Never read by any
/// business logic and never written to the profile.
class RankPreviewState {
  const RankPreviewState(
      this.tierName, this.nextTierName, this.orders, this.target);
  final String tierName, nextTierName;
  final int orders, target;
  int get remaining =>
      nextTierName.isEmpty ? 0 : (target - orders).clamp(0, target);
  double get progress => nextTierName.isEmpty || target == 0
      ? 1.0
      : (orders / target).clamp(0.0, 1.0);
}

/// Simulated data for the three demo ranks (not real achievements). Gold is the
/// top of the demo: no higher tier is invented.
const rankPreviewBronze = RankPreviewState('Đồng', 'Bạc', 6, 12);
const rankPreviewSilver = RankPreviewState('Bạc', 'Vàng', 18, 24);
const rankPreviewGold = RankPreviewState('Vàng', '', 30, 30);

/// Drives the "Mô phỏng" preview of the rank panel. UI-only: it holds no app
/// data and changes nothing but what the weekly banner shows.
class RankPreviewController extends ChangeNotifier {
  RankPreviewState? _state;
  Timer? _timer;
  bool _running = false;

  /// null = show the real rank.
  RankPreviewState? get state => _state;
  bool get running => _running;

  void show(RankPreviewState s) {
    _cancel();
    _state = s;
    notifyListeners();
  }

  /// Đồng → Bạc → Vàng, holding each for [hold]; stops on Vàng. Calling it
  /// again restarts cleanly (never two runs at once).
  void runDemo({Duration hold = const Duration(milliseconds: 1400)}) {
    _cancel();
    _running = true;
    _state = rankPreviewBronze;
    notifyListeners();
    const steps = [rankPreviewSilver, rankPreviewGold];
    var i = 0;
    void next() {
      _timer = Timer(hold, () {
        _state = steps[i++];
        if (i >= steps.length) {
          _running = false;
          _timer = null;
        } else {
          next();
        }
        notifyListeners();
      });
    }

    next();
  }

  /// Back to the real rank.
  void clear() {
    _cancel();
    if (_state != null) {
      _state = null;
      notifyListeners();
    }
  }

  void _cancel() {
    _timer?.cancel();
    _timer = null;
    _running = false;
  }

  @override
  void dispose() {
    _cancel();
    super.dispose();
  }
}

final RankPreviewController rankPreview = RankPreviewController();
