import 'dart:convert';

enum Gender { men, women }
enum ClueSource { profile, photo, question, goggles, conversation }
enum ClueStrength { weak, medium, strong }
enum GamePhase { mainMenu, genderSelection, briefing, profileReview, messaging, finalAccusation, levelWon, levelFailed }

Gender genderFromJson(String value) => value == 'women' ? Gender.women : Gender.men;
ClueSource clueSourceFromJson(String value) => ClueSource.values.firstWhere((e) => e.name == value.toLowerCase(), orElse: () => ClueSource.profile);
ClueStrength clueStrengthFromJson(String value) => ClueStrength.values.firstWhere((e) => e.name == value.toLowerCase(), orElse: () => ClueStrength.weak);

class ProfileQuestion {
  const ProfileQuestion({required this.question, required this.answer});
  final String question;
  final String answer;
  factory ProfileQuestion.fromJson(Map<String, dynamic> json) => ProfileQuestion(question: json['question'] as String, answer: json['answer'] as String);
}

class GogglesData {
  const GogglesData({required this.activeConnections, required this.inactiveFormerConnections, required this.lastActive, this.extra = const {}});
  final int activeConnections;
  final int inactiveFormerConnections;
  final String lastActive;
  final Map<String, dynamic> extra;
  factory GogglesData.fromJson(Map<String, dynamic> json) => GogglesData(
    activeConnections: json['activeConnections'] as int,
    inactiveFormerConnections: json['inactiveFormerConnections'] as int,
    lastActive: json['lastActive'] as String? ?? 'Unknown',
    extra: Map<String, dynamic>.from(json)..removeWhere((key, _) => {'activeConnections', 'inactiveFormerConnections', 'lastActive'}.contains(key)),
  );
}

class ClueDefinition {
  const ClueDefinition({required this.id, required this.source, required this.strength, required this.description, required this.relatedClueIds, required this.developerExplanation});
  final String id;
  final ClueSource source;
  final ClueStrength strength;
  final String description;
  final List<String> relatedClueIds;
  final String developerExplanation;
  factory ClueDefinition.fromJson(Map<String, dynamic> json) => ClueDefinition(
    id: json['id'] as String,
    source: clueSourceFromJson(json['source'] as String),
    strength: clueStrengthFromJson(json['strength'] as String),
    description: json['description'] as String,
    relatedClueIds: List<String>.from(json['relatedClueIds'] as List? ?? const []),
    developerExplanation: json['developerExplanation'] as String,
  );
}

class Profile {
  const Profile({required this.id, required this.levelId, required this.gender, required this.name, required this.age, required this.location, required this.occupation, required this.bio, required this.description, required this.intent, required this.interests, required this.photos, required this.questions, required this.gogglesData, required this.conversationId, required this.isKiller, required this.clues, required this.redHerrings});
  final String id;
  final String levelId;
  final Gender gender;
  final String name;
  final int age;
  final String location;
  final String occupation;
  final String bio;
  final String description;
  final String intent;
  final List<String> interests;
  final List<String> photos;
  final List<ProfileQuestion> questions;
  final GogglesData gogglesData;
  final String conversationId;
  final bool isKiller;
  final List<ClueDefinition> clues;
  final List<String> redHerrings;
  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
    id: json['id'] as String,
    levelId: json['levelId'] as String,
    gender: genderFromJson(json['gender'] as String),
    name: json['name'] as String,
    age: json['age'] as int,
    location: json['location'] as String,
    occupation: json['occupation'] as String,
    bio: json['bio'] as String,
    description: json['description'] as String,
    intent: json['intent'] as String,
    interests: List<String>.from(json['interests'] as List),
    photos: List<String>.from(json['photos'] as List),
    questions: (json['questions'] as List? ?? const []).map((e) => ProfileQuestion.fromJson(Map<String, dynamic>.from(e as Map))).toList(growable: false),
    gogglesData: GogglesData.fromJson(Map<String, dynamic>.from(json['gogglesData'] as Map)),
    conversationId: json['conversationId'] as String,
    isKiller: json['isKiller'] as bool? ?? false,
    clues: (json['clues'] as List? ?? const []).map((e) => ClueDefinition.fromJson(Map<String, dynamic>.from(e as Map))).toList(growable: false),
    redHerrings: List<String>.from(json['redHerrings'] as List? ?? const []),
  );
}

class Level {
  const Level({required this.id, required this.gender, required this.title, required this.difficulty, required this.profileIds, required this.killerProfileId, required this.caseDescription});
  final String id;
  final Gender gender;
  final String title;
  final String difficulty;
  final List<String> profileIds;
  final String killerProfileId;
  final String caseDescription;
  factory Level.fromJson(Map<String, dynamic> json) => Level(
    id: json['id'] as String,
    gender: genderFromJson(json['gender'] as String),
    title: json['title'] as String,
    difficulty: json['difficulty'] as String,
    profileIds: List<String>.from(json['profileIds'] as List),
    killerProfileId: json['killerProfileId'] as String,
    caseDescription: json['caseDescription'] as String? ?? '',
  );
}

class ResponseOption {
  const ResponseOption({required this.id, required this.playerText, required this.suspectReply, this.nextStageId, this.optionalClueId});
  final String id;
  final String playerText;
  final String suspectReply;
  final String? nextStageId;
  final String? optionalClueId;
  factory ResponseOption.fromJson(Map<String, dynamic> json) => ResponseOption(id: json['id'] as String, playerText: json['playerText'] as String, suspectReply: json['suspectReply'] as String, nextStageId: json['nextStageId'] as String?, optionalClueId: json['optionalClueId'] as String?);
}

class ConversationStage {
  const ConversationStage({required this.id, required this.suspectMessage, required this.responseOptions});
  final String id;
  final String suspectMessage;
  final List<ResponseOption> responseOptions;
  factory ConversationStage.fromJson(Map<String, dynamic> json) => ConversationStage(id: json['id'] as String, suspectMessage: json['suspectMessage'] as String, responseOptions: (json['responseOptions'] as List).map((e) => ResponseOption.fromJson(Map<String, dynamic>.from(e as Map))).toList(growable: false));
}

class Conversation {
  const Conversation({required this.id, required this.stages});
  final String id;
  final List<ConversationStage> stages;
  factory Conversation.fromJson(String id, Map<String, dynamic> json) => Conversation(id: id, stages: (json['stages'] as List).map((e) => ConversationStage.fromJson(Map<String, dynamic>.from(e as Map))).toList(growable: false));
}

class ChatEntry {
  const ChatEntry({required this.isPlayer, required this.text});
  final bool isPlayer;
  final String text;
  Map<String, dynamic> toJson() => {'isPlayer': isPlayer, 'text': text};
  factory ChatEntry.fromJson(Map<String, dynamic> json) => ChatEntry(isPlayer: json['isPlayer'] as bool, text: json['text'] as String);
}

Map<String, dynamic> decodeMap(String value) => Map<String, dynamic>.from(jsonDecode(value) as Map);

