import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:find_a_serial_killer/data.dart';
import 'package:find_a_serial_killer/game_controller.dart';
import 'package:find_a_serial_killer/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late GameContent content;
  late GameController game;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    content = await const ContentRepository().load();
    game = GameController(content: content, preferences: await SharedPreferences.getInstance());
  });

  test('sample case has ten profiles and exactly one fixed killer', () {
    final level = content.levels['case_001']!;
    expect(level.profileIds, hasLength(10));
    expect(content.profilesFor(level).where((profile) => profile.isKiller), hasLength(1));
    expect(level.killerProfileId, 'm007');
    expect(ContentValidator().validate(content), isEmpty);
  });

  test('profile review never allows more than three suspects', () {
    game.chooseGender(Gender.men);
    game.beginCase();
    for (var i = 0; i < 3; i++) {
      expect(game.processCurrentProfile(investigate: true), isTrue);
    }
    expect(game.selectedSuspects.length, 3);
    expect(game.processCurrentProfile(investigate: true), isFalse);
    expect(game.selectedSuspects.length, 3);
  });

  test('retry resets play state but preserves the same level and killer', () {
    game.chooseGender(Gender.men);
    game.beginCase();
    game.processCurrentProfile(investigate: true);
    final killerBefore = game.currentLevel.killerProfileId;
    game.retryCase();
    expect(game.currentLevel.killerProfileId, killerBefore);
    expect(game.reviewedProfileIds, isEmpty);
    expect(game.selectedSuspects, isEmpty);
    expect(game.phase, GamePhase.profileReview);
  });

  test('saved progress restores as a playable state', () async {
    game.chooseGender(Gender.men);
    game.beginCase();
    game.processCurrentProfile(investigate: true);
    final restored = GameController(content: content, preferences: await SharedPreferences.getInstance());
    await restored.restore();
    expect(restored.investigationGender, Gender.men);
    expect(restored.reviewedProfileIds, contains('m001'));
    expect(restored.selectedSuspects, contains('m001'));
    expect(restored.phase, GamePhase.profileReview);
  });

  test('conversation advances through both-choice stages and completes', () {
    game.chooseGender(Gender.men);
    game.beginCase();
    for (var i = 0; i < 2; i++) {
      game.processCurrentProfile(investigate: true);
    }
    for (var i = 2; i < 6; i++) {
      game.processCurrentProfile(investigate: false);
    }
    game.processCurrentProfile(investigate: true);
    for (var i = 7; i < 10; i++) {
      game.processCurrentProfile(investigate: false);
    }
    expect(game.phase, GamePhase.messaging);
    final id = game.selectedSuspects.first;
    for (var i = 0; i < 3; i++) {
      game.chooseResponse(id, 'a');
    }
    expect(game.isConversationComplete(id), isTrue);
    expect(game.conversationHistory[id], hasLength(9));
  });

  test('accusation correctness and progression are state-driven', () {
    game.chooseGender(Gender.men);
    game.beginCase();
    for (var i = 0; i < 2; i++) {
      game.processCurrentProfile(investigate: true);
    }
    for (var i = 2; i < 6; i++) {
      game.processCurrentProfile(investigate: false);
    }
    game.processCurrentProfile(investigate: true);
    for (var i = 7; i < 10; i++) {
      game.processCurrentProfile(investigate: false);
    }
    for (final id in game.selectedSuspects) {
      for (var i = 0; i < 3; i++) {
        game.chooseResponse(id, 'b');
      }
    }
    expect(game.phase, GamePhase.finalAccusation);
    game.selectAccusation('m007');
    expect(game.submitAccusation(), isTrue);
    expect(game.phase, GamePhase.levelWon);
    game.continueToNextCase();
    expect(game.completedLevelIds, contains('case_001'));
    expect(game.phase, GamePhase.mainMenu);
  });

  test('malformed content is reported by validation', () {
    const malformed = GameContent(profiles: {}, levels: {}, conversations: {});
    final errors = ContentValidator().validate(malformed);
    expect(errors, isNotEmpty);
  });
}

extension on GameController {
  List<String> get selectedSuspects => selectedSuspectIds;
}
