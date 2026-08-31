import 'dart:convert';
import 'package:flutter/services.dart';
import 'models.dart';

class GameContent {
  const GameContent({required this.profiles, required this.levels, required this.conversations});
  final Map<String, Profile> profiles;
  final Map<String, Level> levels;
  final Map<String, Conversation> conversations;

  List<Profile> profilesFor(Level level) => level.profileIds.map((id) => profiles[id]!).toList(growable: false);
}

class ContentRepository {
  const ContentRepository();

  Future<GameContent> load() async {
    final profilesJson = jsonDecode(await rootBundle.loadString('assets/data/profiles.json')) as List;
    final levelsJson = jsonDecode(await rootBundle.loadString('assets/data/levels.json')) as List;
    final conversationsJson = jsonDecode(await rootBundle.loadString('assets/data/conversations.json')) as Map;
    final profileModels = profilesJson.map((item) => Profile.fromJson(Map<String, dynamic>.from(item as Map))).toList(growable: false);
    final levelModels = levelsJson.map((item) => Level.fromJson(Map<String, dynamic>.from(item as Map))).toList(growable: false);
    if (profileModels.map((profile) => profile.id).toSet().length != profileModels.length) throw const FormatException('Content validation failed: profile IDs must be unique.');
    if (levelModels.map((level) => level.id).toSet().length != levelModels.length) throw const FormatException('Content validation failed: level IDs must be unique.');
    final conversationModels = {
      for (final entry in conversationsJson.entries) entry.key as String: Conversation.fromJson(entry.key as String, Map<String, dynamic>.from(entry.value as Map)),
    };
    for (final profile in profileModels) {
      conversationModels.putIfAbsent(profile.conversationId, () => _generatedConversation(profile));
    }
    final content = GameContent(
      profiles: {for (final profile in profileModels) profile.id: profile},
      levels: {for (final level in levelModels) level.id: level},
      conversations: conversationModels,
    );
    final errors = ContentValidator().validate(content);
    assert(errors.isEmpty, 'Content validation failed:\n${errors.join('\n')}');
    return content;
  }
}

Conversation _generatedConversation(Profile profile) {
  const prompts = {
    'case_005': ['Which song would you keep after a difficult day?', 'When does a playlist become private?', 'What makes a memory attached to music trustworthy?'],
    'case_006': ['How do you find your way through a crowded station?', 'What should a useful travel record contain?', 'What makes an absence noticeable?'],
    'case_007': ['What do you notice in a greenhouse?', 'How much can weather explain about a day?', 'What makes a photograph honest?'],
    'case_008': ['What makes a weekend trip worth taking?', 'How much of a plan should you share?', 'When does borrowing an idea become suspicious?'],
    'case_009': ['What makes a route worth remembering?', 'What should happen at a checkpoint?', 'When does a missing message matter?'],
    'case_010': ['What makes an emergency believable?', 'How quickly should someone act on a warning?', 'What makes a witness trustworthy?'],
    'case_011': ['What should an old case file preserve?', 'How do you know a pattern is real?', 'What detail would you never leave out?'],
    'case_012': ['What makes a witness convincing?', 'How should a person handle an uncertain memory?', 'What makes a perfect story suspicious?'],
    'case_013': ['What makes a place feel safe after dark?', 'Why might someone ignore a message at sunset?', 'What detail would you remember from a riverside walk?'],
    'case_014': ['What makes an invitation feel personal?', 'When should an unfamiliar address raise questions?', 'What makes a handwriting or message memorable?'],
    'case_015': ['What makes a voice reassuring?', 'How can a person borrow someone else’s identity?', 'Which small phrase can expose a copied story?'],
    'case_016': ['What makes a journey feel final?', 'How much can weather change a travel plan?', 'What would prove someone was on the last ferry?'],
    'case_017': ['What makes an alibi strong?', 'How do repeated details change a story?', 'What can a quiet place hide from a timeline?'],
    'case_018': ['What does an unsent message suggest?', 'When does privacy become concealment?', 'How can timing reveal who sent an invitation?'],
    'case_019': ['What makes a physical clue useful?', 'How can a common object still form a pattern?', 'What does a person reveal by denying a place too quickly?'],
    'case_020': ['What can a reflection reveal?', 'How do you test whether photographs share a witness?', 'What makes an omission more suspicious than a lie?'],
  };
  final questions = prompts[profile.levelId] ?? const ['What brought you here?', 'What do people misunderstand about you?', 'What makes a story trustworthy?'];
  final id = profile.conversationId;
  return Conversation(id: id, stages: [
    ConversationStage(id: '${id}_s1', suspectMessage: questions[0], responseOptions: [
      ResponseOption(id: 'a', playerText: 'I look for the details people usually skip.', suspectReply: 'That can reveal more than a polished answer.', nextStageId: '${id}_s2'),
      ResponseOption(id: 'b', playerText: 'I prefer to hear the simple version first.', suspectReply: 'Simple versions are useful, if they hold up later.', nextStageId: '${id}_s2'),
    ]),
    ConversationStage(id: '${id}_s2', suspectMessage: questions[1], responseOptions: [
      ResponseOption(id: 'a', playerText: 'I would compare it with what happened before.', suspectReply: 'Patterns are helpful, but they can also mislead.', nextStageId: '${id}_s3'),
      ResponseOption(id: 'b', playerText: 'I would ask what is missing from the account.', suspectReply: 'The missing part is often the most interesting one.', nextStageId: '${id}_s3'),
    ]),
    ConversationStage(id: '${id}_s3', suspectMessage: questions[2], responseOptions: [
      const ResponseOption(id: 'a', playerText: 'It stays consistent when the details are checked.', suspectReply: 'Consistency is harder than confidence.', nextStageId: null),
      const ResponseOption(id: 'b', playerText: 'It admits what the speaker does not know.', suspectReply: 'That is a rare kind of honesty.', nextStageId: null),
    ]),
  ]);
}

class ContentValidator {
  List<String> validate(GameContent content) {
    final errors = <String>[];
    if (content.profiles.isEmpty) errors.add('Content must contain at least one profile.');
    if (content.levels.isEmpty) errors.add('Content must contain at least one level.');
    if (content.conversations.isEmpty) errors.add('Content must contain at least one conversation.');
    final seenProfileIds = <String>{};
    for (final profile in content.profiles.values) {
      if (!seenProfileIds.add(profile.id)) errors.add('Duplicate profile id: ${profile.id}');
      if (profile.age < 18) errors.add('Profile ${profile.id} must be 18 or older.');
      if (profile.photos.isEmpty) errors.add('Profile ${profile.id} needs at least one photo reference.');
      if (!content.conversations.containsKey(profile.conversationId)) errors.add('Profile ${profile.id} references missing conversation ${profile.conversationId}.');
      final clueIds = profile.clues.map((clue) => clue.id).toSet();
      if (clueIds.length != profile.clues.length) errors.add('Profile ${profile.id} contains duplicate clue ids.');
      for (final clue in profile.clues) {
        for (final related in clue.relatedClueIds) {
          if (!clueIds.contains(related)) errors.add('Clue ${clue.id} references missing related clue $related on ${profile.id}.');
        }
      }
    }
    for (final level in content.levels.values) {
      if (level.profileIds.length != 10) errors.add('Level ${level.id} must contain exactly 10 profiles.');
      if (level.caseDescription.trim().isEmpty) errors.add('Level ${level.id} must include a case description.');
      if (level.profileIds.toSet().length != level.profileIds.length) errors.add('Level ${level.id} contains duplicate profile ids.');
      final levelProfiles = <Profile>[];
      for (final id in level.profileIds) {
        final profile = content.profiles[id];
        if (profile == null) {
          errors.add('Level ${level.id} references missing profile $id.');
        } else {
          levelProfiles.add(profile);
          if (profile.levelId != level.id) errors.add('Profile $id has the wrong levelId.');
        }
      }
      final killerCount = levelProfiles.where((profile) => profile.isKiller).length;
      if (killerCount != 1) errors.add('Level ${level.id} must contain exactly one killer, found $killerCount.');
      if (!level.profileIds.contains(level.killerProfileId)) errors.add('Level ${level.id} killer is not in its profile list.');
      if (content.profiles[level.killerProfileId]?.isKiller != true) errors.add('Level ${level.id} killerProfileId does not identify the killer profile.');
    }
    for (final conversation in content.conversations.values) {
      if (conversation.stages.length != 3) errors.add('Conversation ${conversation.id} must contain exactly 3 stages.');
      final stageIds = conversation.stages.map((stage) => stage.id).toSet();
      if (stageIds.length != conversation.stages.length) errors.add('Conversation ${conversation.id} has duplicate stage ids.');
      final stagesById = {for (final stage in conversation.stages) stage.id: stage};
      for (final stage in conversation.stages) {
        if (stage.responseOptions.length != 2) errors.add('Stage ${stage.id} must have exactly two response options.');
        for (final option in stage.responseOptions) {
          if (option.nextStageId != null && !stageIds.contains(option.nextStageId)) errors.add('Option ${option.id} in ${stage.id} references missing stage ${option.nextStageId}.');
          if (stage == conversation.stages.last && option.nextStageId != null) errors.add('Final stage ${stage.id} must terminate.');
        }
      }
      bool reachesTermination(String stageId, Set<String> visiting) {
        if (!visiting.add(stageId)) return false;
        final stage = stagesById[stageId];
        if (stage == null) return false;
        for (final option in stage.responseOptions) {
          if (option.nextStageId != null && !reachesTermination(option.nextStageId!, {...visiting})) return false;
        }
        return true;
      }
      if (conversation.stages.isNotEmpty && !reachesTermination(conversation.stages.first.id, {})) errors.add('Conversation ${conversation.id} contains a non-terminating branch.');
    }
    return errors;
  }
}
