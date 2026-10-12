import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

class FakeHomeVideoPlatform extends VideoPlayerPlatform {
  FakeHomeVideoPlatform({this.initializeImmediately = true});
  bool initializeImmediately;
  final sources = <int, DataSource>{};
  final events = <int, StreamController<VideoEvent>>{};
  final playing = <int>{};
  final disposed = <int>[];
  final disposals = <int, Completer<void>>{};
  final volumes = <double>[];
  final looping = <bool>[];
  int _nextId = 1;

  @override
  Future<void> init() async {}

  @override
  Future<void> setMixWithOthers(bool mixWithOthers) async {}
  @override
  Future<void> setAllowBackgroundPlayback(bool allowBackgroundPlayback) async {}

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async {
    final id = _nextId++;
    sources[id] = options.dataSource;
    disposals[id] = Completer<void>();
    events[id] = StreamController<VideoEvent>.broadcast(sync: true);
    return id;
  }

  void initialize(int id) => events[id]!.add(
    VideoEvent(
      eventType: VideoEventType.initialized,
      duration: const Duration(seconds: 8),
      size: const Size(1280, 720),
    ),
  );

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) {
    if (initializeImmediately) {
      Future<void>.delayed(Duration.zero, () => initialize(playerId));
    }
    return events[playerId]!.stream;
  }

  @override
  Future<void> setLooping(int playerId, bool value) async => looping.add(value);
  @override
  Future<void> setVolume(int playerId, double volume) async =>
      volumes.add(volume);
  @override
  Future<void> play(int playerId) async => playing.add(playerId);
  @override
  Future<void> pause(int playerId) async => playing.remove(playerId);
  @override
  Future<void> seekTo(int playerId, Duration position) async {}
  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}
  @override
  Future<Duration> getPosition(int playerId) async => Duration.zero;

  @override
  Widget buildViewWithOptions(VideoViewOptions options) => const ColoredBox(
    key: ValueKey('fake-video-view'),
    color: Color(0xFF142A40),
  );

  @override
  Future<void> dispose(int playerId) async {
    disposed.add(playerId);
    playing.remove(playerId);
    await events[playerId]?.close();
    disposals[playerId]!.complete();
  }
}
