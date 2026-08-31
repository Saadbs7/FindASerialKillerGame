import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:find_a_serial_killer/data.dart';
import 'package:find_a_serial_killer/game_controller.dart';
import 'package:find_a_serial_killer/models.dart';
import 'package:find_a_serial_killer/result_scene.dart';

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

  test('case 2 is available as a second male case', () {
    final level = content.levels['case_002']!;
    expect(level.gender, Gender.men);
    expect(level.profileIds, hasLength(10));
    expect(level.killerProfileId, 'm017');
    expect(level.caseDescription, isNotEmpty);
    expect(content.profiles[level.killerProfileId]!.isKiller, isTrue);
  });

  test('men campaign contains ten cases with the intended difficulty curve', () {
    final menCases = content.levels.values.where((level) => level.gender == Gender.men).toList();
    expect(menCases, hasLength(10));
    expect(menCases.map((level) => level.difficulty), ['Easy', 'Easy', 'Easy', 'Medium', 'Medium', 'Medium', 'Hard', 'Hard', 'Hard', 'Very Hard']);
    expect(menCases.every((level) => level.profileIds.length == 10), isTrue);
    expect(menCases.map((level) => level.profileIds.where((id) => content.profiles[id]!.isKiller).length), everyElement(1));
  });

  test('Women cases contain ten profiles and unlock in sequence', () {
    final firstCase = content.levels['case_003']!;
    final secondCase = content.levels['case_004']!;
    expect(firstCase.gender, Gender.women);
    expect(firstCase.profileIds, hasLength(10));
    expect(secondCase.gender, Gender.women);
    expect(secondCase.profileIds, hasLength(10));
    expect(firstCase.killerProfileId, 'f007');
    expect(secondCase.killerProfileId, 'f017');
    expect(game.unlockedLevelIds, contains('case_003'));
    expect(game.unlockedLevelIds, isNot(contains('case_004')));
    expect(ContentValidator().validate(content), isEmpty);
  });

  test('winning a case unlocks and starts the next case briefing', () {
    game.chooseGender(Gender.men);
    game.continueToNextCase();
    expect(game.currentLevelId, 'case_002');
    expect(game.currentLevel.killerProfileId, 'm017');
    expect(game.currentLevel.gender, Gender.men);
    expect(game.currentProfiles, hasLength(10));
    expect(game.unlockedLevelIds, contains('case_002'));
    expect(game.allAvailableLevelsCompleted, isFalse);
    expect(game.phase, GamePhase.briefing);
    game.continueToNextCase();
    expect(game.allAvailableLevelsCompleted, isFalse);
    game.continueToNextCase();
    expect(game.allAvailableLevelsCompleted, isFalse);
    game.continueToNextCase();
    expect(game.currentLevelId, 'case_007');
    expect(game.allAvailableLevelsCompleted, isFalse);
  });

  test('starting a new men game uses the next unlocked unfinished case', () {
    game.chooseGender(Gender.men);
    game.continueToNextCase();
    game.returnToMainMenu();
    game.startNewGame();
    game.chooseGender(Gender.men);
    expect(game.currentLevelId, 'case_002');
    expect(game.phase, GamePhase.briefing);
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

  test('profile review can return to the previous profile without leaving the case', () {
    game.chooseGender(Gender.men);
    game.beginCase();
    final firstProfileId = game.currentProfiles[0].id;
    final secondProfileId = game.currentProfiles[1].id;
    expect(game.canGoToPreviousProfile, isFalse);
    expect(game.goToPreviousProfile(), isFalse);
    game.setReviewProfile(secondProfileId);
    expect(game.canGoToPreviousProfile, isTrue);
    expect(game.goToPreviousProfile(), isTrue);
    expect(game.activeProfile.id, firstProfileId);
    expect(game.goToPreviousProfile(), isFalse);
  });

  test('profile browsing selects three without rejecting the remaining profiles', () {
    game.chooseGender(Gender.men);
    game.beginCase();
    final firstProfileId = game.currentProfiles[0].id;
    final secondProfileId = game.currentProfiles[1].id;
    final thirdProfileId = game.currentProfiles[2].id;
    game.setReviewProfile(secondProfileId);
    expect(game.processCurrentProfile(investigate: true), isTrue);
    expect(game.activeProfile.id, thirdProfileId);
    expect(game.processCurrentProfile(investigate: true), isTrue);
    game.setReviewProfile(firstProfileId);
    expect(game.processCurrentProfile(investigate: true), isTrue);
    expect(game.selectedSuspects, [secondProfileId, thirdProfileId, firstProfileId]);
    expect(game.rejectedProfileIds, isEmpty);
    expect(game.phase, GamePhase.messaging);
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
    final selectedId = game.activeProfile.id;
    game.processCurrentProfile(investigate: true);
    final restored = GameController(content: content, preferences: await SharedPreferences.getInstance());
    await restored.restore();
    expect(restored.investigationGender, Gender.men);
    expect(restored.reviewedProfileIds, contains(selectedId));
    expect(restored.selectedSuspects, contains(selectedId));
    expect(restored.currentProfiles.map((profile) => profile.id), game.currentProfiles.map((profile) => profile.id));
    expect(restored.phase, GamePhase.profileReview);
  });

  test('Continue restarts the active case from its beginning', () {
    game.chooseGender(Gender.men);
    game.beginCase();
    final levelId = game.currentLevelId;
    final killerId = game.currentLevel.killerProfileId;
    game.processCurrentProfile(investigate: true);
    game.returnToMainMenu();

    game.resumeSavedGame();

    expect(game.currentLevelId, levelId);
    expect(game.currentLevel.killerProfileId, killerId);
    expect(game.currentProfileIndex, 0);
    expect(game.reviewedProfileIds, isEmpty);
    expect(game.selectedSuspects, isEmpty);
    expect(game.conversationHistory, isEmpty);
    expect(game.phase, GamePhase.profileReview);
  });

  test('profile order is randomized for a retry and preserved in saved progress', () async {
    game.chooseGender(Gender.men);
    game.beginCase();
    final firstOrder = game.currentProfiles.map((profile) => profile.id).toList();
    final restored = GameController(content: content, preferences: await SharedPreferences.getInstance());
    await restored.restore();
    expect(restored.currentProfiles.map((profile) => profile.id), firstOrder);

    game.retryCase();
    final retryOrder = game.currentProfiles.map((profile) => profile.id).toList();
    expect(retryOrder, hasLength(10));
    expect(retryOrder.toSet(), firstOrder.toSet());
    expect(retryOrder, isNot(firstOrder));
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
    final killerId = game.currentLevel.killerProfileId;
    final otherIds = game.currentProfiles.where((profile) => profile.id != killerId).take(2).map((profile) => profile.id);
    for (final id in [killerId, ...otherIds]) {
      game.setReviewProfile(id);
      game.processCurrentProfile(investigate: true);
    }
    for (final id in game.selectedSuspects) {
      for (var i = 0; i < 3; i++) {
        game.chooseResponse(id, 'b');
      }
    }
    expect(game.phase, GamePhase.messaging);
    game.openFinalAccusation();
    expect(game.phase, GamePhase.finalAccusation);
    game.selectAccusation('m007');
    expect(game.submitAccusation(), isTrue);
    expect(game.phase, GamePhase.levelWon);
    expect(game.unlockedLevelIds, contains('case_002'));
    game.returnToMainMenu();
    game.startNewGame();
    game.chooseGender(Gender.men);
    expect(game.currentLevelId, 'case_002');
    expect(game.phase, GamePhase.briefing);
  });

  test('malformed content is reported by validation', () {
    const malformed = GameContent(profiles: {}, levels: {}, conversations: {});
    final errors = ContentValidator().validate(malformed);
    expect(errors, isNotEmpty);
  });

  testWidgets('dismissed result animation keeps opacity values valid', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: CaseDismissedScene())));
    await tester.pump(const Duration(seconds: 3));
    expect(find.byType(CaseDismissedScene), findsOneWidget);
  });

  testWidgets('closed result animation keeps opacity values valid', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: CaseClosedScene())));
    await tester.pump(const Duration(seconds: 3));
    expect(find.byType(CaseClosedScene), findsOneWidget);
  });
}

extension on GameController {
  List<String> get selectedSuspects => selectedSuspectIds;
}
