import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'audio_voice.dart';

/// Starts the next preloaded copy before EOF and blends between the two.
/// Native position events drive the blend, so pauses freeze it naturally.
class LoopingAudioVoice implements AudioVoice {
  LoopingAudioVoice(PositionedAudioVoice first, PositionedAudioVoice second)
    : _decks = [first, second];

  final List<PositionedAudioVoice> _decks;
  final List<StreamSubscription<Duration>> _subscriptions = [];
  Future<void> _queue = Future.value();
  Duration _duration = Duration.zero;
  Duration _blendDuration = const Duration(seconds: 3);
  int _active = 0;
  int? _incoming;
  int _generation = 0;
  double _gain = 0;
  double _blend = 0;
  bool _running = false;
  bool _disposed = false;

  Future<void> _enqueue(Future<void> Function() action) {
    final operation = _queue.then((_) => action());
    // Keep the queue usable after native errors; callers still receive errors.
    _queue = operation.catchError((Object error) {
      debugPrint('Music loop unavailable: $error');
    });
    return operation;
  }

  @visibleForTesting
  Future<void> get idle => _queue;

  @override
  Future<void> load(String asset, {required bool loop}) async {
    await stop();
    await _enqueue(() async {
      for (final subscription in _subscriptions) {
        await subscription.cancel();
      }
      _subscriptions.clear();
      for (final deck in _decks) {
        await deck.volume(0);
        await deck.load(asset, loop: false);
      }
      final duration = await _decks.first.duration();
      if (duration == null || duration <= const Duration(seconds: 1)) {
        throw StateError('Music duration unavailable for $asset');
      }
      _duration = duration;
      _blendDuration = Duration(
        milliseconds: math.min(3000, duration.inMilliseconds ~/ 4),
      );
      final generation = _generation;
      for (var i = 0; i < _decks.length; i++) {
        final index = i;
        _subscriptions.add(
          _decks[i].positions.listen(
            (position) {
              if (!_running || _disposed || generation != _generation) return;
              unawaited(
                _enqueue(() async {
                  if (!_running || _disposed || generation != _generation) {
                    return;
                  }
                  await _position(index, position);
                }).catchError((Object _) {}),
              );
            },
            onError: (Object error) {
              debugPrint('Music position unavailable: $error');
            },
          ),
        );
      }
    });
  }

  Future<void> _position(int index, Duration position) async {
    if (_incoming == index) {
      _blend = (position.inMicroseconds / _blendDuration.inMicroseconds).clamp(
        0.0,
        1.0,
      );
      await _applyVolume();
      if (_blend == 1) {
        final old = _active;
        _active = index;
        _incoming = null;
        _blend = 0;
        // stop resets the muted deck to zero while retaining its loaded asset.
        await _decks[old].stop();
      }
    } else if (index == _active &&
        _incoming == null &&
        position >=
            _duration - _blendDuration - const Duration(milliseconds: 350)) {
      final next = 1 - _active;
      await _decks[next].volume(0);
      await _decks[next].resume();
      _incoming = next;
      _blend = 0;
    }
  }

  Future<void> _applyVolume() async {
    if (_incoming == null) {
      await _decks[_active].volume(_gain);
      await _decks[1 - _active].volume(0);
    } else {
      // Equal-power fades keep ambient layers from dipping halfway through.
      await _decks[_active].volume(_gain * math.cos(_blend * math.pi / 2));
      await _decks[_incoming!].volume(_gain * math.sin(_blend * math.pi / 2));
    }
  }

  @override
  Future<void> volume(double value) => _enqueue(() async {
    if (_disposed) return;
    _gain = value.clamp(0.0, 1.0);
    await _applyVolume();
  });

  @override
  Future<void> resume() => _enqueue(() async {
    if (_disposed) return;
    await _applyVolume();
    await _decks[_active].resume();
    if (_incoming != null) await _decks[_incoming!].resume();
    _running = true;
  });

  @override
  Future<void> pause() {
    _running = false;
    return _enqueue(() async {
      _running = false;
      for (final deck in _decks) {
        await deck.pause();
      }
    });
  }

  @override
  Future<void> stop() {
    _running = false;
    _generation++;
    return _enqueue(() async {
      _running = false;
      for (final deck in _decks) {
        await deck.stop();
      }
      _active = 0;
      _incoming = null;
      _blend = 0;
    });
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _running = false;
    _generation++;
    await _queue;
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    for (final deck in _decks) {
      await deck.dispose();
    }
  }
}
