import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:find_a_serial_killer/audio_voice.dart';
import 'package:find_a_serial_killer/looping_audio_voice.dart';

class Deck implements PositionedAudioVoice {
  final ticks = StreamController<Duration>.broadcast(sync: true);
  final loads = <String>[];
  double gain = 0;
  bool playing = false;
  bool disposed = false;
  int resumes = 0;
  int stops = 0;
  Completer<void>? startGate;
  @override
  Stream<Duration> get positions => ticks.stream;
  @override
  Future<Duration?> duration() async => const Duration(seconds: 48);
  @override
  Future<void> load(String asset, {required bool loop}) async {
    expect(loop, isFalse);
    loads.add(asset);
  }

  @override
  Future<void> volume(double value) async {
    gain = value;
  }

  @override
  Future<void> resume() async {
    await startGate?.future;
    playing = true;
    resumes++;
  }

  @override
  Future<void> pause() async {
    playing = false;
  }

  @override
  Future<void> stop() async {
    playing = false;
    stops++;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    await ticks.close();
  }
}

void main() {
  late Deck first;
  late Deck second;
  late LoopingAudioVoice music;
  setUp(() async {
    first = Deck();
    second = Deck();
    music = LoopingAudioVoice(first, second);
    await music.load('music.wav', loop: true);
    await music.volume(.7);
    await music.resume();
  });
  tearDown(() => music.dispose());

  Future<void> tick(Deck deck, int milliseconds) async {
    deck.ticks.add(Duration(milliseconds: milliseconds));
    await music.idle;
  }

  test(
    'next copy starts before EOF and overlapping gains preserve power',
    () async {
      await tick(first, 44000);
      expect(second.playing, isFalse);
      await tick(first, 44700);
      expect(first.playing, isTrue);
      expect(second.playing, isTrue);
      expect(second.gain, 0);
      await tick(second, 1500);
      expect(
        math.pow(first.gain, 2) + math.pow(second.gain, 2),
        closeTo(.49, .0001),
      );
      await tick(second, 3000);
      expect(first.playing, isFalse);
      expect(second.playing, isTrue);
      expect(second.gain, closeTo(.7, .0001));
    },
  );

  test(
    'repeated loops reuse both preloaded decks without reopening the file',
    () async {
      for (var i = 0; i < 6; i++) {
        final outgoing = i.isEven ? first : second;
        final incoming = i.isEven ? second : first;
        await tick(outgoing, 44700);
        await tick(incoming, 3000);
        expect(incoming.playing, isTrue);
        expect(outgoing.playing, isFalse);
      }
      expect(first.loads, ['music.wav']);
      expect(second.loads, ['music.wav']);
    },
  );

  test(
    'pause freezes a blend and both decks resume at their existing positions',
    () async {
      await tick(first, 44700);
      await tick(second, 1000);
      final gains = [first.gain, second.gain];
      await music.pause();
      await tick(second, 3000);
      expect(first.playing || second.playing, isFalse);
      expect([first.gain, second.gain], gains);
      await music.resume();
      expect(first.playing && second.playing, isTrue);
      expect([first.gain, second.gain], gains);
      await tick(second, 3000);
      expect(second.playing, isTrue);
      expect(first.playing, isFalse);
    },
  );

  test('mute applies to both decks during a handoff', () async {
    await tick(first, 44700);
    await tick(second, 1500);
    await music.volume(0);
    expect([first.gain, second.gain], [0, 0]);
    await tick(second, 2000);
    expect([first.gain, second.gain], [0, 0]);
  });

  test(
    'track change discards old position events and preloads both copies',
    () async {
      await tick(first, 44700);
      final changing = music.load('new.wav', loop: true);
      first.ticks.add(const Duration(seconds: 47));
      second.ticks.add(const Duration(seconds: 3));
      await changing;
      expect(first.playing || second.playing, isFalse);
      await music.resume();
      expect(first.playing, isTrue);
      expect(second.playing, isFalse);
      await tick(first, 44700);
      expect(second.playing, isTrue);
      expect(first.loads, ['music.wav', 'new.wav']);
      expect(second.loads, ['music.wav', 'new.wav']);
    },
  );

  test(
    'background request during native start leaves both decks paused',
    () async {
      second.startGate = Completer<void>();
      first.ticks.add(const Duration(milliseconds: 44700));
      await Future<void>.delayed(Duration.zero);
      final paused = music.pause();
      second.startGate!.complete();
      await paused;
      expect(first.playing || second.playing, isFalse);
    },
  );

  test(
    'pause queued during resume cannot reactivate the loop scheduler',
    () async {
      await music.pause();
      first.startGate = Completer<void>();
      final resuming = music.resume();
      await Future<void>.delayed(Duration.zero);
      final pausing = music.pause();
      first.startGate!.complete();
      await Future.wait([resuming, pausing]);
      await tick(first, 44700);
      expect(first.playing || second.playing, isFalse);
      expect(second.resumes, 0);
    },
  );
}
