# Original synthesized game audio

The WAV masters were generated for Find a Serial Killer using the repository's
`tools/generate_audio.py`. The arrangements, envelopes, oscillators, and effects
were authored for this project. No third-party recordings, samples, soundfonts,
melodies, music-generation service, or stock audio was used.

The source script is the reproducible provenance record; `manifest.json` records
durations, signal measurements, and SHA-256 hashes. NumPy performs numerical
calculations and contributes no recorded audio. WAV encoding uses Python's
standard library. There are no third-party audio attribution or royalty terms
attached to these files. This document does not change the repository's license
or claim that automated copyright systems can never make a mistaken match.

Menu, investigation, and accusation are 48-second circular ambient arrangements.
The eight short effects correspond to interface actions and case outcomes.
The WAV masters and short effects use 22.05 kHz stereo 16-bit PCM.
The game bundles the three music tracks as 44.1 kHz stereo, 192 kbps MP3s,
encoded from those same masters with `tools/encode_music.py` and FFmpeg's
libmp3lame encoder. `music_manifest.json` records the source and output hashes
and encoding settings. Run the encoder after regenerating the WAV masters.
The music WAVs remain as reproducible sources but are not bundled in the app.
Encoding changes no composition or audio ownership; FFmpeg is a development
tool and is not shipped with the game.

Playback uses the MIT-licensed audioplayers and audio_session packages;
their software licenses remain applicable to those dependencies.
