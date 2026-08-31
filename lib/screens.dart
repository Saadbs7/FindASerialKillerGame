import 'dart:ui';
import 'package:flutter/material.dart';
import 'models.dart';
import 'game_controller.dart';
import 'widgets.dart';
import 'app_scope.dart';
import 'result_scene.dart';

class _CaseHeaderActions extends StatelessWidget {
  const _CaseHeaderActions({this.leading});
  final Widget? leading;

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    if (leading != null) leading!,
    const _CaseBriefingButton(),
    const _CaseOptionsButton(),
  ]);
}

class _CaseBriefingButton extends StatelessWidget {
  const _CaseBriefingButton();

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'Read case briefing',
    onPressed: () => showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close case briefing',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, __, ___) => const _CaseBriefingDialog(),
      transitionBuilder: (context, animation, secondaryAnimation, child) => Stack(children: [
        Positioned.fill(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7), child: Container(color: Colors.black.withValues(alpha: .48)))),
        Center(child: FadeTransition(opacity: animation, child: ScaleTransition(scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack), child: child))),
      ]),
    ),
    icon: const Icon(Icons.article_outlined),
  );
}

class _CaseBriefingDialog extends StatelessWidget {
  const _CaseBriefingDialog();

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final genderCases = game.content.levels.values.where((level) => level.gender == game.currentLevel.gender).toList();
    final caseNumber = (genderCases.indexWhere((level) => level.id == game.currentLevel.id) + 1).toString().padLeft(2, '0');
    return Dialog(
      backgroundColor: panel,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28), side: BorderSide(color: aqua.withValues(alpha: .55), width: 1.2)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 620),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(children: [
                Container(width: 44, height: 44, decoration: BoxDecoration(color: aqua.withValues(alpha: .14), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.article_outlined, color: aqua)),
                const SizedBox(width: 12),
                const Text('Case briefing', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
              ]),
              IconButton(
                tooltip: 'Close briefing',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, size: 28),
                style: IconButton.styleFrom(
                  foregroundColor: coral,
                  backgroundColor: coral.withValues(alpha: .12),
                  minimumSize: const Size(52, 52),
                  shape: CircleBorder(side: BorderSide(color: coral.withValues(alpha: .55))),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            Flexible(child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Expanded(child: Text('CASE $caseNumber — ${game.currentLevel.title}', style: const TextStyle(color: coral, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.1))),
              const SizedBox(width: 10),
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: coral.withValues(alpha: .14), borderRadius: BorderRadius.circular(10)), child: Text(game.currentLevel.difficulty.toUpperCase(), style: const TextStyle(color: coral, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1))),
            ]),
            const SizedBox(height: 18),
            const Text('CASE INTELLIGENCE', style: TextStyle(color: coral, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            Text(game.currentLevel.caseDescription, style: const TextStyle(fontSize: 16, height: 1.5)),
            const SizedBox(height: 18),
            const Text('YOUR BRIEF', style: TextStyle(color: coral, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            const Text('You are a private investigator with access to a dating platform and an unofficial intelligence layer called Goggles. Review ten profiles, select exactly three for deeper investigation, and compare what people say with what the data suggests.', style: TextStyle(color: muted, height: 1.5)),
            const SizedBox(height: 18),
            const Text('KEEP YOUR JUDGMENT FLEXIBLE', style: TextStyle(color: coral, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            const _BriefBullet(text: 'Goggles provides hidden platform information, not proof.'),
            const _BriefBullet(text: 'Innocent people can look suspicious, and the killer may seem completely normal.'),
            const _BriefBullet(text: 'Compare profiles, photos, questions, Goggles, and conversations.'),
            const _BriefBullet(text: 'Only three profiles can be investigated more closely.'),
            ]))),
          ]),
        ),
      ),
    );
  }
}

class _CaseOptionsButton extends StatelessWidget {
  const _CaseOptionsButton();

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'Case options',
    onPressed: () => showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close options',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, __, ___) => const _CaseOptionsDialog(),
      transitionBuilder: (context, animation, secondaryAnimation, child) => Stack(children: [
        Positioned.fill(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7), child: Container(color: Colors.black.withValues(alpha: .48)))),
        Center(child: FadeTransition(opacity: animation, child: ScaleTransition(scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack), child: child))),
      ]),
    ),
    icon: const Icon(Icons.tune_rounded),
  );
}

class _CaseOptionsDialog extends StatelessWidget {
  const _CaseOptionsDialog();

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    return Dialog(
      backgroundColor: panel,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28), side: BorderSide(color: aqua.withValues(alpha: .55), width: 1.2)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              Container(width: 44, height: 44, decoration: BoxDecoration(color: aqua.withValues(alpha: .14), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.tune_rounded, color: aqua)),
              const SizedBox(width: 12),
              const Text('Case options', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
            ]),
            IconButton(
              tooltip: 'Close options',
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded, size: 28),
              style: IconButton.styleFrom(
                foregroundColor: coral,
                backgroundColor: coral.withValues(alpha: .12),
                minimumSize: const Size(52, 52),
                shape: CircleBorder(side: BorderSide(color: coral.withValues(alpha: .55))),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.music_note_rounded, color: aqua),
            title: const Text('Music', style: TextStyle(fontWeight: FontWeight.w700)),
            value: game.musicVolume > 0,
            onChanged: (enabled) => game.setMusicVolume(enabled ? .70 : 0),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.volume_up_rounded, color: aqua),
            title: const Text('Sound effects', style: TextStyle(fontWeight: FontWeight.w700)),
            value: game.effectsVolume > 0,
            onChanged: (enabled) => game.setEffectsVolume(enabled ? .85 : 0),
          ),
          const SizedBox(height: 10),
          MenuActionButton(label: 'Back to main menu', icon: Icons.home_rounded, primary: true, showChevron: false, onPressed: () {
            Navigator.of(context).pop();
            game.returnToMainMenu();
          }),
          ]),
        ),
      ),
    );
  }
}

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
      MenuActionButton(label: 'New Game', icon: Icons.play_arrow_rounded, primary: true, onPressed: game.startNewGame),
      const SizedBox(height: 10),
      MenuActionButton(label: 'Continue', icon: Icons.bookmark_outline_rounded, onPressed: game.canContinue ? () => game.resumeSavedGame() : null),
      if (game.allAvailableLevelsCompleted) const Padding(padding: EdgeInsets.only(top: 12), child: Text('CONGRATS! ALL CASES COMPLETED. MORE CASES COMING SOON!', textAlign: TextAlign.center, style: TextStyle(color: aqua, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1))),
    ]))))));
  }
}

class GenderSelectionScreen extends StatefulWidget {
  const GenderSelectionScreen({super.key});

  @override
  State<GenderSelectionScreen> createState() => _GenderSelectionScreenState();
}

class _GenderSelectionScreenState extends State<GenderSelectionScreen> {
  Gender? _selectedGender;

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    if (_selectedGender != null) return _buildCaseList(context, game, _selectedGender!);
    return PageFrame(title: 'Who are you investigating?', subtitle: 'Select a suspect pool and open its case files.', child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SizedBox(height: 18),
    _ChoiceCard(icon: Icons.male_rounded, title: 'Men', body: '${game.content.levels.values.where((level) => level.gender == Gender.men).length} case files available', color: coral, onTap: () => setState(() => _selectedGender = Gender.men)),
    const SizedBox(height: 14),
    _ChoiceCard(icon: Icons.female_rounded, title: 'Women', body: '${game.content.levels.values.where((level) => level.gender == Gender.women).length} case files available', color: aqua, onTap: () => setState(() => _selectedGender = Gender.women)),
    const Spacer(),
    MenuActionButton(label: 'Back to main menu', icon: Icons.arrow_back_rounded, showChevron: false, onPressed: game.returnToMainMenu),
  ]));
  }

  Widget _buildCaseList(BuildContext context, GameController game, Gender gender) {
    final cases = game.content.levels.values.where((level) => level.gender == gender).toList();
    final label = gender == Gender.men ? 'Men' : 'Women';
    return PageFrame(title: '$label · Case files', subtitle: 'Choose an available investigation.', child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SizedBox(height: 18),
      Expanded(child: ListView(children: cases.asMap().entries.map((entry) {
        final caseNumber = (entry.key + 1).toString().padLeft(2, '0');
        final level = entry.value;
        final available = game.unlockedLevelIds.contains(level.id);
        return Padding(padding: const EdgeInsets.only(bottom: 14), child: _CaseChoiceCard(caseNumber: caseNumber, title: available ? level.title : 'Case Classified', body: available ? '${level.difficulty} · 10 profiles' : 'Locked · Complete the previous case first', available: available, onTap: available ? () => game.chooseCase(level.id) : null));
      }).toList())),
      MenuActionButton(label: 'Back to gender selection', icon: Icons.arrow_back_rounded, showChevron: false, onPressed: () => setState(() => _selectedGender = null)),
    ]));
  }
}

class _CaseChoiceCard extends StatelessWidget {
  const _CaseChoiceCard({required this.caseNumber, required this.title, required this.body, required this.available, required this.onTap});
  final String caseNumber;
  final String title;
  final String body;
  final bool available;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Opacity(opacity: available ? 1 : .55, child: InkWell(borderRadius: BorderRadius.circular(24), onTap: onTap, child: SectionCard(child: Row(children: [Container(width: 58, height: 58, decoration: BoxDecoration(color: (available ? coral : muted).withValues(alpha: .15), borderRadius: BorderRadius.circular(18)), child: Icon(available ? Icons.folder_open_rounded : Icons.lock_outline_rounded, color: available ? coral : muted, size: 30)), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('CASE $caseNumber', style: const TextStyle(color: coral, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2)), const SizedBox(height: 4), Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)), const SizedBox(height: 4), Text(body, style: const TextStyle(color: muted))])), Icon(available ? Icons.chevron_right_rounded : Icons.lock_outline_rounded, color: muted)]))));
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
    final genderCases = game.content.levels.values.where((level) => level.gender == game.currentLevel.gender).toList();
    final caseNumber = (genderCases.indexWhere((level) => level.id == game.currentLevel.id) + 1).toString().padLeft(2, '0');
    return PageFrame(title: 'Investigation briefing', leading: ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.asset('assets/logo.jpg', width: 52, height: 52, fit: BoxFit.cover, semanticLabel: 'Find a Serial Killer app logo')), action: const _CaseOptionsButton(), centerTitle: true, child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SectionCard(color: const Color(0xFF121C2E), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('CASE $caseNumber — ${game.currentLevel.title}', style: const TextStyle(color: coral, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.4)),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: coral.withValues(alpha: .14), borderRadius: BorderRadius.circular(10)), child: Text(game.currentLevel.difficulty.toUpperCase(), style: const TextStyle(color: coral, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1))),
        ]),
        const SizedBox(height: 18),
        const Text('CASE INTELLIGENCE', style: TextStyle(color: coral, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
        const SizedBox(height: 8),
        Text(game.currentLevel.caseDescription, style: const TextStyle(fontSize: 16, height: 1.5)),
        const SizedBox(height: 18),
        const Text('Your brief', style: TextStyle(color: coral, fontWeight: FontWeight.w900, letterSpacing: 1)),
        const SizedBox(height: 8),
        const Text('You are a private investigator with access to a dating platform and an unofficial intelligence layer called Goggles. Review ten profiles, select exactly three for deeper investigation, and compare what people say with what the data suggests.', style: TextStyle(color: muted, height: 1.5)),
      ])),
      const SizedBox(height: 14),
      const SectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Keep your judgment flexible', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)), SizedBox(height: 12), _BriefBullet(text: 'Goggles provides hidden platform information, not proof.'), _BriefBullet(text: 'Innocent people can look suspicious, and the killer may seem completely normal.'), _BriefBullet(text: 'Compare profiles, photos, questions, Goggles insights, and conversations.'), _BriefBullet(text: 'Only three profiles can be investigated more closely.') ])),
      const SizedBox(height: 18),
      MenuActionButton(label: 'Start investigation', icon: Icons.play_arrow_rounded, primary: true, showChevron: false, onPressed: game.beginCase),
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
    final selected = game.selectedSuspectIds.contains(profile.id);
    final genderCases = game.content.levels.values.where((level) => level.gender == game.currentLevel.gender).toList();
    final caseNumber = (genderCases.indexWhere((level) => level.id == game.currentLevel.id) + 1).toString().padLeft(2, '0');
    return PageFrame(title: 'Browse Profiles', subtitle: 'Case $caseNumber  ·  ${game.currentProfileIndex + 1} of ${game.currentProfiles.length} profiles', subtitleAction: SuspectCounter(count: game.selectedCount), action: const _CaseHeaderActions(), child: LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth > 700;
      final details = _ProfileDetails(profile: profile);
      final gallery = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [PlaceholderPhoto(profile: profile), const SizedBox(height: 12), GogglesButton(onPressed: () => GogglesDialog.show(context, profile))]);
      return Stack(
        fit: StackFit.expand,
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 82),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (wide) Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 5, child: gallery), const SizedBox(width: 20), Expanded(flex: 6, child: details)]) else ...[gallery, const SizedBox(height: 18), details],
              const SizedBox(height: 18),
              if (selected) const Text('SELECTED FOR INVESTIGATION', style: TextStyle(color: aqua, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.3)),
            ]),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: ProfileActionButton(label: 'Previous\nprofile', icon: Icons.arrow_back_rounded, accent: aqua, backgroundColor: panel, onPressed: game.canGoToPreviousProfile ? () => game.goToPreviousProfile() : null)),
              const SizedBox(width: 8),
              Expanded(child: ProfileActionButton(label: 'Next\nprofile', icon: Icons.arrow_forward_rounded, accent: aqua, backgroundColor: panel, onPressed: game.canGoToNextProfile ? () => game.goToNextProfile() : null)),
              const SizedBox(width: 8),
              Expanded(child: ProfileActionButton(label: 'Investigate', icon: Icons.radar_rounded, accent: coral, primary: true, onPressed: selected ? null : () => _process(context))),
            ]),
          ),
        ],
      );
    }));
  }

  void _process(BuildContext context) {
    final didProcess = GameScope.of(context).processCurrentProfile(investigate: true);
    if (!didProcess) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Choose another profile for investigation.')));
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

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  int _tabIndex = 1;

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    return PageFrame(
      title: _tabIndex == 0 ? 'Suspects' : 'Inbox',
      subtitle: _tabIndex == 0 ? 'Compare their stories. Find what does not fit.\nRevisit the briefing anytime.' : 'The truth is hidden between their replies.\nRevisit the briefing anytime.',
      action: const _CaseHeaderActions(),
      child: Column(children: [
        Expanded(
          child: IndexedStack(
            index: _tabIndex,
            children: const [_SelectedProfilesTab(), _InboxMessagesTab()],
          ),
        ),
        if (_tabIndex == 1 && game.allConversationsCompleted) ...[
          const SizedBox(height: 12),
          MenuActionButton(label: 'Choose the killer', icon: Icons.gavel_rounded, primary: true, onPressed: game.openFinalAccusation),
        ],
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: NavigationBar(
            height: 72,
            selectedIndex: _tabIndex,
            onDestinationSelected: (index) => setState(() => _tabIndex = index),
            backgroundColor: const Color(0xFF121A2B),
            indicatorColor: coral.withValues(alpha: .2),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: const [
              NavigationDestination(icon: Icon(Icons.people_alt_outlined), selectedIcon: Icon(Icons.people_alt_rounded), label: 'Profiles'),
              NavigationDestination(icon: Icon(Icons.forum_outlined), selectedIcon: Icon(Icons.forum_rounded), label: 'Messages'),
            ],
          ),
        ),
      ]),
    );
  }
}

class _SelectedProfilesTab extends StatefulWidget {
  const _SelectedProfilesTab();

  @override
  State<_SelectedProfilesTab> createState() => _SelectedProfilesTabState();
}

class _SelectedProfilesTabState extends State<_SelectedProfilesTab> {
  int _profileIndex = 0;

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final selectedIds = game.selectedSuspectIds;
    if (selectedIds.isEmpty) return const Center(child: Text('No profiles selected yet.', style: TextStyle(color: muted)));
    final index = _profileIndex.clamp(0, selectedIds.length - 1).toInt();
    final profile = game.profileById(selectedIds[index]);
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth > 700;
      final gallery = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [PlaceholderPhoto(profile: profile), const SizedBox(height: 12), GogglesButton(onPressed: () => GogglesDialog.show(context, profile))]);
      final details = _ProfileDetails(profile: profile);
      return Stack(
        fit: StackFit.expand,
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 82),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('SELECTED PROFILE  ${index + 1} OF ${selectedIds.length}', style: const TextStyle(color: aqua, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.3)),
              const SizedBox(height: 10),
              if (wide) Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 5, child: gallery), const SizedBox(width: 20), Expanded(flex: 6, child: details)]) else ...[gallery, const SizedBox(height: 18), details],
            ]),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: ProfileActionButton(label: 'Previous Profile', icon: Icons.arrow_back_rounded, accent: aqua, backgroundColor: panel, horizontal: true, onPressed: index > 0 ? () => setState(() => _profileIndex = index - 1) : null)),
              const SizedBox(width: 10),
              Expanded(child: ProfileActionButton(label: 'Next Profile', icon: Icons.arrow_forward_rounded, accent: aqua, backgroundColor: panel, horizontal: true, onPressed: index < selectedIds.length - 1 ? () => setState(() => _profileIndex = index + 1) : null)),
            ]),
          ),
        ],
      );
    });
  }
}

class _InboxMessagesTab extends StatelessWidget {
  const _InboxMessagesTab();

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    return ListView(
      padding: const EdgeInsets.only(bottom: 4),
      children: [
        const SectionCard(color: Color(0xFF121C2E), child: Row(children: [Icon(Icons.forum_outlined, color: aqua), SizedBox(width: 12), Expanded(child: Text('Your matches are waiting. Every conversation has three short stages and two ways to respond.', style: TextStyle(color: muted, height: 1.4)))])),
        const SizedBox(height: 16),
        ...game.selectedSuspectIds.map((id) => _InboxTile(profile: game.profileById(id), complete: game.isConversationComplete(id), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatScreen(profileId: id))))),
      ],
    );
  }
}

class _InboxTile extends StatelessWidget {
  const _InboxTile({required this.profile, required this.complete, required this.onTap});
  final Profile profile; final bool complete; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 12), child: InkWell(borderRadius: BorderRadius.circular(22), onTap: onTap, child: SectionCard(child: Row(children: [Container(width: 54, height: 54, decoration: BoxDecoration(color: coral.withValues(alpha: .16), borderRadius: BorderRadius.circular(17)), child: Center(child: Text(profile.name.substring(0, 1), style: const TextStyle(color: coral, fontSize: 22, fontWeight: FontWeight.w900)))), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${profile.name}, ${profile.age}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)), const SizedBox(height: 5), Text(complete ? 'Conversation complete' : 'Reply waiting · stage ${complete ? 3 : 1} of 3', style: const TextStyle(color: muted))])), Icon(complete ? Icons.check_circle : Icons.chevron_right_rounded, color: complete ? aqua : muted)]))));
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.profileId});
  final String profileId;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _completionScrollScheduled = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final profile = game.profileById(widget.profileId);
    final conversation = game.conversationFor(widget.profileId);
    final complete = game.isConversationComplete(widget.profileId);
    final stageIndex = game.stageIndexFor(widget.profileId);
    final history = game.conversationHistory[widget.profileId] ?? const <ChatEntry>[];
    if (complete && !_completionScrollScheduled) {
      _completionScrollScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scrollController.hasClients) {
          _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 220), curve: Curves.easeOut);
        }
      });
    } else if (!complete) {
      _completionScrollScheduled = false;
    }
    return PageFrame(title: '${profile.name}, ${profile.age}', subtitle: profile.occupation, action: _CaseHeaderActions(leading: IconButton(tooltip: 'Close conversation', onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close))), child: Column(children: [
      Expanded(child: ListView(controller: _scrollController, children: [
        Row(children: [const Icon(Icons.lock_outline, size: 15, color: aqua), const SizedBox(width: 7), Text('PRIVATE MATCH  ·  STAGE ${complete ? 3 : stageIndex + 1} / 3', style: const TextStyle(color: aqua, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1))]),
        const SizedBox(height: 16),
        ...history.map((entry) => ChatBubble(entry: entry)),
        if (!complete) ChatBubble(entry: ChatEntry(isPlayer: false, text: conversation.stages[stageIndex].suspectMessage)),
      ])),
      if (complete) Padding(padding: const EdgeInsets.only(top: 12), child: SectionCard(child: Column(children: [const Icon(Icons.check_circle_outline, color: aqua, size: 29), const SizedBox(height: 8), const Text('Conversation complete', style: TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 10), PrimaryButton(label: 'Back to inbox', onPressed: () => Navigator.of(context).pop(), outlined: true)])))
      else ...conversation.stages[stageIndex].responseOptions.map((option) => Padding(padding: const EdgeInsets.only(top: 8), child: SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () => game.chooseResponse(widget.profileId, option.id), child: Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Text(option.playerText))))))],));
  }
}

class AccusationScreen extends StatelessWidget {
  const AccusationScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    return PageFrame(title: 'Who is the killer?', subtitle: 'Choose wisely. Justice depends on you.', action: const _CaseHeaderActions(), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Expanded(child: ListView(children: game.selectedSuspectIds.map((id) { final profile = game.profileById(id); final selected = id == game.selectedAccusationId; return Padding(padding: const EdgeInsets.only(bottom: 12), child: InkWell(borderRadius: BorderRadius.circular(22), onTap: () => game.selectAccusation(id), child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: selected ? coral.withValues(alpha: .16) : panel, borderRadius: BorderRadius.circular(22), border: Border.all(color: selected ? coral : Colors.white.withValues(alpha: .07), width: selected ? 2 : 1)), child: Row(children: [SizedBox(width: 74, child: PlaceholderPhoto(profile: profile)), const SizedBox(width: 15), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${profile.name}, ${profile.age}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)), const SizedBox(height: 5), Text(profile.occupation, style: const TextStyle(color: muted)), const SizedBox(height: 12), Text(selected ? 'SELECTED FOR ACCUSATION' : 'Tap to select', style: TextStyle(color: selected ? coral : muted, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1))])), Icon(selected ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: selected ? coral : muted)])))); }).toList())),
      PrimaryButton(label: 'Confirm accusation', icon: Icons.gavel_rounded, onPressed: game.selectedAccusationId == null ? null : () => _confirm(context)),
    ]));
  }
  void _confirm(BuildContext context) {
    final game = GameScope.of(context);
    final profile = game.profileById(game.selectedAccusationId!);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: const Color(0xFF101827),
        elevation: 18,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28), side: BorderSide(color: coral.withValues(alpha: .65), width: 1.5)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Container(width: 54, height: 54, decoration: BoxDecoration(color: coral.withValues(alpha: .16), borderRadius: BorderRadius.circular(17), border: Border.all(color: coral.withValues(alpha: .55))), child: const Icon(Icons.gavel_rounded, color: coral, size: 28)),
              const SizedBox(width: 14),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('FINAL DECISION', style: TextStyle(color: coral, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.6)), SizedBox(height: 5), Text('Confirm accusation', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900))])),
            ]),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: coral.withValues(alpha: .09), borderRadius: BorderRadius.circular(18), border: Border.all(color: coral.withValues(alpha: .3))),
              child: Row(children: [
                const Icon(Icons.person_search_rounded, color: coral, size: 26),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('ACCUSED PROFILE', style: TextStyle(color: muted, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2)), const SizedBox(height: 4), Text('${profile.name}, ${profile.age}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)), Text(profile.occupation, style: const TextStyle(color: muted, fontSize: 12))])),
              ]),
            ),
            const SizedBox(height: 16),
            const Text('This decision cannot be undone for this attempt.', style: TextStyle(color: muted, height: 1.4)),
            const SizedBox(height: 22),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: () => Navigator.of(dialogContext).pop(), style: OutlinedButton.styleFrom(foregroundColor: coral, side: BorderSide(color: coral.withValues(alpha: .7)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), padding: const EdgeInsets.symmetric(vertical: 14)), child: const Text('Review again'))),
              const SizedBox(width: 10),
              Expanded(child: FilledButton(onPressed: () { Navigator.of(dialogContext).pop(); game.submitAccusation(); }, style: FilledButton.styleFrom(backgroundColor: coral, foregroundColor: ink, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), padding: const EdgeInsets.symmetric(vertical: 14)), child: const Text('Submit accusation'))),
            ]),
          ]),
        ),
      ),
    );
  }
}

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key, required this.won});
  final bool won;
  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    return PageFrame(child: Center(child: SingleChildScrollView(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      won ? const CaseClosedScene() : const CaseDismissedScene(),
      const SizedBox(height: 24),
      Text(won ? 'CASE CLOSED' : 'WRONG SUSPECT', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900, color: won ? aqua : coral), textAlign: TextAlign.center),
      const SizedBox(height: 14),
      Text(won ? 'You found the killer.' : 'Your accusation could not be proven. The killer remains free.', style: const TextStyle(color: muted, fontSize: 17), textAlign: TextAlign.center),
      const SizedBox(height: 30),
      MenuActionButton(label: won ? 'Continue to next case' : 'Retry case', icon: won ? Icons.arrow_forward : Icons.replay, primary: true, onPressed: won ? game.continueToNextCase : game.retryCase),
      const SizedBox(height: 10),
      MenuActionButton(label: 'Return to main menu', icon: Icons.home_rounded, onPressed: game.returnToMainMenu),
    ]))));
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
