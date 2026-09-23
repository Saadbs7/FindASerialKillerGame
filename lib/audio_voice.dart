abstract interface class AudioVoice {
  Future<void> load(String asset, {required bool loop});
  Future<void> volume(double value);
  Future<void> resume();
  Future<void> pause();
  Future<void> stop();
  Future<void> dispose();
}

abstract interface class PositionedAudioVoice implements AudioVoice {
  Stream<Duration> get positions;
  Future<Duration?> duration();
}
