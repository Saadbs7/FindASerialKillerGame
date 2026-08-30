import 'package:flutter/material.dart';
import 'models.dart';

const ink = Color(0xFF0C1220);
const panel = Color(0xFF151E31);
const muted = Color(0xFF98A5BA);
const coral = Color(0xFFE97964);
const aqua = Color(0xFF6ED5C8);

class PageFrame extends StatelessWidget {
  const PageFrame({super.key, required this.child, this.title, this.subtitle, this.action});
  final Widget child;
  final String? title;
  final String? subtitle;
  final Widget? action;
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
                if (title != null) Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title!, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)), if (subtitle != null) ...[const SizedBox(height: 5), Text(subtitle!, style: const TextStyle(color: muted))]])),
                  if (action != null) action!,
                ]),
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
    ClipRRect(borderRadius: BorderRadius.circular(compact ? 11 : 14), child: Image.asset('assets/images/app_logo.jpg', width: compact ? 54 : 64, height: compact ? 54 : 64, fit: BoxFit.cover, semanticLabel: 'Find a Serial Killer app logo')),
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
          child: Stack(children: [
            Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.person_outline_rounded, size: 82, color: Colors.white.withValues(alpha: .72)), const SizedBox(height: 14), Text(widget.profile.id.toUpperCase(), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 3)), Text('PHOTO ${index + 1}', style: const TextStyle(color: aqua, fontWeight: FontWeight.bold, letterSpacing: 2))])),
            Positioned(top: 14, left: 14, right: 14, child: Row(children: List.generate(widget.profile.photos.length, (dot) => Expanded(child: Container(height: 4, margin: const EdgeInsets.symmetric(horizontal: 2), decoration: BoxDecoration(color: dot == index ? Colors.white : Colors.white.withValues(alpha: .25), borderRadius: BorderRadius.circular(4))))))),
            const Positioned(bottom: 15, left: 17, child: Text('Tap or swipe to browse', style: TextStyle(color: Colors.white70, fontSize: 11))),
          ]),
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
