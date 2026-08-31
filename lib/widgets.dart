import 'package:flutter/material.dart';
import 'models.dart';

const ink = Color(0xFF0C1220);
const panel = Color(0xFF151E31);
const muted = Color(0xFF98A5BA);
const coral = Color(0xFFE97964);
const aqua = Color(0xFF6ED5C8);

class PageFrame extends StatelessWidget {
  const PageFrame({super.key, required this.child, this.title, this.subtitle, this.subtitleAction, this.leading, this.action, this.centerTitle = false});
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
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                if (title != null) ...[
                  Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                    if (leading != null) leading!,
                    Expanded(child: Text(title!, textAlign: centerTitle ? TextAlign.center : TextAlign.start, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800))),
                    if (action != null) action!,
                  ]),
                  if (subtitle != null || subtitleAction != null) ...[
                    const SizedBox(height: 5),
                    Row(children: [
                      if (subtitle != null) Expanded(child: Text(subtitle!, style: const TextStyle(color: muted), maxLines: subtitle!.contains('\n') ? 2 : 1, overflow: TextOverflow.ellipsis)),
                      if (subtitleAction != null) ...[if (subtitle != null) const SizedBox(width: 10), subtitleAction!],
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
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    ClipRRect(borderRadius: BorderRadius.circular(compact ? 11 : 14), child: Image.asset('assets/logo.jpg', width: compact ? 54 : 64, height: compact ? 54 : 64, fit: BoxFit.cover, semanticLabel: 'Find a Serial Killer app logo')),
    const SizedBox(width: 10),
    Text('FIND A', style: TextStyle(fontSize: compact ? 30 : 35, fontWeight: FontWeight.w400, letterSpacing: 2.2, color: Colors.white)),
  ]);
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key, required this.label, required this.onPressed, this.icon, this.outlined = false, this.expand = true});
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool outlined;
  final bool expand;
  @override
  Widget build(BuildContext context) {
    final button = outlined
      ? OutlinedButton.icon(onPressed: onPressed, icon: icon == null ? const SizedBox.shrink() : Icon(icon), label: Text(label))
      : FilledButton.icon(onPressed: onPressed, icon: icon == null ? const SizedBox.shrink() : Icon(icon), label: Text(label));
    return SizedBox(width: expand ? double.infinity : null, height: 52, child: button);
  }
}

class MenuActionButton extends StatefulWidget {
  const MenuActionButton({super.key, required this.label, required this.onPressed, this.icon, this.primary = false, this.showChevron = true, this.centerContent = false});
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
        ? const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFE97964), Color(0xFFB9404B)])
        : LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [panel.withValues(alpha: .96), const Color(0xFF101827)]);

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
                  border: Border.all(color: enabled ? accent.withValues(alpha: widget.primary ? .95 : .72) : Colors.white.withValues(alpha: .12), width: _hovered ? 1.6 : 1),
                  boxShadow: enabled ? [BoxShadow(color: accent.withValues(alpha: widget.primary ? .28 : .12), blurRadius: _hovered ? 20 : 11, spreadRadius: _hovered ? 1 : 0, offset: const Offset(0, 6))] : const [],
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
                          Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(color: widget.primary ? Colors.black.withValues(alpha: .16) : accent.withValues(alpha: .13), borderRadius: BorderRadius.circular(11)),
                              child: Icon(widget.icon ?? Icons.arrow_forward_rounded, color: widget.primary ? Colors.white : accent, size: 21),
                            ),
                            const SizedBox(width: 10),
                            Text(widget.label.toUpperCase(), textAlign: TextAlign.center, style: TextStyle(color: enabled ? Colors.white : muted, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.7)),
                          ]))
                        else ...[
                          Center(child: Text(widget.label.toUpperCase(), textAlign: TextAlign.center, style: TextStyle(color: enabled ? Colors.white : muted, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.7))),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(color: widget.primary ? Colors.black.withValues(alpha: .16) : accent.withValues(alpha: .13), borderRadius: BorderRadius.circular(11)),
                              child: Icon(widget.icon ?? Icons.arrow_forward_rounded, color: widget.primary ? Colors.white : accent, size: 21),
                            ),
                          ),
                        ],
                        if (widget.showChevron && !widget.centerContent) Align(alignment: Alignment.centerRight, child: Icon(Icons.chevron_right_rounded, color: enabled ? (widget.primary ? Colors.white70 : accent) : muted, size: 25)),
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
  const ProfileActionButton({super.key, required this.label, required this.icon, required this.accent, required this.onPressed, this.primary = false, this.backgroundColor, this.horizontal = false});
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
                  gradient: enabled && widget.primary ? LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [widget.accent, Color.lerp(widget.accent, ink, .36)!]) : null,
                  color: widget.backgroundColor ?? (enabled && !widget.primary ? widget.accent.withValues(alpha: .08) : (!enabled ? Colors.white.withValues(alpha: .035) : null)),
                  borderRadius: radius,
                  border: Border.all(color: enabled ? widget.accent.withValues(alpha: widget.primary ? .95 : .7) : Colors.white.withValues(alpha: .12), width: _hovered ? 1.6 : 1),
                  boxShadow: enabled ? [BoxShadow(color: widget.accent.withValues(alpha: widget.primary ? .25 : .1), blurRadius: _hovered ? 16 : 8, offset: const Offset(0, 5))] : const [],
                ),
                child: InkWell(
                  onTap: widget.onPressed,
                  onHover: (value) => setState(() => _hovered = value),
                  borderRadius: radius,
                  splashColor: widget.accent.withValues(alpha: .22),
                  highlightColor: widget.accent.withValues(alpha: .08),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                    child: widget.horizontal
                        ? Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(widget.icon, color: enabled ? (widget.primary ? Colors.white : widget.accent) : muted, size: 22),
                            const SizedBox(width: 8),
                            Flexible(child: Text(widget.label, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: enabled ? (widget.primary ? Colors.white : Colors.white70) : muted, fontSize: 12, height: 1.05, fontWeight: FontWeight.w900, letterSpacing: .25))),
                          ])
                        : Column(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(widget.icon, color: enabled ? (widget.primary ? Colors.white : widget.accent) : muted, size: 20),
                            const SizedBox(height: 2),
                            Text(widget.label, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: enabled ? (widget.primary ? Colors.white : Colors.white70) : muted, fontSize: 10, height: 1.05, fontWeight: FontWeight.w900, letterSpacing: .35)),
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
  const SectionCard({super.key, required this.child, this.padding = const EdgeInsets.all(18), this.color = panel});
  final Widget child;
  final EdgeInsets padding;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(padding: padding, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(22), border: Border.all(color: Colors.white.withValues(alpha: .07))), child: child);
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
    final color = [const Color(0xFF354667), const Color(0xFF684B59), const Color(0xFF35605E)][index % 3];
    return GestureDetector(
      onTap: () => setState(() => index = (index + 1) % widget.profile.photos.length),
      onHorizontalDragEnd: (details) => setState(() => index = (details.primaryVelocity ?? 0) < 0 ? (index + 1) % widget.profile.photos.length : (index - 1 + widget.profile.photos.length) % widget.profile.photos.length),
      child: AspectRatio(
        aspectRatio: 0.88,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(26), gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [color, ink])),
          child: LayoutBuilder(builder: (context, constraints) {
            final compact = constraints.maxWidth < 140;
            final iconSize = compact ? 38.0 : 82.0;
            final gap = compact ? 5.0 : 14.0;
            final idSize = compact ? 14.0 : 28.0;
            final photoSize = compact ? 9.0 : 14.0;
            return Stack(children: [
              Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.person_outline_rounded, size: iconSize, color: Colors.white.withValues(alpha: .72)), SizedBox(height: gap), Text(widget.profile.id.toUpperCase(), style: TextStyle(fontSize: idSize, fontWeight: FontWeight.w900, letterSpacing: compact ? 1 : 3)), Text('PHOTO ${index + 1}', style: TextStyle(color: aqua, fontSize: photoSize, fontWeight: FontWeight.bold, letterSpacing: compact ? .8 : 2))])),
              Positioned(top: compact ? 8 : 14, left: compact ? 8 : 14, right: compact ? 8 : 14, child: Row(children: List.generate(widget.profile.photos.length, (dot) => Expanded(child: Container(height: compact ? 3 : 4, margin: const EdgeInsets.symmetric(horizontal: 2), decoration: BoxDecoration(color: dot == index ? Colors.white : Colors.white.withValues(alpha: .25), borderRadius: BorderRadius.circular(4))))))),
              if (!compact) const Positioned(bottom: 15, left: 17, child: Text('Tap or swipe to browse', style: TextStyle(color: Colors.white70, fontSize: 11))),
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
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('${profile.name}, ${profile.age}', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
    const SizedBox(height: 5),
    Text('${profile.occupation}  ·  ${profile.location}', style: const TextStyle(color: muted)),
  ]);
}

class InterestChips extends StatelessWidget {
  const InterestChips({super.key, required this.interests});
  final List<String> interests;
  @override
  Widget build(BuildContext context) => Wrap(spacing: 8, runSpacing: 8, children: interests.map((interest) => Chip(label: Text(interest), side: BorderSide.none, backgroundColor: const Color(0xFF24314A))).toList());
}

class GogglesDialog extends StatelessWidget {
  const GogglesDialog({super.key, required this.profile});
  final Profile profile;
  static Future<void> show(BuildContext context, Profile profile) => showDialog<void>(context: context, builder: (_) => GogglesDialog(profile: profile));
  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: const Color(0xFF0A111B),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: aqua.withValues(alpha: .4))),
    child: Padding(padding: const EdgeInsets.all(22), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const BrandMark(),
      const SizedBox(height: 18),
      Text('INTELLIGENCE SCAN // ${profile.id.toUpperCase()}', style: const TextStyle(color: aqua, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
      const SizedBox(height: 12),
      TweenAnimationBuilder<double>(tween: Tween(begin: 0, end: 1), duration: const Duration(milliseconds: 850), builder: (_, value, child) => Column(children: [LinearProgressIndicator(value: value, color: aqua, backgroundColor: Colors.white12), const SizedBox(height: 6), Align(alignment: Alignment.centerRight, child: Text(value < 1 ? 'Scanning…' : 'Scan complete', style: const TextStyle(color: muted, fontSize: 11)))])),
      const SizedBox(height: 18),
      _goggleRow(Icons.people_alt_outlined, 'CURRENT CONTACTS', '${profile.gogglesData.activeConnections} users'),
      _goggleRow(Icons.person_off_outlined, 'FORMER CONTACTS / INACTIVE', '${profile.gogglesData.inactiveFormerConnections} users'),
      _goggleRow(Icons.schedule_outlined, 'LAST ACTIVE', profile.gogglesData.lastActive),
      const SizedBox(height: 12),
      const Text('Goggles is intelligence, not proof. Compare it with the rest of the case.', style: TextStyle(color: muted, height: 1.4, fontSize: 12)),
      const SizedBox(height: 16),
      PrimaryButton(label: 'Close scan', onPressed: () => Navigator.of(context).pop(), outlined: true),
    ])),
  );
  Widget _goggleRow(IconData icon, String label, String value) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [Icon(icon, color: aqua), const SizedBox(width: 12), Expanded(child: Text(label, style: const TextStyle(color: muted, fontSize: 11, letterSpacing: .8))), Text(value, style: const TextStyle(fontWeight: FontWeight.w800))]));
}

class SuspectCounter extends StatelessWidget {
  const SuspectCounter({super.key, required this.count});
  final int count;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8), decoration: BoxDecoration(color: coral.withValues(alpha: .14), borderRadius: BorderRadius.circular(30)), child: Text('SUSPECTS SELECTED  $count / 3', style: const TextStyle(color: coral, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: .8)));
}

class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.entry});
  final ChatEntry entry;
  @override
  Widget build(BuildContext context) => Align(alignment: entry.isPlayer ? Alignment.centerRight : Alignment.centerLeft, child: Container(constraints: const BoxConstraints(maxWidth: 310), margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12), decoration: BoxDecoration(color: entry.isPlayer ? coral : panel, borderRadius: BorderRadius.circular(18).copyWith(bottomRight: entry.isPlayer ? const Radius.circular(4) : null, bottomLeft: entry.isPlayer ? null : const Radius.circular(4))), child: Text(entry.text, style: TextStyle(color: entry.isPlayer ? ink : Colors.white, height: 1.35))));
}
