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
    final content = GameContent(
      profiles: {for (final profile in profileModels) profile.id: profile},
      levels: {for (final level in levelModels) level.id: level},
      conversations: {for (final entry in conversationsJson.entries) entry.key as String: Conversation.fromJson(entry.key as String, Map<String, dynamic>.from(entry.value as Map))},
    );
    final errors = ContentValidator().validate(content);
    assert(errors.isEmpty, 'Content validation failed:\n${errors.join('\n')}');
    return content;
  }
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
