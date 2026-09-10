import 'package:flutter/material.dart';
import 'models.dart';

const ink = Color(0xFF0C1220);
const panel = Color(0xFF151E31);
const muted = Color(0xFF98A5BA);
const coral = Color(0xFFE97964);
const aqua = Color(0xFF6ED5C8);

class PageFrame extends StatelessWidget {
  const PageFrame(
      {super.key,
      required this.child,
      this.title,
      this.subtitle,
      this.subtitleAction,
      this.leading,
      this.action,
      this.centerTitle = false});
  final Widget child;
  final String? title;
  final String? subtitle;
  final Widget? subtitleAction;
  final Widget? leading;
  final Widget? action;
  final bool centerTitle;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (title != null) ...[
                      Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            if (leading != null) leading!,
                            Expanded(
                                child: Text(title!,
                                    textAlign: centerTitle
                                        ? TextAlign.center
                                        : TextAlign.start,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                            fontWeight: FontWeight.w800))),
                            if (action != null) action!,
                          ]),
                      if (subtitle != null || subtitleAction != null) ...[
                        const SizedBox(height: 5),
                        Row(children: [
                          if (subtitle != null)
                            Expanded(
                                child: Text(subtitle!,
                                    style: const TextStyle(color: muted),
                                    maxLines: subtitle!.contains('\n') ? 2 : 1,
                                    overflow: TextOverflow.ellipsis)),
                          if (subtitleAction != null) ...[
                            if (subtitle != null) const SizedBox(width: 10),
                            subtitleAction!
                          ],
                        ]),
                      ],
                    ],
                    if (title != null) const SizedBox(height: 18),
                    Expanded(child: child),
                  ]),
            ),
          ),
        ),
      ),
    );
  }
}

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.compact = false});
  final bool compact;
  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        ClipRRect(
            borderRadius: BorderRadius.circular(compact ? 11 : 14),
            child: Image.asset('assets/logo.jpg',
                width: compact ? 54 : 64,
                height: compact ? 54 : 64,
                fit: BoxFit.cover,
                semanticLabel: 'Find a Serial Killer app logo')),
        const SizedBox(width: 10),
        Text('FIND A',
            style: TextStyle(
                fontSize: compact ? 30 : 35,
                fontWeight: FontWeight.w400,
                letterSpacing: 2.2,
                color: Colors.white)),
      ]);
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton(
      {super.key,
      required this.label,
      required this.onPressed,
      this.icon,
      this.outlined = false,
      this.expand = true});
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool outlined;
  final bool expand;
  @override
  Widget build(BuildContext context) {
    final button = outlined
        ? OutlinedButton.icon(
            onPressed: onPressed,
            icon: icon == null ? const SizedBox.shrink() : Icon(icon),
            label: Text(label))
        : FilledButton.icon(
            onPressed: onPressed,
            icon: icon == null ? const SizedBox.shrink() : Icon(icon),
            label: Text(label));
    return SizedBox(
        width: expand ? double.infinity : null, height: 52, child: button);
  }
}

class MenuActionButton extends StatefulWidget {
  const MenuActionButton(
      {super.key,
      required this.label,
      required this.onPressed,
      this.icon,
      this.primary = false,
      this.showChevron = true,
      this.centerContent = false});
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool primary;
  final bool showChevron;
  final bool centerContent;

  @override
  State<MenuActionButton> createState() => _MenuActionButtonState();
}

class _MenuActionButtonState extends State<MenuActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final accent = widget.primary ? coral : aqua;
    final background = widget.primary
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE97964), Color(0xFFB9404B)])
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [panel.withValues(alpha: .96), const Color(0xFF101827)]);

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: enabled ? (_) => setState(() => _hovered = true) : null,
        onExit: enabled ? (_) => setState(() => _hovered = false) : null,
        child: AnimatedScale(
          scale: _hovered ? 1.012 : 1,
          duration: const Duration(milliseconds: 140),
          child: SizedBox(
            width: double.infinity,
            height: 64,
            child: Material(
              color: Colors.transparent,
              child: Ink(
                decoration: BoxDecoration(
                  gradient: enabled ? background : null,
                  color: enabled ? null : Colors.white.withValues(alpha: .035),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                      color: enabled
                          ? accent.withValues(alpha: widget.primary ? .95 : .72)
                          : Colors.white.withValues(alpha: .12),
                      width: _hovered ? 1.6 : 1),
                  boxShadow: enabled
                      ? [
                          BoxShadow(
                              color: accent.withValues(
                                  alpha: widget.primary ? .28 : .12),
                              blurRadius: _hovered ? 20 : 11,
                              spreadRadius: _hovered ? 1 : 0,
                              offset: const Offset(0, 6))
                        ]
                      : const [],
                ),
                child: InkWell(
                  onTap: widget.onPressed,
                  onHover: (value) => setState(() => _hovered = value),
                  borderRadius: BorderRadius.circular(18),
                  splashColor: accent.withValues(alpha: .22),
                  highlightColor: accent.withValues(alpha: .08),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (widget.centerContent)
                          Center(
                              child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                      color: widget.primary
                                          ? Colors.black.withValues(alpha: .16)
                                          : accent.withValues(alpha: .13),
                                      borderRadius: BorderRadius.circular(11)),
                                  child: Icon(
                                      widget.icon ??
                                          Icons.arrow_forward_rounded,
                                      color: widget.primary
                                          ? Colors.white
                                          : accent,
                                      size: 21),
                                ),
                                const SizedBox(width: 10),
                                Text(widget.label.toUpperCase(),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: enabled ? Colors.white : muted,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.7)),
                              ]))
                        else ...[
                          Center(
                              child: Text(widget.label.toUpperCase(),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: enabled ? Colors.white : muted,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.7))),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                  color: widget.primary
                                      ? Colors.black.withValues(alpha: .16)
                                      : accent.withValues(alpha: .13),
                                  borderRadius: BorderRadius.circular(11)),
                              child: Icon(
                                  widget.icon ?? Icons.arrow_forward_rounded,
                                  color: widget.primary ? Colors.white : accent,
                                  size: 21),
                            ),
                          ),
                        ],
                        if (widget.showChevron && !widget.centerContent)
                          Align(
                              alignment: Alignment.centerRight,
                              child: Icon(Icons.chevron_right_rounded,
                                  color: enabled
                                      ? (widget.primary
                                          ? Colors.white70
                                          : accent)
                                      : muted,
                                  size: 25)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ProfileActionButton extends StatefulWidget {
  const ProfileActionButton(
      {super.key,
      required this.label,
      required this.icon,
      required this.accent,
      required this.onPressed,
      this.primary = false,
      this.backgroundColor,
      this.horizontal = false});
  final String label;
  final IconData icon;
  final Color accent;
  final VoidCallback? onPressed;
  final bool primary;
  final Color? backgroundColor;
  final bool horizontal;

  @override
  State<ProfileActionButton> createState() => _ProfileActionButtonState();
}

class _ProfileActionButtonState extends State<ProfileActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final radius = BorderRadius.circular(24);
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: enabled ? (_) => setState(() => _hovered = true) : null,
        onExit: enabled ? (_) => setState(() => _hovered = false) : null,
        child: AnimatedScale(
          scale: _hovered ? 1.025 : 1,
          duration: const Duration(milliseconds: 140),
          child: SizedBox(
            height: 66,
            child: Material(
              color: Colors.transparent,
              child: Ink(
                decoration: BoxDecoration(
                  gradient: enabled && widget.primary
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                              widget.accent,
                              Color.lerp(widget.accent, ink, .36)!
                            ])
                      : null,
                  color: widget.backgroundColor ??
                      (enabled && !widget.primary
                          ? widget.accent.withValues(alpha: .08)
                          : (!enabled
                              ? Colors.white.withValues(alpha: .035)
                              : null)),
                  borderRadius: radius,
                  border: Border.all(
                      color: enabled
                          ? widget.accent
                              .withValues(alpha: widget.primary ? .95 : .7)
                          : Colors.white.withValues(alpha: .12),
                      width: _hovered ? 1.6 : 1),
                  boxShadow: enabled
                      ? [
                          BoxShadow(
                              color: widget.accent
                                  .withValues(alpha: widget.primary ? .25 : .1),
                              blurRadius: _hovered ? 16 : 8,
                              offset: const Offset(0, 5))
                        ]
                      : const [],
                ),
                child: InkWell(
                  onTap: widget.onPressed,
                  onHover: (value) => setState(() => _hovered = value),
                  borderRadius: radius,
                  splashColor: widget.accent.withValues(alpha: .22),
                  highlightColor: widget.accent.withValues(alpha: .08),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                    child: widget.horizontal
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                                Icon(widget.icon,
                                    color: enabled
                                        ? (widget.primary
                                            ? Colors.white
                                            : widget.accent)
                                        : muted,
                                    size: 22),
                                const SizedBox(width: 8),
                                Flexible(
                                    child: Text(widget.label,
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            color: enabled
                                                ? (widget.primary
                                                    ? Colors.white
                                                    : Colors.white70)
                                                : muted,
                                            fontSize: 12,
                                            height: 1.05,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: .25))),
                              ])
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                                Icon(widget.icon,
                                    color: enabled
                                        ? (widget.primary
                                            ? Colors.white
                                            : widget.accent)
                                        : muted,
                                    size: 20),
                                const SizedBox(height: 2),
                                Text(widget.label,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        color: enabled
                                            ? (widget.primary
                                                ? Colors.white
                                                : Colors.white70)
                                            : muted,
                                        fontSize: 10,
                                        height: 1.05,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: .35)),
                              ]),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  const SectionCard(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(18),
      this.color = panel});
  final Widget child;
  final EdgeInsets padding;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
      padding: padding,
      decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: .07))),
      child: child);
}

class PlaceholderPhoto extends StatefulWidget {
  const PlaceholderPhoto({super.key, required this.profile, this.height});
  final Profile profile;
  final double? height;
  @override
  State<PlaceholderPhoto> createState() => _PlaceholderPhotoState();
}

class _PlaceholderPhotoState extends State<PlaceholderPhoto> {
  int index = 0;
  @override
  Widget build(BuildContext context) {
    final color = [
      const Color(0xFF354667),
      const Color(0xFF684B59),
      const Color(0xFF35605E)
    ][index % 3];
    return GestureDetector(
      onTap: () =>
          setState(() => index = (index + 1) % widget.profile.photos.length),
      onHorizontalDragEnd: (details) => setState(() => index =
          (details.primaryVelocity ?? 0) < 0
              ? (index + 1) % widget.profile.photos.length
              : (index - 1 + widget.profile.photos.length) %
                  widget.profile.photos.length),
      child: AspectRatio(
        aspectRatio: 0.88,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(26),
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color, ink])),
          child: LayoutBuilder(builder: (context, constraints) {
            final compact = constraints.maxWidth < 140;
            final iconSize = compact ? 38.0 : 82.0;
            final gap = compact ? 5.0 : 14.0;
            final idSize = compact ? 14.0 : 28.0;
            final photoSize = compact ? 9.0 : 14.0;
            return Stack(children: [
              Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.person_outline_rounded,
                    size: iconSize, color: Colors.white.withValues(alpha: .72)),
                SizedBox(height: gap),
                Text(widget.profile.id.toUpperCase(),
                    style: TextStyle(
                        fontSize: idSize,
                        fontWeight: FontWeight.w900,
                        letterSpacing: compact ? 1 : 3)),
                Text('PHOTO ${index + 1}',
                    style: TextStyle(
                        color: aqua,
                        fontSize: photoSize,
                        fontWeight: FontWeight.bold,
                        letterSpacing: compact ? .8 : 2))
              ])),
              Positioned(
                  top: compact ? 8 : 14,
                  left: compact ? 8 : 14,
                  right: compact ? 8 : 14,
                  child: Row(
                      children: List.generate(
                          widget.profile.photos.length,
                          (dot) => Expanded(
                              child: Container(
                                  height: compact ? 3 : 4,
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 2),
                                  decoration: BoxDecoration(
                                      color: dot == index
                                          ? Colors.white
                                          : Colors.white.withValues(alpha: .25),
                                      borderRadius:
                                          BorderRadius.circular(4))))))),
              if (!compact)
                const Positioned(
                    bottom: 15,
                    left: 17,
                    child: Text('Tap or swipe to browse',
                        style: TextStyle(color: Colors.white70, fontSize: 11))),
            ]);
          }),
        ),
      ),
    );
  }
}

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key, required this.profile});
  final Profile profile;
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${profile.name}, ${profile.age}',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 5),
        Text('${profile.occupation}  ·  ${profile.location}',
            style: const TextStyle(color: muted)),
      ]);
}

class InterestChips extends StatelessWidget {
  const InterestChips({super.key, required this.interests});
  final List<String> interests;
  @override
  Widget build(BuildContext context) => Wrap(
      spacing: 8,
      runSpacing: 8,
      children: interests
          .map((interest) => Chip(
              label: Text(interest),
              side: BorderSide.none,
              backgroundColor: const Color(0xFF24314A)))
          .toList());
}

class GogglesDialog extends StatelessWidget {
  const GogglesDialog(
      {super.key, required this.profile, this.conversationComplete = false});
  final Profile profile;
  final bool conversationComplete;
  static Future<void> show(BuildContext context, Profile profile,
          {bool conversationComplete = false}) =>
      showDialog<void>(
          context: context,
          builder: (_) => GogglesDialog(
              profile: profile, conversationComplete: conversationComplete));
  ClueDefinition? _firstClue(ClueSource source) {
    for (final clue in profile.clues) {
      if (clue.source == source) return clue;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final scanClue = _firstClue(ClueSource.goggles);
    final profileClue =
        _firstClue(ClueSource.profile) ?? _firstClue(ClueSource.question);
    final photoClue = _firstClue(ClueSource.photo);
    final conversationClue = _firstClue(ClueSource.conversation);

    return Dialog(
      backgroundColor: const Color(0xFF0A111B),
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: aqua.withValues(alpha: .4))),
      child: ConstrainedBox(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .84),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                      color: aqua.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: aqua.withValues(alpha: .45))),
                  child:
                      const Icon(Icons.radar_rounded, color: aqua, size: 27)),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    const Text('GOGGLES INTELLIGENCE',
                        style: TextStyle(
                            color: aqua,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.1)),
                    const SizedBox(height: 5),
                    Text('${profile.name} · ${profile.id.toUpperCase()}',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w900)),
                  ])),
              IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: muted)),
            ]),
            const SizedBox(height: 16),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 850),
              builder: (_, value, child) => Column(children: [
                LinearProgressIndicator(
                    value: value, color: aqua, backgroundColor: Colors.white12),
                const SizedBox(height: 6),
                Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                        value < 1
                            ? 'Decrypting profile data…'
                            : 'Scan complete',
                        style: const TextStyle(color: muted, fontSize: 11))),
              ]),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                  child: _GoggleMetric(
                      icon: Icons.people_alt_outlined,
                      value: '${profile.gogglesData.activeConnections}',
                      label: 'ACTIVE CONTACTS')),
              const SizedBox(width: 10),
              Expanded(
                  child: _GoggleMetric(
                      icon: Icons.person_off_outlined,
                      value: '${profile.gogglesData.inactiveFormerConnections}',
                      label: 'FORMER CONTACTS')),
            ]),
            const SizedBox(height: 10),
            _GogglesInfoSection(
                icon: Icons.schedule_outlined,
                title: 'LAST ACTIVE',
                body: profile.gogglesData.lastActive),
            _GogglesInfoSection(
                icon: Icons.timeline_rounded,
                title: 'ACTIVITY TRACE',
                body: scanClue?.description ??
                    'Connection activity appears ordinary for this profile.'),
            _GogglesUnlockBanner(unlocked: conversationComplete),
            _GogglesInfoSection(
                icon: Icons.manage_search_rounded,
                title: 'PROFILE CROSS-CHECK',
                body: profileClue?.description ??
                    'No direct contradiction surfaced in the profile data.',
                locked: !conversationComplete),
            _GogglesInfoSection(
                icon: Icons.photo_camera_back_outlined,
                title: 'PHOTO METADATA',
                body: photoClue?.description ??
                    'No unusual photo metadata surfaced in this scan.',
                locked: !conversationComplete),
            _GogglesInfoSection(
                icon: Icons.forum_outlined,
                title: 'CONVERSATION CROSS-CHECK',
                body: conversationClue?.description ??
                    'No conversation anomaly detected yet. Revisit this profile after questioning.',
                locked: !conversationComplete),
            const Text(
                'This is a lead, not proof. Compare it with the profile, photos, and conversation.',
                style: TextStyle(color: muted, height: 1.4, fontSize: 12)),
            const SizedBox(height: 16),
            PrimaryButton(
                label: 'Close scan',
                onPressed: () => Navigator.of(context).pop(),
                outlined: true),
          ]),
        ),
      ),
    );
  }
}

class _GoggleMetric extends StatelessWidget {
  const _GoggleMetric(
      {required this.icon, required this.value, required this.label});
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
            color: panel,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: .07))),
        child: Row(children: [
          Icon(icon, color: aqua, size: 20),
          const SizedBox(width: 9),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(value,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w900)),
                Text(label,
                    style: const TextStyle(
                        color: muted,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .6))
              ])),
        ]),
      );
}

class _GogglesInfoSection extends StatelessWidget {
  const _GogglesInfoSection(
      {required this.icon,
      required this.title,
      required this.body,
      this.locked = false});
  final IconData icon;
  final String title;
  final String body;
  final bool locked;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
            color: panel,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: .07))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(locked ? Icons.lock_outline_rounded : icon,
              color: locked ? muted : aqua, size: 21),
          const SizedBox(width: 11),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title,
                    style: TextStyle(
                        color: locked ? muted : aqua,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1)),
                const SizedBox(height: 5),
                Text(
                    locked
                        ? 'Complete this profile’s conversation to decrypt this evidence.'
                        : body,
                    style: TextStyle(
                        color: locked ? muted : Colors.white,
                        fontSize: 12,
                        height: 1.35)),
              ])),
        ]),
      );
}

class _GogglesUnlockBanner extends StatelessWidget {
  const _GogglesUnlockBanner({required this.unlocked});
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    final color = unlocked ? aqua : coral;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
          color: color.withValues(alpha: .10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: .35))),
      child: Row(children: [
        Icon(unlocked ? Icons.lock_open_rounded : Icons.lock_rounded,
            color: color, size: 21),
        const SizedBox(width: 10),
        Expanded(
            child: Text(
                unlocked
                    ? 'DEEP INTELLIGENCE UNLOCKED'
                    : 'DEEP INTELLIGENCE LOCKED',
                style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .9))),
        if (unlocked)
          const Icon(Icons.check_circle_outline_rounded, color: aqua, size: 18),
      ]),
    );
  }
}

class EvidenceBoardDialog extends StatelessWidget {
  const EvidenceBoardDialog(
      {super.key, required this.profiles, required this.completedProfileIds});
  final List<Profile> profiles;
  final Set<String> completedProfileIds;

  static Future<void> show(BuildContext context,
          {required List<Profile> profiles,
          required Set<String> completedProfileIds}) =>
      showDialog<void>(
        context: context,
        barrierColor: Colors.black.withValues(alpha: .88),
        builder: (_) => Dialog.fullscreen(
            child: EvidenceBoardDialog(
                profiles: profiles, completedProfileIds: completedProfileIds)),
      );

  List<Profile> get completedProfiles => profiles
      .where((profile) => completedProfileIds.contains(profile.id))
      .toList(growable: false);

  @override
  Widget build(BuildContext context) {
    final reviewedProfiles = completedProfiles;
    return Material(
      color: const Color(0xFF171316),
      child: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Row(children: [
              Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                      color: coral.withValues(alpha: .14),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: coral.withValues(alpha: .5))),
                  child: const Icon(Icons.account_tree_rounded,
                      color: coral, size: 25)),
              const SizedBox(width: 12),
              const Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('EVIDENCE BOARD',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w900)),
                    SizedBox(height: 3),
                    Text('Connections emerge as the interviews unfold.',
                        style: TextStyle(color: muted, fontSize: 12))
                  ])),
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                  decoration: BoxDecoration(
                      color: panel, borderRadius: BorderRadius.circular(20)),
                  child: Text(
                      '${reviewedProfiles.length} / ${profiles.length} CHATS',
                      style: const TextStyle(
                          color: aqua,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .7))),
            ]),
          ),
          Expanded(
              child: reviewedProfiles.isEmpty
                  ? const _EmptyEvidenceBoard()
                  : _EvidenceBoardCanvas(
                      profiles: reviewedProfiles, notesFor: _notesFor)),
          Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
              child: PrimaryButton(
                  label: 'Back to inbox',
                  icon: Icons.arrow_back_rounded,
                  onPressed: () => Navigator.of(context).pop())),
        ]),
      ),
    );
  }

  List<_EvidenceNoteData> _notesFor(Profile profile) {
    // The full activity trace belongs in Goggles. The board uses the short,
    // curated leads so it remains readable at a glance.
    final leadSummaries = profile.redHerrings
        .map((lead) => lead.trim())
        .where((lead) => lead.isNotEmpty)
        .take(3)
        .toList(growable: true);

    if (leadSummaries.isEmpty && profile.clues.isNotEmpty) {
      leadSummaries.add(_summarizeLead(profile.clues.first.description));
    }

    if (leadSummaries.isEmpty) {
      return const [
        _EvidenceNoteData(
          title: 'INTERVIEW NOTE',
          body: 'No direct contradiction surfaced in the available evidence.',
          color: Color(0xFFA8D9C8),
        ),
      ];
    }

    return [
      for (final summary in leadSummaries)
        _EvidenceNoteData(
          title: 'SUSPICIOUS LEAD',
          body: summary,
          color: const Color(0xFFF4CB72),
        ),
    ];
  }

  String _summarizeLead(String description) {
    const maxLength = 58;
    final compact = description.trim().replaceAll(RegExp(r'\s+'), ' ');
    final sentenceEnd = compact.indexOf('.');
    final firstThought =
        sentenceEnd > 0 ? compact.substring(0, sentenceEnd) : compact;
    if (firstThought.length <= maxLength) return firstThought;

    final wordBreak = firstThought.lastIndexOf(' ', maxLength);
    final cutAt = wordBreak > 20 ? wordBreak : maxLength;
    return '${firstThought.substring(0, cutAt).trim()}…';
  }
}

class _EmptyEvidenceBoard extends StatelessWidget {
  const _EmptyEvidenceBoard();

  @override
  Widget build(BuildContext context) => Center(
          child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Stack(clipBehavior: Clip.none, children: [
            Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                    color: const Color(0xFF2A2020),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: coral.withValues(alpha: .5))),
                child: const Icon(Icons.push_pin_outlined,
                    color: coral, size: 42)),
            const Positioned(
                right: -8,
                top: -8,
                child: Icon(Icons.push_pin_rounded,
                    color: Color(0xFFF4CB72), size: 30)),
          ]),
          const SizedBox(height: 22),
          const Text('Your board is empty.',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              textAlign: TextAlign.center),
          const SizedBox(height: 10),
          const Text(
              'Complete a suspect conversation to uncover evidence and draw the first connection.',
              style: TextStyle(color: muted, height: 1.45),
              textAlign: TextAlign.center),
        ]),
      ));
}

class _EvidenceBoardCanvas extends StatelessWidget {
  const _EvidenceBoardCanvas({required this.profiles, required this.notesFor});
  final List<Profile> profiles;
  final List<_EvidenceNoteData> Function(Profile profile) notesFor;

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        const rowHeight = 270.0;
        final boardHeight = profiles.length * rowHeight + 18;
        final profileWidth =
            (constraints.maxWidth * .31).clamp(98.0, 128.0).toDouble();
        final noteLeft =
            (constraints.maxWidth * .40).clamp(126.0, 190.0).toDouble();
        final notesByProfile = profiles.map(notesFor).toList(growable: false);
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Container(
            height: boardHeight,
            decoration: BoxDecoration(
                color: const Color(0xFF46352C),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF906145), width: 2),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black54,
                      blurRadius: 16,
                      offset: Offset(0, 8))
                ]),
            child: CustomPaint(
              painter: _EvidenceThreadPainter(
                  noteCounts: notesByProfile
                      .map((notes) => notes.length)
                      .toList(growable: false),
                  rowHeight: rowHeight,
                  profileAnchor: profileWidth + 18,
                  noteAnchor: noteLeft),
              child: Stack(children: [
                for (var index = 0; index < profiles.length; index++) ...[
                  Positioned(
                      left: 12,
                      top: index * rowHeight + 24,
                      width: profileWidth,
                      child: _BoardProfileCard(profile: profiles[index])),
                  Positioned(
                      left: noteLeft,
                      right: 12,
                      top: index * rowHeight + 10,
                      child: _BoardNoteStack(notes: notesByProfile[index])),
                ],
              ]),
            ),
          ),
        );
      });
}

class _BoardProfileCard extends StatelessWidget {
  const _BoardProfileCard({required this.profile});
  final Profile profile;

  @override
  Widget build(BuildContext context) =>
      Stack(clipBehavior: Clip.none, children: [
        Transform.rotate(
            angle: -.025,
            child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                    color: const Color(0xFF151E31),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: .16)),
                    boxShadow: const [
                      BoxShadow(
                          color: Colors.black45,
                          blurRadius: 6,
                          offset: Offset(2, 4))
                    ]),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ClipRRect(
                          borderRadius: BorderRadius.circular(7),
                          child: AspectRatio(
                              aspectRatio: 1.05,
                              child: Image.asset(profile.photos.first,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                      color: const Color(0xFF354667),
                                      child: const Icon(
                                          Icons.person_outline_rounded,
                                          color: Colors.white70,
                                          size: 36))))),
                      const SizedBox(height: 7),
                      Text(profile.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 2),
                      Text(profile.id.toUpperCase(),
                          style: const TextStyle(
                              color: aqua,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1)),
                    ]))),
        const Positioned(
            top: -12,
            left: 0,
            right: 0,
            child: Center(child: _ThumbPin(color: coral))),
      ]);
}

class _BoardNoteStack extends StatelessWidget {
  const _BoardNoteStack({required this.notes});
  final List<_EvidenceNoteData> notes;

  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (var index = 0; index < notes.length; index++)
          Padding(
            padding: EdgeInsets.only(
                left: (index % 2) * 8.0,
                right: (index % 2) * 2.0,
                bottom: index == notes.length - 1 ? 0 : 6),
            child: SizedBox(
                height: 78,
                child: Transform.rotate(
                    angle: index.isEven ? .018 : -.025,
                    child: _StickyNote(note: notes[index]))),
          ),
      ]);
}

class _StickyNote extends StatelessWidget {
  const _StickyNote({required this.note});
  final _EvidenceNoteData note;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 9),
        decoration: BoxDecoration(
            color: note.color,
            borderRadius: BorderRadius.circular(3),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black45, blurRadius: 5, offset: Offset(2, 4))
            ]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(note.title,
              style: const TextStyle(
                  color: Color(0xFF3B2525),
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .8)),
          const SizedBox(height: 5),
          Text(note.body,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Color(0xFF302427),
                  fontSize: 10,
                  height: 1.18,
                  fontWeight: FontWeight.w600)),
        ]),
      );
}

class _ThumbPin extends StatelessWidget {
  const _ThumbPin({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white70, width: 1.5),
          boxShadow: const [
            BoxShadow(
                color: Colors.black54, blurRadius: 4, offset: Offset(1, 2))
          ]));
}

class _EvidenceNoteData {
  const _EvidenceNoteData(
      {required this.title, required this.body, required this.color});
  final String title;
  final String body;
  final Color color;
}

class _EvidenceThreadPainter extends CustomPainter {
  const _EvidenceThreadPainter(
      {required this.noteCounts,
      required this.rowHeight,
      required this.profileAnchor,
      required this.noteAnchor});
  final List<int> noteCounts;
  final double rowHeight;
  final double profileAnchor;
  final double noteAnchor;

  @override
  void paint(Canvas canvas, Size size) {
    final thread = Paint()
      ..color = const Color(0xFFB43F4A)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: .3)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;
    for (var row = 0; row < noteCounts.length; row++) {
      for (var note = 0; note < noteCounts[row]; note++) {
        final start = Offset(profileAnchor, row * rowHeight + 78 + note * 5);
        final end = Offset(noteAnchor + (note.isEven ? 0 : 8),
            row * rowHeight + 10 + note * 84 + 39);
        final control = Offset((start.dx + end.dx) / 2,
            (start.dy + end.dy) / 2 - (note == 1 ? 14 : 0));
        final path = Path()
          ..moveTo(start.dx, start.dy)
          ..quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);
        canvas.drawPath(path, shadow);
        canvas.drawPath(path, thread);
        canvas.drawCircle(start, 4, Paint()..color = const Color(0xFFD95A5A));
        canvas.drawCircle(end, 4, Paint()..color = const Color(0xFFD95A5A));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _EvidenceThreadPainter oldDelegate) =>
      oldDelegate.noteCounts.length != noteCounts.length ||
      oldDelegate.noteCounts.toString() != noteCounts.toString() ||
      oldDelegate.rowHeight != rowHeight ||
      oldDelegate.profileAnchor != profileAnchor ||
      oldDelegate.noteAnchor != noteAnchor;
}

class SuspectCounter extends StatelessWidget {
  const SuspectCounter({super.key, required this.count});
  final int count;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
          color: coral.withValues(alpha: .14),
          borderRadius: BorderRadius.circular(30)),
      child: Text('SUSPECTS SELECTED  $count / 3',
          style: const TextStyle(
              color: coral,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: .8)));
}

class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.entry});
  final ChatEntry entry;
  @override
  Widget build(BuildContext context) => Align(
      alignment: entry.isPlayer ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
          constraints: const BoxConstraints(maxWidth: 310),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          decoration: BoxDecoration(
              color: entry.isPlayer ? coral : panel,
              borderRadius: BorderRadius.circular(18).copyWith(
                  bottomRight: entry.isPlayer ? const Radius.circular(4) : null,
                  bottomLeft:
                      entry.isPlayer ? null : const Radius.circular(4))),
          child: Text(entry.text,
              style: TextStyle(
                  color: entry.isPlayer ? ink : Colors.white, height: 1.35))));
}
