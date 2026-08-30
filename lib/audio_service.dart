/// Platform-neutral audio boundary. The vertical slice ships without final
/// audio assets, so the default implementation is intentionally a no-op.
abstract interface class AudioService {
  Future<void> playMusic(String assetPath);
  Future<void> playEffect(String assetPath);
  Future<void> stopMusic();
  void setMusicVolume(double value);
  void setEffectsVolume(double value);
}

class NoopAudioService implements AudioService {
  @override
  Future<void> playMusic(String assetPath) async {}
  @override
  Future<void> playEffect(String assetPath) async {}
  @override
  Future<void> stopMusic() async {}
  @override
  void setMusicVolume(double value) {}
  @override
  void setEffectsVolume(double value) {}
}

