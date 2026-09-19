import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'audio_service.dart';

/// Small playback seam for testing transitions without native audio hardware.
abstract interface class AudioVoice {
  Future<void> load(String asset, {required bool loop});
  Future<void> volume(double value);
  Future<void> resume();
  Future<void> pause();
  Future<void> stop();
  Future<void> dispose();
}

class _PlayerVoice implements AudioVoice {
  final _player = AudioPlayer();

  @override
  Future<void> load(String asset, {required bool loop}) async {
    await _player.setAudioContext(AudioContext(
      android: AudioContextAndroid(
        usageType: AndroidUsageType.game,
        audioFocus: loop ? AndroidAudioFocus.gain : AndroidAudioFocus.none,
      ),
      iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
    ));
    await _player.setReleaseMode(loop ? ReleaseMode.loop : ReleaseMode.stop);
    await _player.setSource(AssetSource(asset));
  }

  @override
  Future<void> volume(double value) => _player.setVolume(value);
  @override
  Future<void> resume() => _player.resume();
  @override
  Future<void> pause() => _player.pause();
  @override
  Future<void> stop() => _player.stop();
  @override
  Future<void> dispose() => _player.dispose();
}

/// One music voice, cached effect voices, and serialized music transitions.
/// New requests cancel an in-flight fade so stale tracks cannot start later.
class PlayerAudioService implements AudioService {
  PlayerAudioService(
      {AudioVoice Function()? createVoice,
      this.fadeStep = const Duration(milliseconds: 35)})
      : _createVoice = createVoice ?? _PlayerVoice.new {
    _music = _createVoice();
  }

  final AudioVoice Function() _createVoice;
  final Duration fadeStep;
  late final AudioVoice _music;
  final Map<String, AudioVoice> _effects = {};
  final Map<String, Future<void>> _loading = {};
  final Set<String> _busy = {};
  final Map<String, DateTime> _lastPlayed = {};
  Future<void> _musicQueue = Future.value();
  String? _wantedTrack;
  String? _loadedTrack;
  double _musicVolume = .7;
  double _effectsVolume = .85;
  double _fade = 0;
  bool _suspended = false;
  bool _disposed = false;
  int _revision = 0;
  int _effectRevision = 0;

  Future<void> _safe(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      debugPrint('Audio unavailable: $error');
    }
  }

  Future<void> _loadEffect(String asset) => _loading.putIfAbsent(asset, () {
        final voice = _effects.putIfAbsent(asset, _createVoice);
        return voice.load(asset, loop: false);
      });

  Future<void> preload() async {
    for (final asset in GameAudio.effects) {
      if (_disposed) return;
      await _safe(() => _loadEffect(asset));
    }
  }

  Future<void> _scheduleMusic() {
    final revision = ++_revision;
    _musicQueue = _musicQueue.then((_) => _safe(() async {
          bool current() => !_disposed && revision == _revision;
          if (!current()) return;
          if (_suspended || _musicVolume == 0) {
            await _music.pause();
            return;
          }
          if (_loadedTrack != _wantedTrack) {
            final startFade = _fade;
            for (var i = 7; i >= 0 && current(); i--) {
              _fade = startFade * i / 8;
              await _music.volume(_fade * _musicVolume);
              await Future<void>.delayed(fadeStep);
            }
            if (!current()) return;
            await _music.stop();
            _loadedTrack = null;
            final wanted = _wantedTrack;
            if (wanted == null || !current()) return;
            await _music.load(wanted, loop: true);
            _loadedTrack = wanted;
          }
          if (_loadedTrack == null || !current()) return;
          await _music.volume(0);
          if (!current()) return;
          await _music.resume();
          for (var i = 1; i <= 8 && current(); i++) {
            _fade = i / 8;
            await _music.volume(_fade * _musicVolume);
            await Future<void>.delayed(fadeStep);
          }
        }));
    return _musicQueue;
  }

  @override
  Future<void> playMusic(String assetPath) {
    if (_disposed || _wantedTrack == assetPath) return _musicQueue;
    _wantedTrack = assetPath;
    return _scheduleMusic();
  }

  @override
  Future<void> stopMusic() {
    _wantedTrack = null;
    return _scheduleMusic();
  }

  @override
  Future<void> playEffect(String assetPath) async {
    final now = DateTime.now();
    if (_disposed ||
        _suspended ||
        _effectsVolume == 0 ||
        _busy.contains(assetPath) ||
        now.difference(_lastPlayed[assetPath] ?? DateTime(2000)) <
            const Duration(milliseconds: 140)) {
      return;
    }
    _lastPlayed[assetPath] = now;
    _busy.add(assetPath);
    final revision = _effectRevision;
    try {
      await _safe(() async {
        await _loadEffect(assetPath);
        if (_disposed || _suspended || revision != _effectRevision) return;
        final voice = _effects[assetPath]!;
        await voice.stop();
        await voice.volume(_effectsVolume);
        if (_disposed || _suspended || revision != _effectRevision) return;
        await voice.resume();
      });
    } finally {
      _busy.remove(assetPath);
    }
  }

  @override
  void setMusicVolume(double value) {
    final wasMuted = _musicVolume == 0;
    _musicVolume = value.clamp(0, 1);
    if (_disposed) return;
    if (wasMuted != (_musicVolume == 0)) {
      unawaited(_scheduleMusic());
    } else {
      unawaited(_safe(() => _music.volume(_fade * _musicVolume)));
    }
  }

  @override
  void setEffectsVolume(double value) {
    _effectsVolume = value.clamp(0, 1);
    if (_disposed) return;
    if (_effectsVolume == 0) _effectRevision++;
    for (final voice in _effects.values) {
      unawaited(_safe(() => voice.volume(_effectsVolume)));
    }
  }

  Future<void> setSuspended(bool value) async {
    if (_disposed || _suspended == value) return;
    _suspended = value;
    _effectRevision++;
    final transition = _scheduleMusic();
    if (value) {
      await _safe(_music.pause);
      for (final voice in _effects.values) {
        await _safe(voice.stop);
      }
    }
    await transition;
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _revision++;
    _effectRevision++;
    await _musicQueue;
    for (final load in _loading.values) {
      await _safe(() => load);
    }
    await _safe(_music.dispose);
    for (final voice in _effects.values) {
      await _safe(voice.dispose);
    }
  }
}
