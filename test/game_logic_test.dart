import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:find_a_serial_killer/app_scope.dart';
import 'package:find_a_serial_killer/audio_service.dart';
import 'package:find_a_serial_killer/data.dart';
import 'package:find_a_serial_killer/game_controller.dart';
import 'package:find_a_serial_killer/main.dart' show SplashScreen;
import 'package:find_a_serial_killer/models.dart';
import 'package:find_a_serial_killer/result_scene.dart';
import 'package:find_a_serial_killer/screens.dart';
import 'package:find_a_serial_killer/widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late GameContent content;
  late GameController game;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    content = await const ContentRepository().load();
    game = GameController(
        content: content, preferences: await SharedPreferences.getInstance());
  });

  test('sample case has ten profiles and exactly one fixed killer', () {
    final level = content.levels['case_001']!;
    expect(level.profileIds, hasLength(10));
    expect(content.profilesFor(level).where((profile) => profile.isKiller),
        hasLength(1));
    expect(level.killerProfileId, 'm007');
    expect(level.caseDescription, contains('On three different nights'));
    expect(level.caseDescription, contains('each at exactly midnight'));
    expect(
        level.caseDescription, contains('meet at a different late-night cafe'));
    expect(level.caseDescription, contains('disappeared before dawn'));
    expect(level.caseDescription, isNot(contains('11:47')));
    expect(
        level.caseIntelligenceFormat
            .expand((block) => block.contentParts)
            .join(' '),
        level.caseDescription);
    expect(level.caseIntelligenceFormat.map((block) => block.type), [
      CaseIntelligenceBlockType.paragraph,
      CaseIntelligenceBlockType.bullets,
      CaseIntelligenceBlockType.paragraph,
      CaseIntelligenceBlockType.callout,
    ]);
    expect(level.caseIntelligenceFormat[1].heading, 'THE PATTERN');
    expect(level.caseIntelligenceFormat[1].items, hasLength(3));
    expect(level.caseIntelligenceFormat[3].heading, 'INVESTIGATIVE FOCUS');
    expect(ContentValidator().validate(content), isEmpty);
  });

  testWidgets('case 1 briefing renders its formatted intelligence blocks',
      (tester) async {
    game.chooseGender(Gender.men);
    await tester.pumpWidget(
      GameScope(
        controller: game,
        child: const MaterialApp(home: BriefingScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('THE PATTERN'), findsOneWidget);
    expect(find.text('INVESTIGATIVE FOCUS'), findsOneWidget);
    expect(
        find.text(
            'Each agreed to meet at a different late-night cafe and disappeared before dawn.'),
        findsOneWidget);
    expect(find.text(game.currentLevel.caseDescription), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('men cases 2 through 5 preserve their formatted intelligence', () {
    final expectedTypes = {
      'case_002': [
        CaseIntelligenceBlockType.paragraph,
        CaseIntelligenceBlockType.quote,
        CaseIntelligenceBlockType.bullets,
        CaseIntelligenceBlockType.paragraph,
        CaseIntelligenceBlockType.paragraph,
        CaseIntelligenceBlockType.callout,
      ],
      'case_003': [
        CaseIntelligenceBlockType.paragraph,
        CaseIntelligenceBlockType.bullets,
        CaseIntelligenceBlockType.quote,
        CaseIntelligenceBlockType.paragraph,
        CaseIntelligenceBlockType.callout,
      ],
      'case_004': [
        CaseIntelligenceBlockType.paragraph,
        CaseIntelligenceBlockType.timeline,
        CaseIntelligenceBlockType.bullets,
        CaseIntelligenceBlockType.quote,
        CaseIntelligenceBlockType.paragraph,
        CaseIntelligenceBlockType.callout,
      ],
      'case_005': [
        CaseIntelligenceBlockType.quote,
        CaseIntelligenceBlockType.paragraph,
        CaseIntelligenceBlockType.bullets,
        CaseIntelligenceBlockType.bullets,
        CaseIntelligenceBlockType.callout,
        CaseIntelligenceBlockType.paragraph,
        CaseIntelligenceBlockType.callout,
      ],
    };

    for (final entry in expectedTypes.entries) {
      final level = content.levels[entry.key]!;
      expect(
          level.caseIntelligenceFormat.map((block) => block.type), entry.value,
          reason: entry.key);
      expect(
          level.caseIntelligenceFormat
              .expand((block) => block.contentParts)
              .join(' '),
          level.caseDescription,
          reason: '${entry.key} must retain every word in its description');
    }

    expect(content.levels['case_002']!.caseIntelligenceFormat[2].heading,
        'WHAT THE HOTELS SHOW');
    expect(content.levels['case_003']!.caseIntelligenceFormat[2].heading,
        'VOICE SAMPLE');
    expect(content.levels['case_004']!.caseIntelligenceFormat[1].heading,
        "MARA'S ESCAPE");
    expect(content.levels['case_005']!.caseIntelligenceFormat[4].heading,
        'THE IMPOSSIBLE DETAIL');
    expect(ContentValidator().validate(content), isEmpty);
  });

  testWidgets('men cases 2 through 5 render their distinct intelligence styles',
      (tester) async {
    final expectedHeading = {
      'case_002': 'THE REPEATED MESSAGE',
      'case_003': 'PLAYLIST CHANGES',
      'case_004': "MARA'S ESCAPE",
      'case_005': 'THE IMPOSSIBLE DETAIL',
    };

    for (final entry in expectedHeading.entries) {
      game.unlockedLevelIds.add(entry.key);
      game.chooseCase(entry.key);
      await tester.pumpWidget(
        GameScope(
          controller: game,
          child: const MaterialApp(home: BriefingScreen()),
        ),
      );
      await tester.pump();

      expect(find.text(entry.value), findsOneWidget, reason: entry.key);
      expect(find.text(game.currentLevel.caseDescription), findsNothing,
          reason: entry.key);
      expect(tester.takeException(), isNull, reason: entry.key);
    }
  });

  test('case 2 establishes the complete Midnight Check-In mystery', () {
    final level = content.levels['case_002']!;
    expect(level.gender, Gender.men);
    expect(level.title, 'The Midnight Check-In');
    expect(level.difficulty, 'Easy');
    expect(level.profileIds, hasLength(10));
    expect(level.killerProfileId, 'm017');
    expect(content.profiles[level.killerProfileId]!.isKiller, isTrue);
    expect(content.profilesFor(level).where((profile) => profile.isKiller),
        hasLength(1));
    expect(level.caseDescription, contains('three dating-app users'));
    expect(level.caseDescription, contains("'Your room is ready.'"));
    expect(level.caseDescription, contains('exactly 12:14 a.m.'));
    expect(level.caseDescription, contains("hotel's side entrance"));
    expect(level.caseDescription, contains('transit ticket folded twice'));
    expect(level.caseDescription, contains('hotel-and-driver partner system'));
  });

  test('case 2 profiles are distinct dating profiles, not case summaries', () {
    const profileIds = [
      'm011',
      'm012',
      'm013',
      'm014',
      'm015',
      'm016',
      'm017',
      'm018',
      'm019',
      'm020',
    ];
    final prompts = <String>[];
    final answers = <String>[];
    final descriptions = <String>[];
    final preferences = <String>[];
    final caseAwareLanguage = RegExp(
      r'\b(victims?|disappear(?:ed|ance|ances)|the case|police|investigat(?:e|ion|or)|alibi|evidence|false reservations?|minibars?)\b',
      caseSensitive: false,
    );

    for (final profileId in profileIds) {
      final profile = content.profiles[profileId]!;
      expect(profile.levelId, 'case_002', reason: profileId);
      expect(profile.questions, hasLength(2), reason: profileId);
      expect(profile.redHerrings, hasLength(3), reason: profileId);
      expect(profile.redHerrings.toSet(), hasLength(3), reason: profileId);
      expect(
          profile.redHerrings, everyElement(hasLength(lessThanOrEqualTo(45))),
          reason: profileId);

      descriptions.add(profile.description);
      preferences.add(profile.lookingFor);
      for (final profileQuestion in profile.questions) {
        prompts.add(profileQuestion.question);
        answers.add(profileQuestion.answer);
      }

      final visibleProfileText = [
        profile.description,
        profile.lookingFor,
        ...profile.questions
            .map((question) => '${question.question} ${question.answer}'),
      ].join(' ');
      expect(visibleProfileText, isNot(matches(caseAwareLanguage)),
          reason: profileId);
    }

    expect(prompts.toSet(), hasLength(20));
    expect(answers.toSet(), hasLength(20));
    expect(descriptions.toSet(), hasLength(10));
    expect(preferences.toSet(), hasLength(10));
  });

  test('case 2 conversations reveal clues through natural dating chat', () {
    const transcriptAnchors = {
      'm011': 'comparing how people moved through Meridian House',
      'm012': 'inventory backup at 12:14',
      'm013': 'hotel rooming lists',
      'm014': 'overnight bridge test',
      'm015': 'midnight pastries',
      'm016': 'Grand Hotel exhibition',
      'm017': 'fold them twice with the printed side inward',
      'm018': 'Night Wheel two months ago',
      'm019': 'regional mystery audits',
      'm020': 'hotel-app test runs every night at 12:14',
    };
    const crossCheckAnchors = {
      'm011': 'data fields confirm',
      'm012': 'Backup logs',
      'm013': 'Account permissions',
      'm014': 'Crew sheets',
      'm015': 'Kitchen dispatch logs',
      'm016': 'public audio file',
      'm017': 'minibar creases',
      'm018': 'Event records',
      'm019': 'account permissions',
      'm020': 'Build records',
    };
    final caseAwareLanguage = RegExp(
      r'\b(victims?|disappear(?:ed|ance|ances)|the case|police|investigators?|alibi|evidence|false reservations?|minibars?|what proves|verify independently|records show)\b',
      caseSensitive: false,
    );

    for (final entry in transcriptAnchors.entries) {
      final profile = content.profiles[entry.key]!;
      final conversation = content.conversations[profile.conversationId]!;
      final transcript = conversation.stages.expand((stage) sync* {
        yield stage.suspectMessage;
        for (final option in stage.responseOptions) {
          yield option.playerText;
          yield option.suspectReply;
        }
      }).join(' ');

      expect(conversation.stages, hasLength(3), reason: entry.key);
      expect(transcript, contains(entry.value), reason: entry.key);
      expect(transcript, isNot(matches(caseAwareLanguage)), reason: entry.key);
      expect(transcript, isNot(contains('The plain version is less dramatic')),
          reason: entry.key);
      expect(
          transcript,
          isNot(contains(
              'The difficult part is admitting how often I do the opposite')),
          reason: entry.key);

      final conversationClue = profile.clues
          .singleWhere((clue) => clue.source == ClueSource.conversation);
      expect(
          conversationClue.description, contains(crossCheckAnchors[entry.key]!),
          reason: entry.key);
    }
  });

  test('case 2 Goggles traces are plain, distinct, and fairly grounded', () {
    const traceAnchors = {
      'm011': 'anonymous guest counts',
      'm012': 'automatic inventory backup',
      'm013': 'could not create reservations or mobile keys',
      'm014': 'three bridge-inspection devices',
      'm015': 'weekly pastry deliveries',
      'm016': 'public museum audio guide',
      'm017': 'driver login entered the hotel partner system',
      'm018': 'public Night Wheel event',
      'm019': 'regional audit account',
      'm020': 'closed test system',
    };
    final technicalJargon = RegExp(
      r'cache key|device token|contact cluster|diagnostic indexed',
      caseSensitive: false,
    );
    final traces = <String>[];

    for (final entry in traceAnchors.entries) {
      final profile = content.profiles[entry.key]!;
      final goggles = profile.clues
          .singleWhere((clue) => clue.source == ClueSource.goggles);
      traces.add(goggles.description);
      expect(goggles.description, contains(entry.value), reason: entry.key);
      expect(goggles.description, isNot(matches(technicalJargon)),
          reason: entry.key);
      expect(goggles.strength,
          entry.key == 'm017' ? ClueStrength.strong : ClueStrength.weak,
          reason: entry.key);
    }

    expect(traces.toSet(), hasLength(10));
    final killerTrace = content.profiles['m017']!.clues
        .singleWhere((clue) => clue.source == ClueSource.goggles)
        .description;
    expect(killerTrace, contains('before every false reservation'));
    expect(killerTrace, contains('service lane at each hotel'));
    expect(killerTrace, contains('12:14 mobile-key entry'));
  });

  test('case 2 stores a Goggles summary plus two board leads per profile', () {
    const gogglesSummaries = {
      'm011': 'Downloaded data from all three hotels',
      'm012': 'Shop computer active at 12:14',
      'm013': 'Opened lists for all three hotels',
      'm014': 'Night route passed all three hotels',
      'm015': 'Used every hotel service entrance',
      'm016': 'Recorded exact room-ready phrase',
      'm017': 'Driver login preceded every booking',
      'm018': 'Night ride passed all three hotels',
      'm019': 'Opened records at all three hotels',
      'm020': 'Test check-ins ran at 12:14',
    };

    for (final entry in gogglesSummaries.entries) {
      final profile = content.profiles[entry.key]!;
      expect(profile.redHerrings, hasLength(3), reason: entry.key);
      expect(profile.redHerrings.first, entry.value, reason: entry.key);
    }
  });

  testWidgets('case 2 evidence board shows Henrik three concise leads',
      (tester) async {
    final henrik = content.profiles['m017']!;
    final fullTrace = henrik.clues
        .singleWhere((clue) => clue.source == ClueSource.goggles)
        .description;

    await tester.pumpWidget(MaterialApp(
      home: EvidenceBoardDialog(
        profiles: [henrik],
        completedProfileIds: {henrik.id},
      ),
    ));
    await tester.pump();

    expect(find.text('SUSPICIOUS LEAD'), findsNWidgets(3));
    expect(find.text('Driver login preceded every booking'), findsOneWidget);
    expect(find.text('Matching inward-folded ticket'), findsOneWidget);
    expect(find.text('Knew all three side entrances'), findsOneWidget);
    expect(find.text(fullTrace), findsNothing);
  });
  test('case 3 establishes the complete AFTER MIDNIGHT mystery', () {
    final level = content.levels['case_003']!;
    expect(level.gender, Gender.men);
    expect(level.title, 'The Playlist That Knew Too Much');
    expect(level.difficulty, 'Easy');
    expect(level.profileIds, hasLength(10));
    expect(level.killerProfileId, 'm027');
    expect(content.profiles[level.killerProfileId]!.isKiller, isTrue);
    expect(content.profilesFor(level).where((profile) => profile.isKiller),
        hasLength(1));
    expect(level.caseDescription, contains('three dating-app users'));
    expect(level.caseDescription, contains('AFTER MIDNIGHT'));
    expect(level.caseDescription, contains('Glass Arcade'));
    expect(level.caseDescription, contains('River Steps'));
    expect(level.caseDescription, contains('North Platform'));
    expect(level.caseDescription, contains("'last stop home.'"));
    expect(level.caseDescription, contains('before anyone knew it mattered'));
  });

  test('case 3 profiles are distinct dating profiles, not case summaries', () {
    const profileIds = [
      'm021',
      'm022',
      'm023',
      'm024',
      'm025',
      'm026',
      'm027',
      'm028',
      'm029',
      'm030',
    ];
    final prompts = <String>[];
    final answers = <String>[];
    final descriptions = <String>[];
    final preferences = <String>[];
    final caseAwareLanguage = RegExp(
      r'\b(victims?|disappear(?:ed|ance|ances)|the case|police|investigat(?:e|ion|or)|alibi|evidence|killer|suspects?)\b',
      caseSensitive: false,
    );

    for (final profileId in profileIds) {
      final profile = content.profiles[profileId]!;
      expect(profile.levelId, 'case_003', reason: profileId);
      expect(profile.questions, hasLength(2), reason: profileId);
      expect(profile.redHerrings, hasLength(3), reason: profileId);
      expect(profile.redHerrings.toSet(), hasLength(3), reason: profileId);
      expect(
          profile.redHerrings, everyElement(hasLength(lessThanOrEqualTo(45))),
          reason: profileId);

      descriptions.add(profile.description);
      preferences.add(profile.lookingFor);
      for (final profileQuestion in profile.questions) {
        prompts.add(profileQuestion.question);
        answers.add(profileQuestion.answer);
      }

      final visibleProfileText = [
        profile.description,
        profile.lookingFor,
        ...profile.questions
            .map((question) => '${question.question} ${question.answer}'),
      ].join(' ');
      expect(visibleProfileText, isNot(matches(caseAwareLanguage)),
          reason: profileId);
    }

    expect(prompts.toSet(), hasLength(20));
    expect(answers.toSet(), hasLength(20));
    expect(descriptions.toSet(), hasLength(10));
    expect(preferences.toSet(), hasLength(10));
  });

  test('case 3 conversations reveal clues through natural dating chat', () {
    const transcriptAnchors = {
      'm021': 'city recital around Glass Arcade',
      'm022': 'AFTER MIDNIGHT. Slightly dramatic',
      'm023': 'three untitled instrumentals',
      'm024': 'three landmarks—Glass Arcade',
      'm025': "city's sound archive",
      'm026': 'night-cycling video',
      'm027': 'small pulse when a listener reaches the final song',
      'm028': 'night-city short from a licensed media pack',
      'm029': 'rotate between three branches near Glass Arcade',
      'm030': "campus music club",
    };
    const crossCheckAnchors = {
      'm021': 'School account records',
      'm022': 'distributor list',
      'm023': 'venue manifest',
      'm024': 'invitation permissions agree',
      'm025': 'Search timestamps',
      'm026': 'campaign archive',
      'm027': 'playlist order',
      'm028': 'competition submission',
      'm029': 'Permission logs',
      'm030': 'Club membership',
    };
    final caseAwareLanguage = RegExp(
      r'\b(victims?|disappear(?:ed|ance|ances)|the case|police|investigators?|alibi|evidence|killer|suspects?|what proves|verify independently|records show)\b',
      caseSensitive: false,
    );
    final openingMessages = <String>[];
    final suspectReplies = <String>[];

    for (final entry in transcriptAnchors.entries) {
      final profile = content.profiles[entry.key]!;
      final conversation = content.conversations[profile.conversationId]!;
      final transcript = conversation.stages.expand((stage) sync* {
        openingMessages.add(stage.suspectMessage);
        yield stage.suspectMessage;
        for (final option in stage.responseOptions) {
          yield option.playerText;
          suspectReplies.add(option.suspectReply);
          yield option.suspectReply;
        }
      }).join(' ');

      expect(conversation.stages, hasLength(3), reason: entry.key);
      expect(
          conversation.stages,
          everyElement(predicate<ConversationStage>(
              (stage) => stage.responseOptions.length == 2)),
          reason: entry.key);
      expect(transcript, contains(entry.value), reason: entry.key);
      expect(transcript, isNot(matches(caseAwareLanguage)), reason: entry.key);
      expect(transcript, isNot(contains('The plain version is less dramatic')),
          reason: entry.key);

      final conversationClue = profile.clues
          .singleWhere((clue) => clue.source == ClueSource.conversation);
      expect(
          conversationClue.description, contains(crossCheckAnchors[entry.key]!),
          reason: entry.key);
    }

    expect(openingMessages.toSet(), hasLength(30));
    expect(suspectReplies.toSet(), hasLength(60));
  });

  test('case 3 Goggles traces are plain, distinct, and fairly grounded', () {
    const traceAnchors = {
      'm021': 'playback access only',
      'm022': 'scheduled closing playlist',
      'm023': 'showcase pack arrived six weeks before',
      'm024': 'comment-only',
      'm025': 'morning after that song appeared publicly',
      'm026': 'predates AFTER MIDNIGHT by nine months',
      'm027': 'six to eight minutes before every final-track swap',
      'm028': 'licensed media pack',
      'm029': 'could suggest tracks but could not publish',
      'm030': 'public share exposed neither private listening',
    };
    final technicalJargon = RegExp(
      r'cache key|device token|contact cluster|diagnostic indexed',
      caseSensitive: false,
    );
    final traces = <String>[];

    for (final entry in traceAnchors.entries) {
      final profile = content.profiles[entry.key]!;
      final goggles = profile.clues
          .singleWhere((clue) => clue.source == ClueSource.goggles);
      traces.add(goggles.description);
      expect(goggles.description, contains(entry.value), reason: entry.key);
      expect(goggles.description, isNot(matches(technicalJargon)),
          reason: entry.key);
      expect(goggles.strength,
          entry.key == 'm027' ? ClueStrength.strong : ClueStrength.weak,
          reason: entry.key);
    }

    expect(traces.toSet(), hasLength(10));
    final killer = content.profiles['m027']!;
    expect(
        killer.clues
            .singleWhere((clue) => clue.source == ClueSource.profile)
            .strength,
        ClueStrength.medium);
    expect(
        killer.clues
            .singleWhere((clue) => clue.source == ClueSource.photo)
            .strength,
        ClueStrength.strong);
    expect(
        killer.clues
            .singleWhere((clue) => clue.source == ClueSource.conversation)
            .strength,
        ClueStrength.strong);
  });

  test('case 3 stores a Goggles summary plus two board leads per profile', () {
    const gogglesSummaries = {
      'm021': 'Played all three location tracks',
      'm022': 'Playlist played after midnight',
      'm023': 'Downloaded all three instrumentals',
      'm024': 'Opened the playlist preview repeatedly',
      'm025': 'Searched every location track',
      'm026': 'Used the last-stop audio sample',
      'm027': 'Edited list before every disappearance',
      'm028': 'Used all three tracks in a film',
      'm029': 'Restaurant account followed playlist',
      'm030': 'Shared playlist with campus group',
    };

    for (final entry in gogglesSummaries.entries) {
      final profile = content.profiles[entry.key]!;
      expect(profile.redHerrings, hasLength(3), reason: entry.key);
      expect(profile.redHerrings.first, entry.value, reason: entry.key);
    }
  });

  testWidgets('case 3 evidence board shows Julian three concise leads',
      (tester) async {
    final julian = content.profiles['m027']!;
    final fullTrace = julian.clues
        .singleWhere((clue) => clue.source == ClueSource.goggles)
        .description;

    await tester.pumpWidget(MaterialApp(
      home: EvidenceBoardDialog(
        profiles: [julian],
        completedProfileIds: {julian.id},
      ),
    ));
    await tester.pump();

    expect(find.text('SUSPICIOUS LEAD'), findsNWidgets(3));
    expect(find.text('Edited list before every disappearance'), findsOneWidget);
    expect(find.text('Unreleased endings on studio screen'), findsOneWidget);
    expect(find.text('Named location sequence in order'), findsOneWidget);
    expect(find.text(fullTrace), findsNothing);
  });
  test('case 4 establishes the complete Platform Zero mystery', () {
    final level = content.levels['case_004']!;
    expect(level.gender, Gender.men);
    expect(level.title, 'Platform Zero');
    expect(level.difficulty, 'Medium');
    expect(level.profileIds, hasLength(10));
    expect(level.killerProfileId, 'm037');
    expect(content.profiles[level.killerProfileId]!.isKiller, isTrue);
    expect(content.profilesFor(level).where((profile) => profile.isKiller),
        hasLength(1));
    expect(level.caseDescription, contains('Mara Voss'));
    expect(level.caseDescription, contains('"Leon, 35"'));
    expect(level.caseDescription, contains('eleven days'));
    expect(level.caseDescription, contains('has no Platform 0'));
    expect(level.caseDescription, contains('cut both hands'));
    expect(level.caseDescription, contains('seven luggage tags'));
    expect(level.caseDescription, contains('Leon Arendt'));
    expect(level.caseDescription,
        contains('His tag is the oldest in the passage'));
    expect(level.caseDescription, contains('MISSED CONNECTION'));
    expect(level.caseDescription,
        contains("'This time, stay for the departure.'"));
    expect(level.caseDescription, contains('before the return journey begins'));
  });

  test('case 4 profiles are distinct dating profiles, not case summaries', () {
    const profileIds = [
      'm031',
      'm032',
      'm033',
      'm034',
      'm035',
      'm036',
      'm037',
      'm038',
      'm039',
      'm040',
    ];
    final prompts = <String>[];
    final answers = <String>[];
    final descriptions = <String>[];
    final preferences = <String>[];
    final caseAwareLanguage = RegExp(
      r'\b(Mara|Leon Arendt|victims?|disappear(?:ed|ance|ances)|the case|police|investigat(?:e|ion|or)|alibi|evidence|killer|suspects?|Platform 0|luggage tags?)\b',
      caseSensitive: false,
    );

    for (final profileId in profileIds) {
      final profile = content.profiles[profileId]!;
      expect(profile.levelId, 'case_004', reason: profileId);
      expect(profile.questions, hasLength(2), reason: profileId);
      expect(profile.redHerrings, hasLength(3), reason: profileId);
      expect(profile.redHerrings.toSet(), hasLength(3), reason: profileId);
      expect(
          profile.redHerrings, everyElement(hasLength(lessThanOrEqualTo(45))),
          reason: profileId);
      expect(profile.lookingFor, startsWith('A woman who'), reason: profileId);

      descriptions.add(profile.description);
      preferences.add(profile.lookingFor);
      for (final profileQuestion in profile.questions) {
        prompts.add(profileQuestion.question);
        answers.add(profileQuestion.answer);
      }

      final visibleProfileText = [
        profile.description,
        profile.lookingFor,
        ...profile.questions
            .map((question) => '${question.question} ${question.answer}'),
      ].join(' ');
      expect(visibleProfileText, isNot(matches(caseAwareLanguage)),
          reason: profileId);
    }

    expect(prompts.toSet(), hasLength(20));
    expect(answers.toSet(), hasLength(20));
    expect(descriptions.toSet(), hasLength(10));
    expect(preferences.toSet(), hasLength(10));
  });

  test('case 4 conversations reveal clues through natural dating chat', () {
    const transcriptAnchors = {
      'm031': 'monthly display test ran without me',
      'm032': '1996 plan is actually titled Platform 0',
      'm033': 'replacement signal part for Central Station',
      'm034': 'unfinished project I designed eighteen years ago',
      'm035': 'supervisor making me narrate every switch over video',
      'm036': 'proposed exhibit called Lost Journeys',
      'm037': 'old emergency hatch into the service yard',
      'm038': 'emergency coffee delivery to Central Station',
      'm039': 'transit campaign called Every Route Needs an Exit',
      'm040': 'local-history podcast from old newspapers',
    };
    const crossCheckAnchors = {
      'm031': "another dispatcher's badge log",
      'm032': 'project brief confirms',
      'm033': 'recipient signature',
      'm034': 'museum email',
      'm035': 'call recording',
      'm036': 'Auction records',
      'm037': 'withheld from every public report',
      'm038': 'Van, alarm, and oven records',
      'm039': 'Agency invoices',
      'm040': "school's publication page",
    };
    final investigativeLanguage = RegExp(
      r'\b(victims?|disappear(?:ed|ance|ances)|the case|police|investigators?|alibi|evidence|killer|suspects?|what proves|verify independently|records show)\b',
      caseSensitive: false,
    );
    final stageMessages = <String>[];
    final playerLines = <String>[];
    final suspectReplies = <String>[];

    for (final entry in transcriptAnchors.entries) {
      final profile = content.profiles[entry.key]!;
      final conversation = content.conversations[profile.conversationId]!;
      final transcript = conversation.stages.expand((stage) sync* {
        stageMessages.add(stage.suspectMessage);
        yield stage.suspectMessage;
        for (final option in stage.responseOptions) {
          playerLines.add(option.playerText);
          yield option.playerText;
          suspectReplies.add(option.suspectReply);
          yield option.suspectReply;
        }
      }).join(' ');

      expect(conversation.stages, hasLength(3), reason: entry.key);
      expect(
          conversation.stages,
          everyElement(predicate<ConversationStage>(
              (stage) => stage.responseOptions.length == 2)),
          reason: entry.key);
      expect(transcript, contains(entry.value), reason: entry.key);
      expect(transcript, isNot(matches(investigativeLanguage)),
          reason: entry.key);

      final conversationClue = profile.clues
          .singleWhere((clue) => clue.source == ClueSource.conversation);
      expect(
          conversationClue.description, contains(crossCheckAnchors[entry.key]!),
          reason: entry.key);
    }

    expect(stageMessages.toSet(), hasLength(30));
    expect(playerLines.toSet(), hasLength(60));
    expect(suspectReplies.toSet(), hasLength(60));
  });

  test('case 4 Goggles traces create a fair three-profile shortlist', () {
    const traceAnchors = {
      'm031': 'unnamed simulation job',
      'm032': 'public city archive',
      'm033': 'signed parcel scan five kilometers away at 00:02',
      'm034': 'station museum',
      'm035': 'recorded video call',
      'm036': 'railway exhibit proposal',
      'm037': 'one-use QR ticket later sent to Mara',
      'm038': 'roastery',
      'm039': 'working gate code was inserted',
      'm040': 'published newspaper index',
    };
    const expectedStrengths = {
      'm031': ClueStrength.weak,
      'm032': ClueStrength.weak,
      'm033': ClueStrength.weak,
      'm034': ClueStrength.medium,
      'm035': ClueStrength.medium,
      'm036': ClueStrength.weak,
      'm037': ClueStrength.strong,
      'm038': ClueStrength.weak,
      'm039': ClueStrength.weak,
      'm040': ClueStrength.weak,
    };
    final technicalJargon = RegExp(
      r'cache key|device token|contact cluster|diagnostic indexed',
      caseSensitive: false,
    );
    final traces = <String>[];

    for (final entry in traceAnchors.entries) {
      final goggles = content.profiles[entry.key]!.clues
          .singleWhere((clue) => clue.source == ClueSource.goggles);
      traces.add(goggles.description);
      expect(goggles.description, contains(entry.value), reason: entry.key);
      expect(goggles.description, isNot(matches(technicalJargon)),
          reason: entry.key);
      expect(goggles.strength, expectedStrengths[entry.key], reason: entry.key);
    }

    expect(traces.toSet(), hasLength(10));
    expect(
        expectedStrengths.entries
            .where((entry) => entry.value != ClueStrength.weak)
            .map((entry) => entry.key),
        ['m034', 'm035', 'm037']);

    final stefan = content.profiles['m037']!;
    expect(
        stefan.clues
            .singleWhere((clue) => clue.source == ClueSource.profile)
            .strength,
        ClueStrength.medium);
    expect(
        stefan.clues
            .singleWhere((clue) => clue.source == ClueSource.photo)
            .strength,
        ClueStrength.strong);
    expect(
        stefan.clues
            .singleWhere((clue) => clue.source == ClueSource.conversation)
            .strength,
        ClueStrength.strong);
  });

  test('case 4 stores one Goggles summary and two board leads per profile', () {
    const gogglesSummaries = {
      'm031': "Display override used Emil's console",
      'm032': 'Downloaded the Platform 0 plans',
      'm033': "Used Mara's staff gate that night",
      'm034': 'Opened passage plans two days earlier',
      'm035': 'Disabled corridor lights and hatch alarm',
      'm036': 'Searched Leon and the luggage-tag stamp',
      'm037': "Created Mara's P0 journey",
      'm038': 'Van entered Platform 0 service yard',
      'm039': 'Exported the Platform 0 ticket design',
      'm040': 'Searched all seven missing names',
    };

    for (final entry in gogglesSummaries.entries) {
      final profile = content.profiles[entry.key]!;
      expect(profile.redHerrings, hasLength(3), reason: entry.key);
      expect(profile.redHerrings.first, entry.value, reason: entry.key);
    }
  });

  testWidgets('case 4 evidence board shows Stefan three concise leads',
      (tester) async {
    final stefan = content.profiles['m037']!;
    final fullTrace = stefan.clues
        .singleWhere((clue) => clue.source == ClueSource.goggles)
        .description;

    await tester.pumpWidget(MaterialApp(
      home: EvidenceBoardDialog(
        profiles: [stefan],
        completedProfileIds: {stefan.id},
      ),
    ));
    await tester.pump();

    expect(find.text('SUSPICIOUS LEAD'), findsNWidgets(3));
    expect(find.text("Created Mara's P0 journey"), findsOneWidget);
    expect(find.text('Photographed inside the sealed passage'), findsOneWidget);
    expect(find.text('Knew which hatch Mara used'), findsOneWidget);
    expect(find.text(fullTrace), findsNothing);
  });
  test('case 5 establishes the complete Glasshouse Alibi mystery', () {
    final level = content.levels['case_005']!;
    expect(level.gender, Gender.men);
    expect(level.title, 'The Glasshouse Alibi');
    expect(level.difficulty, 'Medium');
    expect(level.profileIds, hasLength(10));
    expect(level.killerProfileId, 'm047');
    expect(content.profiles[level.killerProfileId]!.isKiller, isTrue);
    expect(content.profilesFor(level).where((profile) => profile.isKiller),
        hasLength(1));
    expect(level.caseDescription, contains('At 2:13 a.m.'));
    expect(level.caseDescription, contains('He knew about the orchid'));
    expect(level.caseDescription,
        contains('five unsolved deaths over eight years'));
    expect(level.caseDescription, contains('no account appeared in all six'));
    expect(level.caseDescription, contains('His access card entered'));
    expect(level.caseDescription, contains('the night was clear'));
    expect(level.caseDescription, contains('quarantine three weeks earlier'));
    expect(level.caseDescription,
        contains('The footage is real. The timestamp is not.'));
    expect(level.caseDescription,
        contains('manufactured a night that never happened'));
  });

  test('case 5 profiles are distinct dating profiles, not case summaries', () {
    const profileIds = [
      'm041',
      'm042',
      'm043',
      'm044',
      'm045',
      'm046',
      'm047',
      'm048',
      'm049',
      'm050',
    ];
    final prompts = <String>[];
    final answers = <String>[];
    final descriptions = <String>[];
    final preferences = <String>[];
    final caseAwareLanguage = RegExp(
      r'\b(Lena|victims?|murder|disappear(?:ed|ance|ances)|the case|police|investigat(?:e|ion|or)|alibi|evidence|killer|suspects?)\b',
      caseSensitive: false,
    );

    for (final profileId in profileIds) {
      final profile = content.profiles[profileId]!;
      expect(profile.levelId, 'case_005', reason: profileId);
      expect(profile.questions, hasLength(2), reason: profileId);
      expect(profile.clues, hasLength(4), reason: profileId);
      expect(profile.redHerrings, hasLength(3), reason: profileId);
      expect(profile.redHerrings.toSet(), hasLength(3), reason: profileId);
      expect(
          profile.redHerrings, everyElement(hasLength(lessThanOrEqualTo(45))),
          reason: profileId);
      expect(profile.lookingFor, startsWith('A woman who'), reason: profileId);

      descriptions.add(profile.description);
      preferences.add(profile.lookingFor);
      for (final profileQuestion in profile.questions) {
        prompts.add(profileQuestion.question);
        answers.add(profileQuestion.answer);
      }

      final visibleProfileText = [
        profile.bio,
        profile.description,
        profile.lookingFor,
        ...profile.questions
            .map((question) => '${question.question} ${question.answer}'),
      ].join(' ');
      expect(visibleProfileText, isNot(matches(caseAwareLanguage)),
          reason: profileId);
    }

    expect(prompts.toSet(), hasLength(20));
    expect(answers.toSet(), hasLength(20));
    expect(descriptions.toSet(), hasLength(10));
    expect(preferences.toSet(), hasLength(10));
  });

  test('case 5 conversations reveal clues through natural dating chat', () {
    const transcriptAnchors = {
      'm041': 'humidity alert sent me into the quarantine care file at 2:09',
      'm042': 'At 2:26 I had the raw station report',
      'm043': 'one sealed white orchid box, no card',
      'm044': 'Rain Room inside Central Glasshouse three weeks ago',
      'm045': 'display bed and quarantine',
      'm046': 'signed out at 20:38',
      'm047': 'three black bruises across a white orchid',
      'm048': 'repeated the same watering route for fourteen minutes',
      'm049': 'shared glasshouse trade account',
      'm050': 'message card printed blank',
    };
    const crossCheckAnchors = {
      'm041': 'Sensor history, home access',
      'm042': 'newsroom rundown',
      'm043': 'Dispatch records and van footage',
      'm044': 'Commission and removal records',
      'm045': "trainee's error report",
      'm046': 'student rota',
      'm047': 'withheld from every public report',
      'm048': 'Contract delivery and read-only archive',
      'm049': 'purchase record and pickup camera',
      'm050': 'automatic import log',
    };
    final investigativeLanguage = RegExp(
      r'\b(Lena|victims?|murder|disappear(?:ed|ance|ances)|the case|police|investigators?|alibi|evidence|killer|suspects?|what proves|verify independently|records show)\b',
      caseSensitive: false,
    );
    final stageMessages = <String>[];
    final playerLines = <String>[];
    final suspectReplies = <String>[];

    for (final entry in transcriptAnchors.entries) {
      final profile = content.profiles[entry.key]!;
      final conversation = content.conversations[profile.conversationId]!;
      final transcript = conversation.stages.expand((stage) sync* {
        stageMessages.add(stage.suspectMessage);
        yield stage.suspectMessage;
        for (final option in stage.responseOptions) {
          playerLines.add(option.playerText);
          yield option.playerText;
          suspectReplies.add(option.suspectReply);
          yield option.suspectReply;
        }
      }).join(' ');

      expect(conversation.stages, hasLength(3), reason: entry.key);
      expect(
          conversation.stages,
          everyElement(predicate<ConversationStage>(
              (stage) => stage.responseOptions.length == 2)),
          reason: entry.key);
      expect(transcript, contains(entry.value), reason: entry.key);
      expect(transcript, isNot(matches(investigativeLanguage)),
          reason: entry.key);

      final conversationClue = profile.clues
          .singleWhere((clue) => clue.source == ClueSource.conversation);
      expect(
          conversationClue.description, contains(crossCheckAnchors[entry.key]!),
          reason: entry.key);
    }

    expect(stageMessages.toSet(), hasLength(30));
    expect(playerLines.toSet(), hasLength(60));
    expect(suspectReplies.toSet(), hasLength(60));
  });

  test('case 5 Goggles traces create a fair three-profile shortlist', () {
    const traceAnchors = {
      'm041': 'automatic humidity alert',
      'm042': 'raw 2:13 station report',
      'm043': 'forty-six-second doorstep handoff',
      'm044': 'one promotional night three weeks earlier',
      'm045': 'fourteen minutes after intake',
      'm046': '21:04 bus tap',
      'm047': 'loaded a fourteen-minute Rain Room recording',
      'm048': 'client folder became read-only',
      'm049': 'shared trade-purchasing alias',
      'm050': 'blank message card',
    };
    const expectedStrengths = {
      'm041': ClueStrength.weak,
      'm042': ClueStrength.weak,
      'm043': ClueStrength.weak,
      'm044': ClueStrength.weak,
      'm045': ClueStrength.medium,
      'm046': ClueStrength.weak,
      'm047': ClueStrength.strong,
      'm048': ClueStrength.medium,
      'm049': ClueStrength.weak,
      'm050': ClueStrength.weak,
    };
    final traces = <String>[];

    for (final entry in traceAnchors.entries) {
      final goggles = content.profiles[entry.key]!.clues
          .singleWhere((clue) => clue.source == ClueSource.goggles);
      traces.add(goggles.description);
      expect(goggles.description, contains(entry.value), reason: entry.key);
      expect(goggles.strength, expectedStrengths[entry.key], reason: entry.key);
    }

    expect(traces.toSet(), hasLength(10));
    expect(
        expectedStrengths.entries
            .where((entry) => entry.value != ClueStrength.weak)
            .map((entry) => entry.key),
        ['m045', 'm047', 'm048']);

    final christoph = content.profiles['m047']!;
    expect(
        christoph.clues
            .singleWhere((clue) => clue.source == ClueSource.profile)
            .strength,
        ClueStrength.medium);
    expect(
        christoph.clues
            .singleWhere((clue) => clue.source == ClueSource.photo)
            .strength,
        ClueStrength.strong);
    expect(
        christoph.clues
            .singleWhere((clue) => clue.source == ClueSource.conversation)
            .strength,
        ClueStrength.strong);
  });

  test('case 5 stores one Goggles summary and two board leads per profile', () {
    const gogglesSummaries = {
      'm041': 'Opened the orchid quarantine record',
      'm042': 'Downloaded the 2:13 weather record',
      'm043': 'Delivered the orchid to Lena',
      'm044': 'Created artificial rain on the glass',
      'm045': 'Changed the orchid transfer record',
      'm046': 'Entered orchid quarantine that evening',
      'm047': 'Inserted old footage into the live feed',
      'm048': 'Recorded the footage used as alibi',
      'm049': "Supplied Lena's rare orchid",
      'm050': "Prepared Lena's anonymous orchid",
    };

    for (final entry in gogglesSummaries.entries) {
      final profile = content.profiles[entry.key]!;
      expect(profile.redHerrings, hasLength(3), reason: entry.key);
      expect(profile.redHerrings.first, entry.value, reason: entry.key);
    }
  });

  testWidgets('case 5 evidence board shows Christoph three concise leads',
      (tester) async {
    final christoph = content.profiles['m047']!;
    final fullTrace = christoph.clues
        .singleWhere((clue) => clue.source == ClueSource.goggles)
        .description;

    await tester.pumpWidget(MaterialApp(
      home: EvidenceBoardDialog(
        profiles: [christoph],
        completedProfileIds: {christoph.id},
      ),
    ));
    await tester.pump();

    expect(find.text('SUSPICIOUS LEAD'), findsNWidgets(3));
    expect(
        find.text('Inserted old footage into the live feed'), findsOneWidget);
    expect(find.text('Recorded beside the quarantined orchid'), findsOneWidget);
    expect(find.text('Knew Lena had crushed the flower'), findsOneWidget);
    expect(find.text(fullTrace), findsNothing);
  });
  test('men cases 6 through 10 preserve their formatted intelligence', () {
    final expectedTypes = {
      'case_006': [
        CaseIntelligenceBlockType.paragraph,
        CaseIntelligenceBlockType.paragraph,
        CaseIntelligenceBlockType.quote,
        CaseIntelligenceBlockType.timeline,
        CaseIntelligenceBlockType.callout,
        CaseIntelligenceBlockType.paragraph,
        CaseIntelligenceBlockType.bullets,
        CaseIntelligenceBlockType.paragraph,
        CaseIntelligenceBlockType.callout,
      ],
      'case_007': [
        CaseIntelligenceBlockType.quote,
        CaseIntelligenceBlockType.paragraph,
        CaseIntelligenceBlockType.timeline,
        CaseIntelligenceBlockType.quote,
        CaseIntelligenceBlockType.paragraph,
        CaseIntelligenceBlockType.bullets,
        CaseIntelligenceBlockType.callout,
        CaseIntelligenceBlockType.paragraph,
        CaseIntelligenceBlockType.callout,
      ],
      'case_008': [
        CaseIntelligenceBlockType.paragraph,
        CaseIntelligenceBlockType.quote,
        CaseIntelligenceBlockType.timeline,
        CaseIntelligenceBlockType.paragraph,
        CaseIntelligenceBlockType.bullets,
        CaseIntelligenceBlockType.bullets,
        CaseIntelligenceBlockType.timeline,
        CaseIntelligenceBlockType.paragraph,
        CaseIntelligenceBlockType.callout,
      ],
      'case_009': [
        CaseIntelligenceBlockType.paragraph,
        CaseIntelligenceBlockType.paragraph,
        CaseIntelligenceBlockType.bullets,
        CaseIntelligenceBlockType.quote,
        CaseIntelligenceBlockType.timeline,
        CaseIntelligenceBlockType.bullets,
        CaseIntelligenceBlockType.quote,
        CaseIntelligenceBlockType.bullets,
        CaseIntelligenceBlockType.paragraph,
        CaseIntelligenceBlockType.callout,
      ],
      'case_010': [
        CaseIntelligenceBlockType.paragraph,
        CaseIntelligenceBlockType.bullets,
        CaseIntelligenceBlockType.paragraph,
        CaseIntelligenceBlockType.timeline,
        CaseIntelligenceBlockType.quote,
        CaseIntelligenceBlockType.timeline,
        CaseIntelligenceBlockType.bullets,
        CaseIntelligenceBlockType.paragraph,
        CaseIntelligenceBlockType.callout,
      ],
    };

    for (final entry in expectedTypes.entries) {
      final level = content.levels[entry.key]!;
      expect(
          level.caseIntelligenceFormat.map((block) => block.type), entry.value,
          reason: entry.key);
      expect(
          level.caseIntelligenceFormat
              .expand((block) => block.contentParts)
              .join(' '),
          level.caseDescription,
          reason: '${entry.key} must retain every word in its description');
    }

    expect(content.levels['case_006']!.caseIntelligenceFormat[3].heading,
        'INSIDE THE PHOTO BOOTH');
    expect(content.levels['case_007']!.caseIntelligenceFormat[2].heading,
        'THE ERASED QUESTION');
    expect(content.levels['case_008']!.caseIntelligenceFormat[6].heading,
        'THE NEXT VOICE');
    expect(content.levels['case_009']!.caseIntelligenceFormat[5].heading,
        'THE RECREATED SCENE');
    expect(content.levels['case_010']!.caseIntelligenceFormat[6].heading,
        "SOPHIE'S RECORDING");
    expect(ContentValidator().validate(content), isEmpty);
  });

  testWidgets('men cases 6 through 10 render their intelligence layouts',
      (tester) async {
    final expectedHeading = {
      'case_006': 'INSIDE THE PHOTO BOOTH',
      'case_007': 'THE ERASED QUESTION',
      'case_008': 'THE NEXT VOICE',
      'case_009': 'THE RECREATED SCENE',
      'case_010': "SOPHIE'S RECORDING",
    };

    for (final entry in expectedHeading.entries) {
      game.unlockedLevelIds.add(entry.key);
      game.chooseCase(entry.key);
      await tester.pumpWidget(
        GameScope(
          controller: game,
          child: const MaterialApp(home: BriefingScreen()),
        ),
      );
      await tester.pump();

      expect(find.text(entry.value), findsOneWidget, reason: entry.key);
      expect(find.text(game.currentLevel.caseDescription), findsNothing,
          reason: entry.key);
      expect(tester.takeException(), isNull, reason: entry.key);
    }
  });

  test('case 6 establishes the complete Eleventh Date mystery', () {
    final level = content.levels['case_006']!;
    expect(level.gender, Gender.men);
    expect(level.title, 'The Eleventh Date');
    expect(level.difficulty, 'Medium');
    expect(level.profileIds, hasLength(10));
    expect(level.killerProfileId, 'm057');
    expect(content.profiles[level.killerProfileId]!.isKiller, isTrue);
    expect(content.profilesFor(level).where((profile) => profile.isKiller),
        hasLength(1));
    expect(level.caseDescription, contains('Ten Chances'));
    expect(level.caseDescription, contains('ten six-minute dates'));
    expect(level.caseDescription, contains('NO MATCH'));
    expect(level.caseDescription, contains('Guest 27'));
    expect(level.caseDescription, contains('There were only ten'));
    expect(level.caseDescription, contains('an eleventh bell rang'));
    expect(level.caseDescription, contains('four exposures'));
    expect(level.caseDescription, contains('The fourth photograph is missing'));
    expect(level.caseDescription, contains('NOBODY LEAVES UNCHOSEN'));
    expect(level.caseDescription, contains('two women who vanished'));
    expect(level.caseDescription, contains('rejected every person they met'));
  });

  test('case 6 profiles are distinct dating profiles, not case summaries', () {
    const profileIds = [
      'm051',
      'm052',
      'm053',
      'm054',
      'm055',
      'm056',
      'm057',
      'm058',
      'm059',
      'm060',
    ];
    final prompts = <String>[];
    final answers = <String>[];
    final descriptions = <String>[];
    final preferences = <String>[];
    final caseAwareLanguage = RegExp(
      r'\b(Elisa|Guest 27|victims?|murder|disappear(?:ed|ance|ances)|the case|police|investigat(?:e|ion|or)|alibi|evidence|killer|suspects?|wildcard|eleventh)\b',
      caseSensitive: false,
    );

    for (final profileId in profileIds) {
      final profile = content.profiles[profileId]!;
      expect(profile.levelId, 'case_006', reason: profileId);
      expect(profile.questions, hasLength(2), reason: profileId);
      expect(profile.clues, hasLength(4), reason: profileId);
      expect(profile.redHerrings, hasLength(3), reason: profileId);
      expect(profile.redHerrings.toSet(), hasLength(3), reason: profileId);
      expect(
          profile.redHerrings, everyElement(hasLength(lessThanOrEqualTo(45))),
          reason: profileId);
      expect(profile.lookingFor, startsWith('A woman who'), reason: profileId);

      descriptions.add(profile.description);
      preferences.add(profile.lookingFor);
      for (final profileQuestion in profile.questions) {
        prompts.add(profileQuestion.question);
        answers.add(profileQuestion.answer);
      }

      final visibleProfileText = [
        profile.bio,
        profile.description,
        profile.lookingFor,
        ...profile.questions
            .map((question) => '${question.question} ${question.answer}'),
      ].join(' ');
      expect(visibleProfileText, isNot(matches(caseAwareLanguage)),
          reason: profileId);
    }

    expect(prompts.toSet(), hasLength(20));
    expect(answers.toSet(), hasLength(20));
    expect(descriptions.toSet(), hasLength(10));
    expect(preferences.toSet(), hasLength(10));
  });

  test('case 6 conversations reveal clues through natural dating chat', () {
    const transcriptAnchors = {
      'm051': 'field called WILDCARD BUFFER',
      'm052': 'One numbered pouch was still there',
      'm053': 'ice stored beside an old photo booth',
      'm054': 'I typed an annoyed message before the event',
      'm055': 'sign for the only square service key',
      'm056': 'Your wildcard is waiting',
      'm057':
          'operated several small singles nights under different company names',
      'm058': 'group photograph wearing another number',
      'm059': 'a photographer insisted on signing for it personally',
      'm060': 'called a former colleague',
    };
    const crossCheckAnchors = {
      'm051': 'File history confirms Martin authored',
      'm052': 'Desk video and the cabinet audit',
      'm053': 'Video timestamps and the order ticket',
      'm054': 'Table witnesses and the sealed-phone log',
      'm055': 'signature from Martin',
      'm056': 'production request and export record',
      'm057': 'Business registrations connect',
      'm058': 'replacement slip and two table photographs',
      'm059': 'Route video and the digital receipt',
      'm060': 'call record and transit tap',
    };
    final investigativeLanguage = RegExp(
      r'\b(Elisa|victims?|murder|disappear(?:ed|ance|ances)|the case|police|investigators?|alibi|evidence|killer|suspects?|what proves|verify independently|records show)\b',
      caseSensitive: false,
    );
    final stageMessages = <String>[];
    final playerLines = <String>[];
    final suspectReplies = <String>[];

    for (final entry in transcriptAnchors.entries) {
      final profile = content.profiles[entry.key]!;
      final conversation = content.conversations[profile.conversationId]!;
      final transcript = conversation.stages.expand((stage) sync* {
        stageMessages.add(stage.suspectMessage);
        yield stage.suspectMessage;
        for (final option in stage.responseOptions) {
          playerLines.add(option.playerText);
          yield option.playerText;
          suspectReplies.add(option.suspectReply);
          yield option.suspectReply;
        }
      }).join(' ');

      expect(conversation.stages, hasLength(3), reason: entry.key);
      expect(
          conversation.stages,
          everyElement(predicate<ConversationStage>(
              (stage) => stage.responseOptions.length == 2)),
          reason: entry.key);
      expect(transcript, contains(entry.value), reason: entry.key);
      expect(transcript, isNot(matches(investigativeLanguage)),
          reason: entry.key);

      final conversationClue = profile.clues
          .singleWhere((clue) => clue.source == ClueSource.conversation);
      expect(
          conversationClue.description, contains(crossCheckAnchors[entry.key]!),
          reason: entry.key);
    }

    expect(stageMessages.toSet(), hasLength(30));
    expect(playerLines.toSet(), hasLength(60));
    expect(suspectReplies.toSet(), hasLength(60));
  });

  test('case 6 Goggles traces create a fair three-profile shortlist', () {
    const traceAnchors = {
      'm051': 'WILDCARD BUFFER',
      'm052': "Guest 27's phone-pouch record",
      'm053': 'sixty-eight seconds later',
      'm054': 'unsent draft',
      'm055': 'opened that panel at 21:08',
      'm056': "exported to Martin's photo tablet",
      'm057': 'ten NO selections',
      'm058': 'exchanged badges',
      'm059': 'blank wildcard cards',
      'm060': 'ninety minutes before her final photograph',
    };
    const expectedStrengths = {
      'm051': ClueStrength.weak,
      'm052': ClueStrength.weak,
      'm053': ClueStrength.weak,
      'm054': ClueStrength.weak,
      'm055': ClueStrength.medium,
      'm056': ClueStrength.medium,
      'm057': ClueStrength.strong,
      'm058': ClueStrength.weak,
      'm059': ClueStrength.weak,
      'm060': ClueStrength.weak,
    };
    final traces = <String>[];

    for (final entry in traceAnchors.entries) {
      final goggles = content.profiles[entry.key]!.clues
          .singleWhere((clue) => clue.source == ClueSource.goggles);
      traces.add(goggles.description);
      expect(goggles.description, contains(entry.value), reason: entry.key);
      expect(goggles.strength, expectedStrengths[entry.key], reason: entry.key);
    }

    expect(traces.toSet(), hasLength(10));
    expect(
        expectedStrengths.entries
            .where((entry) => entry.value != ClueStrength.weak)
            .map((entry) => entry.key),
        ['m055', 'm056', 'm057']);

    final martin = content.profiles['m057']!;
    expect(
        martin.clues
            .singleWhere((clue) => clue.source == ClueSource.profile)
            .strength,
        ClueStrength.medium);
    expect(
        martin.clues
            .singleWhere((clue) => clue.source == ClueSource.photo)
            .strength,
        ClueStrength.strong);
    expect(
        martin.clues
            .singleWhere((clue) => clue.source == ClueSource.conversation)
            .strength,
        ClueStrength.strong);
  });

  test('case 6 stores one Goggles summary and two board leads per profile', () {
    const gogglesSummaries = {
      'm051': 'Schedule contained a wildcard field',
      'm052': "Opened Guest 27's phone record",
      'm053': 'Entered the booth-side store',
      'm054': 'Matched Elisa before the event',
      'm055': "Built the booth's rear access panel",
      'm056': 'His voice announced the wildcard',
      'm057': "Received Elisa's completed scorecard",
      'm058': 'Badge appeared at the wrong table',
      'm059': 'Delivered the wildcard materials',
      'm060': 'Attended an earlier linked event',
    };

    for (final entry in gogglesSummaries.entries) {
      final profile = content.profiles[entry.key]!;
      expect(profile.redHerrings, hasLength(3), reason: entry.key);
      expect(profile.redHerrings.first, entry.value, reason: entry.key);
    }
  });

  testWidgets('case 6 evidence board shows Martin three concise leads',
      (tester) async {
    final martin = content.profiles['m057']!;
    final fullTrace = martin.clues
        .singleWhere((clue) => clue.source == ClueSource.goggles)
        .description;

    await tester.pumpWidget(MaterialApp(
      home: EvidenceBoardDialog(
        profiles: [martin],
        completedProfileIds: {martin.id},
      ),
    ));
    await tester.pump();

    expect(find.text('SUSPICIOUS LEAD'), findsNWidgets(3));
    expect(find.text("Received Elisa's completed scorecard"), findsOneWidget);
    expect(find.text('Controlled the eleventh bell'), findsOneWidget);
    expect(find.text('Operated every linked singles event'), findsOneWidget);
    expect(find.text(fullTrace), findsNothing);
  });
  test('case 7 establishes the complete Unsent Question mystery', () {
    final level = content.levels['case_007']!;
    expect(level.gender, Gender.men);
    expect(level.title, 'The Unsent Question');
    expect(level.difficulty, 'Hard');
    expect(level.profileIds, hasLength(10));
    expect(level.killerProfileId, 'm067');
    expect(content.profiles[level.killerProfileId]!.isKiller, isTrue);
    expect(content.profilesFor(level).where((profile) => profile.isKiller),
        hasLength(1));
    expect(level.caseDescription, contains('Letters First'));
    expect(level.caseDescription, contains('sentence I crossed out'));
    expect(level.caseDescription, contains('Did you know Amelie Rauch'));
    expect(level.caseDescription, contains('opaque correction film'));
    expect(level.caseDescription, contains('Amelie asked me about Klara too'));
    expect(level.caseDescription, contains('twenty-two minutes'));
    expect(level.caseDescription, contains('Nine routed replies'));
    expect(level.caseDescription, contains('dark-green sealing wax'));
    expect(level.caseDescription, contains('miniature tracker'));
    expect(level.caseDescription, contains('fifteen years ago'));
  });

  test('case 7 profiles are distinct dating profiles, not case summaries', () {
    const profileIds = [
      'm061',
      'm062',
      'm063',
      'm064',
      'm065',
      'm066',
      'm067',
      'm068',
      'm069',
      'm070',
    ];
    final prompts = <String>[];
    final answers = <String>[];
    final descriptions = <String>[];
    final preferences = <String>[];
    final caseAwareLanguage = RegExp(
      r'\b(Nora|Amelie|Klara|victims?|murder|disappear(?:ed|ance|ances)|the case|police|investigat(?:e|ion|or)|alibi|evidence|killer|suspects?)\b',
      caseSensitive: false,
    );

    for (final profileId in profileIds) {
      final profile = content.profiles[profileId]!;
      expect(profile.levelId, 'case_007', reason: profileId);
      expect(profile.questions, hasLength(2), reason: profileId);
      expect(profile.clues, hasLength(4), reason: profileId);
      expect(profile.redHerrings, hasLength(3), reason: profileId);
      expect(profile.redHerrings.toSet(), hasLength(3), reason: profileId);
      expect(
          profile.redHerrings, everyElement(hasLength(lessThanOrEqualTo(45))),
          reason: profileId);
      expect(profile.lookingFor, startsWith('A woman who'), reason: profileId);

      descriptions.add(profile.description);
      preferences.add(profile.lookingFor);
      for (final profileQuestion in profile.questions) {
        prompts.add(profileQuestion.question);
        answers.add(profileQuestion.answer);
      }

      final visibleProfileText = [
        profile.bio,
        profile.description,
        profile.lookingFor,
        ...profile.questions
            .map((question) => '${question.question} ${question.answer}'),
      ].join(' ');
      expect(visibleProfileText, isNot(matches(caseAwareLanguage)),
          reason: profileId);
    }

    expect(prompts.toSet(), hasLength(20));
    expect(answers.toSet(), hasLength(20));
    expect(descriptions.toSet(), hasLength(10));
    expect(preferences.toSet(), hasLength(10));
  });

  test('case 7 conversations reveal clues through natural dating chat', () {
    const transcriptAnchors = {
      'm061': 'Four GPS tracks',
      'm062': 'permission could only read entries',
      'm063': 'map inside one of my handwritten letters',
      'm064': 'unfinished article about two old municipal files',
      'm065': 'decode the regional hub and sorting district',
      'm066': 'still broadcasting from inside a drone battery housing',
      'm067': 'uncover a sentence beneath correction film',
      'm068': 'Bluetooth diagnostic tablet on a night service bus',
      'm069':
          'first paid campaign photographed people exchanging anonymous handwritten letters',
      'm070': 'journalist recently requested two old record boxes',
    };
    const crossCheckAnchors = {
      'm061': 'city assignment and four synchronized GPS',
      'm062': 'service ticket, screen recording',
      'm063': 'original file and shop receipt',
      'm064': 'Editor notes and interview recordings',
      'm065': 'work ticket and mirrored terminal log',
      'm066': 'Repair video and continuous telemetry',
      'm067': 'appointment ledger identifies her as Amelie Rauch',
      'm068': 'Depot video, driver assignment',
      'm069': 'archive index confirms',
      'm070': 'Request tickets and delivery receipts',
    };
    final investigativeLanguage = RegExp(
      r'\b(Nora|Amelie|Klara|victims?|murder|disappear(?:ed|ance|ances)|the case|police|investigators?|alibi|evidence|killer|suspects?|what proves|verify independently|records show)\b',
      caseSensitive: false,
    );
    final stageMessages = <String>[];
    final playerLines = <String>[];
    final suspectReplies = <String>[];

    for (final entry in transcriptAnchors.entries) {
      final profile = content.profiles[entry.key]!;
      final conversation = content.conversations[profile.conversationId]!;
      final transcript = conversation.stages.expand((stage) sync* {
        stageMessages.add(stage.suspectMessage);
        yield stage.suspectMessage;
        for (final option in stage.responseOptions) {
          playerLines.add(option.playerText);
          yield option.playerText;
          suspectReplies.add(option.suspectReply);
          yield option.suspectReply;
        }
      }).join(' ');

      expect(conversation.stages, hasLength(3), reason: entry.key);
      expect(
          conversation.stages,
          everyElement(predicate<ConversationStage>(
              (stage) => stage.responseOptions.length == 2)),
          reason: entry.key);
      expect(transcript, contains(entry.value), reason: entry.key);
      expect(transcript, isNot(matches(investigativeLanguage)),
          reason: entry.key);

      final conversationClue = profile.clues
          .singleWhere((clue) => clue.source == ClueSource.conversation);
      expect(
          conversationClue.description, contains(crossCheckAnchors[entry.key]!),
          reason: entry.key);
    }

    expect(stageMessages.toSet(), hasLength(30));
    expect(playerLines.toSet(), hasLength(60));
    expect(suspectReplies.toSet(), hasLength(60));
  });

  test('case 7 Goggles traces create a fair all-medium shortlist', () {
    const traceAnchors = {
      'm061': 'municipal work order',
      'm062': 'read events but could not unlock',
      'm063': '1.2 kilometers',
      'm064': 'editor calendar and source log',
      'm065': 'decoded its district sorting zone',
      'm066': 'twelfth radio identifier',
      'm067': 'dark-green archival wax',
      'm068': 'night foreman drove the bus',
      'm069': 'twelve days before she vanished',
      'm070': 'submitted by Nils',
    };
    const expectedStrengths = {
      'm061': ClueStrength.weak,
      'm062': ClueStrength.weak,
      'm063': ClueStrength.weak,
      'm064': ClueStrength.weak,
      'm065': ClueStrength.medium,
      'm066': ClueStrength.medium,
      'm067': ClueStrength.medium,
      'm068': ClueStrength.weak,
      'm069': ClueStrength.weak,
      'm070': ClueStrength.weak,
    };
    final traces = <String>[];

    for (final entry in traceAnchors.entries) {
      final goggles = content.profiles[entry.key]!.clues
          .singleWhere((clue) => clue.source == ClueSource.goggles);
      traces.add(goggles.description);
      expect(goggles.description, contains(entry.value), reason: entry.key);
      expect(goggles.strength, expectedStrengths[entry.key], reason: entry.key);
    }

    expect(traces.toSet(), hasLength(10));
    expect(
        expectedStrengths.entries
            .where((entry) => entry.value != ClueStrength.weak)
            .map((entry) => entry.key),
        ['m065', 'm066', 'm067']);

    final viktor = content.profiles['m067']!;
    expect(
        viktor.clues
            .singleWhere((clue) => clue.source == ClueSource.profile)
            .strength,
        ClueStrength.medium);
    expect(
        viktor.clues
            .singleWhere((clue) => clue.source == ClueSource.photo)
            .strength,
        ClueStrength.strong);
    expect(
        viktor.clues
            .singleWhere((clue) => clue.source == ClueSource.conversation)
            .strength,
        ClueStrength.strong);
  });

  test('case 7 stores three concise board leads per profile', () {
    const expectedBoardLeads = {
      'm061': [
        "Mapped Nora's delivery district",
        'Worked on her street two days earlier',
        'Team route log confirms the survey',
      ],
      'm062': [
        "Opened Nora's building-access audit",
        'Had inspected the entrance system',
        'Read-only access could not open the door',
      ],
      'm063': [
        "Drew a map near Nora's neighborhood",
        'Used the programme cotton paper',
        'Map ends far from her building',
      ],
      'm064': [
        'Researched both earlier missing women',
        'Kept copies of their correspondence',
        'Source logs predate the letter programme',
      ],
      'm065': [
        "Accessed Nora's forwarding batch",
        'Understood concealed routing codes',
        'Audit never exposed her street address',
      ],
      'm066': [
        'Bought trackers matching the wax cavity',
        'One tracker left his inventory',
        'Radio ID remained in a survey drone',
      ],
      'm067': [
        'Bought the tracker hidden in the seal',
        'Owned the chipped sealing stamp',
        'Met Amelie before she disappeared',
      ],
      'm068': [
        "Work device passed Nora's building",
        'Maintained the bus used that night',
        'Depot camera keeps him at work',
      ],
      'm069': [
        'Photographed Amelie before she vanished',
        'Kept the old programme negatives',
        'Consent form dates the portrait session',
      ],
      'm070': [
        "Opened both earlier women's files",
        'Read their unpublished correspondence',
        'Journalist request explains the access',
      ],
    };

    for (final entry in expectedBoardLeads.entries) {
      final profile = content.profiles[entry.key]!;
      expect(profile.redHerrings, entry.value, reason: entry.key);
      expect(
          profile.redHerrings, everyElement(hasLength(lessThanOrEqualTo(45))),
          reason: entry.key);
    }
  });

  testWidgets('case 7 evidence board shows Viktor three concise leads',
      (tester) async {
    final viktor = content.profiles['m067']!;
    final fullTrace = viktor.clues
        .singleWhere((clue) => clue.source == ClueSource.goggles)
        .description;

    await tester.pumpWidget(MaterialApp(
      home: EvidenceBoardDialog(
        profiles: [viktor],
        completedProfileIds: {viktor.id},
      ),
    ));
    await tester.pump();

    expect(find.text('SUSPICIOUS LEAD'), findsNWidgets(3));
    expect(find.text('Bought the tracker hidden in the seal'), findsOneWidget);
    expect(find.text('Owned the chipped sealing stamp'), findsOneWidget);
    expect(find.text('Met Amelie before she disappeared'), findsOneWidget);
    expect(find.text(fullTrace), findsNothing);
  });
  test("case 8 establishes the complete If You're Home mystery", () {
    final level = content.levels['case_008']!;
    expect(level.gender, Gender.men);
    expect(level.title, "If You're Home");
    expect(level.difficulty, 'Hard');
    expect(level.profileIds, hasLength(10));
    expect(level.killerProfileId, 'm077');
    expect(content.profiles[level.killerProfileId]!.isKiller, isTrue);
    expect(content.profilesFor(level).where((profile) => profile.isKiller),
        hasLength(1));
    expect(level.caseDescription, contains('1:16 a.m.'));
    expect(level.caseDescription, contains('Red shoes. No questions.'));
    expect(level.caseDescription, contains('Twenty-three minutes'));
    expect(
        level.caseDescription, contains("If you're home, who am I hearing?"));
    expect(level.caseDescription, contains('forty-one minutes'));
    expect(level.caseDescription, contains('ninety-six seconds'));
    expect(level.caseDescription, contains('thirteen-second birthday video'));
    expect(level.caseDescription, contains('four older deaths'));
    expect(level.caseDescription, contains("I'm coming"));
    expect(level.caseDescription, contains('2:03 a.m.'));
    expect(level.caseDescription, contains('6:00 a.m.'));
  });

  test('case 8 profiles are distinct dating profiles, not case summaries', () {
    const profileIds = [
      'm071',
      'm072',
      'm073',
      'm074',
      'm075',
      'm076',
      'm077',
      'm078',
      'm079',
      'm080',
    ];
    final prompts = <String>[];
    final answers = <String>[];
    final descriptions = <String>[];
    final preferences = <String>[];
    final caseAwareLanguage = RegExp(
      r'\b(Eva|Mia|victims?|murder|disappear(?:ed|ance|ances)|the case|police|investigat(?:e|ion|or)|alibi|evidence|killer|suspects?)\b',
      caseSensitive: false,
    );

    for (final profileId in profileIds) {
      final profile = content.profiles[profileId]!;
      expect(profile.levelId, 'case_008', reason: profileId);
      expect(profile.questions, hasLength(2), reason: profileId);
      expect(profile.clues, hasLength(4), reason: profileId);
      expect(profile.redHerrings, hasLength(3), reason: profileId);
      expect(profile.redHerrings.toSet(), hasLength(3), reason: profileId);
      expect(
          profile.redHerrings, everyElement(hasLength(lessThanOrEqualTo(45))),
          reason: profileId);
      expect(profile.lookingFor, startsWith('A woman who'), reason: profileId);

      descriptions.add(profile.description);
      preferences.add(profile.lookingFor);
      for (final profileQuestion in profile.questions) {
        prompts.add(profileQuestion.question);
        answers.add(profileQuestion.answer);
      }

      final visibleProfileText = [
        profile.bio,
        profile.description,
        profile.lookingFor,
        ...profile.questions
            .map((question) => '${question.question} ${question.answer}'),
      ].join(' ');
      expect(visibleProfileText, isNot(matches(caseAwareLanguage)),
          reason: profileId);
    }

    expect(prompts.toSet(), hasLength(20));
    expect(answers.toSet(), hasLength(20));
    expect(descriptions.toSet(), hasLength(10));
    expect(preferences.toSet(), hasLength(10));
  });

  test('case 8 conversations reveal clues through natural dating chat', () {
    const transcriptAnchors = {
      'm071': 'retired account sign in from another machine',
      'm072': 'decommissioned warning building',
      'm073': 'wall speakers still carried sound',
      'm074': 'training ambulance move across the tracking map',
      'm075': 'Several archived claims from different years',
      'm076': 'obsolete warning console',
      'm077': 'words people obey are usually ordinary words',
      'm078': 'restored emergency lighting in an abandoned municipal building',
      'm079':
          'sibling-story feature uses recordings listeners submit themselves',
      'm080': 'nightly backup I maintain once made thousands',
    };
    const crossCheckAnchors = {
      'm071': 'Dispatch audio, workstation capture',
      'm072': 'instructor camera and complete class roster',
      'm073': 'inspection report and signed key receipt',
      'm074': 'patient chart, badge scan',
      'm075': 'Intake timestamps and read-only access records',
      'm076': 'museum roster and closing camera',
      'm077': 'platform abuse-recovery cache',
      'm078': 'Coworker video, the electrical invoice',
      'm079': 'upload history, producer login',
      'm080': 'server audit confirms',
    };
    final investigativeLanguage = RegExp(
      r'\b(Eva|Mia|victims?|murder|disappear(?:ed|ance|ances)|the case|police|investigators?|alibi|evidence|killer|suspects?|what proves|verify independently|records show)\b',
      caseSensitive: false,
    );
    final stageMessages = <String>[];
    final playerLines = <String>[];
    final suspectReplies = <String>[];

    for (final entry in transcriptAnchors.entries) {
      final profile = content.profiles[entry.key]!;
      final conversation = content.conversations[profile.conversationId]!;
      final transcript = conversation.stages.expand((stage) sync* {
        stageMessages.add(stage.suspectMessage);
        yield stage.suspectMessage;
        for (final option in stage.responseOptions) {
          playerLines.add(option.playerText);
          yield option.playerText;
          suspectReplies.add(option.suspectReply);
          yield option.suspectReply;
        }
      }).join(' ');

      expect(conversation.stages, hasLength(3), reason: entry.key);
      expect(
          conversation.stages,
          everyElement(predicate<ConversationStage>(
              (stage) => stage.responseOptions.length == 2)),
          reason: entry.key);
      expect(transcript, contains(entry.value), reason: entry.key);
      expect(transcript, isNot(matches(investigativeLanguage)),
          reason: entry.key);

      final conversationClue = profile.clues
          .singleWhere((clue) => clue.source == ClueSource.conversation);
      expect(
          conversationClue.description, contains(crossCheckAnchors[entry.key]!),
          reason: entry.key);
    }

    expect(stageMessages.toSet(), hasLength(30));
    expect(playerLines.toSet(), hasLength(60));
    expect(suspectReplies.toSet(), hasLength(60));
  });

  test('case 8 Goggles traces create a fair all-medium shortlist', () {
    const traceAnchors = {
      'm071': '1:11 a.m.',
      'm072': 'Eleven days before',
      'm073': 'Five months earlier',
      'm074': '1:24 a.m.',
      'm075': 'all four older deaths',
      'm076': 'Eight weeks before',
      'm077': '12:58 a.m.',
      'm078': '4:40 p.m.',
      'm079': 'thirteen-second birthday video',
      'm080': '8,412 user archives',
    };
    const expectedStrengths = {
      'm071': ClueStrength.medium,
      'm072': ClueStrength.weak,
      'm073': ClueStrength.weak,
      'm074': ClueStrength.weak,
      'm075': ClueStrength.weak,
      'm076': ClueStrength.weak,
      'm077': ClueStrength.medium,
      'm078': ClueStrength.weak,
      'm079': ClueStrength.medium,
      'm080': ClueStrength.weak,
    };
    final traces = <String>[];

    for (final entry in traceAnchors.entries) {
      final goggles = content.profiles[entry.key]!.clues
          .singleWhere((clue) => clue.source == ClueSource.goggles);
      traces.add(goggles.description);
      expect(goggles.description, contains(entry.value), reason: entry.key);
      expect(goggles.strength, expectedStrengths[entry.key], reason: entry.key);
    }

    expect(traces.toSet(), hasLength(10));
    expect(
        expectedStrengths.entries
            .where((entry) => entry.value != ClueStrength.weak)
            .map((entry) => entry.key),
        ['m071', 'm077', 'm079']);

    final daniel = content.profiles['m077']!;
    expect(
        daniel.clues
            .singleWhere((clue) => clue.source == ClueSource.profile)
            .strength,
        ClueStrength.medium);
    expect(
        daniel.clues
            .singleWhere((clue) => clue.source == ClueSource.photo)
            .strength,
        ClueStrength.strong);
    expect(
        daniel.clues
            .singleWhere((clue) => clue.source == ClueSource.conversation)
            .strength,
        ClueStrength.strong);
  });

  test('case 8 stores three concise board leads per profile', () {
    const expectedBoardLeads = {
      'm071': [
        'Old account touched the relay',
        'Knew the station call protocol',
        'Live dispatch record confirms his shift',
      ],
      'm072': [
        'Rehearsed a roadside rescue nearby',
        'Taught callers how to sound clear',
        'Class video confirms the full session',
      ],
      'm073': [
        'Opened plans for the warning station',
        'Inspected its sealed service door',
        'Keys were returned months earlier',
      ],
      'm074': [
        "Ambulance crossed Eva's route",
        'Recognized the staged crash details',
        'Patient log fixes his location',
      ],
      'm075': [
        'Reviewed the four earlier accidents',
        "Saw every 'I'm coming' message",
        'Assignments began after each death',
      ],
      'm076': [
        'Phone paired inside the relay room',
        'Helped restore its old equipment',
        'Volunteer log confirms departure',
      ],
      'm077': [
        'Generated a matching voice package',
        "Learned Eva's private rescue phrase",
        'Kept access to the warning relay',
      ],
      'm078': [
        'Restored power at the warning station',
        'Tested its emergency speakers',
        'Lockout seal remained intact',
      ],
      'm079': [
        "Stored Mia's birthday recording",
        'Owned professional cloning tools',
        'Live broadcast fixes his location',
      ],
      'm080': [
        "Exported Eva's voice-message cache",
        'Built the platform backup service',
        'Audit shows an automated export',
      ],
    };

    for (final entry in expectedBoardLeads.entries) {
      final profile = content.profiles[entry.key]!;
      expect(profile.redHerrings, entry.value, reason: entry.key);
      expect(
          profile.redHerrings, everyElement(hasLength(lessThanOrEqualTo(45))),
          reason: entry.key);
    }
  });

  testWidgets('case 8 evidence board shows Daniel three decisive leads',
      (tester) async {
    final daniel = content.profiles['m077']!;
    final fullTrace = daniel.clues
        .singleWhere((clue) => clue.source == ClueSource.goggles)
        .description;

    await tester.pumpWidget(MaterialApp(
      home: EvidenceBoardDialog(
        profiles: [daniel],
        completedProfileIds: {daniel.id},
      ),
    ));
    await tester.pump();

    expect(find.text('SUSPICIOUS LEAD'), findsNWidgets(3));
    expect(find.text('Generated a matching voice package'), findsOneWidget);
    expect(find.text("Learned Eva's private rescue phrase"), findsOneWidget);
    expect(find.text('Kept access to the warning relay'), findsOneWidget);
    expect(find.text(fullTrace), findsNothing);
  });
  test('case 9 establishes the complete Night Archive mystery', () {
    final level = content.levels['case_009']!;
    expect(level.gender, Gender.men);
    expect(level.title, 'The Night Archive');
    expect(level.difficulty, 'Hard');
    expect(level.profileIds, hasLength(10));
    expect(level.killerProfileId, 'm087');
    expect(content.profiles[level.killerProfileId]!.isKiller, isTrue);
    expect(content.profilesFor(level).where((profile) => profile.isKiller),
        hasLength(1));
    expect(level.caseDescription, contains('past eighteen months'));
    expect(level.caseDescription, contains('five women'));
    expect(level.caseDescription, contains('The Revisionist'));
    expect(level.caseDescription, contains('11:52 p.m.'));
    expect(level.caseDescription, contains('written in pencil'));
    expect(level.caseDescription, contains('Someone is giving himself a past'));
    expect(level.caseDescription, contains('I locked aisle seven'));
    expect(level.caseDescription, contains('12:26 a.m.'));
    expect(level.caseDescription, contains('red thread'));
    expect(level.caseDescription, contains('fingerprint on a shelf handle'));
    expect(level.caseDescription, contains('transparent plastic film'));
    expect(level.caseDescription, contains('NEXT TIME, CLEANER'));
    expect(level.caseDescription, contains('exactly four minutes'));
    expect(level.caseDescription, contains('He wrote it backward'));
    expect(level.caseDescription.toLowerCase(), isNot(contains('graphite')));
    expect(level.caseDescription, isNot(contains(String.fromCharCode(0x2014))));
  });

  test('case 9 profiles are distinct, case-unaware, and plainly written', () {
    const profileIds = [
      'm081',
      'm082',
      'm083',
      'm084',
      'm085',
      'm086',
      'm087',
      'm088',
      'm089',
      'm090',
    ];
    final prompts = <String>[];
    final answers = <String>[];
    final descriptions = <String>[];
    final preferences = <String>[];
    final caseAwareLanguage = RegExp(
      r'\b(Leona|Revisionist|victims?|murder|the case|police|investigat(?:e|ion|or)|alibi|evidence|killer|suspects?)\b',
      caseSensitive: false,
    );

    for (final profileId in profileIds) {
      final profile = content.profiles[profileId]!;
      expect(profile.levelId, 'case_009', reason: profileId);
      expect(profile.questions, hasLength(2), reason: profileId);
      expect(profile.clues, hasLength(4), reason: profileId);
      expect(profile.redHerrings, hasLength(3), reason: profileId);
      expect(profile.redHerrings.toSet(), hasLength(3), reason: profileId);
      expect(
          profile.redHerrings, everyElement(hasLength(lessThanOrEqualTo(45))),
          reason: profileId);
      expect(profile.lookingFor, startsWith('A woman who'), reason: profileId);

      descriptions.add(profile.description);
      preferences.add(profile.lookingFor);
      for (final profileQuestion in profile.questions) {
        prompts.add(profileQuestion.question);
        answers.add(profileQuestion.answer);
      }

      final visibleProfileText = [
        profile.bio,
        profile.description,
        profile.lookingFor,
        ...profile.questions
            .map((question) => '${question.question} ${question.answer}'),
      ].join(' ');
      expect(visibleProfileText, isNot(matches(caseAwareLanguage)),
          reason: profileId);

      final allProfileText = [
        visibleProfileText,
        ...profile.clues.map((clue) => clue.description),
        ...profile.redHerrings,
      ].join(' ');
      expect(allProfileText.toLowerCase(), isNot(contains('graphite')),
          reason: profileId);
      expect(allProfileText, isNot(contains(String.fromCharCode(0x2014))),
          reason: profileId);
    }

    expect(prompts.toSet(), hasLength(20));
    expect(answers.toSet(), hasLength(20));
    expect(descriptions.toSet(), hasLength(10));
    expect(preferences.toSet(), hasLength(10));
  });

  test('case 9 conversations reveal clues through natural dating chat', () {
    const transcriptAnchors = {
      'm081': 'replacement box seals under my master account',
      'm082': 'red thread around a wrist',
      'm083': 'leaking pipe once damaged eighty-three archive labels',
      'm084': 'desk session once went inactive for exactly four minutes',
      'm085': 'scanned a bound transcript I typed many years ago',
      'm086': 'security console fell back to our shared guard login',
      'm087': 'pattern becomes convincing when enough records agree',
      'm088': 'downloaded four quiet minutes from an archive corridor',
      'm089': 'lost a numbered archive pencil',
      'm090': 'scanned one of my old work notebooks',
    };
    const crossCheckAnchors = {
      'm081': 'Continuous bench video, two trainee logs',
      'm082': 'Delivery timestamps and layered drawing files',
      'm083': 'printer ledger, return count',
      'm084': 'patron statement, staff-card trail',
      'm085': 'Home scanner history and the bound page sequence',
      'm086': 'Uninterrupted body-camera footage',
      'm087': 'recovered draft-history folder',
      'm088': 'Server history, studio entry logs',
      'm089': 'Cleaning photographs show it there at 12:03',
      'm090': 'Scan history and continuous page numbering',
    };
    final investigativeLanguage = RegExp(
      r'\b(Leona|Revisionist|victims?|murder|the case|police|investigators?|alibi|evidence|killer|suspects?|what proves|verify independently|records show)\b',
      caseSensitive: false,
    );
    final stageMessages = <String>[];
    final playerLines = <String>[];
    final suspectReplies = <String>[];

    for (final entry in transcriptAnchors.entries) {
      final profile = content.profiles[entry.key]!;
      final conversation = content.conversations[profile.conversationId]!;
      final transcript = conversation.stages.expand((stage) sync* {
        stageMessages.add(stage.suspectMessage);
        yield stage.suspectMessage;
        for (final option in stage.responseOptions) {
          playerLines.add(option.playerText);
          yield option.playerText;
          suspectReplies.add(option.suspectReply);
          yield option.suspectReply;
        }
      }).join(' ');

      expect(conversation.stages, hasLength(3), reason: entry.key);
      expect(
          conversation.stages,
          everyElement(predicate<ConversationStage>(
              (stage) => stage.responseOptions.length == 2)),
          reason: entry.key);
      expect(transcript, contains(entry.value), reason: entry.key);
      expect(transcript, isNot(matches(investigativeLanguage)),
          reason: entry.key);
      expect(transcript.toLowerCase(), isNot(contains('graphite')),
          reason: entry.key);
      expect(transcript, isNot(contains(String.fromCharCode(0x2014))),
          reason: entry.key);

      final conversationClue = profile.clues
          .singleWhere((clue) => clue.source == ClueSource.conversation);
      expect(
          conversationClue.description, contains(crossCheckAnchors[entry.key]!),
          reason: entry.key);
    }

    expect(stageMessages.toSet(), hasLength(30));
    expect(playerLines.toSet(), hasLength(60));
    expect(suspectReplies.toSet(), hasLength(60));
  });

  test('case 9 Goggles traces create a fair all-medium shortlist', () {
    const traceAnchors = {
      'm081': '11:43 p.m.',
      'm082': 'all five historical scenes',
      'm083': 'water leak',
      'm084': 'four minutes missing',
      'm085': '10:18 p.m.',
      'm086': 'shared guard login',
      'm087': 'all five selected historical summaries',
      'm088': 'NIGHT ARCHIVE BACKGROUND',
      'm089': '11:28 p.m.',
      'm090': '9:34 p.m.',
    };
    const expectedStrengths = {
      'm081': ClueStrength.medium,
      'm082': ClueStrength.weak,
      'm083': ClueStrength.weak,
      'm084': ClueStrength.weak,
      'm085': ClueStrength.weak,
      'm086': ClueStrength.weak,
      'm087': ClueStrength.medium,
      'm088': ClueStrength.medium,
      'm089': ClueStrength.weak,
      'm090': ClueStrength.weak,
    };
    final traces = <String>[];

    for (final entry in traceAnchors.entries) {
      final goggles = content.profiles[entry.key]!.clues
          .singleWhere((clue) => clue.source == ClueSource.goggles);
      traces.add(goggles.description);
      expect(goggles.description, contains(entry.value), reason: entry.key);
      expect(goggles.strength, expectedStrengths[entry.key], reason: entry.key);
    }

    expect(traces.toSet(), hasLength(10));
    expect(
        expectedStrengths.entries
            .where((entry) => entry.value != ClueStrength.weak)
            .map((entry) => entry.key),
        ['m081', 'm087', 'm088']);

    final victor = content.profiles['m087']!;
    expect(
        victor.clues
            .singleWhere((clue) => clue.source == ClueSource.profile)
            .strength,
        ClueStrength.medium);
    expect(
        victor.clues
            .singleWhere((clue) => clue.source == ClueSource.photo)
            .strength,
        ClueStrength.strong);
    expect(
        victor.clues
            .singleWhere((clue) => clue.source == ClueSource.conversation)
            .strength,
        ClueStrength.strong);
  });

  test('case 9 stores three concise board leads per profile', () {
    const expectedBoardLeads = {
      'm081': [
        'Master account reprinted the box seal',
        'Handled the 2003 file',
        'Bench camera confirms his full shift',
      ],
      'm082': [
        'Drew the reconstructed crime scenes',
        'Used the same red-thread detail',
        'Sources arrived after every death',
      ],
      'm083': [
        'Replaced archive barcodes and seals',
        'Knew the folder tracking weakness',
        'Printer ledger accounts for every label',
      ],
      'm084': [
        'Left during the camera gap',
        'Worked beside the archive at night',
        'Staff-card trail follows a lost patron',
      ],
      'm085': [
        'Digitized the original court transcript',
        'Knew details missing from the archive',
        'Legal copy never entered aisle seven',
      ],
      'm086': [
        'Security login covered the camera gap',
        'Knew the archive blind routes',
        'Body camera records the alarm response',
      ],
      'm087': [
        'Studied every selected cold case',
        'Drafted details before the murders',
        'Wrote the past to match his crimes',
      ],
      'm088': [
        'Downloaded the missing camera minutes',
        'Built matching documentary images',
        'Server copy proves footage remained',
      ],
      'm089': [
        'Borrowed the same archival pencil',
        'Made notes on copies of old files',
        'Reading-room video shows every page',
      ],
      'm090': [
        'Investigated the 2003 murder',
        'Knew the original fingerprint mistake',
        'Old notes preserve the untouched version',
      ],
    };

    for (final entry in expectedBoardLeads.entries) {
      final profile = content.profiles[entry.key]!;
      expect(profile.redHerrings, entry.value, reason: entry.key);
      expect(
          profile.redHerrings, everyElement(hasLength(lessThanOrEqualTo(45))),
          reason: entry.key);
    }
  });

  testWidgets('case 9 evidence board shows Victor three decisive leads',
      (tester) async {
    final victor = content.profiles['m087']!;
    final fullTrace = victor.clues
        .singleWhere((clue) => clue.source == ClueSource.goggles)
        .description;

    await tester.pumpWidget(MaterialApp(
      home: EvidenceBoardDialog(
        profiles: [victor],
        completedProfileIds: {victor.id},
      ),
    ));
    await tester.pump();

    expect(find.text('SUSPICIOUS LEAD'), findsNWidgets(3));
    expect(find.text('Studied every selected cold case'), findsOneWidget);
    expect(find.text('Drafted details before the murders'), findsOneWidget);
    expect(find.text('Wrote the past to match his crimes'), findsOneWidget);
    expect(find.text(fullTrace), findsNothing);
  });
  test('case 10 establishes the complete Perfect Witness mystery', () {
    final level = content.levels['case_010']!;
    expect(level.gender, Gender.men);
    expect(level.title, 'The Perfect Witness');
    expect(level.difficulty, 'Very Hard');
    expect(level.profileIds, hasLength(10));
    expect(level.killerProfileId, 'm097');
    expect(content.profiles[level.killerProfileId]!.isKiller, isTrue);
    expect(content.profilesFor(level).where((profile) => profile.isKiller),
        hasLength(1));
    expect(level.caseDescription, contains('past fourteen months'));
    expect(level.caseDescription, contains('four women'));
    expect(level.caseDescription, contains('exactly seven details'));
    expect(level.caseDescription, contains("I had a clear view"));
    expect(level.caseDescription, contains('10:38 p.m.'));
    expect(level.caseDescription, contains('hands-free voice message'));
    expect(level.caseDescription, contains('West Station car park'));
    expect(level.caseDescription, contains('No earlier emergency call'));
    expect(
        level.caseDescription, contains("Sophie's unfinished voice message"));
    expect(level.caseDescription, contains('the description was planted'));
    expect(level.caseDescription,
        contains('He returned to tell them what they saw'));
    expect(level.caseDescription.toLowerCase(),
        isNot(contains('the light was kind')));
    expect(level.caseDescription, isNot(contains(String.fromCharCode(0x2014))));
  });

  test('case 10 profiles are distinct and unaware of the investigation', () {
    const profileIds = [
      'm091',
      'm092',
      'm093',
      'm094',
      'm095',
      'm096',
      'm097',
      'm098',
      'm099',
      'm100',
    ];
    final prompts = <String>[];
    final answers = <String>[];
    final descriptions = <String>[];
    final preferences = <String>[];
    final caseAwareLanguage = RegExp(
      r'\b(Sophie|Alina|murders?|the case|police|investigat(?:e|ion|or)|alibi|evidence|killer|suspects?|crime scenes?)\b',
      caseSensitive: false,
    );

    for (final profileId in profileIds) {
      final profile = content.profiles[profileId]!;
      expect(profile.levelId, 'case_010', reason: profileId);
      expect(profile.questions, hasLength(2), reason: profileId);
      expect(profile.clues, hasLength(4), reason: profileId);
      expect(profile.redHerrings, hasLength(3), reason: profileId);
      expect(profile.redHerrings.toSet(), hasLength(3), reason: profileId);
      expect(
          profile.redHerrings, everyElement(hasLength(lessThanOrEqualTo(45))),
          reason: profileId);
      expect(profile.lookingFor, startsWith('A woman who'), reason: profileId);

      descriptions.add(profile.description);
      preferences.add(profile.lookingFor);
      for (final question in profile.questions) {
        prompts.add(question.question);
        answers.add(question.answer);
      }

      final visibleProfileText = [
        profile.bio,
        profile.description,
        profile.lookingFor,
        ...profile.questions
            .map((question) => '${question.question} ${question.answer}'),
      ].join(' ');
      expect(visibleProfileText, isNot(matches(caseAwareLanguage)),
          reason: profileId);

      final allProfileText = [
        visibleProfileText,
        ...profile.clues.map((clue) => clue.description),
        ...profile.redHerrings,
      ].join(' ');
      expect(allProfileText, isNot(contains(String.fromCharCode(0x2014))),
          reason: profileId);
    }

    expect(prompts.toSet(), hasLength(20));
    expect(answers.toSet(), hasLength(20));
    expect(descriptions.toSet(), hasLength(10));
    expect(preferences.toSet(), hasLength(10));
  });

  test('case 10 conversations sound like ten different potential dates', () {
    const transcriptAnchors = {
      'm091': 'the first question can shape the answer',
      'm092': 'make a fight look completely real',
      'm093': 'find what somebody hoped would stay hidden',
      'm094': 'my midnight voice reaches rooms I will never see',
      'm095': 'roads so quiet that maps seem to forget them',
      'm096': 'responsible editor has to bury a story',
      'm097': 'uncertainty deserves patience, not pressure',
      'm098': 'wrong light can make a familiar face look like somebody else',
      'm099': 'enough editing I can make almost anyone sound certain',
      'm100': 'Some people should never walk away from consequences',
    };
    const crossCheckAnchors = {
      'm091': 'Continuous conference footage',
      'm092': 'signed collection sheet names Alexander',
      'm093': 'Claim assignments, supervisor approvals',
      'm094': 'Uncut studio video and live listener calls',
      'm095': 'Dispatch recordings, driver cameras',
      'm096': "guest Wi-Fi at Alexander's support center",
      'm097': 'archived support-training video',
      'm098': 'lamp-controller history',
      'm099': 'untouched police files',
      'm100': 'archived judgment proves',
    };
    final investigativeLanguage = RegExp(
      r'\b(Sophie|Alina|murders?|the case|police|evidence|killer|suspects?|crime scene)\b',
      caseSensitive: false,
    );
    final stageMessages = <String>[];
    final playerLines = <String>[];
    final suspectReplies = <String>[];

    for (final entry in transcriptAnchors.entries) {
      final profile = content.profiles[entry.key]!;
      final conversation = content.conversations[profile.conversationId]!;
      final transcript = conversation.stages.expand((stage) sync* {
        stageMessages.add(stage.suspectMessage);
        yield stage.suspectMessage;
        for (final option in stage.responseOptions) {
          playerLines.add(option.playerText);
          yield option.playerText;
          suspectReplies.add(option.suspectReply);
          yield option.suspectReply;
        }
      }).join(' ');

      expect(conversation.stages, hasLength(3), reason: entry.key);
      expect(
          conversation.stages,
          everyElement(predicate<ConversationStage>(
              (stage) => stage.responseOptions.length == 2)),
          reason: entry.key);
      expect(transcript, contains(entry.value), reason: entry.key);
      expect(transcript, isNot(matches(investigativeLanguage)),
          reason: entry.key);
      expect(transcript, isNot(contains(String.fromCharCode(0x2014))),
          reason: entry.key);

      final conversationClue = profile.clues
          .singleWhere((clue) => clue.source == ClueSource.conversation);
      expect(
          conversationClue.description, contains(crossCheckAnchors[entry.key]!),
          reason: entry.key);
    }

    expect(stageMessages.toSet(), hasLength(30));
    expect(playerLines.toSet(), hasLength(60));
    expect(suspectReplies.toSet(), hasLength(60));

    final alexanderConversation =
        content.conversations[content.profiles['m097']!.conversationId]!;
    final alexanderTranscript =
        alexanderConversation.stages.expand((stage) sync* {
      yield stage.suspectMessage;
      for (final option in stage.responseOptions) {
        yield option.playerText;
        yield option.suspectReply;
      }
    }).join(' ');
    expect(
        alexanderTranscript,
        isNot(matches(RegExp(
            r'\b(kill|murder|attack|witness|disappear|vanish|bury|fight|victim|police|seven)\b',
            caseSensitive: false))));
  });

  test('case 10 creates a fair shortlist and decisive Alexander proof', () {
    const expectedStrengths = {
      'm091': ClueStrength.medium,
      'm092': ClueStrength.medium,
      'm093': ClueStrength.weak,
      'm094': ClueStrength.weak,
      'm095': ClueStrength.weak,
      'm096': ClueStrength.weak,
      'm097': ClueStrength.medium,
      'm098': ClueStrength.weak,
      'm099': ClueStrength.weak,
      'm100': ClueStrength.weak,
    };
    final traces = <String>[];

    for (final entry in expectedStrengths.entries) {
      final goggles = content.profiles[entry.key]!.clues
          .singleWhere((clue) => clue.source == ClueSource.goggles);
      traces.add(goggles.description);
      expect(goggles.strength, entry.value, reason: entry.key);
    }
    expect(traces.toSet(), hasLength(10));
    expect(
        expectedStrengths.entries
            .where((entry) => entry.value != ClueStrength.weak)
            .map((entry) => entry.key),
        ['m091', 'm092', 'm097']);

    final alexander = content.profiles['m097']!;
    final goggles = alexander.clues
        .singleWhere((clue) => clue.source == ClueSource.goggles);
    final profile = alexander.clues
        .singleWhere((clue) => clue.source == ClueSource.profile);
    final photo =
        alexander.clues.singleWhere((clue) => clue.source == ClueSource.photo);
    final conversation = alexander.clues
        .singleWhere((clue) => clue.source == ClueSource.conversation);
    expect(goggles.description, contains('shared staff tablet'));
    expect(goggles.description, isNot(contains('Sophie')));
    expect(profile.strength, ClueStrength.medium);
    expect(profile.description, contains('seven-question order'));
    expect(photo.strength, ClueStrength.strong);
    expect(photo.description, contains('West Station locker key'));
    expect(photo.description, contains("fibers matching Alina's clothing"));
    expect(conversation.strength, ClueStrength.strong);
    expect(conversation.description, contains('support-training video'));
    expect(conversation.description, contains("Sophie's recording"));
    expect(conversation.description, contains('personal hotspot'));
  });

  test('case 10 stores three concise evidence-board leads per profile', () {
    const expectedBoardLeads = {
      'm091': [
        'Designed the seven-step memory exercise',
        "Trained Alexander's support organization",
        'Conference recording clears the attack',
      ],
      'm092': [
        'Staged attacks at three crime locations',
        "His costume matched Sophie's description",
        'Charity collected the donated disguise',
      ],
      'm093': [
        'Opened every false-arrest claim',
        "Mapped the witnesses' contradictions",
        'Searches followed official requests',
      ],
      'm094': [
        'Radio voice resembled the stranger',
        'Repeated the witness phrase on air',
        'Live studio feeds clear every attack',
      ],
      'm095': [
        'Fleet vans crossed three crime routes',
        'Knew the car park service exits',
        'Driver cameras verify every journey',
      ],
      'm096': [
        'Published one detail before police',
        'Received tips from a hidden sender',
        'Email trail clears the newsroom',
      ],
      'm097': [
        'Worked nights during two past attacks',
        'Profile photo exposed the disguise locker',
        "Training audio matches Sophie's recording",
      ],
      'm098': [
        'Worked on lights at two crime scenes',
        'Knew where faces would be hidden',
        'Service logs place him elsewhere',
      ],
      'm099': [
        'Edited every witness interview',
        'Removed hesitation from their answers',
        'Police originals predate his edits',
      ],
      'm100': [
        'Used the phrase in an old judgment',
        'Ruled against a mistaken witness',
        'Archived wording predates the murders',
      ],
    };

    for (final entry in expectedBoardLeads.entries) {
      final profile = content.profiles[entry.key]!;
      expect(profile.redHerrings, entry.value, reason: entry.key);
      expect(
          profile.redHerrings, everyElement(hasLength(lessThanOrEqualTo(45))),
          reason: entry.key);
    }
  });

  testWidgets('case 10 evidence board reveals Alexander without full traces',
      (tester) async {
    final alexander = content.profiles['m097']!;
    final fullTrace = alexander.clues
        .singleWhere((clue) => clue.source == ClueSource.goggles)
        .description;

    await tester.pumpWidget(MaterialApp(
      home: EvidenceBoardDialog(
        profiles: [alexander],
        completedProfileIds: {alexander.id},
      ),
    ));
    await tester.pump();

    expect(find.text('SUSPICIOUS LEAD'), findsNWidgets(3));
    expect(find.text('Worked nights during two past attacks'), findsOneWidget);
    expect(
        find.text('Profile photo exposed the disguise locker'), findsOneWidget);
    expect(
        find.text("Training audio matches Sophie's recording"), findsOneWidget);
    expect(find.text(fullTrace), findsNothing);
  });
  test('men campaign contains ten cases with the intended difficulty curve',
      () {
    final menCases = content.levels.values
        .where((level) => level.gender == Gender.men)
        .toList();
    expect(menCases, hasLength(10));
    expect(menCases.map((level) => level.difficulty), [
      'Easy',
      'Easy',
      'Easy',
      'Medium',
      'Medium',
      'Medium',
      'Hard',
      'Hard',
      'Hard',
      'Very Hard'
    ]);
    expect(menCases.every((level) => level.profileIds.length == 10), isTrue);
    expect(
        menCases.map((level) => level.profileIds
            .where((id) => content.profiles[id]!.isKiller)
            .length),
        everyElement(1));
  });

  test('case IDs and JSON ordering follow the two campaigns', () {
    final levels = content.levels.values.toList();
    expect(levels, hasLength(20));
    expect(
        levels.map((level) => level.id),
        List.generate(
            20, (index) => 'case_${(index + 1).toString().padLeft(3, '0')}'));
    expect(
        levels.take(10).every((level) => level.gender == Gender.men), isTrue);
    expect(
        levels.skip(10).every((level) => level.gender == Gender.women), isTrue);

    final profileIds = content.profiles.keys.toList();
    expect(
        profileIds.take(100),
        List.generate(
            100, (index) => 'm${(index + 1).toString().padLeft(3, '0')}'));
    expect(
        profileIds.skip(100),
        List.generate(
            100, (index) => 'f${(index + 1).toString().padLeft(3, '0')}'));

    for (var index = 0; index < levels.length; index++) {
      final expectedPrefix = index < 10 ? 'm' : 'f';
      final campaignIndex = index < 10 ? index : index - 10;
      final firstProfileNumber = campaignIndex * 10 + 1;
      final expectedProfileIds = List.generate(
          10,
          (offset) =>
              '$expectedPrefix${(firstProfileNumber + offset).toString().padLeft(3, '0')}');
      expect(levels[index].profileIds, expectedProfileIds,
          reason: levels[index].id);
      expect(
          content.profilesFor(levels[index]).map((profile) => profile.levelId),
          everyElement(levels[index].id),
          reason: levels[index].id);
    }
  });
  test('all profiles have distinct character writing', () {
    final profiles = content.profiles.values.toList();
    expect(profiles, hasLength(200));
    expect(profiles.map((profile) => profile.name).toSet(), hasLength(200));
    expect(profiles.map((profile) => profile.bio).toSet(), hasLength(200));
    expect(
        profiles.map((profile) => profile.description).toSet(), hasLength(200));
    expect(profiles.map((profile) => profile.interests.join('|')).toSet(),
        hasLength(200));
    expect(
        profiles.map((profile) => profile.lookingFor).toSet(), hasLength(200));
    expect(
      profiles
          .where((profile) => profile.gender == Gender.men)
          .every((profile) => profile.lookingFor.startsWith('A woman who')),
      isTrue,
    );
    expect(
      profiles
          .where((profile) => profile.gender == Gender.women)
          .every((profile) => profile.lookingFor.startsWith('A man who')),
      isTrue,
    );
    expect(
      profiles
          .map(
            (profile) => profile.questions
                .map((question) => '${question.question}|${question.answer}')
                .join('||'),
          )
          .toSet(),
      hasLength(200),
    );
  });

  test('every case has exactly one killer and complete evidence channels', () {
    for (final level in content.levels.values) {
      final profiles = content.profilesFor(level);
      final killers = profiles.where((profile) => profile.isKiller).toList();
      expect(profiles, hasLength(10), reason: level.id);
      expect(killers, hasLength(1), reason: level.id);
      expect(killers.single.id, level.killerProfileId, reason: level.id);

      for (final profile in profiles) {
        expect(profile.clues, hasLength(4), reason: profile.id);
        expect(
          profile.clues.map((clue) => clue.source).toSet(),
          equals({
            ClueSource.goggles,
            ClueSource.profile,
            ClueSource.photo,
            ClueSource.conversation,
          }),
          reason: profile.id,
        );
        final clueIds = profile.clues.map((clue) => clue.id).toSet();
        expect(
          profile.clues
              .expand((clue) => clue.relatedClueIds)
              .every(clueIds.contains),
          isTrue,
          reason: profile.id,
        );
      }
    }
  });

  test('case 1 profile prompts are unique and case-unaware', () {
    final caseProfiles = [
      for (var index = 1; index <= 10; index++)
        content.profiles['m${index.toString().padLeft(3, '0')}']!,
    ];
    final prompts = <String>[];
    final answers = <String>[];
    final caseAwareLanguage = RegExp(
      r'\b(missing users?|vanished match|victims?|meeting places?|deleted account|case evidence|investigat(?:e|ion|or)|saved fragment|complete schedule|timestamp)\b',
      caseSensitive: false,
    );

    for (final profile in caseProfiles) {
      expect(profile.questions, hasLength(2), reason: profile.id);
      for (final profileQuestion in profile.questions) {
        prompts.add(profileQuestion.question);
        answers.add(profileQuestion.answer);
        expect(
          '${profileQuestion.question} ${profileQuestion.answer}',
          isNot(matches(caseAwareLanguage)),
          reason: profile.id,
        );
      }
    }

    expect(prompts.toSet(), hasLength(20));
    expect(answers.toSet(), hasLength(20));
  });
  test('case 1 conversations feel like dating chats, not interrogations', () {
    const transcriptAnchors = {
      'm001': 'same group later sent me to Copper Finch',
      'm002': 'quiet stretch between 11:20 and midnight',
      'm003': 'workbench photograph on my profile',
      'm004': 'tag for locker fourteen',
      'm005': 'ticket validators on a three-stop loop',
      'm006': 'river-cleanup poster',
      'm007': 'Copper Finch',
      'm008': 'public wayfinding survey',
      'm009': 'sealed lost-property phone',
      'm010': 'public safety campaign',
    };
    const clueAnchors = {
      'm001': 'Client briefs',
      'm002': 'vehicle telemetry',
      'm003': 'never viewed, matched with, or messaged',
      'm004': 'clinic inventory',
      'm005': 'travel-card taps',
      'm006': 'fourteen months',
      'm007': 'exact meeting order',
      'm008': 'city contract',
      'm009': 'seal remained intact',
      'm010': 'city event archive',
    };
    final caseAwareLanguage = RegExp(
      r'\b(vanished account|missing people|first disappearance|disappearances|victims?|the case|police|investigators?|alibi|deleted account|records show|what proves|verify independently)\b',
      caseSensitive: false,
    );

    for (final entry in transcriptAnchors.entries) {
      final profile = content.profiles[entry.key]!;
      final conversation = content.conversations[profile.conversationId]!;
      final transcript = conversation.stages.expand((stage) sync* {
        yield stage.suspectMessage;
        for (final option in stage.responseOptions) {
          yield option.playerText;
          yield option.suspectReply;
        }
      }).join(' ');

      expect(conversation.stages, hasLength(3), reason: entry.key);
      expect(transcript, contains(entry.value), reason: entry.key);
      expect(transcript, isNot(matches(caseAwareLanguage)), reason: entry.key);
      expect(transcript, isNot(contains('The plain version is less dramatic')),
          reason: entry.key);
      expect(
          transcript,
          isNot(contains(
              'The difficult part is admitting how often I do the opposite')),
          reason: entry.key);

      final conversationClue = profile.clues
          .singleWhere((clue) => clue.source == ClueSource.conversation);
      expect(conversationClue.description, contains(clueAnchors[entry.key]!),
          reason: entry.key);
      expect(profile.redHerrings, hasLength(3), reason: entry.key);
    }
  });
  test('case 1 Goggles activity traces are distinct and logically grounded',
      () {
    const traceAnchors = {
      'm001': 'Nachtglas',
      'm002': 'ambulance station',
      'm003': 'viewed Lukas',
      'm004': 'nineteen times',
      'm005': 'route in reverse',
      'm006': 'public post',
      'm007': 'same phone',
      'm008': 'saved two public maps',
      'm009': 'sealed lost-property phone',
      'm010': 'public emergency-preparedness event',
    };
    final activityTraces = <String>[];

    for (final entry in traceAnchors.entries) {
      final profile = content.profiles[entry.key]!;
      final activityTrace = profile.clues
          .singleWhere((clue) => clue.source == ClueSource.goggles);
      activityTraces.add(activityTrace.description);
      expect(activityTrace.description, contains(entry.value),
          reason: entry.key);
      expect(
          activityTrace.description,
          isNot(contains(
              'Account activity touches the deleted account cache, but the device and work-session record provide a consistent innocent explanation.')),
          reason: entry.key);
      expect(activityTrace.strength,
          entry.key == 'm007' ? ClueStrength.strong : ClueStrength.weak,
          reason: entry.key);
    }

    expect(activityTraces.toSet(), hasLength(10));
    final killerTrace = activityTraces[6];
    expect(killerTrace, contains('before every midnight match'));
    expect(killerTrace, contains("chosen cafe's Wi-Fi"));
    expect(killerTrace, contains('went offline soon after the victim arrived'));
    expect(content.profiles['m007']!.redHerrings, [
      'Same phone used both accounts',
      'Same phone at all three cafes',
      'Named the meeting route in order',
    ]);

    for (final profileId in ['m002', 'm005']) {
      final profile = content.profiles[profileId]!;
      final profileEvidence = [
        profile.description,
        ...profile.questions.map((question) => question.answer),
        ...profile.clues.map((clue) => clue.description),
        ...profile.redHerrings,
      ].join(' ');
      final conversation = content.conversations[profile.conversationId]!;
      final conversationText = conversation.stages.expand((stage) sync* {
        yield stage.suspectMessage;
        for (final option in stage.responseOptions) {
          yield option.playerText;
          yield option.suspectReply;
        }
      }).join(' ');
      expect(profileEvidence, isNot(matches(RegExp(r'11:4[67]'))),
          reason: profileId);
      expect(conversationText, isNot(matches(RegExp(r'11:4[67]'))),
          reason: profileId);
    }
  });

  test('case 1 stores a concise Goggles summary as its first board lead', () {
    const gogglesSummaries = {
      'm001': 'Camera phone logged in at each cafe',
      'm002': 'Active before every midnight match',
      'm003': 'Vanished account viewed him three times',
      'm004': 'Opened public clue nineteen times',
      'm005': 'App followed the meeting corridor',
      'm006': 'Phrase posted fourteen months earlier',
      'm007': 'Same phone used both accounts',
      'm008': 'Vanished account saved two maps',
      'm009': 'Vanished-account data on sealed phone',
      'm010': 'Event activity linked two victims',
    };

    for (final entry in gogglesSummaries.entries) {
      final profile = content.profiles[entry.key]!;
      expect(profile.redHerrings, hasLength(3), reason: entry.key);
      expect(profile.redHerrings.first, entry.value, reason: entry.key);
      expect(profile.redHerrings.toSet(), hasLength(3), reason: entry.key);
      expect(
          profile.redHerrings, everyElement(hasLength(lessThanOrEqualTo(42))),
          reason: entry.key);
    }
  });
  testWidgets('evidence board shows three concise suspicious leads',
      (tester) async {
    final martin = content.profiles['m007']!;
    final gogglesTrace = martin.clues
        .singleWhere((clue) => clue.source == ClueSource.goggles)
        .description;

    await tester.pumpWidget(MaterialApp(
      home: EvidenceBoardDialog(
        profiles: [martin],
        completedProfileIds: {martin.id},
      ),
    ));
    await tester.pump();

    expect(find.text('SUSPICIOUS LEAD'), findsNWidgets(3));
    expect(find.text('Same phone used both accounts'), findsOneWidget);
    expect(find.text('Same phone at all three cafes'), findsOneWidget);
    expect(find.text('Named the meeting route in order'), findsOneWidget);
    expect(find.text('GOGGLES LEAD'), findsNothing);
    expect(find.text(gogglesTrace), findsNothing);
  });
  test(
      'red herrings scale by difficulty and very-hard killers avoid direct confessions',
      () {
    expect(content.conversations, hasLength(200));
    final conversationIds = content.conversations.keys.toList();
    expect(conversationIds.take(100).every((id) => id.startsWith('chat_m')),
        isTrue);
    expect(conversationIds.skip(100).every((id) => id.startsWith('chat_f')),
        isTrue);
    expect(
        content.conversations.values
            .map((conversation) => conversation.stages.first.suspectMessage)
            .toSet(),
        hasLength(200));
    for (final level in content.levels.values) {
      final expectedCount = {
        'case_001',
        'case_002',
        'case_003',
        'case_011',
        'case_012',
        'case_013'
      }.contains(level.id)
          ? 3
          : (level.difficulty == 'Easy' ? 2 : 3);
      expect(
          content
              .profilesFor(level)
              .map((profile) => profile.redHerrings.length),
          everyElement(expectedCount));
    }

    expect(content.profiles['m097']!.redHerrings,
        contains('Worked nights during two past attacks'));
    expect(content.profiles['f097']!.redHerrings,
        contains('Quoted the unpublished sixth verdict'));
    expect(content.profiles['m097']!.redHerrings,
        isNot(contains('Supported Sophie after the attack')));
    expect(content.profiles['f097']!.redHerrings,
        isNot(contains('Appears in emergency records')));
    expect(content.profiles['m091']!.lookingFor, startsWith('A woman who'));
    expect(
        content.profiles['f091']!.lookingFor, contains('genuinely interested'));
    expect(content.profiles['m097']!.lookingFor,
        isNot(contains('contradictions')));
    expect(
        content.profiles['f097']!.lookingFor, isNot(contains('reflections')));

    final m091Final = content.conversations['chat_m091']!.stages.last;
    final f091Final = content.conversations['chat_f091']!.stages.last;
    expect(m091Final.responseOptions.map((option) => option.suspectReply),
        anyElement(contains('mistaken memory')));
    expect(f091Final.responseOptions.map((option) => option.suspectReply),
        anyElement(contains('bookshops')));
    expect(
        content.conversations['chat_m097']!.stages.last.responseOptions
            .map((option) => option.suspectReply),
        everyElement(isNot(contains('disappear'))));
    expect(
        content.conversations['chat_f097']!.stages.last.responseOptions
            .map((option) => option.suspectReply),
        everyElement(isNot(contains('disappear'))));
  });

  test('women cases 1 through 5 preserve their formatted intelligence', () {
    final expectedTypes = {
      'case_011': [
        CaseIntelligenceBlockType.paragraph,
        CaseIntelligenceBlockType.bullets,
        CaseIntelligenceBlockType.paragraph,
        CaseIntelligenceBlockType.bullets,
        CaseIntelligenceBlockType.callout,
        CaseIntelligenceBlockType.paragraph,
        CaseIntelligenceBlockType.paragraph,
        CaseIntelligenceBlockType.callout,
      ],
      'case_012': [
        CaseIntelligenceBlockType.paragraph,
        CaseIntelligenceBlockType.bullets,
        CaseIntelligenceBlockType.paragraph,
        CaseIntelligenceBlockType.timeline,
        CaseIntelligenceBlockType.paragraph,
        CaseIntelligenceBlockType.quote,
        CaseIntelligenceBlockType.paragraph,
        CaseIntelligenceBlockType.bullets,
        CaseIntelligenceBlockType.paragraph,
        CaseIntelligenceBlockType.callout,
      ],
      'case_013': [
        CaseIntelligenceBlockType.paragraph,
        CaseIntelligenceBlockType.bullets,
        CaseIntelligenceBlockType.paragraph,
        CaseIntelligenceBlockType.timeline,
        CaseIntelligenceBlockType.quote,
        CaseIntelligenceBlockType.bullets,
        CaseIntelligenceBlockType.paragraph,
        CaseIntelligenceBlockType.bullets,
        CaseIntelligenceBlockType.paragraph,
        CaseIntelligenceBlockType.callout,
      ],
      'case_014': [
        CaseIntelligenceBlockType.timeline,
        CaseIntelligenceBlockType.bullets,
        CaseIntelligenceBlockType.paragraph,
        CaseIntelligenceBlockType.quote,
        CaseIntelligenceBlockType.quote,
        CaseIntelligenceBlockType.timeline,
        CaseIntelligenceBlockType.bullets,
        CaseIntelligenceBlockType.paragraph,
        CaseIntelligenceBlockType.callout,
      ],
      'case_015': [
        CaseIntelligenceBlockType.paragraph,
        CaseIntelligenceBlockType.quote,
        CaseIntelligenceBlockType.timeline,
        CaseIntelligenceBlockType.paragraph,
        CaseIntelligenceBlockType.bullets,
        CaseIntelligenceBlockType.paragraph,
        CaseIntelligenceBlockType.bullets,
        CaseIntelligenceBlockType.paragraph,
        CaseIntelligenceBlockType.quote,
        CaseIntelligenceBlockType.bullets,
        CaseIntelligenceBlockType.callout,
        CaseIntelligenceBlockType.paragraph,
        CaseIntelligenceBlockType.callout,
      ],
    };

    for (final entry in expectedTypes.entries) {
      final level = content.levels[entry.key]!;
      expect(
          level.caseIntelligenceFormat.map((block) => block.type), entry.value,
          reason: entry.key);
      expect(
          level.caseIntelligenceFormat
              .expand((block) => block.contentParts)
              .join(' '),
          level.caseDescription,
          reason: '${entry.key} must retain every word in its description');
    }

    expect(content.levels['case_011']!.caseIntelligenceFormat[4].heading,
        'THE TROPHY CHAIN');
    expect(content.levels['case_012']!.caseIntelligenceFormat[3].heading,
        "PAUL'S FIRST FALL");
    expect(content.levels['case_013']!.caseIntelligenceFormat[4].heading,
        'THE RECORDING');
    expect(content.levels['case_014']!.caseIntelligenceFormat[6].heading,
        'THE MOVING HOUSE');
    expect(content.levels['case_015']!.caseIntelligenceFormat[10].heading,
        'THE DELIVERY WINDOW');
    expect(ContentValidator().validate(content), isEmpty);
  });

  testWidgets('women cases 1 through 5 render their intelligence layouts',
      (tester) async {
    final expectedHeading = {
      'case_011': 'THE TROPHY CHAIN',
      'case_012': "PAUL'S FIRST FALL",
      'case_013': 'THE RECORDING',
      'case_014': 'THE MOVING HOUSE',
      'case_015': 'THE DELIVERY WINDOW',
    };

    for (final entry in expectedHeading.entries) {
      game.unlockedLevelIds.add(entry.key);
      game.chooseCase(entry.key);
      await tester.pumpWidget(
        GameScope(
          controller: game,
          child: const MaterialApp(home: BriefingScreen()),
        ),
      );
      await tester.pump();

      expect(find.text(entry.value), findsOneWidget, reason: entry.key);
      expect(find.text(game.currentLevel.caseDescription), findsNothing,
          reason: entry.key);
      expect(tester.takeException(), isNull, reason: entry.key);
    }
  });

  test('women case 1 establishes the complete Empty Chair mystery', () {
    final level = content.levels['case_011']!;
    final profiles = content.profilesFor(level);

    expect(level.title, 'The Empty Chair');
    expect(level.difficulty, 'Easy');
    expect(level.gender, Gender.women);
    expect(
        level.profileIds,
        List.generate(
            10, (index) => 'f${(index + 1).toString().padLeft(3, '0')}'));
    expect(level.killerProfileId, 'f007');
    expect(profiles.where((profile) => profile.isKiller).single.id, 'f007');
    expect(level.caseDescription, contains('five men living alone'));
    expect(level.caseDescription, contains('Oscar Faber'));
    expect(level.caseDescription, contains('Mathias Krüger'));
    expect(level.caseDescription, contains('fingerprint preserved inside'));
    expect(level.caseDescription, contains('blue ceramic cup'));
    expect(level.caseDescription, contains('engraved silver honey spoon'));
    expect(level.caseDescription, contains('ten recent connections'));
    expect(level.caseDescription, contains('arranged outside the app'));
    expect(level.caseDescription, contains('another empty chair'));
  });

  test('women case 1 profiles are distinct dates and remain case-unaware', () {
    final profiles = content.profilesFor(content.levels['case_011']!);
    final prompts = <String>[];
    final answers = <String>[];
    final caseAwareLanguage = RegExp(
      r'\b(oscar|mathias|victim|killer|poison|murder|police|evidence|investigat(?:e|ion|or))\b',
      caseSensitive: false,
    );

    expect(profiles.map((profile) => profile.name).toSet(), hasLength(10));
    expect(profiles.map((profile) => profile.bio).toSet(), hasLength(10));
    expect(
        profiles.map((profile) => profile.occupation).toSet(), hasLength(10));
    expect(profiles.map((profile) => profile.interests.join('|')).toSet(),
        hasLength(10));
    expect(
        profiles.map((profile) => profile.lookingFor).toSet(), hasLength(10));

    for (final profile in profiles) {
      expect(profile.lookingFor, startsWith('A man'), reason: profile.id);
      expect(profile.lookingFor, isNot(matches(caseAwareLanguage)),
          reason: profile.id);
      expect(profile.questions, hasLength(2), reason: profile.id);
      for (final question in profile.questions) {
        prompts.add(question.question);
        answers.add(question.answer);
        expect(question.question, isNot(matches(caseAwareLanguage)),
            reason: profile.id);
        expect(question.answer, isNot(matches(caseAwareLanguage)),
            reason: profile.id);
      }
    }

    expect(prompts.toSet(), hasLength(20));
    expect(answers.toSet(), hasLength(20));
  });

  test('women case 1 conversations sound like ten different possible dates',
      () {
    const transcriptAnchors = <String, String>{
      'f001': 'blue-and-cream breakfast set',
      'f002': 'delivering basil to a restaurant',
      'f003': 'blue hotel cup',
      'f004': 'dinner sound',
      'f005': 'allergies and medication',
      'f006': 'photograph of their kitchen shelf',
      'f007': "I'll bring something for the table",
      'f008': 'controlled landscaping treatment',
      'f009': 'meals and household objects carry memory',
      'f010': 'forty engraved spoons',
    };
    final caseAwareLanguage = RegExp(
      r'\b(oscar|mathias|victim|killer|poison|murder|police|evidence|investigat(?:e|ion|or))\b',
      caseSensitive: false,
    );
    final openingMessages = <String>{};

    for (final entry in transcriptAnchors.entries) {
      final conversation = content.conversations['chat_${entry.key}']!;
      expect(conversation.stages, hasLength(3), reason: entry.key);
      openingMessages.add(conversation.stages.first.suspectMessage);
      final transcript = conversation.stages.expand((stage) sync* {
        yield stage.suspectMessage;
        for (final option in stage.responseOptions) {
          yield option.playerText;
          yield option.suspectReply;
        }
      }).join(' ');
      expect(transcript, contains(entry.value), reason: entry.key);
      expect(transcript, isNot(matches(caseAwareLanguage)), reason: entry.key);
    }

    expect(openingMessages, hasLength(10));
  });

  test('women case 1 Goggles creates a fair three-profile shortlist', () {
    final profiles = content.profilesFor(content.levels['case_011']!);
    final gogglesStrengths = <String, ClueStrength>{
      for (final profile in profiles)
        profile.id: profile.clues
            .singleWhere((clue) => clue.source == ClueSource.goggles)
            .strength,
    };

    expect(gogglesStrengths['f005'], ClueStrength.medium);
    expect(gogglesStrengths['f006'], ClueStrength.medium);
    expect(gogglesStrengths['f007'], ClueStrength.strong);
    for (final profileId in <String>[
      'f001',
      'f002',
      'f003',
      'f004',
      'f008',
      'f009',
      'f010'
    ]) {
      expect(gogglesStrengths[profileId], ClueStrength.weak, reason: profileId);
    }

    expect(
        content.profiles['f005']!.clues
            .singleWhere((clue) => clue.source == ClueSource.goggles)
            .description,
        allOf(contains('heart medication'), contains('emergency ward')));
    expect(
        content.profiles['f006']!.clues
            .singleWhere((clue) => clue.source == ClueSource.goggles)
            .description,
        allOf(contains('blue glaze'), contains("maker's mark")));
    expect(
        content.profiles['f007']!.clues
            .singleWhere((clue) => clue.source == ClueSource.goggles)
            .description,
        allOf(contains("Helena's phone"), contains('matched Mathias')));
  });

  test('women case 1 stores complete clues and concise board leads', () {
    final profiles = content.profilesFor(content.levels['case_011']!);
    final expectedSources = ClueSource.values
        .where((source) => source != ClueSource.question)
        .toSet();

    for (final profile in profiles) {
      expect(profile.clues, hasLength(4), reason: profile.id);
      expect(profile.clues.map((clue) => clue.source).toSet(), expectedSources,
          reason: profile.id);
      expect(profile.redHerrings, hasLength(3), reason: profile.id);
      expect(profile.redHerrings.every((lead) => lead.length <= 48), isTrue,
          reason: profile.id);
      if (!profile.isKiller) {
        expect(
            profile.clues.where((clue) => clue.strength == ClueStrength.strong),
            isEmpty,
            reason: profile.id);
      }
    }

    final helena = content.profiles['f007']!;
    expect(helena.redHerrings, <String>[
      'Deleted profile matched Mathias',
      "Mathias's cup appears in her photo",
      "Repeated Oscar's private invitation"
    ]);
    expect(
        helena.clues
            .singleWhere((clue) => clue.source == ClueSource.photo)
            .description,
        allOf(contains('six weeks after Mathias died'),
            contains('recovered from Oscar')));
    expect(
        helena.clues
            .singleWhere((clue) => clue.source == ClueSource.conversation)
            .description,
        allOf(contains("I'll bring something for the table"),
            contains("Oscar's off-app dinner invitation")));
  });

  testWidgets('women case 1 evidence board shows Helena decisive leads',
      (tester) async {
    final helena = content.profiles['f007']!;

    await tester.pumpWidget(MaterialApp(
      home: EvidenceBoardDialog(
        profiles: <Profile>[helena],
        completedProfileIds: <String>{helena.id},
      ),
    ));
    await tester.pump();

    expect(find.text('SUSPICIOUS LEAD'), findsNWidgets(3));
    expect(find.text('Deleted profile matched Mathias'), findsOneWidget);
    expect(find.text("Mathias's cup appears in her photo"), findsOneWidget);
    expect(find.text("Repeated Oscar's private invitation"), findsOneWidget);
  });
  test('women case 2 establishes the complete Three Minutes Early mystery', () {
    final level = content.levels['case_012']!;
    final profiles = content.profilesFor(level);

    expect(level.title, 'Three Minutes Early');
    expect(level.difficulty, 'Easy');
    expect(level.gender, Gender.women);
    expect(
        level.profileIds,
        List.generate(
            10, (index) => 'f${(index + 11).toString().padLeft(3, '0')}'));
    expect(level.killerProfileId, 'f017');
    expect(profiles.where((profile) => profile.isKiller).single.id, 'f017');
    expect(level.caseDescription, contains('four men died while recovering'));
    expect(level.caseDescription, contains('Paul Gerber'));
    expect(level.caseDescription, contains('7:12 p.m.'));
    expect(level.caseDescription, contains('7:15 p.m.'));
    expect(level.caseDescription, contains('three minutes before'));
    expect(level.caseDescription,
        contains('Yesterday I walked to the kitchen alone'));
    expect(level.caseDescription, contains('Quiet helps before questions do'));
    expect(level.caseDescription, contains('ten recent connections'));
    expect(level.caseDescription, contains('the name was false'));
  });

  test('women case 2 profiles are distinct dates and remain case-unaware', () {
    final profiles = content.profilesFor(content.levels['case_012']!);
    final prompts = <String>[];
    final answers = <String>[];
    final caseAwareLanguage = RegExp(
      r'\b(paul|nora|victim|killer|murder|police|evidence|investigat(?:e|ion|or))\b',
      caseSensitive: false,
    );

    expect(profiles.map((profile) => profile.name).toSet(), hasLength(10));
    expect(profiles.map((profile) => profile.bio).toSet(), hasLength(10));
    expect(
        profiles.map((profile) => profile.occupation).toSet(), hasLength(10));
    expect(profiles.map((profile) => profile.interests.join('|')).toSet(),
        hasLength(10));
    expect(
        profiles.map((profile) => profile.lookingFor).toSet(), hasLength(10));

    for (final profile in profiles) {
      expect(profile.lookingFor, startsWith('A man who'), reason: profile.id);
      expect(profile.lookingFor, isNot(matches(caseAwareLanguage)),
          reason: profile.id);
      expect(profile.questions, hasLength(2), reason: profile.id);
      for (final question in profile.questions) {
        prompts.add(question.question);
        answers.add(question.answer);
        expect(question.question, isNot(matches(caseAwareLanguage)),
            reason: profile.id);
        expect(question.answer, isNot(matches(caseAwareLanguage)),
            reason: profile.id);
      }
    }

    expect(prompts.toSet(), hasLength(20));
    expect(answers.toSet(), hasLength(20));
  });

  test('women case 2 conversations sound like ten different possible dates',
      () {
    const transcriptAnchors = <String, String>{
      'f011': 'Project LE-1840',
      'f012': 'clinic appointment',
      'f013': 'private workshop job',
      'f014': 'forty-seven pictures',
      'f015': 'Rest should never quietly become isolation',
      'f016': 'four continuous days',
      'f017': 'Quiet helps before questions do',
      'f018': 'three minutes before the test fall',
      'f019': 'three-minute evacuation target',
      'f020': 'recovery article',
    };
    final caseAwareLanguage = RegExp(
      r'\b(paul|nora|victim|killer|murder|police|evidence|investigat(?:e|ion|or))\b',
      caseSensitive: false,
    );
    final openingMessages = <String>{};

    for (final entry in transcriptAnchors.entries) {
      final conversation = content.conversations['chat_${entry.key}']!;
      expect(conversation.stages, hasLength(3), reason: entry.key);
      openingMessages.add(conversation.stages.first.suspectMessage);
      final transcript = conversation.stages.expand((stage) sync* {
        yield stage.suspectMessage;
        for (final option in stage.responseOptions) {
          yield option.playerText;
          yield option.suspectReply;
        }
      }).join(' ');
      expect(transcript, contains(entry.value), reason: entry.key);
      expect(transcript, isNot(matches(caseAwareLanguage)), reason: entry.key);
    }

    expect(openingMessages, hasLength(10));
  });

  test('women case 2 Goggles creates a fair three-profile shortlist', () {
    final profiles = content.profilesFor(content.levels['case_012']!);
    final gogglesStrengths = <String, ClueStrength>{
      for (final profile in profiles)
        profile.id: profile.clues
            .singleWhere((clue) => clue.source == ClueSource.goggles)
            .strength,
    };

    expect(gogglesStrengths['f013'], ClueStrength.medium);
    expect(gogglesStrengths['f015'], ClueStrength.medium);
    expect(gogglesStrengths['f017'], ClueStrength.strong);
    for (final profileId in <String>[
      'f011',
      'f012',
      'f014',
      'f016',
      'f018',
      'f019',
      'f020'
    ]) {
      expect(gogglesStrengths[profileId], ClueStrength.weak, reason: profileId);
    }

    expect(
        content.profiles['f013']!.clues
            .singleWhere((clue) => clue.source == ClueSource.goggles)
            .description,
        allOf(contains("Paul's workshop Wi-Fi"),
            contains('signed safety quote')));
    expect(
        content.profiles['f015']!.clues
            .singleWhere((clue) => clue.source == ClueSource.goggles)
            .description,
        allOf(contains('Paul and two earlier victims'), contains('recorded')));
    expect(
        content.profiles['f017']!.clues
            .singleWhere((clue) => clue.source == ClueSource.goggles)
            .description,
        allOf(
            contains("Valerie's work handset"), contains('temporary numbers')));
  });

  test('women case 2 stores complete clues and concise board leads', () {
    final profiles = content.profilesFor(content.levels['case_012']!);
    final expectedSources = ClueSource.values
        .where((source) => source != ClueSource.question)
        .toSet();

    for (final profile in profiles) {
      expect(profile.clues, hasLength(4), reason: profile.id);
      expect(profile.clues.map((clue) => clue.source).toSet(), expectedSources,
          reason: profile.id);
      expect(profile.redHerrings, hasLength(3), reason: profile.id);
      expect(profile.redHerrings.every((lead) => lead.length <= 48), isTrue,
          reason: profile.id);
      if (!profile.isKiller) {
        expect(
            profile.clues.where((clue) => clue.strength == ClueStrength.strong),
            isEmpty,
            reason: profile.id);
      }
    }

    final valerie = content.profiles['f017']!;
    expect(valerie.redHerrings, <String>[
      'Her handset opened the early-call numbers',
      "Photo taken inside Paul's workshop",
      'Repeated the message sent to families'
    ]);
    expect(
        valerie.clues
            .singleWhere((clue) => clue.source == ClueSource.photo)
            .description,
        allOf(contains("during Paul's recovery"),
            contains('inside his workshop')));
    expect(
        valerie.clues
            .singleWhere((clue) => clue.source == ClueSource.conversation)
            .description,
        allOf(contains('Quiet helps before questions do'),
            contains("every victim's phone")));
  });

  testWidgets('women case 2 evidence board shows Valerie decisive leads',
      (tester) async {
    final valerie = content.profiles['f017']!;

    await tester.pumpWidget(MaterialApp(
      home: EvidenceBoardDialog(
        profiles: <Profile>[valerie],
        completedProfileIds: <String>{valerie.id},
      ),
    ));
    await tester.pump();

    expect(find.text('SUSPICIOUS LEAD'), findsNWidgets(3));
    expect(
        find.text('Her handset opened the early-call numbers'), findsOneWidget);
    expect(find.text("Photo taken inside Paul's workshop"), findsOneWidget);
    expect(find.text('Repeated the message sent to families'), findsOneWidget);
  });
  test('women case 3 establishes the complete Someone in the Water mystery',
      () {
    final level = content.levels['case_013']!;
    final profiles = content.profilesFor(level);

    expect(level.title, 'Someone in the Water');
    expect(level.difficulty, 'Easy');
    expect(level.gender, Gender.women);
    expect(
        level.profileIds,
        List.generate(
            10, (index) => 'f${(index + 21).toString().padLeft(3, '0')}'));
    expect(level.killerProfileId, 'f027');
    expect(profiles.where((profile) => profile.isKiller).single.id, 'f027');
    expect(level.caseDescription, contains('three men drowned'));
    expect(level.caseDescription, contains('same short voice message'));
    expect(level.caseDescription, contains('Look at the water'));
    expect(level.caseDescription,
        contains('flashed blue to warn that someone had fallen'));
    expect(level.caseDescription, contains('David Lorenz'));
    expect(level.caseDescription, contains('South Lock signal post'));
    expect(level.caseDescription,
        contains('Please pick up. I am almost there. Just pick up.'));
    expect(level.caseDescription, contains('Careful. The last step is loose.'));
    expect(level.caseDescription,
        contains('red coat fastened around a weighted rehearsal dummy'));
    expect(level.caseDescription, contains('portable battery'));
    expect(level.caseDescription, contains('helping strangers in danger'));
  });

  test('women case 3 profiles are distinct dates and remain case-unaware', () {
    final profiles = content.profilesFor(content.levels['case_013']!);
    final prompts = <String>[];
    final answers = <String>[];
    final caseAwareLanguage = RegExp(
      r'\b(david|victim|killer|murder|police|evidence|investigat(?:e|ion|or)|drown(?:ed|ing)?)\b',
      caseSensitive: false,
    );

    expect(profiles.map((profile) => profile.name).toSet(), hasLength(10));
    expect(profiles.map((profile) => profile.bio).toSet(), hasLength(10));
    expect(
        profiles.map((profile) => profile.occupation).toSet(), hasLength(10));
    expect(profiles.map((profile) => profile.interests.join('|')).toSet(),
        hasLength(10));
    expect(
        profiles.map((profile) => profile.lookingFor).toSet(), hasLength(10));

    for (final profile in profiles) {
      expect(profile.lookingFor, startsWith('A man who'), reason: profile.id);
      expect(profile.lookingFor, isNot(matches(caseAwareLanguage)),
          reason: profile.id);
      expect(profile.questions, hasLength(2), reason: profile.id);
      for (final question in profile.questions) {
        prompts.add(question.question);
        answers.add(question.answer);
        expect(question.question, isNot(matches(caseAwareLanguage)),
            reason: profile.id);
        expect(question.answer, isNot(matches(caseAwareLanguage)),
            reason: profile.id);
      }
    }

    expect(prompts.toSet(), hasLength(20));
    expect(answers.toSet(), hasLength(20));
  });

  test('women case 3 conversations sound like ten different possible dates',
      () {
    const transcriptAnchors = <String, String>{
      'f021': 'Eight of us waited for a city inspector',
      'f022': 'three missing ferry batteries',
      'f023': 'free sound library',
      'f024': 'bright red field sheet',
      'f025': 'bottom step shifted under my weight',
      'f026': 'blue river lights and maintenance ladders',
      'f027': 'Careful. The last step is loose',
      'f028': 'blue light appeared across the water',
      'f029': 'three unused river signal posts',
      'f030': 'working blue warning lamp',
    };
    final caseAwareLanguage = RegExp(
      r'\b(david|victim|killer|murder|police|evidence|investigat(?:e|ion|or)|drown(?:ed|ing)?)\b',
      caseSensitive: false,
    );
    final openingMessages = <String>{};

    for (final entry in transcriptAnchors.entries) {
      final conversation = content.conversations['chat_${entry.key}']!;
      expect(conversation.stages, hasLength(3), reason: entry.key);
      openingMessages.add(conversation.stages.first.suspectMessage);
      final transcript = conversation.stages.expand((stage) sync* {
        yield stage.suspectMessage;
        for (final option in stage.responseOptions) {
          yield option.playerText;
          yield option.suspectReply;
        }
      }).join(' ');
      expect(transcript, contains(entry.value), reason: entry.key);
      expect(transcript, isNot(matches(caseAwareLanguage)), reason: entry.key);
    }

    expect(openingMessages, hasLength(10));
  });

  test('women case 3 Goggles creates a fair three-profile shortlist', () {
    final profiles = content.profilesFor(content.levels['case_013']!);
    final gogglesStrengths = <String, ClueStrength>{
      for (final profile in profiles)
        profile.id: profile.clues
            .singleWhere((clue) => clue.source == ClueSource.goggles)
            .strength,
    };

    expect(gogglesStrengths['f021'], ClueStrength.medium);
    expect(gogglesStrengths['f025'], ClueStrength.medium);
    expect(gogglesStrengths['f027'], ClueStrength.strong);
    for (final profileId in <String>[
      'f022',
      'f023',
      'f024',
      'f026',
      'f028',
      'f029',
      'f030'
    ]) {
      expect(gogglesStrengths[profileId], ClueStrength.weak, reason: profileId);
    }

    expect(
        content.profiles['f021']!.clues
            .singleWhere((clue) => clue.source == ClueSource.goggles)
            .description,
        allOf(contains('weatherproof blue lamp'),
            contains('permitted public lighting test')));
    expect(
        content.profiles['f025']!.clues
            .singleWhere((clue) => clue.source == ClueSource.goggles)
            .description,
        allOf(contains('opened all three signal platforms'),
            contains('South Lock two days before')));
    expect(
        content.profiles['f027']!.clues
            .singleWhere((clue) => clue.source == ClueSource.goggles)
            .description,
        allOf(
            contains("Vera's stage-lighting app"),
            contains('all three river locations'),
            contains('No performance or public event')));
  });

  test('women case 3 stores complete clues and concise board leads', () {
    final profiles = content.profilesFor(content.levels['case_013']!);
    final expectedSources = ClueSource.values
        .where((source) => source != ClueSource.question)
        .toSet();

    for (final profile in profiles) {
      expect(profile.clues, hasLength(4), reason: profile.id);
      expect(profile.clues.map((clue) => clue.source).toSet(), expectedSources,
          reason: profile.id);
      expect(profile.redHerrings, hasLength(3), reason: profile.id);
      expect(profile.redHerrings.every((lead) => lead.length <= 48), isTrue,
          reason: profile.id);
      if (!profile.isKiller) {
        expect(
            profile.clues.where((clue) => clue.strength == ClueStrength.strong),
            isEmpty,
            reason: profile.id);
      }
    }

    final vera = content.profiles['f027']!;
    expect(vera.occupation, 'Stage production manager');
    expect(vera.redHerrings, <String>[
      'Switched on all three blue warning lights',
      'Her rehearsal dummy became the decoy',
      'Repeated the loose-step warning'
    ]);
    expect(
        vera.clues
            .singleWhere((clue) => clue.source == ClueSource.photo)
            .description,
        allOf(contains('bent shoulder bracket'), contains("David's platform")));
    expect(
        vera.clues
            .singleWhere((clue) => clue.source == ClueSource.conversation)
            .description,
        allOf(contains('Careful. The last step is loose'),
            contains("David's ladder")));
  });

  testWidgets('women case 3 evidence board shows Vera decisive leads',
      (tester) async {
    final vera = content.profiles['f027']!;

    await tester.pumpWidget(MaterialApp(
      home: EvidenceBoardDialog(
        profiles: <Profile>[vera],
        completedProfileIds: <String>{vera.id},
      ),
    ));
    await tester.pump();

    expect(find.text('SUSPICIOUS LEAD'), findsNWidgets(3));
    expect(
        find.text('Switched on all three blue warning lights'), findsOneWidget);
    expect(find.text('Her rehearsal dummy became the decoy'), findsOneWidget);
    expect(find.text('Repeated the loose-step warning'), findsOneWidget);
  });
  test('women case 4 establishes the complete House with No Address mystery',
      () {
    final level = content.levels['case_014']!;
    final profiles = content.profilesFor(level);

    expect(level.title, 'The House with No Address');
    expect(level.difficulty, 'Medium');
    expect(level.gender, Gender.women);
    expect(
        level.profileIds,
        List.generate(
            10, (index) => 'f${(index + 31).toString().padLeft(3, '0')}'));
    expect(level.killerProfileId, 'f037');
    expect(profiles.where((profile) => profile.isKiller).single.id, 'f037');
    expect(level.caseDescription, contains('carbon monoxide poisoning'));
    expect(level.caseDescription, contains('same candlelit room'));
    expect(level.caseDescription, contains('Lars Decker'));
    expect(level.caseDescription, contains('THE HOUSE YOU REMEMBER IS READY'));
    expect(level.caseDescription, contains('yellow wooden train'));
    expect(level.caseDescription, contains('She remembered the train'));
    expect(
        level.caseDescription,
        contains(
            "The window is a screen. This isn't a house. I'm inside a truck."));
    expect(level.caseDescription, contains('unmarked furniture truck'));
    expect(level.caseDescription, contains('portable generator'));
    expect(level.caseDescription, contains('ten recent female connections'));
  });

  test('women case 4 profiles are distinct dates and remain case-unaware', () {
    final profiles = content.profilesFor(content.levels['case_014']!);
    final prompts = <String>[];
    final answers = <String>[];
    final caseAwareLanguage = RegExp(
      r'\b(lars|victim|killer|murder|police|evidence|investigat(?:e|ion|or)|disappearance)\b',
      caseSensitive: false,
    );

    expect(profiles.map((profile) => profile.name).toSet(), hasLength(10));
    expect(profiles.map((profile) => profile.bio).toSet(), hasLength(10));
    expect(
        profiles.map((profile) => profile.occupation).toSet(), hasLength(10));
    expect(profiles.map((profile) => profile.interests.join('|')).toSet(),
        hasLength(10));
    expect(
        profiles.map((profile) => profile.lookingFor).toSet(), hasLength(10));

    for (final profile in profiles) {
      expect(profile.lookingFor, startsWith('A man who'), reason: profile.id);
      expect(profile.lookingFor, isNot(matches(caseAwareLanguage)),
          reason: profile.id);
      expect(profile.questions, hasLength(2), reason: profile.id);
      for (final question in profile.questions) {
        prompts.add(question.question);
        answers.add(question.answer);
        expect(question.question, isNot(matches(caseAwareLanguage)),
            reason: profile.id);
        expect(question.answer, isNot(matches(caseAwareLanguage)),
            reason: profile.id);
      }
    }

    expect(prompts.toSet(), hasLength(20));
    expect(answers.toSet(), hasLength(20));
  });

  test('women case 4 conversations sound like ten different possible dates',
      () {
    const transcriptAnchors = <String, String>{
      'f031': 'complete showroom inside an exhibition truck',
      'f032': 'anniversary album',
      'f033': 'copied company job numbers',
      'f034': 'entire thing fit inside one suitcase',
      'f035': 'never run a portable generator inside a closed truck',
      'f036': 'yellow wooden train copied from one old family photograph',
      'f037': 'complete living room inside my furniture truck',
      'f038': 'thin screen in front of it',
      'f039': 'three empty industrial yards',
      'f040': 'storm-damaged childhood home',
    };
    final caseAwareLanguage = RegExp(
      r'\b(lars|victim|killer|murder|police|evidence|investigat(?:e|ion|or)|disappearance)\b',
      caseSensitive: false,
    );
    final openingMessages = <String>{};

    for (final entry in transcriptAnchors.entries) {
      final conversation = content.conversations['chat_${entry.key}']!;
      expect(conversation.stages, hasLength(3), reason: entry.key);
      openingMessages.add(conversation.stages.first.suspectMessage);
      final transcript = conversation.stages.expand((stage) sync* {
        yield stage.suspectMessage;
        for (final option in stage.responseOptions) {
          yield option.playerText;
          yield option.suspectReply;
        }
      }).join(' ');
      expect(transcript, contains(entry.value), reason: entry.key);
      expect(transcript, isNot(matches(caseAwareLanguage)), reason: entry.key);
    }

    expect(openingMessages, hasLength(10));
  });

  test('women case 4 Goggles creates a fair three-profile shortlist', () {
    final profiles = content.profilesFor(content.levels['case_014']!);
    final gogglesStrengths = <String, ClueStrength>{
      for (final profile in profiles)
        profile.id: profile.clues
            .singleWhere((clue) => clue.source == ClueSource.goggles)
            .strength,
    };

    expect(gogglesStrengths['f031'], ClueStrength.medium);
    expect(gogglesStrengths['f033'], ClueStrength.medium);
    expect(gogglesStrengths['f037'], ClueStrength.strong);
    for (final profileId in <String>[
      'f032',
      'f034',
      'f035',
      'f036',
      'f038',
      'f039',
      'f040'
    ]) {
      expect(gogglesStrengths[profileId], ClueStrength.weak, reason: profileId);
    }

    expect(
        content.profiles['f031']!.clues
            .singleWhere((clue) => clue.source == ClueSource.goggles)
            .description,
        allOf(contains('furnished room built inside a display truck'),
            contains('screen that creates a false window')));
    expect(
        content.profiles['f033']!.clues
            .singleWhere((clue) => clue.source == ClueSource.goggles)
            .description,
        allOf(contains('scheduled furniture trucks'),
            contains('valid company job numbers')));
    expect(
        content.profiles['f037']!.clues
            .singleWhere((clue) => clue.source == ClueSource.goggles)
            .description,
        allOf(contains("Iris's shop rented a furniture truck"),
            contains("shop's device and payment account")));
  });

  test('women case 4 stores complete clues and concise board leads', () {
    final profiles = content.profilesFor(content.levels['case_014']!);
    final expectedSources = ClueSource.values
        .where((source) => source != ClueSource.question)
        .toSet();

    for (final profile in profiles) {
      expect(profile.clues, hasLength(4), reason: profile.id);
      expect(profile.clues.map((clue) => clue.source).toSet(), expectedSources,
          reason: profile.id);
      expect(profile.redHerrings, hasLength(3), reason: profile.id);
      expect(profile.redHerrings.every((lead) => lead.length <= 48), isTrue,
          reason: profile.id);
      if (!profile.isKiller) {
        expect(
            profile.clues.where((clue) => clue.strength == ClueStrength.strong),
            isEmpty,
            reason: profile.id);
      }
    }

    final iris = content.profiles['f037']!;
    expect(iris.occupation, 'Second-hand furniture dealer');
    expect(iris.redHerrings, <String>[
      'Rented a truck before every disappearance',
      'Her profile room was built inside a truck',
      'Owned the furniture and hidden generator'
    ]);
    expect(
        iris.clues
            .singleWhere((clue) => clue.source == ClueSource.profile)
            .description,
        allOf(contains('portable generator'), contains('no buyer or receipt')));
    expect(
        iris.clues
            .singleWhere((clue) => clue.source == ClueSource.photo)
            .description,
        allOf(
            contains('cargo tie-down ring'),
            contains('same repeating window view'),
            contains('inside a truck')));
  });

  testWidgets('women case 4 evidence board shows Iris decisive leads',
      (tester) async {
    final iris = content.profiles['f037']!;

    await tester.pumpWidget(MaterialApp(
      home: EvidenceBoardDialog(
        profiles: <Profile>[iris],
        completedProfileIds: <String>{iris.id},
      ),
    ));
    await tester.pump();

    expect(find.text('SUSPICIOUS LEAD'), findsNWidgets(3));
    expect(
        find.text('Rented a truck before every disappearance'), findsOneWidget);
    expect(
        find.text('Her profile room was built inside a truck'), findsOneWidget);
    expect(
        find.text('Owned the furniture and hidden generator'), findsOneWidget);
  });
  test('women case 5 establishes the complete Black Funeral Card mystery', () {
    final level = content.levels['case_015']!;
    final profiles = content.profilesFor(level);

    expect(level.title, 'The Black Funeral Card');
    expect(level.difficulty, 'Medium');
    expect(level.gender, Gender.women);
    expect(
        level.profileIds,
        List.generate(
            10, (index) => 'f${(index + 41).toString().padLeft(3, '0')}'));
    expect(level.killerProfileId, 'f049');
    expect(profiles.where((profile) => profile.isKiller).single.id, 'f049');
    expect(level.caseDescription, contains('black funeral card'));
    expect(level.caseDescription, contains('HE IS COMING HOME'));
    expect(level.caseDescription, contains('display coffin'));
    expect(level.caseDescription, contains('fast-acting sedative'));
    expect(level.caseDescription, contains('no release handles'));
    expect(level.caseDescription,
        contains('freelance vehicle-relocation drivers'));
    expect(level.caseDescription, contains('fake exhibition-company accounts'));
    expect(level.caseDescription, contains('Tonight, at 7:40 p.m.'));
    expect(level.caseDescription, contains('HE IS COMING HOME. 11:40 P.M.'));
    expect(
        level.caseDescription, contains('phone was found beneath his chair'));
    expect(level.caseDescription, contains('becoming unusually dizzy'));
    expect(level.caseDescription, contains('black funeral van'));
    expect(level.caseDescription,
        contains('hearse parked thirty kilometres away'));
    expect(level.caseDescription, contains('Noah may still be alive'));
    expect(level.caseDescription, contains('ten recent female connections'));
  });

  test('women case 5 profiles are distinct dates and remain case-unaware', () {
    final profiles = content.profilesFor(content.levels['case_015']!);
    final prompts = <String>[];
    final answers = <String>[];
    final caseAwareLanguage = RegExp(
      r'\b(noah|victim|killer|murder|police|evidence|abduct(?:ed|ion)?)\b',
      caseSensitive: false,
    );

    expect(profiles.map((profile) => profile.name).toSet(), hasLength(10));
    expect(profiles.map((profile) => profile.bio).toSet(), hasLength(10));
    expect(
        profiles.map((profile) => profile.description).toSet(), hasLength(10));
    expect(
        profiles.map((profile) => profile.occupation).toSet(), hasLength(10));
    expect(profiles.map((profile) => profile.interests.join('|')).toSet(),
        hasLength(10));
    expect(
        profiles.map((profile) => profile.lookingFor).toSet(), hasLength(10));

    for (final profile in profiles) {
      expect(profile.lookingFor, startsWith('A man who'), reason: profile.id);
      final publicText = <String>[
        profile.bio,
        profile.description,
        profile.intent,
        profile.lookingFor,
      ].join(' ');
      expect(publicText, isNot(matches(caseAwareLanguage)), reason: profile.id);
      expect(profile.questions, hasLength(2), reason: profile.id);
      for (final question in profile.questions) {
        prompts.add(question.question);
        answers.add(question.answer);
        expect(question.question, isNot(matches(caseAwareLanguage)),
            reason: profile.id);
        expect(question.answer, isNot(matches(caseAwareLanguage)),
            reason: profile.id);
      }
    }

    expect(prompts.toSet(), hasLength(20));
    expect(answers.toSet(), hasLength(20));
  });

  test('women case 5 conversations sound like ten different possible dates',
      () {
    const transcriptAnchors = <String, String>{
      'f041': 'private download gallery',
      'f042': 'two funeral vans stolen months apart',
      'f043': 'late-night dedications stay searchable',
      'f044': 'overnight guest bench',
      'f045': 'temporary digital key',
      'f046': 'signed approval for every draft',
      'f047': 'nineteenth-century mourning album',
      'f048': 'map quiet roads',
      'f049': 'funeral-industry exhibition',
      'f050': 'borrowed display coffins',
    };
    final caseAwareLanguage = RegExp(
      r'\b(noah|victim|killer|murder|police|evidence|investigat(?:e|ion|or)|abduct(?:ed|ion)?)\b',
      caseSensitive: false,
    );
    final openingMessages = <String>{};

    for (final entry in transcriptAnchors.entries) {
      final conversation = content.conversations['chat_${entry.key}']!;
      expect(conversation.stages, hasLength(3), reason: entry.key);
      openingMessages.add(conversation.stages.first.suspectMessage);
      final transcript = conversation.stages.expand((stage) sync* {
        yield stage.suspectMessage;
        for (final option in stage.responseOptions) {
          yield option.playerText;
          yield option.suspectReply;
        }
      }).join(' ');
      expect(transcript, contains(entry.value), reason: entry.key);
      expect(transcript, isNot(matches(caseAwareLanguage)), reason: entry.key);
    }

    expect(openingMessages, hasLength(10));
  });

  test('women case 5 Goggles creates a fair three-profile shortlist', () {
    final profiles = content.profilesFor(content.levels['case_015']!);
    final gogglesStrengths = <String, ClueStrength>{
      for (final profile in profiles)
        profile.id: profile.clues
            .singleWhere((clue) => clue.source == ClueSource.goggles)
            .strength,
    };

    expect(gogglesStrengths['f044'], ClueStrength.medium);
    expect(gogglesStrengths['f045'], ClueStrength.medium);
    expect(gogglesStrengths['f049'], ClueStrength.strong);
    for (final profileId in <String>[
      'f041',
      'f042',
      'f043',
      'f046',
      'f047',
      'f048',
      'f050'
    ]) {
      expect(gogglesStrengths[profileId], ClueStrength.weak, reason: profileId);
    }

    expect(
        content.profiles['f044']!.clues
            .singleWhere((clue) => clue.source == ClueSource.goggles)
            .description,
        allOf(contains("Lena's restored press"), contains("Noah's card")));
    expect(
        content.profiles['f045']!.clues
            .singleWhere((clue) => clue.source == ClueSource.goggles)
            .description,
        allOf(contains('All three stolen funeral vans'),
            contains('temporary digital service keys')));
    expect(
        content.profiles['f049']!.clues
            .singleWhere((clue) => clue.source == ClueSource.goggles)
            .description,
        allOf(contains('expired temporary event key'),
            contains("Lara's coordinator identity")));
  });

  test('women case 5 stores complete clues and concise board leads', () {
    final profiles = content.profilesFor(content.levels['case_015']!);
    final expectedSources = ClueSource.values
        .where((source) => source != ClueSource.question)
        .toSet();

    for (final profile in profiles) {
      expect(profile.clues, hasLength(4), reason: profile.id);
      expect(profile.clues.map((clue) => clue.source).toSet(), expectedSources,
          reason: profile.id);
      expect(profile.redHerrings, hasLength(3), reason: profile.id);
      expect(profile.redHerrings.every((lead) => lead.length <= 48), isTrue,
          reason: profile.id);
      if (!profile.isKiller) {
        expect(
            profile.clues.where((clue) => clue.strength == ClueStrength.strong),
            isEmpty,
            reason: profile.id);
      }
    }

    final lara = content.profiles['f049']!;
    expect(lara.occupation, 'Trade-show logistics coordinator');
    expect(lara.redHerrings, <String>[
      'Her expired keys opened every stolen van',
      'The coffins vanished after her trade shows',
      "Noah's van entered her storage garage"
    ]);
    expect(
        lara.clues
            .singleWhere((clue) => clue.source == ClueSource.profile)
            .description,
        allOf(contains('approved their return'),
            contains('employees who were not working')));
    expect(
        lara.clues
            .singleWhere((clue) => clue.source == ClueSource.photo)
            .description,
        allOf(contains('private storage garage'),
            contains("Noah's funeral van"), contains('never emerging')));
  });

  testWidgets('women case 5 evidence board shows Lara decisive leads',
      (tester) async {
    final lara = content.profiles['f049']!;

    await tester.pumpWidget(MaterialApp(
      home: EvidenceBoardDialog(
        profiles: <Profile>[lara],
        completedProfileIds: <String>{lara.id},
      ),
    ));
    await tester.pump();

    expect(find.text('SUSPICIOUS LEAD'), findsNWidgets(3));
    expect(
        find.text('Her expired keys opened every stolen van'), findsOneWidget);
    expect(find.text('The coffins vanished after her trade shows'),
        findsOneWidget);
    expect(find.text("Noah's van entered her storage garage"), findsOneWidget);
  });
  test('women cases 6 through 10 preserve their formatted intelligence', () {
    final expectedTypes = {
      'case_016': [
        CaseIntelligenceBlockType.paragraph,
        CaseIntelligenceBlockType.timeline,
        CaseIntelligenceBlockType.timeline,
        CaseIntelligenceBlockType.bullets,
        CaseIntelligenceBlockType.bullets,
        CaseIntelligenceBlockType.paragraph,
        CaseIntelligenceBlockType.bullets,
        CaseIntelligenceBlockType.timeline,
        CaseIntelligenceBlockType.bullets,
        CaseIntelligenceBlockType.callout,
      ],
      'case_017': [
        CaseIntelligenceBlockType.paragraph,
        CaseIntelligenceBlockType.quote,
        CaseIntelligenceBlockType.paragraph,
        CaseIntelligenceBlockType.bullets,
        CaseIntelligenceBlockType.paragraph,
        CaseIntelligenceBlockType.bullets,
        CaseIntelligenceBlockType.paragraph,
        CaseIntelligenceBlockType.callout,
        CaseIntelligenceBlockType.paragraph,
        CaseIntelligenceBlockType.callout,
      ],
      'case_018': [
        CaseIntelligenceBlockType.paragraph,
        CaseIntelligenceBlockType.bullets,
        CaseIntelligenceBlockType.paragraph,
        CaseIntelligenceBlockType.bullets,
        CaseIntelligenceBlockType.bullets,
        CaseIntelligenceBlockType.callout,
        CaseIntelligenceBlockType.paragraph,
        CaseIntelligenceBlockType.callout,
      ],
      'case_019': [
        CaseIntelligenceBlockType.paragraph,
        CaseIntelligenceBlockType.bullets,
        CaseIntelligenceBlockType.bullets,
        CaseIntelligenceBlockType.paragraph,
        CaseIntelligenceBlockType.bullets,
        CaseIntelligenceBlockType.bullets,
        CaseIntelligenceBlockType.callout,
        CaseIntelligenceBlockType.callout,
      ],
      'case_020': [
        CaseIntelligenceBlockType.paragraph,
        CaseIntelligenceBlockType.bullets,
        CaseIntelligenceBlockType.paragraph,
        CaseIntelligenceBlockType.bullets,
        CaseIntelligenceBlockType.bullets,
        CaseIntelligenceBlockType.paragraph,
        CaseIntelligenceBlockType.bullets,
        CaseIntelligenceBlockType.bullets,
        CaseIntelligenceBlockType.callout,
        CaseIntelligenceBlockType.callout,
      ],
    };

    for (final entry in expectedTypes.entries) {
      final level = content.levels[entry.key]!;
      expect(
          level.caseIntelligenceFormat.map((block) => block.type), entry.value,
          reason: entry.key);
      expect(
          level.caseIntelligenceFormat
              .expand((block) => block.contentParts)
              .join(' '),
          level.caseDescription,
          reason: '${entry.key} must retain every word in its description');
    }

    expect(content.levels['case_016']!.caseIntelligenceFormat[9].heading,
        'RESCUE WINDOW');
    expect(content.levels['case_017']!.caseIntelligenceFormat[7].heading,
        'THE GROUP WAS USED');
    expect(content.levels['case_018']!.caseIntelligenceFormat[6].heading,
        'THE SELECTION');
    expect(content.levels['case_019']!.caseIntelligenceFormat[4].heading,
        'THE FUTURES ENGRAVED');
    expect(content.levels['case_020']!.caseIntelligenceFormat[8].heading,
        'VERDICT 06');
    expect(ContentValidator().validate(content), isEmpty);
  });

  testWidgets('women cases 6 through 10 render their intelligence layouts',
      (tester) async {
    final expectedHeading = {
      'case_016': 'RESCUE WINDOW',
      'case_017': 'THE GROUP WAS USED',
      'case_018': 'THE SELECTION',
      'case_019': 'THE FUTURES ENGRAVED',
      'case_020': 'VERDICT 06',
    };

    for (final entry in expectedHeading.entries) {
      game.unlockedLevelIds.add(entry.key);
      game.chooseCase(entry.key);
      await tester.pumpWidget(
        GameScope(
          controller: game,
          child: const MaterialApp(home: BriefingScreen()),
        ),
      );
      await tester.pump();

      expect(find.text(entry.value), findsOneWidget, reason: entry.key);
      expect(find.text(game.currentLevel.caseDescription), findsNothing,
          reason: entry.key);
      expect(tester.takeException(), isNull, reason: entry.key);
    }
  });

  test('women case 6 establishes the complete Last Ferry Home mystery', () {
    final level = content.levels['case_016']!;
    final profiles = content.profilesFor(level);

    expect(level.title, 'The Last Ferry Home');
    expect(level.difficulty, 'Medium');
    expect(level.gender, Gender.women);
    expect(
        level.profileIds,
        List.generate(
            10, (index) => 'f${(index + 51).toString().padLeft(3, '0')}'));
    expect(level.killerProfileId, 'f056');
    expect(profiles.where((profile) => profile.isKiller).single.id, 'f056');
    expect(level.caseDescription, contains('Crossed Paths'));
    expect(level.caseDescription,
        contains('even when they never match or exchange messages'));
    expect(level.caseDescription,
        contains('A cafe worker saw Felix leave with a woman'));
    expect(level.caseDescription,
        contains('the two ferries left at different hours'));
    expect(level.caseDescription,
        contains('There was no repeated departure time'));
    expect(level.caseDescription, contains('two locked cold rooms'));
    expect(level.caseDescription, contains('died from hypothermia'));
    expect(level.caseDescription, contains('no release handles inside'));
    expect(level.caseDescription, contains('ordinary cash ticket'));
    expect(level.caseDescription, contains('At 10:18 p.m.'));
    expect(level.caseDescription, contains('departed at 10:25'));
    expect(level.caseDescription, contains("Jonas's red raincoat"));
    expect(level.caseDescription, contains('loose cleaning panel'));
    expect(level.caseDescription, contains('ten women'));
    expect(level.caseDescription, contains('same unidentified marker'));
    expect(level.caseDescription, contains('Jonas may still be alive'));
    expect(level.caseDescription, contains('before the cold takes him'));
    expect(level.caseDescription, isNot(contains('11:40')));
    expect(level.caseDescription, isNot(contains('eleven passengers boarded')));
    expect(level.caseDescription,
        isNot(contains('ten recent female connections')));
  });

  test('women case 6 profiles are distinct dates and remain case-unaware', () {
    final profiles = content.profilesFor(content.levels['case_016']!);
    final prompts = <String>[];
    final answers = <String>[];
    final caseAwareLanguage = RegExp(
      r'\b(jonas|felix|nils|victim|killer|murder|police|evidence|abduct(?:ed|ion)?)\b',
      caseSensitive: false,
    );

    expect(profiles.map((profile) => profile.name).toSet(), hasLength(10));
    expect(profiles.map((profile) => profile.bio).toSet(), hasLength(10));
    expect(
        profiles.map((profile) => profile.description).toSet(), hasLength(10));
    expect(
        profiles.map((profile) => profile.occupation).toSet(), hasLength(10));
    expect(profiles.map((profile) => profile.interests.join('|')).toSet(),
        hasLength(10));
    expect(
        profiles.map((profile) => profile.lookingFor).toSet(), hasLength(10));

    for (final profile in profiles) {
      expect(profile.lookingFor, startsWith('A man who'), reason: profile.id);
      final publicText = <String>[
        profile.bio,
        profile.description,
        profile.intent,
        profile.lookingFor,
      ].join(' ');
      expect(publicText, isNot(matches(caseAwareLanguage)), reason: profile.id);
      expect(profile.questions, hasLength(2), reason: profile.id);
      for (final question in profile.questions) {
        prompts.add(question.question);
        answers.add(question.answer);
        expect(question.question, isNot(matches(caseAwareLanguage)),
            reason: profile.id);
        expect(question.answer, isNot(matches(caseAwareLanguage)),
            reason: profile.id);
      }
    }

    expect(prompts.toSet(), hasLength(20));
    expect(answers.toSet(), hasLength(20));
  });

  test('women case 6 conversations sound like ten different possible dates',
      () {
    const transcriptAnchors = <String, String>{
      'f051': 'changes with season, weather, and daylight',
      'f052': 'public contact sheet',
      'f053': 'thin restroom cleaning panel',
      'f054': 'photograph every label, seam, and damaged patch',
      'f055': 'camera blind spot',
      'f056': 'old refrigerated wing',
      'f057': 'automatic cooling test',
      'f058': 'streams my evening sets',
      'f059': 'emergency keys for harbour buildings',
      'f060': 'forgotten rooms',
    };
    final caseAwareLanguage = RegExp(
      r'\b(jonas|felix|nils|victim|killer|murder|police|evidence|investigat(?:e|ion|or)|abduct(?:ed|ion)?)\b',
      caseSensitive: false,
    );
    final openingMessages = <String>{};

    for (final entry in transcriptAnchors.entries) {
      final conversation = content.conversations['chat_${entry.key}']!;
      expect(conversation.stages, hasLength(3), reason: entry.key);
      openingMessages.add(conversation.stages.first.suspectMessage);
      final transcript = conversation.stages.expand((stage) sync* {
        yield stage.suspectMessage;
        for (final option in stage.responseOptions) {
          yield option.playerText;
          yield option.suspectReply;
        }
      }).join(' ');
      expect(transcript, contains(entry.value), reason: entry.key);
      expect(transcript, isNot(matches(caseAwareLanguage)), reason: entry.key);
    }

    expect(openingMessages, hasLength(10));
  });

  test('women case 6 Goggles creates a fair three-profile shortlist', () {
    final profiles = content.profilesFor(content.levels['case_016']!);
    final gogglesStrengths = <String, ClueStrength>{
      for (final profile in profiles)
        profile.id: profile.clues
            .singleWhere((clue) => clue.source == ClueSource.goggles)
            .strength,
    };

    expect(gogglesStrengths['f053'], ClueStrength.medium);
    expect(gogglesStrengths['f056'], ClueStrength.strong);
    expect(gogglesStrengths['f057'], ClueStrength.medium);
    for (final profileId in <String>[
      'f051',
      'f052',
      'f054',
      'f055',
      'f058',
      'f059',
      'f060'
    ]) {
      expect(gogglesStrengths[profileId], ClueStrength.weak, reason: profileId);
    }

    expect(
        content.profiles['f053']!.clues
            .singleWhere((clue) => clue.source == ClueSource.goggles)
            .description,
        allOf(contains('served aboard the ferries'),
            contains('loose cleaning panel')));
    expect(
        content.profiles['f056']!.clues
            .singleWhere((clue) => clue.source == ClueSource.goggles)
            .description,
        allOf(contains('anonymous device marker'), contains("Selma's profile"),
            contains('near Jonas')));
    expect(
        content.profiles['f057']!.clues
            .singleWhere((clue) => clue.source == ClueSource.goggles)
            .description,
        allOf(contains("Yara's service account"),
            contains('all three activation histories')));
  });

  test('women case 6 stores complete clues and subtle photo evidence', () {
    final profiles = content.profilesFor(content.levels['case_016']!);
    final expectedSources = ClueSource.values
        .where((source) => source != ClueSource.question)
        .toSet();

    for (final profile in profiles) {
      expect(profile.clues, hasLength(4), reason: profile.id);
      expect(profile.clues.map((clue) => clue.source).toSet(), expectedSources,
          reason: profile.id);
      expect(profile.redHerrings, hasLength(3), reason: profile.id);
      expect(profile.redHerrings.every((lead) => lead.length <= 48), isTrue,
          reason: profile.id);
      if (!profile.isKiller) {
        expect(
            profile.clues.where((clue) => clue.strength == ClueStrength.strong),
            isEmpty,
            reason: profile.id);
      }
    }

    final selma = content.profiles['f056']!;
    expect(selma.occupation, 'Night-market operations manager');
    expect(selma.redHerrings, <String>[
      'Her device crossed paths with all three men',
      'Her tag opened a cold room after Jonas vanished',
      'Her photo was taken beside the cold rooms'
    ]);
    expect(
        selma.clues
            .singleWhere((clue) => clue.source == ClueSource.profile)
            .description,
        allOf(contains('Cold Room 18'), contains('paired phone')));
    final photoClue = selma.clues
        .singleWhere((clue) => clue.source == ClueSource.photo)
        .description;
    expect(
        photoClue,
        allOf(
            contains('staff-only loading passage'),
            contains('predates the first disappearance'),
            contains('several market employees')));
    expect(photoClue, isNot(contains('Felix')));
    expect(photoClue, isNot(contains('missing coat')));
    expect(
        selma.clues
            .singleWhere((clue) => clue.source == ClueSource.conversation)
            .description,
        contains('unreported opening of Cold Room 18'));
  });

  testWidgets('women case 6 evidence board shows Selma combined leads',
      (tester) async {
    final selma = content.profiles['f056']!;

    await tester.pumpWidget(MaterialApp(
      home: EvidenceBoardDialog(
        profiles: <Profile>[selma],
        completedProfileIds: <String>{selma.id},
      ),
    ));
    await tester.pump();

    expect(find.text('SUSPICIOUS LEAD'), findsNWidgets(3));
    expect(find.text('Her device crossed paths with all three men'),
        findsOneWidget);
    expect(find.text('Her tag opened a cold room after Jonas vanished'),
        findsOneWidget);
    expect(
        find.text('Her photo was taken beside the cold rooms'), findsOneWidget);
  });
  test('women case 7 establishes the complete Kindness Test mystery', () {
    final level = content.levels['case_017']!;
    final profiles = content.profilesFor(level);

    expect(level.title, 'The Kindness Test');
    expect(level.difficulty, 'Hard');
    expect(level.gender, Gender.women);
    expect(
        level.profileIds,
        List.generate(
            10, (index) => 'f${(index + 61).toString().padLeft(3, '0')}'));
    expect(level.killerProfileId, 'f068');
    expect(profiles.where((profile) => profile.isKiller).single.id, 'f068');
    expect(level.caseDescription, contains('THE KINDNESS TEST'));
    expect(level.caseDescription, contains('Milan Eckert'));
    expect(level.caseDescription, contains('Henrik Mauer'));
    expect(level.caseDescription, contains('Oskar Venn'));
    expect(level.caseDescription, contains('Unedited public footage'));
    expect(level.caseDescription, contains('gave the wallet to station staff'));
    expect(level.caseDescription, contains('stopped traffic'));
    expect(level.caseDescription, contains('twelve temporary actors'));
    expect(level.caseDescription, contains('four for each victim'));
    expect(level.caseDescription,
        contains('offered each man a recorded chance to answer'));
    expect(level.caseDescription, contains('harmless street research'));
    expect(level.caseDescription, contains('Before You Meet Him'));
    expect(level.caseDescription, contains('created to protect women'));
    expect(level.caseDescription,
        contains('Milan spoke with ten women through the dating app'));
    expect(level.caseDescription,
        contains('viewed, commented on, saved, or moderated'));
    expect(level.caseDescription,
        contains('turning red flags into death sentences'));
    expect(level.caseDescription, isNot(contains('fourth victim')));
    expect(level.caseDescription, isNot(contains('The Orchard of Alibis')));
    expect(level.caseDescription, isNot(contains('\u2014')));
  });

  test('women case 7 profiles are distinct dates with valid group links', () {
    final profiles = content.profilesFor(content.levels['case_017']!);
    final prompts = <String>[];
    final answers = <String>[];
    final caseAwareLanguage = RegExp(
      r'\b(milan|henrik|oskar|victim|killer|murder|police|evidence|investigat(?:e|ion|or))\b',
      caseSensitive: false,
    );

    expect(profiles.map((profile) => profile.name).toSet(), hasLength(10));
    expect(profiles.map((profile) => profile.bio).toSet(), hasLength(10));
    expect(
        profiles.map((profile) => profile.description).toSet(), hasLength(10));
    expect(
        profiles.map((profile) => profile.occupation).toSet(), hasLength(10));
    expect(profiles.map((profile) => profile.interests.join('|')).toSet(),
        hasLength(10));
    expect(
        profiles.map((profile) => profile.lookingFor).toSet(), hasLength(10));

    for (final profile in profiles) {
      expect(profile.lookingFor, startsWith('A man who'), reason: profile.id);
      final publicText = <String>[
        profile.bio,
        profile.description,
        profile.intent,
        profile.lookingFor,
      ].join(' ');
      expect(publicText, isNot(matches(caseAwareLanguage)), reason: profile.id);
      expect(profile.questions, hasLength(2), reason: profile.id);
      for (final question in profile.questions) {
        prompts.add(question.question);
        answers.add(question.answer);
        expect(question.question, isNot(matches(caseAwareLanguage)),
            reason: profile.id);
        expect(question.answer, isNot(matches(caseAwareLanguage)),
            reason: profile.id);
      }

      final clueText = profile.clues.map((clue) => clue.description).join(' ');
      expect(clueText,
          matches(RegExp(r'\b(group|thread)\b', caseSensitive: false)),
          reason: '${profile.id} must have an explicit group interaction');
    }

    expect(prompts.toSet(), hasLength(20));
    expect(answers.toSet(), hasLength(20));
  });

  test('women case 7 conversations sound like ten different possible dates',
      () {
    const transcriptAnchors = <String, String>{
      'f061': 'asked people to stop turning one awkward evening into sport',
      'f062': 'every moderator action leaves an audit trail',
      'f063': 'My cloud account records every export',
      'f064': 'Prepaid voucher clients are hidden from coordinators',
      'f065': 'receive codes automatically',
      'f066': 'keep rehearsal takes when a client disputes payment',
      'f067': 'preserve the complete page',
      'f068': 'ten seconds removed from a recording',
      'f069': 'shared a harsh clip before checking the source',
      'f070': 'ask for the beginning and end',
    };
    final caseAwareLanguage = RegExp(
      r'\b(milan|henrik|oskar|victim|killer|murder|police|evidence|investigat(?:e|ion|or))\b',
      caseSensitive: false,
    );
    final openingMessages = <String>{};

    for (final entry in transcriptAnchors.entries) {
      final conversation = content.conversations['chat_${entry.key}']!;
      expect(conversation.stages, hasLength(3), reason: entry.key);
      openingMessages.add(conversation.stages.first.suspectMessage);
      for (final stage in conversation.stages) {
        expect(stage.responseOptions, hasLength(2), reason: stage.id);
      }
      final transcript = conversation.stages.expand((stage) sync* {
        yield stage.suspectMessage;
        for (final option in stage.responseOptions) {
          yield option.playerText;
          yield option.suspectReply;
        }
      }).join(' ');
      expect(transcript, contains(entry.value), reason: entry.key);
      expect(transcript, isNot(matches(caseAwareLanguage)), reason: entry.key);
      expect(transcript, isNot(contains('\u2014')), reason: entry.key);
    }

    expect(openingMessages, hasLength(10));
  });

  test('women case 7 keeps every initial Goggles result at Medium', () {
    final profiles = content.profilesFor(content.levels['case_017']!);

    for (final profile in profiles) {
      final goggles = profile.clues
          .singleWhere((clue) => clue.source == ClueSource.goggles);
      expect(goggles.strength, ClueStrength.medium, reason: profile.id);
    }

    expect(
        content.profiles['f063']!.clues
            .singleWhere((clue) => clue.source == ClueSource.goggles)
            .description,
        allOf(contains("Jana saved Milan's group thread"),
            contains('public red-caption template')));
    expect(
        content.profiles['f064']!.clues
            .singleWhere((clue) => clue.source == ClueSource.goggles)
            .description,
        allOf(contains("Meike viewed Milan's group thread"),
            contains('all twelve actor listings')));
    expect(
        content.profiles['f068']!.clues
            .singleWhere((clue) => clue.source == ClueSource.goggles)
            .description,
        allOf(contains("each victim's thread"),
            contains("Ruth's research workspace")));
  });

  test('women case 7 stores complete clues and Ruth decisive chain', () {
    final profiles = content.profilesFor(content.levels['case_017']!);
    final expectedSources = ClueSource.values
        .where((source) => source != ClueSource.question)
        .toSet();

    for (final profile in profiles) {
      expect(profile.clues, hasLength(4), reason: profile.id);
      expect(profile.clues.map((clue) => clue.source).toSet(), expectedSources,
          reason: profile.id);
      expect(profile.redHerrings, hasLength(3), reason: profile.id);
      expect(profile.redHerrings.toSet(), hasLength(3), reason: profile.id);
      expect(profile.redHerrings.every((lead) => lead.length <= 48), isTrue,
          reason: profile.id);
      if (!profile.isKiller) {
        expect(
            profile.clues.where((clue) => clue.strength == ClueStrength.strong),
            isEmpty,
            reason: profile.id);
      }
    }

    final ruth = content.profiles['f068']!;
    expect(ruth.occupation, 'Customer research specialist');
    expect(ruth.redHerrings, <String>[
      'Viewed each thread before actors were hired',
      'Her business paid the actors and studios',
      'Her editor ID remains in every FAILED video'
    ]);
    expect(
        ruth.clues
            .singleWhere((clue) => clue.source == ClueSource.profile)
            .description,
        allOf(
            contains("Ruth's research business"),
            contains('all twelve test actors'),
            contains('three self-service studio bookings')));
    final photoClue = ruth.clues
        .singleWhere((clue) => clue.source == ClueSource.photo)
        .description;
    expect(
        photoClue,
        allOf(
            contains('eight months before'), contains('legitimately rented')));
    expect(photoClue, isNot(contains('Milan')));
    expect(photoClue, isNot(contains('stun')));
    expect(photoClue, isNot(contains('strang')));
    expect(
        ruth.clues
            .singleWhere((clue) => clue.source == ClueSource.conversation)
            .description,
        allOf(contains('private editing workspace'),
            contains('hidden editor account identifier')));
  });

  testWidgets('women case 7 evidence board shows Ruth combined leads',
      (tester) async {
    final ruth = content.profiles['f068']!;

    await tester.pumpWidget(MaterialApp(
      home: EvidenceBoardDialog(
        profiles: <Profile>[ruth],
        completedProfileIds: <String>{ruth.id},
      ),
    ));
    await tester.pump();

    expect(find.text('SUSPICIOUS LEAD'), findsNWidgets(3));
    expect(find.text('Viewed each thread before actors were hired'),
        findsOneWidget);
    expect(
        find.text('Her business paid the actors and studios'), findsOneWidget);
    expect(find.text('Her editor ID remains in every FAILED video'),
        findsOneWidget);
  });

  test('women case 8 establishes the Everyone Chose Him mystery', () {
    final level = content.levels['case_018']!;
    final profiles = content.profilesFor(level);

    expect(level.title, 'Everyone Chose Him');
    expect(level.difficulty, 'Hard');
    expect(level.gender, Gender.women);
    expect(
        level.profileIds,
        List.generate(
            10, (index) => 'f${(index + 71).toString().padLeft(3, '0')}'));
    expect(level.killerProfileId, 'f078');
    expect(profiles.where((profile) => profile.isKiller).single.id, 'f078');
    expect(
        level.caseDescription,
        startsWith(
            'At four different dinners, the most wanted man was dead by morning.'));
    expect(level.caseDescription, contains('The Shared Table'));
    expect(
        level.caseDescription, contains('hundreds of ordinary dating dinners'));
    expect(level.caseDescription, contains('Niko Brandes'));
    expect(level.caseDescription, contains('Emil Kerner'));
    expect(level.caseDescription, contains('Cem Arslan'));
    expect(level.caseDescription, contains('Theo Jensen'));
    expect(level.caseDescription,
        contains('many dinners between the deaths ended safely'));
    expect(level.caseDescription,
        contains("Theo's autopsy revealed a plant poison"));
    expect(
        level.caseDescription, contains('a fragment of Theo\'s gold stirrer'));
    expect(level.caseDescription, contains('separate sealed packets'));
    expect(level.caseDescription, contains('Ten women'));
    expect(level.caseDescription,
        contains('four unlogged early-morning openings'));
    expect(level.caseDescription,
        contains('the code cannot identify who entered'));
    expect(level.caseDescription, contains('Nothing was missing'));
    expect(level.caseDescription, contains('The room chose him for her.'));
    expect(level.caseDescription, isNot(contains('fifth victim')));
    expect(level.caseDescription, isNot(contains('rescue')));
    expect(level.caseDescription, isNot(contains('reimbursement')));
    expect(level.caseDescription, isNot(contains('\u2014')));
  });

  test('women case 8 profiles are ten distinct possible dates', () {
    final profiles = content.profilesFor(content.levels['case_018']!);
    final prompts = <String>[];
    final answers = <String>[];
    final caseAwareLanguage = RegExp(
      r'\b(niko|emil|cem|theo|victim|killer|murder|police|evidence|investigat(?:e|ion|or)|poison)\b',
      caseSensitive: false,
    );

    expect(profiles.map((profile) => profile.name).toSet(), hasLength(10));
    expect(profiles.map((profile) => profile.bio).toSet(), hasLength(10));
    expect(
        profiles.map((profile) => profile.description).toSet(), hasLength(10));
    expect(
        profiles.map((profile) => profile.occupation).toSet(), hasLength(10));
    expect(profiles.map((profile) => profile.interests.join('|')).toSet(),
        hasLength(10));
    expect(
        profiles.map((profile) => profile.lookingFor).toSet(), hasLength(10));

    for (final profile in profiles) {
      expect(profile.lookingFor, startsWith('A man who'), reason: profile.id);
      final publicText = <String>[
        profile.bio,
        profile.description,
        profile.intent,
        profile.lookingFor,
      ].join(' ');
      expect(publicText, isNot(matches(caseAwareLanguage)), reason: profile.id);
      expect(profile.questions, hasLength(2), reason: profile.id);
      for (final question in profile.questions) {
        prompts.add(question.question);
        answers.add(question.answer);
        expect(question.question, isNot(matches(caseAwareLanguage)),
            reason: profile.id);
        expect(question.answer, isNot(matches(caseAwareLanguage)),
            reason: profile.id);
      }
    }

    expect(prompts.toSet(), hasLength(20));
    expect(answers.toSet(), hasLength(20));
  });

  test('women case 8 conversations sound like ten different possible dates',
      () {
    const transcriptAnchors = <String, String>{
      'f071': 'supplier code changes',
      'f072': 'Winner packets arrive sealed before I pack the kit',
      'f073': 'I keep a sealed sample from every batch',
      'f074': 'I write drink instructions and demonstrate the final toast',
      'f075': 'both approved and rejected material samples',
      'f076': 'Every floor gets a signed time sheet',
      'f077': 'Restaurants request host changes by email',
      'f078': 'It leaves two lines instead of one',
      'f079': 'Every risky plant gets counted back into my van',
      'f080': 'The software drafts the route before I touch it',
    };
    final caseAwareLanguage = RegExp(
      r'\b(niko|emil|cem|theo|victim|killer|murder|police|evidence|investigat(?:e|ion|or)|poison|fatal)\b',
      caseSensitive: false,
    );
    final openingMessages = <String>{};

    for (final entry in transcriptAnchors.entries) {
      final conversation = content.conversations['chat_${entry.key}']!;
      expect(conversation.stages, hasLength(3), reason: entry.key);
      openingMessages.add(conversation.stages.first.suspectMessage);
      for (final stage in conversation.stages) {
        expect(stage.responseOptions, hasLength(2), reason: stage.id);
      }
      final transcript = conversation.stages.expand((stage) sync* {
        yield stage.suspectMessage;
        for (final option in stage.responseOptions) {
          yield option.playerText;
          yield option.suspectReply;
        }
      }).join(' ');
      expect(transcript, contains(entry.value), reason: entry.key);
      expect(transcript, isNot(matches(caseAwareLanguage)), reason: entry.key);
      expect(transcript, isNot(contains('\u2014')), reason: entry.key);
    }

    expect(openingMessages, hasLength(10));
  });

  test('women case 8 starts every Goggles result at Medium', () {
    final profiles = content.profilesFor(content.levels['case_018']!);

    for (final profile in profiles) {
      final goggles = profile.clues
          .singleWhere((clue) => clue.source == ClueSource.goggles);
      expect(goggles.strength, ClueStrength.medium, reason: profile.id);
    }

    expect(
        content.profiles['f072']!.clues
            .singleWhere((clue) => clue.source == ClueSource.goggles)
            .description,
        allOf(contains('all four fatal event kits'),
            contains('personally packed three')));
    expect(
        content.profiles['f079']!.clues
            .singleWhere((clue) => clue.source == ClueSource.goggles)
            .description,
        allOf(contains('all four fatal packing days'),
            contains('poisonous decorative plants')));
    expect(
        content.profiles['f078']!.clues
            .singleWhere((clue) => clue.source == ClueSource.goggles)
            .description,
        allOf(contains('all four unlogged early-morning'),
            contains('shared keypad does not prove she entered')));
  });

  test('women case 8 stores complete clues and Miriam decisive seal chain', () {
    final profiles = content.profilesFor(content.levels['case_018']!);
    final expectedSources = ClueSource.values
        .where((source) => source != ClueSource.question)
        .toSet();

    for (final profile in profiles) {
      expect(profile.clues, hasLength(4), reason: profile.id);
      expect(profile.clues.map((clue) => clue.source).toSet(), expectedSources,
          reason: profile.id);
      expect(profile.redHerrings, hasLength(3), reason: profile.id);
      expect(profile.redHerrings.toSet(), hasLength(3), reason: profile.id);
      expect(profile.redHerrings.every((lead) => lead.length <= 48), isTrue,
          reason: profile.id);
      if (!profile.isKiller) {
        expect(
            profile.clues.where((clue) => clue.strength == ClueStrength.strong),
            isEmpty,
            reason: profile.id);
      }
    }

    final miriam = content.profiles['f078']!;
    expect(miriam.name, 'Miriam Voss');
    expect(miriam.occupation, 'Guest-care manager');
    expect(miriam.redHerrings, <String>[
      'Her phone marked four unlogged room openings',
      'Her role allowed late access to sealed kits',
      'Her sealer closed every poisoned packet'
    ]);
    expect(
        miriam.clues
            .singleWhere((clue) => clue.source == ClueSource.profile)
            .description,
        allOf(
            contains('reopen completed kits'),
            contains('several safe dinners'),
            contains('all four fatal events')));
    final photoClue =
        miriam.clues.singleWhere((clue) => clue.source == ClueSource.photo);
    expect(photoClue.strength, ClueStrength.medium);
    expect(
        photoClue.description,
        allOf(contains('tabletop packet sealer'),
            contains('predates the deaths'), contains('common')));
    final conversationClue = miriam.clues
        .singleWhere((clue) => clue.source == ClueSource.conversation);
    expect(conversationClue.strength, ClueStrength.strong);
    expect(
        conversationClue.description,
        allOf(
            contains('leaves two lines instead of one'),
            contains('same uneven double-ridge pattern'),
            contains('Plant residue was trapped between the resealed layers')));
    final miriamClueText =
        miriam.clues.map((clue) => clue.description).join(' ');
    expect(miriamClueText, isNot(contains('reimbursement')));
    expect(miriamClueText, isNot(contains('replacement stirrer')));
  });

  testWidgets('women case 8 evidence board shows Miriam combined leads',
      (tester) async {
    final miriam = content.profiles['f078']!;

    await tester.pumpWidget(MaterialApp(
      home: EvidenceBoardDialog(
        profiles: <Profile>[miriam],
        completedProfileIds: <String>{miriam.id},
      ),
    ));
    await tester.pump();

    expect(find.text('SUSPICIOUS LEAD'), findsNWidgets(3));
    expect(find.text('Her phone marked four unlogged room openings'),
        findsOneWidget);
    expect(find.text('Her role allowed late access to sealed kits'),
        findsOneWidget);
    expect(
        find.text('Her sealer closed every poisoned packet'), findsOneWidget);
  });

  test('women case 9 establishes the complete garden mystery', () {
    final level = content.levels['case_019']!;
    final profiles = content.profilesFor(level);

    expect(level.title, 'The Garden That Knew Their Names');
    expect(level.difficulty, 'Hard');
    expect(level.gender, Gender.women);
    expect(
        level.profileIds,
        List.generate(
            10, (index) => 'f${(index + 81).toString().padLeft(3, '0')}'));
    expect(level.killerProfileId, 'f087');
    expect(profiles.where((profile) => profile.isKiller).single.id, 'f087');
    expect(level.caseDescription,
        startsWith('A violent storm uprooted an apple tree'));
    expect(level.caseDescription, contains('The Second Spring'));
    expect(level.caseDescription, contains('Jakob Renner'));
    expect(level.caseDescription, contains('Malik Ozdemir'));
    expect(level.caseDescription, contains('Tom Rehfeld'));
    expect(level.caseDescription, contains('Florian Beck'));
    expect(level.caseDescription,
        contains('every body was already beneath its tree'));
    expect(level.caseDescription, contains('the night before that planting'));
    expect(level.caseDescription, contains('fast-acting sedative'));
    expect(level.caseDescription, contains('had been suffocated'));
    expect(level.caseDescription,
        contains('showing that they entered the garden alive'));
    expect(level.caseDescription, contains('deepened one pit'));
    expect(level.caseDescription, contains('lowered the root ball into place'));
    expect(level.caseDescription, contains('brass nursery marker'));
    expect(
        level.caseDescription,
        contains(
            "a kitchen full of Sunday noise, with apples from our own tree"));
    expect(level.caseDescription,
        contains('His blue spruce marks the garden entrance'));
    expect(level.caseDescription, contains('His linden shades the open lawn'));
    expect(level.caseDescription,
        contains("His oak occupies the garden's central permanent bed"));
    expect(level.caseDescription,
        contains('Many other dates and planting mornings ended safely'));
    expect(level.caseDescription,
        contains('different names and stolen photographs'));
    expect(level.caseDescription,
        contains('whose imagined futures belonged beneath those trees'));
    expect(level.caseDescription, isNot(contains('The Blue Glass Thread')));
    expect(level.caseDescription, isNot(contains('fifth victim')));
    expect(level.caseDescription, isNot(contains('rescue')));
    expect(level.caseDescription, isNot(contains('\u2014')));
  });

  test('women case 9 profiles are distinct and unaware of the murders', () {
    final profiles = content.profilesFor(content.levels['case_019']!);
    final prompts = <String>[];
    final answers = <String>[];
    final caseAwareLanguage = RegExp(
      r'\b(jakob|malik|tom|florian|victim|killer|murder|police|evidence|investigat(?:e|ion|or)|corpse|grave|burial)\b',
      caseSensitive: false,
    );

    expect(profiles.map((profile) => profile.name).toSet(), hasLength(10));
    expect(profiles.map((profile) => profile.bio).toSet(), hasLength(10));
    expect(
        profiles.map((profile) => profile.description).toSet(), hasLength(10));
    expect(
        profiles.map((profile) => profile.occupation).toSet(), hasLength(10));
    expect(profiles.map((profile) => profile.interests.join('|')).toSet(),
        hasLength(10));
    expect(
        profiles.map((profile) => profile.lookingFor).toSet(), hasLength(10));

    for (final profile in profiles) {
      expect(profile.lookingFor, startsWith('A man who'), reason: profile.id);
      final publicText = <String>[
        profile.bio,
        profile.description,
        profile.intent,
        profile.lookingFor,
      ].join(' ');
      expect(publicText, isNot(matches(caseAwareLanguage)), reason: profile.id);
      expect(profile.questions, hasLength(2), reason: profile.id);
      for (final question in profile.questions) {
        prompts.add(question.question);
        answers.add(question.answer);
        expect(question.question, isNot(matches(caseAwareLanguage)),
            reason: profile.id);
        expect(question.answer, isNot(matches(caseAwareLanguage)),
            reason: profile.id);
      }
    }

    expect(prompts.toSet(), hasLength(20));
    expect(answers.toSet(), hasLength(20));
  });

  test('women case 9 conversations sound like ten different possible dates',
      () {
    const transcriptAnchors = <String, String>{
      'f081': 'Once a municipal tree report is signed',
      'f082': 'Equipment invoices repeat automatically',
      'f083': 'weather recorder overnight on an automatic timer',
      'f084': 'photograph saplings after sunset at the nursery',
      'f085': 'pressure test means switching soil sensors off overnight',
      'f086': 'photograph both sides of every brass nursery marker',
      'f087': 'Can I ask you a dangerously domestic question',
      'f088': 'I take the first train',
      'f089': 'Tree locations are committee decisions',
      'f090': 'instructors arrive after contractors uncover and level',
    };
    final caseAwareLanguage = RegExp(
      r'\b(jakob|malik|tom|florian|victim|killer|murder|police|evidence|investigat(?:e|ion|or)|corpse|grave|burial|fatal)\b',
      caseSensitive: false,
    );
    final openingMessages = <String>{};

    for (final entry in transcriptAnchors.entries) {
      final conversation = content.conversations['chat_${entry.key}']!;
      expect(conversation.stages, hasLength(3), reason: entry.key);
      openingMessages.add(conversation.stages.first.suspectMessage);
      for (final stage in conversation.stages) {
        expect(stage.responseOptions, hasLength(2), reason: stage.id);
      }
      final transcript = conversation.stages.expand((stage) sync* {
        yield stage.suspectMessage;
        for (final option in stage.responseOptions) {
          yield option.playerText;
          yield option.suspectReply;
        }
      }).join(' ');
      expect(transcript, contains(entry.value), reason: entry.key);
      expect(transcript, isNot(matches(caseAwareLanguage)), reason: entry.key);
      expect(transcript, isNot(contains('\u2014')), reason: entry.key);
    }

    expect(openingMessages, hasLength(10));
  });

  test('women case 9 creates a fair all-Medium initial shortlist', () {
    final profiles = content.profilesFor(content.levels['case_019']!);

    for (final profile in profiles) {
      final goggles = profile.clues
          .singleWhere((clue) => clue.source == ClueSource.goggles);
      expect(goggles.strength, ClueStrength.medium, reason: profile.id);
    }

    expect(
        content.profiles['f085']!.clues
            .singleWhere((clue) => clue.source == ClueSource.goggles)
            .description,
        allOf(contains('disabled soil alarms beside three burial trees'),
            contains('fourth bed')));
    expect(
        content.profiles['f086']!.clues
            .singleWhere((clue) => clue.source == ClueSource.goggles)
            .description,
        allOf(contains('dispatched all four burial trees'),
            contains('printed their brass nursery markers')));
    expect(
        content.profiles['f087']!.clues
            .singleWhere((clue) => clue.source == ClueSource.goggles)
            .description,
        allOf(contains('all four fatal planting mornings'),
            contains('twenty-six safe plantings')));
    expect(
        content.profiles['f089']!.clues
            .singleWhere((clue) => clue.source == ClueSource.goggles)
            .description,
        allOf(contains('selected all four secluded tree positions'),
            contains('public review')));
  });

  test('women case 9 stores complete clues and Clara stolen-future reveal', () {
    final profiles = content.profilesFor(content.levels['case_019']!);
    final expectedSources = ClueSource.values
        .where((source) => source != ClueSource.question)
        .toSet();

    for (final profile in profiles) {
      expect(profile.clues, hasLength(4), reason: profile.id);
      expect(profile.clues.map((clue) => clue.source).toSet(), expectedSources,
          reason: profile.id);
      expect(profile.redHerrings, hasLength(3), reason: profile.id);
      expect(profile.redHerrings.toSet(), hasLength(3), reason: profile.id);
      expect(profile.redHerrings.every((lead) => lead.length <= 48), isTrue,
          reason: profile.id);
      if (!profile.isKiller) {
        expect(
            profile.clues.where((clue) => clue.strength == ClueStrength.strong),
            isEmpty,
            reason: profile.id);
      }
    }

    final amina = content.profiles['f086']!;
    expect(amina.occupation, 'Tree nursery dispatcher');
    expect(
        amina.clues
            .singleWhere((clue) => clue.source == ClueSource.photo)
            .description,
        allOf(contains('both sides'), contains('reverse sides are blank')));

    final clara = content.profiles['f087']!;
    expect(clara.name, 'Clara Jost');
    expect(clara.occupation, 'Memory-care activity coordinator');
    expect(clara.redHerrings, <String>[
      'Tended all four burial trees for years',
      "Knew each man's private dream of home",
      'Claimed all four stolen futures as her own'
    ]);
    expect(
        clara.clues
            .singleWhere((clue) => clue.source == ClueSource.profile)
            .description,
        allOf(contains('watering, pruning, and frost protection'),
            contains('nineteen other trees')));
    final photoClue =
        clara.clues.singleWhere((clue) => clue.source == ClueSource.photo);
    expect(photoClue.strength, ClueStrength.medium);
    expect(
        photoClue.description,
        allOf(contains('public nursery-marker workshop'),
            contains('Forty-two volunteers')));
    final conversationClue = clara.clues
        .singleWhere((clue) => clue.source == ClueSource.conversation);
    expect(conversationClue.strength, ClueStrength.strong);
    expect(
        conversationClue.description,
        allOf(
            contains('Sunday noise in the kitchen'),
            contains('a blue front door'),
            contains('muddy paw prints'),
            contains('growing old without packing again'),
            contains('in disappearance order')));

    final finalStage = content.conversations['chat_f087']!.stages.last;
    expect(finalStage.suspectMessage,
        contains('What would make a future home feel unmistakably yours?'));
    for (final option in finalStage.responseOptions) {
      expect(option.suspectReply, contains('I envy'));
      expect(option.suspectReply, contains('Sunday noise'));
      expect(option.suspectReply, contains('an apple tree'));
      expect(option.suspectReply, contains('a blue front door'));
      expect(option.suspectReply, contains('muddy paw prints'));
      expect(option.suspectReply,
          contains('Somewhere permanent enough to grow old'));
    }
  });

  testWidgets('women case 9 evidence board shows Clara combined leads',
      (tester) async {
    final clara = content.profiles['f087']!;

    await tester.pumpWidget(MaterialApp(
      home: EvidenceBoardDialog(
        profiles: <Profile>[clara],
        completedProfileIds: <String>{clara.id},
      ),
    ));
    await tester.pump();

    expect(find.text('SUSPICIOUS LEAD'), findsNWidgets(3));
    expect(find.text('Tended all four burial trees for years'), findsOneWidget);
    expect(find.text("Knew each man's private dream of home"), findsOneWidget);
    expect(find.text('Claimed all four stolen futures as her own'),
        findsOneWidget);
  });

  test('women case 10 establishes the complete Madam Verdict finale', () {
    final level = content.levels['case_020']!;
    final profiles = content.profilesFor(level);

    expect(level.title, 'Madam Verdict');
    expect(level.difficulty, 'Very Hard');
    expect(level.gender, Gender.women);
    expect(
        level.profileIds,
        List.generate(
            10, (index) => 'f${(index + 91).toString().padLeft(3, '0')}'));
    expect(level.killerProfileId, 'f097');
    expect(profiles.where((profile) => profile.isKiller).single.id, 'f097');
    expect(level.caseDescription,
        startsWith('Five powerful men have been murdered'));
    expect(level.caseDescription, contains('Arno Feld'));
    expect(level.caseDescription, contains('Holger Venn'));
    expect(level.caseDescription, contains('Roman Dittmer'));
    expect(level.caseDescription, contains('Peter Kroll'));
    expect(level.caseDescription, contains('Volker Senn'));
    expect(level.caseDescription, contains('slow-acting heart poison'));
    expect(level.caseDescription, contains('VERDICT 01 through VERDICT 05'));
    expect(level.caseDescription,
        contains('anonymous account calling itself Madam Verdict'));
    expect(level.caseDescription,
        contains('The city turned the unknown killer into a sensation'));
    expect(
        level.caseDescription,
        contains(
            'each man had also confided in a different deleted dating account'));
    expect(level.caseDescription,
        contains('The fixer was the person waiting at the private meeting'));
    expect(
        level.caseDescription,
        contains(
            'Before disappearing, David left investigators enough of his findings'));
    expect(level.caseDescription,
        contains('Following that lead, they compared restored dating records'));
    expect(
        level.caseDescription, contains('narrowing the inquiry to ten women'));
    expect(level.caseDescription,
        isNot(contains('David recently told authorities')));
    expect(level.caseDescription, contains('VERDICT 06 for election night'));
    expect(level.caseDescription, contains('ethics commissioner David Kern'));
    expect(level.caseDescription, contains('The sixth dossier is a lie'));
    expect(level.caseDescription,
        contains('The sixth will silence an innocent one'));
    expect(level.caseDescription,
        endsWith('before murder becomes her path to power.'));
    expect(
        level.caseDescription, isNot(contains('The Witness in Every Photo')));
    expect(level.caseDescription, isNot(contains('\u2014')));
  });

  test('women case 10 profiles are distinct dates and remain case-unaware', () {
    final profiles = content.profilesFor(content.levels['case_020']!);
    final prompts = <String>[];
    final answers = <String>[];
    final caseAwareLanguage = RegExp(
      r'\b(arno|holger|roman|peter|volker|david|victim|killer|murder|police|evidence|investigat(?:e|ion|or)|verdict)\b',
      caseSensitive: false,
    );

    expect(profiles.map((profile) => profile.name).toSet(), hasLength(10));
    expect(profiles.map((profile) => profile.bio).toSet(), hasLength(10));
    expect(
        profiles.map((profile) => profile.description).toSet(), hasLength(10));
    expect(
        profiles.map((profile) => profile.occupation).toSet(), hasLength(10));
    expect(profiles.map((profile) => profile.interests.join('|')).toSet(),
        hasLength(10));
    expect(
        profiles.map((profile) => profile.lookingFor).toSet(), hasLength(10));

    for (final profile in profiles) {
      expect(profile.lookingFor, startsWith('A man who'), reason: profile.id);
      final publicText = <String>[
        profile.bio,
        profile.description,
        profile.intent,
        profile.lookingFor,
      ].join(' ');
      expect(publicText, isNot(matches(caseAwareLanguage)), reason: profile.id);
      expect(publicText, isNot(contains('\u2014')), reason: profile.id);
      expect(profile.questions, hasLength(2), reason: profile.id);
      for (final question in profile.questions) {
        prompts.add(question.question);
        answers.add(question.answer);
        expect(question.question, isNot(matches(caseAwareLanguage)),
            reason: profile.id);
        expect(question.answer, isNot(matches(caseAwareLanguage)),
            reason: profile.id);
        expect(question.question, isNot(contains('\u2014')),
            reason: profile.id);
        expect(question.answer, isNot(contains('\u2014')), reason: profile.id);
      }
    }

    expect(prompts.toSet(), hasLength(20));
    expect(answers.toSet(), hasLength(20));
  });

  test('women case 10 conversations sound like ten different possible dates',
      () {
    const transcriptAnchors = <String, String>{
      'f091': 'if a documented truth ruins a powerful man',
      'f092': 'Escaping punishment proves that a case failed',
      'f093': 'Security is mostly noticing the person',
      'f094': 'stopped believing every powerful man deserves advance warning',
      'f095': 'With the right spreadsheet, I can end a career',
      'f096': 'Give me the right document and I can end a career',
      'f097': 'escaped a reception with two bread rolls',
      'f098': 'privacy begins with a closed door',
      'f099': 'buried records always return',
      'f100': 'public shame can be a civic service',
    };
    final caseAwareLanguage = RegExp(
      r'\b(arno|holger|roman|peter|volker|david|victim|killer|murder|police|evidence|investigat(?:e|ion|or)|madam verdict)\b',
      caseSensitive: false,
    );
    final openingMessages = <String>{};

    for (final entry in transcriptAnchors.entries) {
      final conversation = content.conversations['chat_${entry.key}']!;
      expect(conversation.stages, hasLength(3), reason: entry.key);
      openingMessages.add(conversation.stages.first.suspectMessage);
      for (final stage in conversation.stages) {
        expect(stage.responseOptions, hasLength(2), reason: stage.id);
      }
      final transcript = conversation.stages.expand((stage) sync* {
        yield stage.suspectMessage;
        for (final option in stage.responseOptions) {
          yield option.playerText;
          yield option.suspectReply;
        }
      }).join(' ');
      expect(transcript, contains(entry.value), reason: entry.key);
      expect(transcript, isNot(matches(caseAwareLanguage)), reason: entry.key);
      expect(transcript, isNot(contains('\u2014')), reason: entry.key);
    }

    expect(openingMessages, hasLength(10));
  });

  test('women case 10 creates a fair all-Medium initial shortlist', () {
    final profiles = content.profilesFor(content.levels['case_020']!);

    for (final profile in profiles) {
      final goggles = profile.clues
          .singleWhere((clue) => clue.source == ClueSource.goggles);
      expect(goggles.strength, ClueStrength.medium, reason: profile.id);
    }

    expect(
        content.profiles['f091']!.clues
            .singleWhere((clue) => clue.source == ClueSource.goggles)
            .description,
        allOf(contains('all five murdered men'),
            contains('months before the first death')));
    expect(
        content.profiles['f095']!.clues
            .singleWhere((clue) => clue.source == ClueSource.goggles)
            .description,
        allOf(contains('all five releases'),
            contains('Sixty-eight political, media, and nonprofit')));
    expect(
        content.profiles['f097']!.clues
            .singleWhere((clue) => clue.source == ClueSource.goggles)
            .description,
        allOf(contains('five twenty-minute appointments'),
            contains('Three staff accounts')));
    expect(
        content.profiles['f099']!.clues
            .singleWhere((clue) => clue.source == ClueSource.goggles)
            .description,
        allOf(contains('all five confidential files'),
            contains('six months before the first death')));
    expect(
        content.profiles['f100']!.clues
            .singleWhere((clue) => clue.source == ClueSource.goggles)
            .description,
        allOf(contains('twelve to seventeen minutes'),
            contains('four other media accounts')));
  });

  test('women case 10 stores complete clues and Sabine final reveal', () {
    final profiles = content.profilesFor(content.levels['case_020']!);
    final expectedSources = ClueSource.values
        .where((source) => source != ClueSource.question)
        .toSet();

    for (final profile in profiles) {
      expect(profile.clues, hasLength(4), reason: profile.id);
      expect(profile.clues.map((clue) => clue.source).toSet(), expectedSources,
          reason: profile.id);
      expect(profile.redHerrings, hasLength(3), reason: profile.id);
      expect(profile.redHerrings.toSet(), hasLength(3), reason: profile.id);
      expect(profile.redHerrings.every((lead) => lead.length <= 48), isTrue,
          reason: profile.id);
      if (!profile.isKiller) {
        expect(
            profile.clues.where((clue) => clue.strength == ClueStrength.strong),
            isEmpty,
            reason: profile.id);
      }
    }

    final sabine = content.profiles['f097']!;
    expect(sabine.name, 'Sabine Voss');
    expect(sabine.occupation, 'Deputy mayor and coalition negotiator');
    expect(sabine.redHerrings, <String>[
      'Five private meetings vanished from her calendar',
      'All verdict files passed through her office',
      'Quoted the unpublished sixth verdict'
    ]);
    expect(
        sabine.clues
            .singleWhere((clue) => clue.source == ClueSource.profile)
            .description,
        allOf(contains('All five buried ethics complaints'),
            contains('Twenty-three staff and elected officials')));
    expect(
        sabine.clues
            .singleWhere((clue) => clue.source == ClueSource.photo)
            .description,
        allOf(contains('same restricted municipal media workstation'),
            contains('twelve-person communications team')));
    final conversationClue = sabine.clues
        .singleWhere((clue) => clue.source == ClueSource.conversation);
    expect(conversationClue.strength, ClueStrength.strong);
    expect(
        conversationClue.description,
        allOf(
            contains('A clean suit is not the same as clean hands'),
            contains('encrypted draft of VERDICT 06'),
            contains('never published')));

    final finalStage = content.conversations['chat_f097']!.stages.last;
    expect(finalStage.suspectMessage,
        contains('What makes you lose respect for someone'));
    for (final option in finalStage.responseOptions) {
      expect(option.suspectReply,
          contains('a clean suit is not the same as clean hands'));
    }
  });

  testWidgets('women case 10 evidence board shows Sabine combined leads',
      (tester) async {
    final sabine = content.profiles['f097']!;

    await tester.pumpWidget(MaterialApp(
      home: EvidenceBoardDialog(
        profiles: <Profile>[sabine],
        completedProfileIds: <String>{sabine.id},
      ),
    ));
    await tester.pump();

    expect(find.text('SUSPICIOUS LEAD'), findsNWidgets(3));
    expect(find.text('Five private meetings vanished from her calendar'),
        findsOneWidget);
    expect(find.text('All verdict files passed through her office'),
        findsOneWidget);
    expect(find.text('Quoted the unpublished sixth verdict'), findsOneWidget);
  });
  test('Women cases contain ten profiles and unlock in sequence', () {
    final firstCase = content.levels['case_011']!;
    final secondCase = content.levels['case_012']!;
    expect(firstCase.gender, Gender.women);
    expect(firstCase.profileIds, hasLength(10));
    expect(secondCase.gender, Gender.women);
    expect(secondCase.profileIds, hasLength(10));
    expect(firstCase.killerProfileId, 'f007');
    expect(secondCase.killerProfileId, 'f017');
    expect(game.unlockedLevelIds, contains('case_011'));
    expect(game.unlockedLevelIds, isNot(contains('case_012')));
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
    expect(game.currentLevelId, 'case_005');
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

  test(
      'profile review can return to the previous profile without leaving the case',
      () {
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

  test(
      'profile browsing selects three without rejecting the remaining profiles',
      () {
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
    expect(game.selectedSuspects,
        [secondProfileId, thirdProfileId, firstProfileId]);
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

  test('legacy interleaved case IDs migrate without losing progress', () async {
    final legacyProfileOrder = List.generate(
        10, (index) => 'm${(index + 81).toString().padLeft(3, '0')}');
    final legacySave = <String, dynamic>{
      'phase': 'briefing',
      'investigationGender': 'men',
      'currentLevelId': 'case_011',
      'currentProfileIndex': 0,
      'profileOrderByLevel': {'case_011': legacyProfileOrder},
      'reviewedProfileIds': <String>[],
      'rejectedProfileIds': <String>[],
      'selectedSuspectIds': <String>[],
      'gogglesViewedProfileIds': <String>[],
      'conversationStageIndexes': <String, int>{},
      'conversationHistory': <String, dynamic>{},
      'completedConversationIds': <String>[],
      'completedLevelIds': ['case_003', 'case_005', 'case_010'],
      'unlockedLevelIds': [
        'case_001',
        'case_003',
        'case_005',
        'case_010',
        'case_011',
      ],
      'selectedAccusationId': null,
      'musicVolume': 0.7,
      'effectsVolume': 0.85,
    };
    SharedPreferences.setMockInitialValues({
      'game_save': jsonEncode(legacySave),
    });
    final preferences = await SharedPreferences.getInstance();
    final restored = GameController(content: content, preferences: preferences);

    await restored.restore();

    expect(restored.currentLevelId, 'case_009');
    expect(restored.currentLevel.title, 'The Night Archive');
    expect(restored.currentProfiles.map((profile) => profile.id),
        legacyProfileOrder);
    expect(restored.completedLevelIds,
        containsAll(<String>['case_011', 'case_003', 'case_008']));
    expect(
        restored.unlockedLevelIds,
        containsAll(<String>[
          'case_001',
          'case_011',
          'case_003',
          'case_008',
          'case_009'
        ]));
    final migratedSave = decodeMap(preferences.getString('game_save')!);
    expect(migratedSave['caseIdSchemeVersion'], 2);
    expect(migratedSave['currentLevelId'], 'case_009');
    expect((migratedSave['profileOrderByLevel'] as Map).keys,
        contains('case_009'));
  });
  test('saved progress restores as a playable state', () async {
    game.chooseGender(Gender.men);
    game.beginCase();
    final selectedId = game.activeProfile.id;
    game.processCurrentProfile(investigate: true);
    final restored = GameController(
        content: content, preferences: await SharedPreferences.getInstance());
    await restored.restore();
    expect(restored.investigationGender, Gender.men);
    expect(restored.reviewedProfileIds, contains(selectedId));
    expect(restored.selectedSuspects, contains(selectedId));
    expect(restored.currentProfiles.map((profile) => profile.id),
        game.currentProfiles.map((profile) => profile.id));
    expect(restored.phase, GamePhase.profileReview);
  });

  test('a fresh app launch opens the menu without losing case progress',
      () async {
    game.chooseGender(Gender.men);
    game.beginCase();
    final selectedId = game.activeProfile.id;
    game.processCurrentProfile(investigate: true);
    await game.flushPendingWrites();

    final preferences = await SharedPreferences.getInstance();
    final restored = GameController(content: content, preferences: preferences);
    await restored.restore(openMainMenu: true);

    expect(restored.phase, GamePhase.mainMenu);
    expect(restored.currentLevelId, game.currentLevelId);
    expect(restored.selectedSuspects, contains(selectedId));
    expect(decodeMap(preferences.getString('game_save')!)['phase'], 'mainMenu');
    expect(restored.canContinue, isTrue);
  });

  test('investigation report metrics track and restore Goggles scans',
      () async {
    game.chooseGender(Gender.men);
    game.beginCase();
    final firstProfileId = game.activeProfile.id;
    game.recordGogglesScan(firstProfileId);
    game.recordGogglesScan(firstProfileId);

    expect(game.gogglesScansViewed, 1);
    expect(game.investigationTime, matches(RegExp(r'^\d{2}:\d{2}$')));

    final restored = GameController(
        content: content, preferences: await SharedPreferences.getInstance());
    await restored.restore();
    expect(restored.gogglesViewedProfileIds, contains(firstProfileId));
    expect(restored.gogglesScansViewed, 1);
  });

  test('detective ranks include failed and full-scan C rank', () {
    game.chooseGender(Gender.men);
    game.beginCase();

    expect(game.detectiveRank(won: false), 'FAILED');
    expect(game.detectiveTagline(won: false),
        'The case remains open. The truth is still out there.');

    for (final profile in game.currentProfiles) {
      game.recordGogglesScan(profile.id);
    }

    expect(game.gogglesScansViewed, game.currentProfiles.length);
    expect(game.detectiveRank(won: true), 'C');
    expect(game.detectiveTagline(won: true),
        'You used every lead—and still found the truth.');
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

  test(
      'profile order is randomized for a retry and preserved in saved progress',
      () async {
    game.chooseGender(Gender.men);
    game.beginCase();
    final firstOrder =
        game.currentProfiles.map((profile) => profile.id).toList();
    final restored = GameController(
        content: content, preferences: await SharedPreferences.getInstance());
    await restored.restore();
    expect(restored.currentProfiles.map((profile) => profile.id), firstOrder);

    game.retryCase();
    final retryOrder =
        game.currentProfiles.map((profile) => profile.id).toList();
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

  testWidgets('chat auto-scrolls after every non-final suspect reply',
      (tester) async {
    tester.view.physicalSize = const Size(430, 620);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const profileId = 'm001';
    final conversation = game.conversationFor(profileId);
    await tester.pumpWidget(GameScope(
      controller: game,
      child: const MaterialApp(home: ChatScreen(profileId: profileId)),
    ));
    await tester.pumpAndSettle();

    for (var stageIndex = 0; stageIndex < 2; stageIndex++) {
      final option = conversation.stages[stageIndex].responseOptions.first;
      game.chooseResponse(profileId, option.id);
      await tester.pumpAndSettle();

      expect(game.isConversationComplete(profileId), isFalse);
      final scrollable = find.descendant(
        of: find.byType(ListView),
        matching: find.byType(Scrollable),
      );
      final position = tester.state<ScrollableState>(scrollable).position;
      expect(position.maxScrollExtent, greaterThan(0));

      final listBounds = tester.getRect(find.byType(ListView));
      final replyBounds = tester.getRect(find.text(option.suspectReply));
      expect(replyBounds.top, greaterThanOrEqualTo(listBounds.top));
      expect(replyBounds.bottom, lessThanOrEqualTo(listBounds.bottom));
    }
  });

  test('accusation correctness and progression are state-driven', () async {
    game.chooseGender(Gender.men);
    game.beginCase();
    final killerId = game.currentLevel.killerProfileId;
    final otherIds = game.currentProfiles
        .where((profile) => profile.id != killerId)
        .take(2)
        .map((profile) => profile.id);
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
    final completedTime = game.investigationTime;
    await Future<void>.delayed(const Duration(seconds: 1));
    game.returnToMainMenu();
    expect(game.investigationTime, completedTime);
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

  test('content enum parsing rejects unknown values', () {
    expect(() => genderFromJson('unknown'), throwsFormatException);
    expect(() => clueSourceFromJson('unknown'), throwsFormatException);
    expect(() => clueStrengthFromJson('unknown'), throwsFormatException);
  });

  test('returning to the main menu persists the latest phase', () async {
    game.chooseGender(Gender.men);
    game.beginCase();
    game.goToNextProfile();
    game.returnToMainMenu();
    await game.flushPendingWrites();

    final restored = GameController(
        content: content, preferences: await SharedPreferences.getInstance());
    await restored.restore();

    expect(restored.phase, GamePhase.mainMenu);
    expect(restored.currentProfileIndex, 1);
    expect(restored.canContinue, isTrue);
  });

  test('dedicated audio settings override stale values in an old game save',
      () async {
    game.chooseGender(Gender.men);
    await game.flushPendingWrites();
    game.setMusicVolume(.25);
    game.setEffectsVolume(.4);
    await game.flushPendingWrites();

    final preferences = await SharedPreferences.getInstance();
    final oldSave = decodeMap(preferences.getString('game_save')!)
      ..['musicVolume'] = .9
      ..['effectsVolume'] = .95;
    await preferences.setString('game_save', jsonEncode(oldSave));
    final audio = _RecordingAudioService();
    final restored = GameController(
        content: content, preferences: preferences, audioService: audio);

    await restored.restore();

    expect(restored.musicVolume, .25);
    expect(restored.effectsVolume, .4);
    expect(audio.musicVolume, .25);
    expect(audio.effectsVolume, .4);
    expect(restored.toSaveJson(), isNot(contains('musicVolume')));
    expect(restored.toSaveJson(), isNot(contains('effectsVolume')));
  });

  testWidgets('inbox shows the current conversation stage', (tester) async {
    const profileId = 'm001';
    game.selectedSuspectIds.add(profileId);
    game.conversationStageIndexes[profileId] = 1;

    await tester.pumpWidget(GameScope(
      controller: game,
      child: const MaterialApp(home: InboxScreen()),
    ));

    expect(find.text('Reply waiting · stage 2 of 3'), findsOneWidget);
  });

  testWidgets('splash screen fits a compact phone without overflow',
      (tester) async {
    tester.view.physicalSize = const Size(320, 420);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: SplashScreen()));
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
  });

  testWidgets('dismissed result animation keeps opacity values valid',
      (tester) async {
    await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: CaseDismissedScene())));
    await tester.pump(const Duration(seconds: 3));
    expect(find.byType(CaseDismissedScene), findsOneWidget);
  });

  testWidgets('closed result animation keeps opacity values valid',
      (tester) async {
    await tester
        .pumpWidget(const MaterialApp(home: Scaffold(body: CaseClosedScene())));
    await tester.pump(const Duration(seconds: 3));
    expect(find.byType(CaseClosedScene), findsOneWidget);
  });
}

extension on GameController {
  List<String> get selectedSuspects => selectedSuspectIds;
}

class _RecordingAudioService implements AudioService {
  double? musicVolume;
  double? effectsVolume;

  @override
  Future<void> playEffect(String assetPath) async {}

  @override
  Future<void> playMusic(String assetPath) async {}

  @override
  void setEffectsVolume(double value) => effectsVolume = value;

  @override
  void setMusicVolume(double value) => musicVolume = value;

  @override
  Future<void> stopMusic() async {}
}
