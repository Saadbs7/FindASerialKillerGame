import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:find_a_serial_killer/audio_service.dart';
import 'package:find_a_serial_killer/data.dart';
import 'package:find_a_serial_killer/game_controller.dart';
import 'package:find_a_serial_killer/game_soundtrack.dart';
import 'package:find_a_serial_killer/models.dart';
import 'package:find_a_serial_killer/player_audio_service.dart';

class FakeVoice implements AudioVoice {
  final List<String> loads = [];
  final List<double> volumes = [];
  int resumes = 0;
  int pauses = 0;
  bool disposed = false;
  Completer<void>? loading;
  bool fail = false;
  @override
  Future<void> load(String asset, {required bool loop}) async {
    loads.add(asset);
    if (fail) throw StateError('Audio hardware unavailable');
    await loading?.future;
  }

  @override
  Future<void> volume(double value) async => volumes.add(value);
  @override
  Future<void> resume() async {
    resumes++;
  }

  @override
  Future<void> pause() async {
    pauses++;
  }

  @override
  Future<void> stop() async {}
  @override
  Future<void> dispose() async {
    disposed = true;
  }
}

class RecordingAudio implements AudioService {
  final List<String> tracks = [];
  final List<String> effects = [];
  int stops = 0;
  @override
  Future<void> playMusic(String assetPath) async => tracks.add(assetPath);
  @override
  Future<void> playEffect(String assetPath) async => effects.add(assetPath);
  @override
  Future<void> stopMusic() async {
    stops++;
  }

  @override
  void setMusicVolume(double value) {}
  @override
  void setEffectsVolume(double value) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<FakeVoice> voices;
  late PlayerAudioService audio;
  setUp(() {
    voices = [];
    audio = PlayerAudioService(
        createVoice: () {
          final voice = FakeVoice();
          voices.add(voice);
          return voice;
        },
        fadeStep: Duration.zero);
  });
  tearDown(() => audio.dispose());

  test('same track is continuous, and latest phase wins queued transitions',
      () async {
    await audio.playMusic(GameAudio.menu);
    await audio.playMusic(GameAudio.menu);
    expect(voices.first.loads, [GameAudio.menu]);
    expect(voices.first.resumes, 1);
    final old = audio.playMusic(GameAudio.investigation);
    final latest = audio.playMusic(GameAudio.accusation);
    await Future.wait([old, latest]);
    expect(voices.first.loads, [GameAudio.menu, GameAudio.accusation]);
  });

  test('background stops effects and resumes music without loading it again',
      () async {
    await audio.playMusic(GameAudio.menu);
    await audio.setSuspended(true);
    final count = voices.first.resumes;
    await audio.playEffect(GameAudio.click);
    expect(voices, hasLength(1));
    expect(voices.first.pauses, greaterThan(0));
    await audio.setSuspended(false);
    expect(voices.first.resumes, count + 1);
    expect(voices.first.loads, [GameAudio.menu]);
  });

  test(
      'mute before start, unmute, and stop while muted do not revive old music',
      () async {
    audio.setMusicVolume(0);
    await audio.playMusic(GameAudio.menu);
    expect(voices.first.resumes, 0);
    audio.setMusicVolume(.3);
    await audio.playMusic(GameAudio.menu);
    expect(voices.first.volumes.last, closeTo(.3, .001));
    audio.setMusicVolume(0);
    await audio.stopMusic();
    final count = voices.first.resumes;
    audio.setMusicVolume(.3);
    await audio.stopMusic();
    expect(voices.first.resumes, count);
  });

  test('effects are throttled and muted effects do not load', () async {
    audio.setEffectsVolume(0);
    await audio.playEffect(GameAudio.click);
    expect(voices, hasLength(1));
    audio.setEffectsVolume(.4);
    await Future.wait(
        List.generate(12, (_) => audio.playEffect(GameAudio.click)));
    expect(voices, hasLength(2));
    expect(voices.last.resumes, 1);
    expect(voices.last.volumes.last, .4);
  });

  test('effect that finishes loading in background is not played later',
      () async {
    // First voice is music; the effect voice is allocated by playEffect.
    final effect = audio.playEffect(GameAudio.scan);
    await audio.setSuspended(true);
    await effect;
    expect(voices.last.resumes, 0);
  });

  test('audio failures are contained and disposal releases every voice',
      () async {
    voices.first.fail = true;
    await audio.playMusic(GameAudio.menu);
    await audio.playEffect(GameAudio.click);
    await audio.dispose();
    expect(voices.every((voice) => voice.disposed), isTrue);
    final count = voices.length;
    await audio.playEffect(GameAudio.message);
    expect(voices, hasLength(count));
  });

  test('soundtrack follows gameplay without restarting for scans or replies',
      () async {
    SharedPreferences.setMockInitialValues({});
    final recording = RecordingAudio();
    final content = await const ContentRepository().load();
    final game = GameController(
        content: content,
        preferences: await SharedPreferences.getInstance(),
        audioService: recording);
    final soundtrack = GameSoundtrack(game);
    game.chooseCase('case_001');
    game.beginCase();
    game.recordGogglesScan(game.activeProfile.id);
    for (var i = 0; i < 3; i++) {
      game.processCurrentProfile(investigate: true);
    }
    for (final id in game.selectedSuspectIds) {
      while (!game.completedConversationIds.contains(id)) {
        final stage = game.conversationFor(id).stages[game.stageIndexFor(id)];
        game.chooseResponse(id, stage.responseOptions.first.id);
      }
    }
    expect(recording.tracks, [GameAudio.menu, GameAudio.investigation]);
    game.openFinalAccusation();
    expect(recording.tracks.last, GameAudio.accusation);
    game.selectAccusation(game.selectedSuspectIds.first);
    game.submitAccusation();
    expect(recording.stops, 1);
    final outcome = game.phase == GamePhase.levelWon
        ? GameAudio.success
        : GameAudio.failure;
    expect(recording.effects.where((item) => item == outcome), hasLength(1));
    game.setEffectsVolume(.5);
    expect(recording.effects.where((item) => item == outcome), hasLength(1));
    soundtrack.dispose();
    await game.flushPendingWrites();
    game.dispose();
  });
}
