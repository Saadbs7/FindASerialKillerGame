import 'dart:async';
import 'audio_service.dart';
import 'game_controller.dart';
import 'models.dart';

/// Reacts to phase changes, not widget rebuilds or individual suspect identities.
class GameSoundtrack {
  GameSoundtrack(this.game) {
    game.addListener(_update);
    _update();
  }

  final GameController game;
  GamePhase? _lastPhase;
  String? _track;

  void _update() {
    if (_lastPhase == game.phase) return;
    _lastPhase = game.phase;
    final track = switch (game.phase) {
      GamePhase.mainMenu || GamePhase.genderSelection => GameAudio.menu,
      GamePhase.finalAccusation => GameAudio.accusation,
      GamePhase.levelWon || GamePhase.levelFailed => null,
      _ => GameAudio.investigation,
    };
    if (_track != track) {
      _track = track;
      unawaited(track == null
          ? game.audioService.stopMusic()
          : game.audioService.playMusic(track));
    }
    if (game.phase == GamePhase.levelWon) {
      game.playSound(GameAudio.success);
    } else if (game.phase == GamePhase.levelFailed) {
      game.playSound(GameAudio.failure);
    }
  }

  void dispose() => game.removeListener(_update);
}
