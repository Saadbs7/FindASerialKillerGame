/// Platform-neutral audio boundary; tests can keep using silent playback.
abstract interface class AudioService {
  Future<void> playMusic(String assetPath);
  Future<void> playEffect(String assetPath);
  Future<void> stopMusic();
  void setMusicVolume(double value);
  void setEffectsVolume(double value);
}

class GameAudio {
  static const menu = 'audio/menu.wav';
  static const investigation = 'audio/investigation.wav';
  static const accusation = 'audio/accusation.wav';
  static const click = 'audio/click.wav';
  static const shortlist = 'audio/shortlist.wav';
  static const message = 'audio/message.wav';
  static const scan = 'audio/scan.wav';
  static const analyzed = 'audio/analyzed.wav';
  static const evidence = 'audio/evidence.wav';
  static const success = 'audio/success.wav';
  static const failure = 'audio/failure.wav';
  static const effects = [
    click,
    shortlist,
    message,
    scan,
    analyzed,
    evidence,
    success,
    failure
  ];
}

class NoopAudioService implements AudioService {
  const NoopAudioService();

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
