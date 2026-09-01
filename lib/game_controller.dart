import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data.dart';
import 'models.dart';

class GameController extends ChangeNotifier {
  GameController({required this.content, required this.preferences}) {
    for (final gender in Gender.values) {
      final firstCase = content.levels.values.where((level) => level.gender == gender).firstOrNull;
      if (firstCase != null) unlockedLevelIds.add(firstCase.id);
    }
  }
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
  final Set<String> unlockedLevelIds = {};
  final Map<String, List<String>> _profileOrderByLevel = {};
  final Set<String> gogglesViewedProfileIds = {};
  final math.Random _random = math.Random();
  DateTime? _caseStartedAt;
  Duration? _completedInvestigationDuration;
  String? selectedAccusationId;
  double musicVolume = 0.70;
  double effectsVolume = 0.85;

  Level get currentLevel => content.levels[currentLevelId]!;
  List<Profile> get currentProfiles {
    final level = currentLevel;
    final orderedIds = _profileOrderByLevel[level.id] ?? level.profileIds;
    return orderedIds.map((id) => content.profiles[id]!).toList(growable: false);
  }
  Profile get activeProfile => currentProfiles[currentProfileIndex];
  int get selectedCount => selectedSuspectIds.length;
  int get gogglesScansViewed => gogglesViewedProfileIds.length;
  Duration get investigationDuration {
    final completedDuration = _completedInvestigationDuration;
    if (completedDuration != null) return completedDuration;
    final startedAt = _caseStartedAt;
    return startedAt == null ? Duration.zero : DateTime.now().difference(startedAt);
  }
  String get investigationTime {
    final seconds = investigationDuration.inSeconds.clamp(0, 99 * 60 * 60);
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;
    return hours > 0 ? '${hours}h ${minutes.toString().padLeft(2, '0')}m' : '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
  String detectiveRank({required bool won}) {
    if (!won) return 'FAILED';
    final seconds = investigationDuration.inSeconds;
    if (seconds <= 240 && gogglesScansViewed <= 3) return 'S';
    if (seconds <= 600 && gogglesScansViewed <= 6) return 'A';
    if (gogglesScansViewed >= currentProfiles.length) return 'C';
    return 'B';
  }
  String detectiveTagline({required bool won}) {
    if (!won) return 'The case remains open. The truth is still out there.';
    switch (detectiveRank(won: true)) {
      case 'S':
        return 'Masterful deduction. Nothing got past you.';
      case 'A':
        return 'Sharp work, detective. You followed the evidence.';
      case 'C':
        return 'You used every lead—and still found the truth.';
      default:
        return 'You took your time—and found the truth.';
    }
  }
  bool get canContinue => preferences.containsKey('game_save') && investigationGender != null && !(completedLevelIds.contains(currentLevelId) && allConversationsCompleted);
  bool get allAvailableLevelsCompleted {
    final availableLevels = content.levels.values.where((level) => unlockedLevelIds.contains(level.id));
    return availableLevels.isNotEmpty && availableLevels.every((level) => completedLevelIds.contains(level.id));
  }
  bool get allProfilesReviewed => selectedSuspectIds.length == 3;
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
      final startedAt = data['caseStartedAt'] as String?;
      _caseStartedAt = startedAt == null ? null : DateTime.tryParse(startedAt);
      final completedMilliseconds = (data['completedInvestigationMilliseconds'] as num?)?.round();
      _completedInvestigationDuration = completedMilliseconds == null || completedMilliseconds < 0 ? null : Duration(milliseconds: completedMilliseconds);
      final savedOrders = Map<String, dynamic>.from(data['profileOrderByLevel'] as Map? ?? const {});
      savedOrders.forEach((levelId, rawOrder) {
        final level = content.levels[levelId];
        if (level == null) throw const FormatException('Unknown profile order level');
        final order = List<String>.from(rawOrder as List);
        if (order.length != level.profileIds.length || order.toSet().length != order.length || !order.every(level.profileIds.contains)) {
          throw const FormatException('Invalid profile order');
        }
        _profileOrderByLevel[levelId] = order;
      });
      _ensureProfileOrder(currentLevelId);
      currentProfileIndex = (data['currentProfileIndex'] as int? ?? 0).clamp(0, currentProfiles.length - 1).toInt();
      reviewedProfileIds.addAll(List<String>.from(data['reviewedProfileIds'] as List? ?? const []));
      rejectedProfileIds.addAll(List<String>.from(data['rejectedProfileIds'] as List? ?? const []));
      selectedSuspectIds.addAll(List<String>.from(data['selectedSuspectIds'] as List? ?? const []));
      gogglesViewedProfileIds.addAll(List<String>.from(data['gogglesViewedProfileIds'] as List? ?? const []));
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
      if (!reviewedProfileIds.every(validProfileIds.contains) || !rejectedProfileIds.every(validProfileIds.contains) || !selectedSuspectIds.every(validProfileIds.contains) || !gogglesViewedProfileIds.every(validProfileIds.contains)) throw const FormatException('Invalid profile reference');
      if (selectedSuspectIds.toSet().length != selectedSuspectIds.length || selectedSuspectIds.any((id) => !reviewedProfileIds.contains(id))) throw const FormatException('Invalid suspect selection');
      if (selectedAccusationId != null && !selectedSuspectIds.contains(selectedAccusationId)) throw const FormatException('Invalid accusation');
      _repairProfileIndex();
      if (_completedInvestigationDuration == null && (phase == GamePhase.levelWon || phase == GamePhase.levelFailed)) {
        _completedInvestigationDuration = investigationDuration;
      }
    } catch (_) {
      await clearSave();
    }
    notifyListeners();
  }

  void chooseGender(Gender gender) {
    final matching = content.levels.values.where((level) => level.gender == gender).toList();
    final nextPlayable = matching.where((level) => unlockedLevelIds.contains(level.id) && !completedLevelIds.contains(level.id)).toList();
    final selectedLevel = nextPlayable.isEmpty ? (matching.isEmpty ? null : matching.first) : nextPlayable.first;
    if (selectedLevel != null) chooseCase(selectedLevel.id);
  }

  void chooseCase(String levelId) {
    final level = content.levels[levelId];
    if (level == null || !unlockedLevelIds.contains(levelId)) return;
    investigationGender = level.gender;
    currentLevelId = levelId;
    _resetCaseState();
    _randomizeProfileOrder(levelId);
    _caseStartedAt = DateTime.now();
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
      _resetCaseState();
      _randomizeProfileOrder(currentLevelId);
      _caseStartedAt = DateTime.now();
      phase = GamePhase.profileReview;
      _commit();
    } else {
      notifyListeners();
    }
  }

  void beginCase() {
    _ensureProfileOrder(currentLevelId);
    phase = GamePhase.profileReview;
    _commit();
  }

  bool processCurrentProfile({required bool investigate}) {
    if (!investigate) return goToNextProfile();
    if (phase != GamePhase.profileReview || reviewedProfileIds.contains(activeProfile.id) || selectedSuspectIds.length >= 3) return false;
    reviewedProfileIds.add(activeProfile.id);
    selectedSuspectIds.add(activeProfile.id);
    if (selectedSuspectIds.length == 3) {
      phase = GamePhase.messaging;
    } else {
      _moveToNextUnselectedProfile();
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

  bool get canGoToPreviousProfile => currentProfileIndex > 0;

  bool get canGoToNextProfile => currentProfileIndex < currentProfiles.length - 1;

  bool goToPreviousProfile() {
    if (phase != GamePhase.profileReview || !canGoToPreviousProfile) return false;
    currentProfileIndex -= 1;
    _commit();
    return true;
  }

  bool goToNextProfile() {
    if (phase != GamePhase.profileReview || !canGoToNextProfile) return false;
    currentProfileIndex += 1;
    _commit();
    return true;
  }

  void openMessaging() {
    if (selectedSuspectIds.length == 3) {
      phase = GamePhase.messaging;
      _commit();
    }
  }

  void recordGogglesScan(String profileId) {
    if (currentProfiles.any((profile) => profile.id == profileId) && gogglesViewedProfileIds.add(profileId)) _commit();
  }

  void _moveToNextUnselectedProfile() {
    for (var offset = 1; offset <= currentProfiles.length; offset++) {
      final nextIndex = (currentProfileIndex + offset) % currentProfiles.length;
      if (!selectedSuspectIds.contains(currentProfiles[nextIndex].id)) {
        currentProfileIndex = nextIndex;
        return;
      }
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
    _commit();
  }

  void openFinalAccusation() {
    if (!allConversationsCompleted) return;
    phase = GamePhase.finalAccusation;
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
    final correct = selectedAccusationId == currentLevel.killerProfileId;
    _completedInvestigationDuration = investigationDuration;
    if (correct) _markCurrentLevelComplete();
    phase = correct ? GamePhase.levelWon : GamePhase.levelFailed;
    _commit();
    return true;
  }

  void retryCase() {
    final previousOrder = List<String>.from(_profileOrderByLevel[currentLevelId] ?? currentLevel.profileIds);
    _resetCaseState();
    _randomizeProfileOrder(currentLevelId, avoid: previousOrder);
    _caseStartedAt = DateTime.now();
    phase = GamePhase.profileReview;
    _commit();
  }

  void continueToNextCase() {
    _markCurrentLevelComplete();
    final nextLevel = _nextLevel();
    if (nextLevel == null) {
      phase = GamePhase.mainMenu;
    } else {
      currentLevelId = nextLevel.id;
      investigationGender = nextLevel.gender;
      unlockedLevelIds.add(nextLevel.id);
      _resetCaseState();
      _randomizeProfileOrder(nextLevel.id);
      _caseStartedAt = DateTime.now();
      phase = GamePhase.briefing;
    }
    _commit();
  }

  void _markCurrentLevelComplete() {
    completedLevelIds.add(currentLevelId);
    unlockedLevelIds.add(currentLevelId);
    final nextLevel = _nextLevel();
    if (nextLevel != null) unlockedLevelIds.add(nextLevel.id);
  }

  Level? _nextLevel() {
    final levels = content.levels.values.where((level) => level.gender == currentLevel.gender).toList();
    final currentLevelIndex = levels.indexWhere((level) => level.id == currentLevelId);
    return currentLevelIndex >= 0 && currentLevelIndex + 1 < levels.length ? levels[currentLevelIndex + 1] : null;
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
    'caseStartedAt': _caseStartedAt?.toIso8601String(),
    'completedInvestigationMilliseconds': _completedInvestigationDuration?.inMilliseconds,
    'currentProfileIndex': currentProfileIndex,
    'profileOrderByLevel': _profileOrderByLevel,
    'reviewedProfileIds': reviewedProfileIds.toList(),
    'rejectedProfileIds': rejectedProfileIds.toList(),
    'selectedSuspectIds': selectedSuspectIds,
    'gogglesViewedProfileIds': gogglesViewedProfileIds.toList(),
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
    _caseStartedAt = null;
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
    gogglesViewedProfileIds.clear();
    _caseStartedAt = null;
    _completedInvestigationDuration = null;
    _profileOrderByLevel.clear();
  }

  void _ensureProfileOrder(String levelId) {
    if (!_profileOrderByLevel.containsKey(levelId)) _randomizeProfileOrder(levelId);
  }

  void _randomizeProfileOrder(String levelId, {List<String>? avoid}) {
    final level = content.levels[levelId]!;
    final order = List<String>.from(level.profileIds);
    order.shuffle(_random);
    if (avoid != null && order.length > 1 && listEquals(order, avoid)) {
      final first = order[0];
      order[0] = order[1];
      order[1] = first;
    }
    _profileOrderByLevel[levelId] = order;
  }

  void _repairProfileIndex() {
    if (currentProfileIndex >= currentProfiles.length) currentProfileIndex = currentProfiles.length - 1;
  }

  void _commit() {
    notifyListeners();
    preferences.setString('game_save', jsonEncode(toSaveJson()));
  }
}
