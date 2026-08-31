// Lightweight, dependency-free "3D" set pieces for the case result screens.
//
// These do not use a 3D engine (Flame/Unity/etc, per project constraints) —
// they build the depth illusion with layered Flutter `Transform`s that carry
// a real perspective matrix (`setEntry(3, 2, ...)`), combined with
// `rotateX`/`rotateY` hinge animations and `CustomPainter` set pieces. The
// result is a genuinely foreshortening, camera-like animation using only
// Flutter's built-in rendering — safe to drop into any environment that can
// already run the app, no new packages required.
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'widgets.dart' show coral, aqua;

/// WIN — a killer is caught behind the cell door as it slams shut in perspective.
class CaseClosedScene extends StatefulWidget {
  const CaseClosedScene({super.key});

  @override
  State<CaseClosedScene> createState() => _CaseClosedSceneState();
}

class _CaseClosedSceneState extends State<CaseClosedScene> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value;
          // Camera settles from a slightly raised, tilted angle down to level.
          final camera = Curves.easeOutCubic.transform(t);
          final cameraTiltX = (1 - camera) * -0.22;
          final cameraTiltY = (1 - camera) * 0.10;
          // Bars begin raised flat overhead and slam down to vertical, staggered.
          const barCount = 7;
          final impact = (((t - 0.62).clamp(0.0, 0.06)) / 0.06).clamp(0.0, 1.0); // brief shake window
          final shake = math.sin(impact * math.pi * 6) * (1 - impact) * 3.0;
          final spotlight = Curves.easeIn.transform((t / 0.5).clamp(0.0, 1.0));

          return ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Transform.translate(
              offset: Offset(shake, 0),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF090C13), Color(0xFF0F1626), Color(0xFF05070C)]),
                ),
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.0018)
                    ..rotateX(cameraTiltX)
                    ..rotateY(cameraTiltY),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Spotlight glow behind the killer.
                      Opacity(
                        opacity: spotlight,
                        child: Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [aqua.withValues(alpha: .34), coral.withValues(alpha: .12), Colors.transparent])),
                        ),
                      ),
                      // The killer is painted before the bars, so the cell door visibly
                      // closes in front of him instead of showing the old initial badge.
                      Positioned(
                        bottom: 22,
                        child: Opacity(
                          opacity: (spotlight * 0.9).clamp(0.0, 1.0),
                          child: const _KillerStickman(),
                        ),
                      ),
                      // Floor shadow that darkens as the door slams shut.
                      Positioned(
                        bottom: 18,
                        child: Opacity(
                          opacity: (Curves.easeIn.transform((((t - 0.55) / 0.3).clamp(0.0, 1.0)))) * .55,
                          child: Container(width: 190, height: 14, decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(20))),
                        ),
                      ),
                      // The bars, each hinged at the top and slamming from flat-overhead to vertical.
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(barCount, (i) {
                          const stagger = 0.045;
                          final start = 0.12 + i * stagger;
                          final local = (((t - start) / 0.45).clamp(0.0, 1.0));
                          final eased = Curves.easeOutBack.transform(local);
                          // -1.35 rad ≈ bar tilted almost flat, out of frame above; 0 ≈ vertical, closed.
                          final angle = (1 - eased) * -1.35;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            child: Transform(
                              alignment: Alignment.topCenter,
                              transform: Matrix4.identity()
                                ..setEntry(3, 2, 0.0022)
                                ..rotateX(angle),
                              child: Container(
                                width: 9,
                                height: 232,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  gradient: LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [Colors.grey.shade600, Colors.grey.shade200, Colors.grey.shade800],
                                  ),
                                  boxShadow: const [BoxShadow(color: Colors.black87, blurRadius: 6, offset: Offset(3, 3))],
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                      // Horizontal crossbar, drops in last for the "lock" beat.
                      Positioned(
                        top: 24 + (1 - Curves.easeOutBack.transform((((t - 0.5) / 0.25).clamp(0.0, 1.0)))) * -60,
                        child: Container(width: 224, height: 8, decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), gradient: LinearGradient(colors: [Colors.grey.shade500, Colors.grey.shade200]), boxShadow: const [BoxShadow(color: Colors.black87, blurRadius: 5)])),
                      ),
                      Positioned(
                        bottom: 24 - (1 - Curves.easeOutBack.transform((((t - 0.5) / 0.25).clamp(0.0, 1.0)))) * -60,
                        child: Container(width: 224, height: 8, decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), gradient: LinearGradient(colors: [Colors.grey.shade500, Colors.grey.shade200]), boxShadow: const [BoxShadow(color: Colors.black87, blurRadius: 5)])),
                      ),
                      // Impact flash.
                      Opacity(opacity: (1 - impact) * impact * 2.2, child: Container(color: Colors.white.withValues(alpha: .5))),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _KillerStickman extends StatelessWidget {
  const _KillerStickman();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 210,
      height: 210,
      child: CustomPaint(painter: _KillerStickmanPainter()),
    );
  }
}

class _KillerStickmanPainter extends CustomPainter {
  const _KillerStickmanPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final edge = Paint()
      ..color = aqua.withValues(alpha: .82)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final silhouette = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    void drawBody(Paint paint) {
      canvas.drawLine(const Offset(78, 56), const Offset(86, 128), paint);
      canvas.drawLine(const Offset(81, 72), const Offset(48, 102), paint);
      canvas.drawLine(const Offset(48, 102), const Offset(29, 87), paint);
      canvas.drawLine(const Offset(81, 72), const Offset(115, 94), paint);
      canvas.drawLine(const Offset(115, 94), const Offset(137, 70), paint);
      canvas.drawLine(const Offset(86, 128), const Offset(54, 188), paint);
      canvas.drawLine(const Offset(86, 128), const Offset(126, 186), paint);
      canvas.drawLine(const Offset(54, 188), const Offset(42, 188), paint);
      canvas.drawLine(const Offset(126, 186), const Offset(139, 186), paint);
    }

    // Leaning pose and raised arm give the otherwise simple figure a threatening stance.
    canvas.drawCircle(const Offset(78, 34), 25, edge);
    canvas.drawCircle(const Offset(78, 34), 21, Paint()..color = Colors.black);
    drawBody(edge);
    drawBody(silhouette);

    // Knife: a wrapped handle, crossguard, and a broad pointed blade.
    final handleOutline = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 17
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(137, 70), const Offset(157, 50), handleOutline);

    final handle = Paint()
      ..color = const Color(0xFFB51F4B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(137, 70), const Offset(157, 50), handle);

    // A real crossguard makes the blade and handle read as a knife at a glance.
    final guard = Paint()
      ..color = Colors.black
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(149, 43), const Offset(164, 58), guard);

    final bladePath = Path()
      ..moveTo(154, 44)
      ..lineTo(204, 14)
      ..lineTo(167, 63)
      ..lineTo(155, 55)
      ..close();
    canvas.drawPath(bladePath, Paint()..color = Colors.black);

    final blade = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF8AA7B2), Color(0xFFF4FFFF), Color(0xFFB7D5DE)],
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
      ).createShader(const Rect.fromLTWH(154, 44, 50, 20));
    final innerBladePath = Path()
      ..moveTo(157, 47)
      ..lineTo(198, 20)
      ..lineTo(166, 58)
      ..lineTo(159, 53)
      ..close();
    canvas.drawPath(innerBladePath, blade);

    final glint = Paint()
      ..color = Colors.white.withValues(alpha: .85)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(163, 48), const Offset(193, 25), glint);
  }

  @override
  bool shouldRepaint(covariant _KillerStickmanPainter oldDelegate) => false;
}

/// LOSS — a 3D gavel arcs down, slams the block, and a dismissal stamp lands.
class CaseDismissedScene extends StatefulWidget {
  const CaseDismissedScene({super.key});

  @override
  State<CaseDismissedScene> createState() => _CaseDismissedSceneState();
}

class _CaseDismissedSceneState extends State<CaseDismissedScene> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value;
          // The handle end is the fixed pivot: only the gavel rotates around it.
          final swing = Curves.easeInCubic.transform((t / 0.58).clamp(0.0, 1.0));
          final impactWindow = (((t - 0.58).clamp(0.0, 0.16)) / 0.16).clamp(0.0, 1.0);
          final rebound = Curves.easeOut.transform((((t - 0.58) / 0.14).clamp(0.0, 1.0)));
          final gavelAngle = 0.58 * (1 - swing) - rebound * 0.08;
          final shake = math.sin(impactWindow * math.pi * 6) * (1 - impactWindow) * 4.0;
          final ringT = Curves.easeOut.transform((((t - 0.58) / 0.42).clamp(0.0, 1.0)));
          final flashT = Curves.easeOut.transform((((t - 0.58) / 0.13).clamp(0.0, 1.0)));
          const dismissalRed = Color(0xFFFF4058);
          final dismissalTextEdge = Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 5
            ..color = Colors.black;
          // easeOutBack intentionally overshoots, but Opacity requires a strict
          // 0..1 value, so keep the visual animation bounded at the widget edge.
          final stampT = Curves.easeOutBack.transform((((t - 0.68) / 0.32).clamp(0.0, 1.0))).clamp(0.0, 1.0);
          final cameraTiltX = (1 - Curves.easeOutCubic.transform(t)) * 0.16;

          return ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Transform.translate(
              offset: Offset(shake, 0),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF1B1210), Color(0xFF2A1A16), Color(0xFF120B0A)]),
                ),
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.0018)
                    ..rotateX(cameraTiltX),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Shockwave rings expand from the exact point where the hammer lands.
                      if (ringT > 0)
                        Positioned(
                          bottom: 58,
                          child: Transform.translate(
                            offset: const Offset(-35, 0),
                            child: Opacity(
                              opacity: (1 - ringT).clamp(0.0, 1.0) * .6,
                              child: Container(
                                width: 34 + ringT * 150,
                                height: 12 + ringT * 34,
                                decoration: BoxDecoration(borderRadius: const BorderRadius.all(Radius.elliptical(100, 30)), border: Border.all(color: coral.withValues(alpha: .9), width: 2.5)),
                              ),
                            ),
                          ),
                        ),
                      // The wooden sounding block receives the blow and shows a central strike mark.
                      Positioned(
                        bottom: 40,
                        child: Transform.translate(offset: const Offset(-35, 0), child: const _HammerBoard()),
                      ),
                      // Keep the handle edge fixed in the air while the head swings into the block.
                      Align(
                        alignment: Alignment.topCenter,
                        child: Transform.translate(
                          // The pommel is at (174, 135) in the painter, so this
                          // offset keeps that handle edge stationary during the swing.
                          offset: const Offset(15, 42),
                          child: Transform(
                            alignment: const Alignment(0.93, 0.93),
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.0028)
                              ..rotateZ(gavelAngle)
                              ..scaleByDouble(1.0 + swing * 0.12, 1.0 + swing * 0.12, 1.0 + swing * 0.12, 1.0),
                            child: const _GavelShape(),
                          ),
                        ),
                      ),
                      // Local flash and radial burst sell the instant of impact.
                      Positioned(
                        bottom: 30,
                        child: Opacity(
                          opacity: ((1 - flashT) * flashT * 4).clamp(0.0, 1.0),
                          child: Transform.translate(offset: const Offset(-35, 0), child: Transform.scale(scale: 0.55 + flashT * 0.7, child: const CustomPaint(size: Size(150, 95), painter: _ImpactBurstPainter()))),
                        ),
                      ),
                      // "CASE DISMISSED" stamp slams in.
                      Positioned.fill(
                        child: Center(
                          child: Transform.rotate(
                            angle: -math.pi / 6,
                            child: Transform.scale(
                              scale: 0.55 + stampT * 0.55,
                              child: Opacity(
                                opacity: stampT,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.black, width: 5),
                                    borderRadius: BorderRadius.circular(13),
                                    color: dismissalRed.withValues(alpha: .16),
                                    boxShadow: const [BoxShadow(color: Color(0x66FF4058), blurRadius: 14, spreadRadius: 1)],
                                  ),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Text('DISMISSED', style: TextStyle(foreground: dismissalTextEdge, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 4)),
                                      const Text('DISMISSED', style: TextStyle(color: Color(0xFFFF4058), fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 4)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GavelShape extends StatelessWidget {
  const _GavelShape();

  @override
  Widget build(BuildContext context) => const CustomPaint(size: Size(180, 140), painter: _GavelPainter());
}

class _GavelPainter extends CustomPainter {
  const _GavelPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final outline = Paint()..color = const Color(0xFF10152B);

    // Draw the handle first. It emerges from the underside of the head and angles
    // down-right, so the two pieces read as one connected gavel.
    final handleShadow = Paint()
      ..color = outline.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 25
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(101, 62), const Offset(174, 135), handleShadow);
    final handle = Paint()
      ..shader = const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF6B351F), Color(0xFFC47A43), Color(0xFF713820)]).createShader(const Rect.fromLTWH(101, 62, 73, 73))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(101, 62), const Offset(174, 135), handle);

    // Rounded wooden pommel completes the handle without introducing a bright band.
    canvas.drawCircle(const Offset(174, 135), 10, outline);
    canvas.drawCircle(const Offset(174, 135), 5, Paint()..color = const Color(0xFF9B552F));
    canvas.drawLine(const Offset(115, 76), const Offset(145, 106), Paint()..color = Colors.white.withValues(alpha: .16)..strokeWidth = 2..strokeCap = StrokeCap.round);

    // Large diagonal wooden head, with rounded end caps like the supplied reference.
    canvas.save();
    canvas.translate(101, 62);
    canvas.rotate(-math.pi / 4);

    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-64, -27, 128, 54), const Radius.circular(14)), outline);
    final head = Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFC47A43), Color(0xFF9B552F), Color(0xFF6B351F)]).createShader(const Rect.fromLTWH(-58, -21, 116, 42));
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-58, -21, 116, 42), const Radius.circular(10)), head);

    final cap = Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFD18A4D), Color(0xFF9C552F)]).createShader(const Rect.fromLTWH(-70, -28, 22, 56));
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-70, -28, 22, 56), const Radius.circular(12)), outline);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-65, -23, 12, 46), const Radius.circular(6)), cap);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(48, -28, 22, 56), const Radius.circular(12)), outline);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(53, -23, 12, 46), const Radius.circular(6)), cap);

    final headHighlight = Paint()..color = Colors.white.withValues(alpha: .2)..strokeWidth = 3..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(-47, -14), const Offset(40, -14), headHighlight);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GavelPainter oldDelegate) => false;
}

class _HammerBoard extends StatelessWidget {
  const _HammerBoard();

  @override
  Widget build(BuildContext context) => const CustomPaint(size: Size(170, 50), painter: _HammerBoardPainter());
}

class _HammerBoardPainter extends CustomPainter {
  const _HammerBoardPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(7, 14, 156, 30), const Radius.circular(8)), Paint()..color = Colors.black.withValues(alpha: .6));
    final board = Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF9A603B), Color(0xFF4B2C1D)]).createShader(const Rect.fromLTWH(9, 9, 152, 31));
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(9, 9, 152, 31), const Radius.circular(7)), board);
    canvas.drawLine(const Offset(13, 14), const Offset(157, 14), Paint()..color = const Color(0xFFD08A55).withValues(alpha: .7)..strokeWidth = 2);

    // A dark strike mark remains on the board after the hit.
    final mark = Paint()
      ..color = Colors.black.withValues(alpha: .58)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(const Rect.fromLTWH(68, 10, 34, 15), math.pi * .1, math.pi * .8, false, mark);
    canvas.drawLine(const Offset(84, 18), const Offset(77, 29), mark);
    canvas.drawLine(const Offset(84, 18), const Offset(91, 29), mark);
  }

  @override
  bool shouldRepaint(covariant _HammerBoardPainter oldDelegate) => false;
}

class _ImpactBurstPainter extends CustomPainter {
  const _ImpactBurstPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 5);
    final burst = Paint()
      ..color = coral.withValues(alpha: .95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, 13, burst);
    for (var i = 0; i < 12; i++) {
      final angle = i * math.pi / 6;
      final inner = center + Offset(math.cos(angle) * 20, math.sin(angle) * 12);
      final outer = center + Offset(math.cos(angle) * 38, math.sin(angle) * 24);
      canvas.drawLine(inner, outer, burst);
    }
  }

  @override
  bool shouldRepaint(covariant _ImpactBurstPainter oldDelegate) => false;
}
