<p align="center">
  <img src="assets/logo.jpg" alt="Find a Serial Killer logo" width="180">
</p>

<h1 align="center">Find a Serial Killer</h1>

<p align="center">
  <strong>Every profile tells a story. One of them is hiding a killer.</strong>
</p>

<p align="center">
  Offline narrative deduction game | 20 cases | 200 profiles | 600 portraits | Built with Flutter
</p>

## About the Game

**Find a Serial Killer** is a fictional, offline mystery game in which you investigate dating-platform profiles connected to a series of crimes.

Choose a male or female suspect campaign, open an unlocked case file, and study ten possible suspects. Each profile has three photos alongside personal details, interests, answers, activity traces, hidden contradictions, and carefully placed red herrings. Shortlist exactly three people, speak to them as a potential date, connect their evidence, and make one final accusation.

The most suspicious person is not always the killer.

## Current Content

- 2 separate campaigns: male suspects and female suspects
- 10 cases per campaign
- 10 profiles per case
- 200 distinct profiles and 200 three-stage conversations
- 600 bundled WebP portraits, three for each profile
- Exactly one fixed killer in every case
- Progressive case unlocking and difficulty
- Fully data-driven case, profile, clue, and conversation content

### Case Files

| Case | Male suspect campaign | Female suspect campaign | Difficulty |
| ---: | --- | --- | --- |
| 01 | The Match That Never Existed | The Empty Chair | Easy |
| 02 | The Midnight Check-In | Three Minutes Early | Easy |
| 03 | The Playlist That Knew Too Much | Someone in the Water | Easy |
| 04 | Platform Zero | The House with No Address | Medium |
| 05 | The Glasshouse Alibi | The Black Funeral Card | Medium |
| 06 | The Eleventh Date | The Last Ferry Home | Medium |
| 07 | The Unsent Question | The Kindness Test | Hard |
| 08 | If You're Home | Everyone Chose Him | Hard |
| 09 | The Night Archive | The Garden That Knew Their Names | Hard |
| 10 | The Perfect Witness | Madam Verdict | Very Hard |

## Gameplay Loop

1. Select a suspect campaign and an unlocked case file.
2. Read the formatted investigation briefing and case intelligence.
3. Browse ten profiles presented in a randomized order.
4. Use Goggles to inspect activity information and potential leads.
5. Analyze a profile's pictures at any time to decrypt its Photo Metadata evidence.
6. Shortlist exactly three suspects for deeper investigation.
7. Complete three-stage private conversations with each suspect.
8. Reopen Goggles to unlock profile and conversation cross-checks.
9. Use the evidence board to compare suspicious leads connected by red threads.
10. Once all three conversations are complete, select one suspect, confirm the accusation, and receive a detective report.

Choose wisely. Justice depends on you.

## Features

- Dark, game-focused interface with responsive mobile layouts
- Randomized profile order on every new case attempt
- Three-photo galleries with fullscreen viewing and swipe navigation
- Distinct profiles written to feel like real potential dates
- Choice-based conversations with two responses at each stage
- Goggles intelligence with independent picture analysis plus profile and conversation cross-checks that unlock after chatting
- An evidence board that develops as conversations are completed
- Case briefing and options popups available during an investigation
- Browsable shortlisted profiles and a dedicated messages inbox
- Confirmed accusation flow with animated win and loss scenes
- Local campaign progression and settings storage
- Picture-analysis progress saved across restarts
- Detective ranks: **S**, **A**, **B**, **C**, and **FAILED**
- Runtime content validation in debug and release builds
- No account, server, or internet connection required

## Difficulty Progression

Both campaigns follow the same progression:

| Cases | Difficulty |
| --- | --- |
| 1 to 3 | Easy |
| 4 to 6 | Medium |
| 7 to 9 | Hard |
| 10 | Very Hard |

Later cases use subtler contradictions, more convincing innocent suspects, and less obvious killers.

## Detective Rankings

Successful investigations are ranked using the time taken and the number of profiles scanned with Goggles:

| Rank | Current criteria |
| --- | --- |
| S | Solve within 4 minutes using no more than 3 scans |
| A | Solve within 10 minutes using no more than 6 scans |
| C | Solve after scanning all 10 profiles |
| B | Solve successfully without meeting another rank condition |
| FAILED | Accuse the wrong suspect |

## Progress and Saving

Progress is stored locally with `shared_preferences`.

- Completed and unlocked cases are preserved between sessions.
- The currently active case is remembered.
- Every fresh launch opens on the main menu after the splash screen.
- **Continue** restarts the remembered case from its beginning, as intended by the current game design.
- Save writes are serialized and flushed during normal app lifecycle changes.
- Progress is device-local and is not currently synchronized to the cloud.

## Getting Started

### Requirements

- Flutter SDK `>=3.44.0` with Dart `>=3.12.0 <4.0.0`
- Android Studio, VS Code, or another Flutter-compatible editor
- An Android emulator or physical Android device

### Install and Run

```bash
git clone https://github.com/Saadbs7/FindASerialKillerGame.git
cd FindASerialKillerGame
flutter pub get
flutter run
```

### Verify the Project

```bash
flutter analyze
flutter test
```

### Build an Android APK

```bash
flutter build apk --release
```

The generated APK is placed at:

```text
build/app/outputs/flutter-apk/app-release.apk
```

Prebuilt APKs, when published, can be found on the [GitHub Releases page](https://github.com/Saadbs7/FindASerialKillerGame/releases).

> **Release note:** the current Android release build still uses debug signing. Configure a private upload keystore before publishing to Google Play or distributing a production release.

## Project Structure

```text
lib/
|-- main.dart              # App startup, splash, theme, and screen routing
|-- app_scope.dart         # Provides the game controller to the widget tree
|-- game_controller.dart   # Game state, progression, saving, and scoring
|-- models.dart            # Case, profile, clue, and conversation models
|-- data.dart              # JSON loading and release-safe validation
|-- screens.dart           # Main menu and all gameplay screens
|-- widgets.dart           # Shared UI, Goggles, and evidence board
|-- result_scene.dart      # Animated case-closed and case-dismissed scenes
|-- audio_service.dart     # Audio interface and asset names
|-- player_audio_service.dart # Offline playback, fades, volumes, and lifecycle
`-- game_soundtrack.dart   # Music and outcome cues driven by game phase

assets/
|-- data/
|   |-- levels.json        # 20 cases, briefings, difficulty, and profile sets
|   |-- profiles.json      # 200 profiles, clues, and evidence-board leads
|   `-- conversations.json # 200 distinct three-stage conversations
|-- audio/                 # Original synthesized music, effects, and provenance
|-- images/profiles/
|   |-- male/              # Flat WebP portrait assets such as m001_01.webp
|   `-- female/            # Flat WebP portrait assets such as f001_01.webp
|-- logo.jpg
`-- splash_logo.jpg

test/
`-- game_logic_test.dart   # Content, gameplay, persistence, and widget tests
```

## Data-Driven Content

The narrative content is separated from the Flutter interface:

- `levels.json` defines each case, its formatted intelligence, difficulty, ten profiles, and single killer.
- `profiles.json` stores character details, profile questions, portrait paths, Goggles data, clues, and concise suspicious leads.
- `conversations.json` stores three conversation stages and two response choices per stage for every profile.

At startup, the game validates IDs, profile ownership, case size, killer count, clue references, conversation structure, and formatted case intelligence. Invalid content produces a clear error instead of silently entering the game.

## Current Development Notes

- The primary release target is Android.
- All 600 profile portraits are bundled and used in the galleries. Accusation choices show a single static portrait rather than an interactive gallery.
- Offline audio includes three 48-second music loops and eight short interaction/result effects. Music continues across profile browsing and chats, changes for the final accusation, and fades out for the result cue.
- Long music uses 44.1 kHz stereo MP3 at 192 kbps; short effects use WAV. The original music WAV masters remain in the repository but are excluded from the app's asset bundle. Regenerate MP3s with `tools/encode_music.py --ffmpeg <path>` after changing the masters.
- Music uses two preloaded players with a three-second equal-power overlap before the end of each file, avoiding an audible stop/restart at loop boundaries. One shared audio session manages focus and interruptions for both players.
- Existing music and effects sliders control separate channels; zero mutes that channel. Backgrounding pauses music and stops effects. Returning resumes the current music without replaying old effects.
- Audio was synthesized specifically for this project without external recordings or samples. See `assets/audio/PROVENANCE.md`, the reproducible generator `tools/generate_audio.py`, and the asset hashes in `assets/audio/manifest.json`.
- Playback uses `audioplayers`. Native device listening, phone-call interruptions, silent-mode behavior, and speaker balance still need manual verification.
- Android production signing and Play Store preparation are still required.

## Roadmap

- Refine audio balance through device listening tests
- Configure production Android signing
- Prepare the Google Play listing and release bundle
- Add achievements and longer-term player statistics
- Continue accessibility and device-size testing

## Disclaimer

This is a work of fiction. All characters, cases, conversations, organizations, and events are fictional. Any resemblance to real people or events is coincidental.

## License

This repository does not currently include an open-source license. The project is presently intended for personal and educational use.
