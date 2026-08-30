import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data.dart';
import 'models.dart';

class GameController extends ChangeNotifier {
  GameController({required this.content, required this.preferences});
  final GameContent content;
  final SharedPreferences preferences;

  GamePhase phase = GamePhase.mainMenu;
  Gender? investigationGender;
  String currentLevelId = 'case_001';
  int currentProfileIndex = 0;
  final Set<String> reviewedProfileIds = {};
  final Set<String> rejectedProfileIds = {};
  final List<String> selectedSuspectIds = [];
  final Map<String, int> conversationStageIndexes = {};
  final Map<String, List<ChatEntry>> conversationHistory = {};
  final Set<String> completedConversationIds = {};
  final Set<String> completedLevelIds = {};
  final Set<String> unlockedLevelIds = {'case_001'};
  String? selectedAccusationId;
  double musicVolume = 0.70;
  double effectsVolume = 0.85;

  Level get currentLevel => content.levels[currentLevelId]!;
  List<Profile> get currentProfiles => content.profilesFor(currentLevel);
  Profile get activeProfile => currentProfiles[currentProfileIndex];
  int get selectedCount => selectedSuspectIds.length;
  bool get canContinue => preferences.containsKey('game_save') && investigationGender != null && !(completedLevelIds.contains(currentLevelId) && allProfilesReviewed && allConversationsCompleted);
  bool get allProfilesReviewed => reviewedProfileIds.length == currentProfiles.length;
  bool get allConversationsCompleted => selectedSuspectIds.every(completedConversationIds.contains);
  Profile profileById(String id) => content.profiles[id]!;
  Conversation conversationFor(String profileId) => content.conversations[profileById(profileId).conversationId]!;
  int stageIndexFor(String profileId) => conversationStageIndexes[profileId] ?? 0;
  bool isConversationComplete(String profileId) => completedConversationIds.contains(profileId);

  Future<void> restore() async {
    musicVolume = (preferences.getDouble('settings_music') ?? musicVolume).clamp(0, 1).toDouble();
    effectsVolume = (preferences.getDouble('settings_effects') ?? effectsVolume).clamp(0, 1).toDouble();
    final raw = preferences.getString('game_save');
    if (raw == null) return;
    try {
      final data = decodeMap(raw);
      final phaseName = data['phase'] as String?;
      phase = GamePhase.values.firstWhere((value) => value.name == phaseName);
      final genderName = data['investigationGender'] as String?;
      investigationGender = genderName == null ? null : Gender.values.firstWhere((value) => value.name == genderName);
      currentLevelId = data['currentLevelId'] as String? ?? 'case_001';
      if (!content.levels.containsKey(currentLevelId)) throw const FormatException('Unknown level');
      currentProfileIndex = (data['currentProfileIndex'] as int? ?? 0).clamp(0, currentProfiles.length - 1).toInt();
      reviewedProfileIds.addAll(List<String>.from(data['reviewedProfileIds'] as List? ?? const []));
      rejectedProfileIds.addAll(List<String>.from(data['rejectedProfileIds'] as List? ?? const []));
      selectedSuspectIds.addAll(List<String>.from(data['selectedSuspectIds'] as List? ?? const []));
      completedLevelIds.addAll(List<String>.from(data['completedLevelIds'] as List? ?? const []));
      unlockedLevelIds.addAll(List<String>.from(data['unlockedLevelIds'] as List? ?? const []));
      final stages = Map<String, dynamic>.from(data['conversationStageIndexes'] as Map? ?? const {});
      stages.forEach((key, value) => conversationStageIndexes[key] = value as int);
      final histories = Map<String, dynamic>.from(data['conversationHistory'] as Map? ?? const {});
      histories.forEach((key, value) => conversationHistory[key] = (value as List).map((entry) => ChatEntry.fromJson(Map<String, dynamic>.from(entry as Map))).toList());
      completedConversationIds.addAll(List<String>.from(data['completedConversationIds'] as List? ?? const []));
      selectedAccusationId = data['selectedAccusationId'] as String?;
      musicVolume = ((data['musicVolume'] as num?)?.toDouble() ?? musicVolume).clamp(0, 1).toDouble();
      effectsVolume = ((data['effectsVolume'] as num?)?.toDouble() ?? effectsVolume).clamp(0, 1).toDouble();
      if (phase == GamePhase.profileReview && selectedSuspectIds.length > 3) throw const FormatException('Invalid suspect count');
      final validProfileIds = currentProfiles.map((profile) => profile.id).toSet();
      if (!reviewedProfileIds.every(validProfileIds.contains) || !rejectedProfileIds.every(validProfileIds.contains) || !selectedSuspectIds.every(validProfileIds.contains)) throw const FormatException('Invalid profile reference');
      if (selectedSuspectIds.toSet().length != selectedSuspectIds.length || selectedSuspectIds.any((id) => !reviewedProfileIds.contains(id))) throw const FormatException('Invalid suspect selection');
      if (selectedAccusationId != null && !selectedSuspectIds.contains(selectedAccusationId)) throw const FormatException('Invalid accusation');
      _repairProfileIndex();
    } catch (_) {
      await clearSave();
    }
    notifyListeners();
  }

  void chooseGender(Gender gender) {
    investigationGender = gender;
    final matching = content.levels.values.where((level) => level.gender == gender).toList();
    currentLevelId = matching.isEmpty ? 'case_001' : matching.first.id;
    _resetCaseState();
    phase = GamePhase.briefing;
    _commit();
  }

  void startNewGame() {
    phase = GamePhase.genderSelection;
    notifyListeners();
  }

  void returnToMainMenu() {
    phase = GamePhase.mainMenu;
    notifyListeners();
  }

  void resumeSavedGame() {
    if (!canContinue) return;
    if (phase == GamePhase.mainMenu) {
      phase = allConversationsCompleted ? GamePhase.finalAccusation : (allProfilesReviewed ? GamePhase.messaging : GamePhase.profileReview);
      _commit();
    } else {
      notifyListeners();
    }
  }

  void beginCase() {
    phase = GamePhase.profileReview;
    _commit();
  }

  bool processCurrentProfile({required bool investigate}) {
    if (reviewedProfileIds.contains(activeProfile.id)) return false;
    if (investigate && selectedSuspectIds.length >= 3) return false;
    final selectedAfter = selectedSuspectIds.length + (investigate ? 1 : 0);
    final remainingAfter = currentProfiles.length - reviewedProfileIds.length - 1;
    if (remainingAfter < 3 - selectedAfter) return false;
    reviewedProfileIds.add(activeProfile.id);
    if (investigate) {
      selectedSuspectIds.add(activeProfile.id);
    } else {
      rejectedProfileIds.add(activeProfile.id);
    }
    final nextIndex = currentProfiles.indexWhere((profile) => !reviewedProfileIds.contains(profile.id));
    if (nextIndex == -1) {
      currentProfileIndex = currentProfiles.length - 1;
      phase = GamePhase.messaging;
    } else {
      currentProfileIndex = nextIndex;
    }
    _commit();
    return true;
  }

  void setReviewProfile(String profileId) {
    final index = currentProfiles.indexWhere((profile) => profile.id == profileId);
    if (index >= 0) {
      currentProfileIndex = index;
      notifyListeners();
    }
  }

  void openMessaging() {
    if (allProfilesReviewed && selectedSuspectIds.length == 3) {
      phase = GamePhase.messaging;
      _commit();
    }
  }

  void chooseResponse(String profileId, String optionId) {
    if (completedConversationIds.contains(profileId)) return;
    final conversation = conversationFor(profileId);
    final index = stageIndexFor(profileId);
    if (index >= conversation.stages.length) return;
    final stage = conversation.stages[index];
    final option = stage.responseOptions.firstWhere((item) => item.id == optionId);
    final history = conversationHistory.putIfAbsent(profileId, () => []);
    history.add(ChatEntry(isPlayer: false, text: stage.suspectMessage));
    history.add(ChatEntry(isPlayer: true, text: option.playerText));
    history.add(ChatEntry(isPlayer: false, text: option.suspectReply));
    if (index == conversation.stages.length - 1 || option.nextStageId == null) {
      completedConversationIds.add(profileId);
      conversationStageIndexes[profileId] = conversation.stages.length;
    } else {
      conversationStageIndexes[profileId] = index + 1;
    }
    if (allConversationsCompleted) phase = GamePhase.finalAccusation;
    _commit();
  }

  void selectAccusation(String profileId) {
    if (selectedSuspectIds.contains(profileId)) {
      selectedAccusationId = profileId;
      notifyListeners();
    }
  }

  bool submitAccusation() {
    if (selectedAccusationId == null || !allConversationsCompleted) return false;
    phase = selectedAccusationId == currentLevel.killerProfileId ? GamePhase.levelWon : GamePhase.levelFailed;
    _commit();
    return true;
  }

  void retryCase() {
    _resetCaseState();
    phase = GamePhase.profileReview;
    _commit();
  }

  void continueToNextCase() {
    completedLevelIds.add(currentLevelId);
    unlockedLevelIds.add(currentLevelId);
    phase = GamePhase.mainMenu;
    _commit();
  }

  void setMusicVolume(double value) {
    musicVolume = value;
    preferences.setDouble('settings_music', value);
    notifyListeners();
  }

  void setEffectsVolume(double value) {
    effectsVolume = value;
    preferences.setDouble('settings_effects', value);
    notifyListeners();
  }

  String? get debugPanel {
    if (!kDebugMode) return null;
    final lines = <String>['DEBUG CASE DATA', 'Level: ${currentLevel.id}', 'Killer: ${currentLevel.killerProfileId}'];
    for (final profile in currentProfiles) {
      lines.add('${profile.id} ${profile.name}: ${profile.clues.map((clue) => '${clue.source.name}/${clue.strength.name}').join(', ')}');
      if (profile.redHerrings.isNotEmpty) lines.add('  red herrings: ${profile.redHerrings.join('; ')}');
    }
    return lines.join('\n');
  }

  Map<String, dynamic> toSaveJson() => {
    'phase': phase.name,
    'investigationGender': investigationGender?.name,
    'currentLevelId': currentLevelId,
    'currentProfileIndex': currentProfileIndex,
    'reviewedProfileIds': reviewedProfileIds.toList(),
    'rejectedProfileIds': rejectedProfileIds.toList(),
    'selectedSuspectIds': selectedSuspectIds,
    'conversationStageIndexes': conversationStageIndexes,
    'conversationHistory': conversationHistory.map((key, value) => MapEntry(key, value.map((entry) => entry.toJson()).toList())),
    'completedConversationIds': completedConversationIds.toList(),
    'completedLevelIds': completedLevelIds.toList(),
    'unlockedLevelIds': unlockedLevelIds.toList(),
    'selectedAccusationId': selectedAccusationId,
    'musicVolume': musicVolume,
    'effectsVolume': effectsVolume,
  };

  Future<void> clearSave() async {
    await preferences.remove('game_save');
    _resetCaseState();
    phase = GamePhase.mainMenu;
    investigationGender = null;
  }

  void _resetCaseState() {
    currentProfileIndex = 0;
    reviewedProfileIds.clear();
    rejectedProfileIds.clear();
    selectedSuspectIds.clear();
    conversationStageIndexes.clear();
    conversationHistory.clear();
    completedConversationIds.clear();
    selectedAccusationId = null;
  }

  void _repairProfileIndex() {
    if (currentProfileIndex >= currentProfiles.length) currentProfileIndex = currentProfiles.length - 1;
  }

  void _commit() {
    notifyListeners();
    preferences.setString('game_save', jsonEncode(toSaveJson()));
  }
}
