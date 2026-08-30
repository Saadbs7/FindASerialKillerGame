import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'models.dart';
import 'widgets.dart';
import 'app_scope.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    return Scaffold(body: SafeArea(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 900), child: Padding(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const BrandMark(compact: true), IconButton(tooltip: 'Settings', onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())), icon: const Icon(Icons.tune_rounded))]),
      Expanded(child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // const SizedBox(height: 38),
        // Text('FIND A', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: coral, fontWeight: FontWeight.w900, letterSpacing: 4)),
        Row(
          children: [
            const SizedBox(width: 65),
            Text('Serial Killer', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900, height: 1.05,  color: Colors.red)),
          ],
        ),
        // const SizedBox(height: 18),
        const SizedBox(height: 28),
        // const Text('A dating profile can tell you a lot.', textAlign: TextAlign.center, style: TextStyle(color: muted, fontSize: 20, height: 1.45)),
        const SizedBox(
          width: double.infinity,
          child: Text(
            'A dating profile can tell you a lot.',
            textAlign: TextAlign.center,
            style: TextStyle(color: muted, fontSize: 20, height: 1.45),
          ),
        ),
        const SizedBox(height: 28),
        const Text('It can also hide the one thing that matters.', textAlign: TextAlign.center, style: TextStyle(color: muted, fontSize: 20, height: 1.45)),
        const SizedBox(height: 28),
        SectionCard(child: Row(children: [Container(width: 48, height: 48, decoration: BoxDecoration(color: aqua.withValues(alpha: .15), borderRadius: BorderRadius.circular(18)), child: const Icon(Icons.radar_rounded, color: aqua, size: 30)), const SizedBox(width: 15), const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Observe. Compare. Deduce.', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)), SizedBox(height: 4), Text('Use profile pictures, bio data, conversations, and Goggles intelligence to find red flags.', textAlign: TextAlign.left, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15, color: muted, height: 1.35))]))])),
      ]))),
      const SizedBox(height: 18),
      PrimaryButton(label: 'New Game', icon: Icons.play_arrow_rounded, onPressed: game.startNewGame),
      const SizedBox(height: 10),
      PrimaryButton(label: 'Continue', icon: Icons.bookmark_outline_rounded, outlined: true, onPressed: game.canContinue ? () => game.resumeSavedGame() : null),
      const SizedBox(height: 10),
      PrimaryButton(label: 'Settings', icon: Icons.tune_rounded, outlined: true, onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen()))),
      if (game.completedLevelIds.contains(game.currentLevelId)) const Padding(padding: EdgeInsets.only(top: 12), child: Text('CASE 01 COMPLETE  ·  MORE CASES COMING SOON', textAlign: TextAlign.center, style: TextStyle(color: aqua, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1))),
    ]))))));
  }
}

class GenderSelectionScreen extends StatelessWidget {
  const GenderSelectionScreen({super.key});
  @override
  Widget build(BuildContext context) => PageFrame(title: 'Who are you investigating?', subtitle: 'Choose a case file to begin.', child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    const SizedBox(height: 18),
    _ChoiceCard(icon: Icons.male_rounded, title: 'Men', body: '10 profiles · Case 01 available', color: coral, onTap: () => GameScope.of(context).chooseGender(Gender.men)),
    const SizedBox(height: 14),
    _ChoiceCard(icon: Icons.female_rounded, title: 'Women', body: 'Case files will be added in a future content pack', color: aqua, onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('The first playable case currently contains men’s profiles.')))),
    const Spacer(),
    TextButton.icon(onPressed: GameScope.of(context).returnToMainMenu, icon: const Icon(Icons.arrow_back), label: const Text('Back to main menu')),
  ]));
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({required this.icon, required this.title, required this.body, required this.color, required this.onTap});
  final IconData icon; final String title; final String body; final Color color; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(borderRadius: BorderRadius.circular(24), onTap: onTap, child: SectionCard(child: Row(children: [Container(width: 58, height: 58, decoration: BoxDecoration(color: color.withValues(alpha: .15), borderRadius: BorderRadius.circular(18)), child: Icon(icon, color: color, size: 30)), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)), const SizedBox(height: 4), Text(body, style: const TextStyle(color: muted))])), const Icon(Icons.chevron_right_rounded, color: muted)])));
}

class BriefingScreen extends StatelessWidget {
  const BriefingScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    return PageFrame(title: 'Investigation briefing', subtitle: game.currentLevel.title, child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SectionCard(color: const Color(0xFF121C2E), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const BrandMark(), const SizedBox(height: 18), Text(game.currentLevel.caseDescription, style: const TextStyle(fontSize: 16, height: 1.5)), const SizedBox(height: 18), const Text('Your brief', style: TextStyle(color: coral, fontWeight: FontWeight.w900, letterSpacing: 1)), const SizedBox(height: 8), const Text('You are a private investigator with access to a dating platform and an unofficial intelligence layer called Goggles. Review ten profiles, select exactly three for deeper investigation, and compare what people say with what the data suggests.', style: TextStyle(color: muted, height: 1.5))])),
      const SizedBox(height: 14),
      const SectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Keep your judgment flexible', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)), SizedBox(height: 12), _BriefBullet(text: 'Goggles provides hidden platform information, not proof.'), _BriefBullet(text: 'Innocent people can look suspicious, and the killer may seem completely normal.'), _BriefBullet(text: 'Compare profiles, photos, questions, Goggles, and conversations.'), _BriefBullet(text: 'Only three profiles can be investigated more closely.') ])),
      const SizedBox(height: 18),
      PrimaryButton(label: 'Begin case', icon: Icons.arrow_forward_rounded, onPressed: game.beginCase),
      if (kDebugMode && game.debugPanel != null) ...[const SizedBox(height: 18), ExpansionTile(title: const Text('Developer inspection'), textColor: aqua, collapsedTextColor: aqua, children: [Padding(padding: const EdgeInsets.all(16), child: SelectableText(game.debugPanel!, style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: muted)))])],
    ])));
  }
}

class _BriefBullet extends StatelessWidget {
  const _BriefBullet({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('•  ', style: TextStyle(color: aqua, fontSize: 18)), Expanded(child: Text(text, style: const TextStyle(color: muted, height: 1.35)))]));
}

class ProfileReviewScreen extends StatelessWidget {
  const ProfileReviewScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final profile = game.activeProfile;
    final reviewed = game.reviewedProfileIds.contains(profile.id);
    final fileChips = game.currentProfiles.map<Widget>((item) => Padding(
      padding: const EdgeInsets.only(right: 7),
      child: ChoiceChip(label: Text(item.id.toUpperCase()), selected: item.id == profile.id, onSelected: (_) => game.setReviewProfile(item.id)),
    )).toList(growable: false);
    return PageFrame(title: 'Profile review', subtitle: 'Case 01  ·  ${game.reviewedProfileIds.length} of 10 reviewed', action: SuspectCounter(count: game.selectedCount), child: LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth > 700;
      final details = _ProfileDetails(profile: profile);
      final gallery = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [PlaceholderPhoto(profile: profile), const SizedBox(height: 12), GogglesButton(onPressed: () => GogglesDialog.show(context, profile))]);
      return SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (wide) Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 5, child: gallery), const SizedBox(width: 20), Expanded(flex: 6, child: details)]) else ...[gallery, const SizedBox(height: 18), details],
        const SizedBox(height: 18),
        if (game.reviewedProfileIds.isNotEmpty) ...[const Text('CASE FILES', style: TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.4)), const SizedBox(height: 8), SizedBox(height: 40, child: ListView(scrollDirection: Axis.horizontal, children: fileChips))],
        const SizedBox(height: 18),
        if (!reviewed) Row(children: [Expanded(child: PrimaryButton(label: 'Reject', icon: Icons.close_rounded, outlined: true, onPressed: () => _process(context, false))), const SizedBox(width: 10), Expanded(child: PrimaryButton(label: 'Investigate', icon: Icons.favorite_border_rounded, onPressed: () => _process(context, true)))]),
        if (reviewed) SectionCard(child: Row(children: [const Icon(Icons.check_circle_outline, color: aqua), const SizedBox(width: 10), Expanded(child: Text(game.selectedSuspectIds.contains(profile.id) ? 'Selected for deeper investigation.' : 'Rejected for deeper investigation.', style: const TextStyle(color: muted))), TextButton(onPressed: game.allProfilesReviewed && game.selectedCount == 3 ? game.openMessaging : null, child: const Text('Open inbox'))])),
        if (game.allProfilesReviewed && game.selectedCount == 3) ...[const SizedBox(height: 12), PrimaryButton(label: 'Continue to inbox', icon: Icons.forum_outlined, onPressed: game.openMessaging)],
      ]));
    }));
  }

  void _process(BuildContext context, bool investigate) {
    final didProcess = GameScope.of(context).processCurrentProfile(investigate: investigate);
    if (!didProcess) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select exactly three profiles before leaving the review.')));
  }
}

class GogglesButton extends StatelessWidget {
  const GogglesButton({super.key, required this.onPressed});
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => SizedBox(height: 46, child: OutlinedButton.icon(onPressed: onPressed, icon: const Icon(Icons.radar_rounded, color: aqua), label: const Text('Open Goggles scan')));
}

class _ProfileDetails extends StatelessWidget {
  const _ProfileDetails({required this.profile});
  final Profile profile;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    ProfileHeader(profile: profile), const SizedBox(height: 16), Text(profile.bio, style: const TextStyle(fontSize: 16, height: 1.45)), const SizedBox(height: 12), Text(profile.description, style: const TextStyle(color: muted, height: 1.45)), const SizedBox(height: 16), Text(profile.intent.toUpperCase(), style: const TextStyle(color: coral, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2)), const SizedBox(height: 10), InterestChips(interests: profile.interests),
    if (profile.questions.isNotEmpty) ...[const SizedBox(height: 20), const Text('PROFILE QUESTIONS', style: TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2)), const SizedBox(height: 8), ...profile.questions.map((question) => Padding(padding: const EdgeInsets.only(bottom: 13), child: SectionCard(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(question.question, style: const TextStyle(color: aqua, fontWeight: FontWeight.w700)), const SizedBox(height: 6), Text('“${question.answer}”', style: const TextStyle(height: 1.35))]))))],
  ]);
}

class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    return PageFrame(title: 'Inbox', subtitle: 'Three conversations. Look for what does not fit.', action: SuspectCounter(count: game.selectedCount), child: ListView(children: [
      const SectionCard(color: Color(0xFF121C2E), child: Row(children: [Icon(Icons.forum_outlined, color: aqua), SizedBox(width: 12), Expanded(child: Text('Your matches are waiting. Every conversation has three short stages and two ways to respond.', style: TextStyle(color: muted, height: 1.4)))])),
      const SizedBox(height: 16),
      ...game.selectedSuspectIds.map((id) => _InboxTile(profile: game.profileById(id), complete: game.isConversationComplete(id), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatScreen(profileId: id))))),
    ]));
  }
}

class _InboxTile extends StatelessWidget {
  const _InboxTile({required this.profile, required this.complete, required this.onTap});
  final Profile profile; final bool complete; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 12), child: InkWell(borderRadius: BorderRadius.circular(22), onTap: onTap, child: SectionCard(child: Row(children: [Container(width: 54, height: 54, decoration: BoxDecoration(color: coral.withValues(alpha: .16), borderRadius: BorderRadius.circular(17)), child: Center(child: Text(profile.name.substring(0, 1), style: const TextStyle(color: coral, fontSize: 22, fontWeight: FontWeight.w900)))), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${profile.name}, ${profile.age}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)), const SizedBox(height: 5), Text(complete ? 'Conversation complete' : 'Reply waiting · stage ${complete ? 3 : 1} of 3', style: const TextStyle(color: muted))])), Icon(complete ? Icons.check_circle : Icons.chevron_right_rounded, color: complete ? aqua : muted)]))));
}

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key, required this.profileId});
  final String profileId;
  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final profile = game.profileById(profileId);
    final conversation = game.conversationFor(profileId);
    final complete = game.isConversationComplete(profileId);
    final stageIndex = game.stageIndexFor(profileId);
    final history = game.conversationHistory[profileId] ?? const <ChatEntry>[];
    return PageFrame(title: '${profile.name}, ${profile.age}', subtitle: profile.occupation, action: IconButton(tooltip: 'Close conversation', onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close)), child: Column(children: [
      Expanded(child: ListView(children: [
        Row(children: [const Icon(Icons.lock_outline, size: 15, color: aqua), const SizedBox(width: 7), Text('PRIVATE MATCH  ·  STAGE ${complete ? 3 : stageIndex + 1} / 3', style: const TextStyle(color: aqua, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1))]),
        const SizedBox(height: 16),
        ...history.map((entry) => ChatBubble(entry: entry)),
        if (!complete) ChatBubble(entry: ChatEntry(isPlayer: false, text: conversation.stages[stageIndex].suspectMessage)),
      ])),
      if (complete) SectionCard(child: Column(children: [const Icon(Icons.check_circle_outline, color: aqua, size: 29), const SizedBox(height: 8), const Text('Conversation complete', style: TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 10), PrimaryButton(label: 'Back to inbox', onPressed: () => Navigator.of(context).pop(), outlined: true)]))
      else ...conversation.stages[stageIndex].responseOptions.map((option) => Padding(padding: const EdgeInsets.only(top: 8), child: SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () { game.chooseResponse(profileId, option.id); if (game.phase == GamePhase.finalAccusation) Navigator.of(context).pop(); }, child: Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Text(option.playerText))))))],));
  }
}

class AccusationScreen extends StatelessWidget {
  const AccusationScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    return PageFrame(title: 'Who is the killer?', subtitle: 'Review your conversations, then make one confirmed accusation.', child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Expanded(child: ListView(children: game.selectedSuspectIds.map((id) { final profile = game.profileById(id); final selected = id == game.selectedAccusationId; return Padding(padding: const EdgeInsets.only(bottom: 12), child: InkWell(borderRadius: BorderRadius.circular(22), onTap: () => game.selectAccusation(id), child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: selected ? coral.withValues(alpha: .16) : panel, borderRadius: BorderRadius.circular(22), border: Border.all(color: selected ? coral : Colors.white.withValues(alpha: .07), width: selected ? 2 : 1)), child: Row(children: [SizedBox(width: 74, child: PlaceholderPhoto(profile: profile)), const SizedBox(width: 15), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${profile.name}, ${profile.age}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)), const SizedBox(height: 5), Text(profile.occupation, style: const TextStyle(color: muted)), const SizedBox(height: 12), Text(selected ? 'SELECTED FOR ACCUSATION' : 'Tap to select', style: TextStyle(color: selected ? coral : muted, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1))])), Icon(selected ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: selected ? coral : muted)])))); }).toList())),
      PrimaryButton(label: 'Confirm accusation', icon: Icons.gavel_rounded, onPressed: game.selectedAccusationId == null ? null : () => _confirm(context)),
    ]));
  }
  void _confirm(BuildContext context) => showDialog<void>(context: context, builder: (_) => AlertDialog(title: const Text('Confirm accusation?'), content: Text('You are accusing ${GameScope.of(context).profileById(GameScope.of(context).selectedAccusationId!).name}. This cannot be undone for this attempt.'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Review again')), FilledButton(onPressed: () { Navigator.pop(context); GameScope.of(context).submitAccusation(); }, child: const Text('Submit accusation'))]));
}

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key, required this.won});
  final bool won;
  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    return PageFrame(child: Center(child: SingleChildScrollView(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(won ? Icons.lock_open_rounded : Icons.gavel_rounded, size: 74, color: won ? aqua : coral), const SizedBox(height: 24), Text(won ? 'CASE CLOSED' : 'WRONG SUSPECT', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900, color: won ? aqua : coral), textAlign: TextAlign.center), const SizedBox(height: 14), Text(won ? 'You found the killer.' : 'Your accusation could not be proven. The killer remains free.', style: const TextStyle(color: muted, fontSize: 17), textAlign: TextAlign.center), const SizedBox(height: 30), PrimaryButton(label: won ? 'Continue to next case' : 'Retry case', icon: won ? Icons.arrow_forward : Icons.replay, onPressed: won ? game.continueToNextCase : game.retryCase), const SizedBox(height: 10), PrimaryButton(label: 'Return to main menu', onPressed: game.returnToMainMenu, outlined: true)]))));
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    return PageFrame(title: 'Settings', subtitle: 'Preferences are saved on this device.', child: ListView(children: [
      SectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Music volume', style: TextStyle(fontWeight: FontWeight.w800)), Slider(value: game.musicVolume, onChanged: game.setMusicVolume), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Muted', style: TextStyle(color: muted, fontSize: 12)), Text('${(game.musicVolume * 100).round()}%', style: const TextStyle(color: aqua, fontWeight: FontWeight.bold))])])),
      const SizedBox(height: 12),
      SectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Sound effects volume', style: TextStyle(fontWeight: FontWeight.w800)), Slider(value: game.effectsVolume, onChanged: game.setEffectsVolume), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Muted', style: TextStyle(color: muted, fontSize: 12)), Text('${(game.effectsVolume * 100).round()}%', style: const TextStyle(color: aqua, fontWeight: FontWeight.bold))])])),
      const SizedBox(height: 20), const Text('Audio hooks are ready for future music and sound assets.', style: TextStyle(color: muted, height: 1.4)),
      const SizedBox(height: 22), PrimaryButton(label: 'Done', onPressed: () => Navigator.of(context).pop()),
    ]));
  }
}
