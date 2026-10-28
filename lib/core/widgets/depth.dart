import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

/// Shrinks its child slightly while pressed, so taps feel physical.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool down) {
    if (widget.onTap != null && down != _down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down ? 0.965 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Raised card with a lit top edge and deep layered shadow: the base "3D"
/// surface used across the app, in both themes.
class Surface3D extends StatelessWidget {
  const Surface3D({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.radius = AppRadius.lg,
    this.tint,
    this.highlighted = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double radius;

  /// Colour of the faint glow in the card's corner.
  final Color? tint;

  /// Draws an amber outline, e.g. for the selected or primary item.
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final shape = BorderRadius.circular(radius);
    final glow = tint ?? AppColors.amber;

    final surface = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: shape,
        gradient: p.surfaceGradient,
        border: Border.all(
          color: highlighted
              ? AppColors.amber.withValues(alpha: 0.8)
              : (p.isDark ? p.edge : p.outline.withValues(alpha: 0.7)),
          width: highlighted ? 1.4 : 1,
        ),
        boxShadow: p.raised,
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: AppColors.amber.withValues(alpha: 0.12),
          highlightColor: AppColors.amber.withValues(alpha: 0.05),
          child: Stack(
            // Keep the parent's constraints, e.g. a grid cell's fixed height.
            fit: StackFit.passthrough,
            children: [
              // Faint accent glow in the top-right corner.
              Positioned(
                right: -40,
                top: -40,
                child: IgnorePointer(
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          glow.withValues(alpha: 0.10 * p.glowStrength),
                          glow.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(padding: padding, child: child),
            ],
          ),
        ),
      ),
    );
    return onTap == null ? surface : Pressable(onTap: onTap, child: surface);
  }
}

/// Instrument-style icon dial: a domed disc with a glowing coloured ring,
/// like the knobs on a car's dashboard.
class GlossyIcon extends StatelessWidget {
  const GlossyIcon(
    this.icon, {
    super.key,
    this.color = AppColors.amber,
    this.size = 44,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.35, -0.45),
          radius: 0.95,
          colors: [p.dialLight, p.dialDark],
        ),
        border: Border.all(color: color, width: size >= 40 ? 2 : 1.6),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.30 * p.glowStrength),
            blurRadius: 14,
            spreadRadius: -2,
          ),
          BoxShadow(color: p.shadow, blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Icon(icon, color: color, size: size * 0.46),
    );
  }
}

/// Circular gauge in the style of a speedometer: a dim track, a glowing
/// amber arc for [value] (0–1), tick marks and a centre slot.
class GaugeRing extends StatelessWidget {
  const GaugeRing({
    super.key,
    required this.value,
    this.size = 120,
    this.color = AppColors.amber,
    this.strokeWidth = 9,
    this.child,
  });

  final double value;
  final double size;
  final Color color;
  final double strokeWidth;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SizedBox.square(
      dimension: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (context, v, _) => CustomPaint(
          painter: _GaugePainter(v, color, strokeWidth, p),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter(this.value, this.color, this.stroke, this.palette);

  final double value;
  final Color color;
  final double stroke;
  final AppPalette palette;

  static const _start = math.pi * 0.75;
  static const _sweep = math.pi * 1.5;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - stroke;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final ink = palette.text;

    // Inner dial face, with a soft drop shadow so it sits proud.
    final faceRadius = radius - stroke * 1.2;
    canvas.drawCircle(
      center + const Offset(0, 3),
      faceRadius,
      Paint()
        ..color = palette.shadow
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawCircle(
      center,
      faceRadius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.4),
          colors: [palette.dialLight, palette.dialDark],
        ).createShader(rect),
    );

    // Tick marks.
    final tick = Paint()
      ..color = ink.withValues(alpha: 0.18)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i <= 20; i++) {
      final a = _start + _sweep * i / 20;
      final outer = radius - stroke * 1.6;
      final inner = outer - (i % 5 == 0 ? 7 : 4);
      canvas.drawLine(
        center + Offset(math.cos(a), math.sin(a)) * inner,
        center + Offset(math.cos(a), math.sin(a)) * outer,
        tick,
      );
    }

    canvas.drawArc(
      rect,
      _start,
      _sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = ink.withValues(alpha: 0.08),
    );
    if (value <= 0) return;

    final sweep = _sweep * value;
    // Soft glow underneath the arc.
    canvas.drawArc(
      rect,
      _start,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke * 1.8
        ..strokeCap = StrokeCap.round
        ..color = color.withValues(alpha: 0.35 * palette.glowStrength)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawArc(
      rect,
      _start,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          startAngle: _start,
          endAngle: _start + _sweep,
          colors: [AppColors.amberDeep, color, AppColors.amberSoft],
        ).createShader(rect),
    );
    // Needle dot at the arc's end.
    final end = _start + sweep;
    canvas.drawCircle(
      center + Offset(math.cos(end), math.sin(end)) * radius,
      stroke * 0.42,
      Paint()..color = palette.isDark ? Colors.white : AppColors.onAmber,
    );
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.value != value ||
      old.color != color ||
      old.stroke != stroke ||
      old.palette != palette;
}

/// Hero panel with an amber glow and decorative dial arcs. Used at the top
/// of the login screen and home dashboards.
class HeroPanel extends StatelessWidget {
  const HeroPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.xl),
    this.radius = AppRadius.xl,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = BorderRadius.circular(radius);
    return Container(
      decoration: BoxDecoration(
        borderRadius: r,
        gradient: p.panelGradient,
        border: Border.all(color: p.isDark ? p.edge : p.outline),
        boxShadow: p.raised,
      ),
      child: ClipRRect(
        borderRadius: r,
        child: Stack(
          children: [
            Positioned(
              right: -70,
              top: -70,
              child: Container(
                width: 230,
                height: 230,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.amber.withValues(alpha: p.isDark ? 0.22 : 0.28),
                      AppColors.amber.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            const Positioned(
              right: -46,
              top: -46,
              child: _Arc(size: 150, opacity: 0.35),
            ),
            const Positioned(
              right: -20,
              top: -20,
              child: _Arc(size: 98, opacity: 0.18),
            ),
            Padding(
              padding: padding,
              child: DefaultTextStyle.merge(
                style: TextStyle(color: p.text),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Arc extends StatelessWidget {
  const _Arc({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.amber.withValues(alpha: opacity),
          width: 1.5,
        ),
      ),
    );
  }
}

/// Amber initials avatar with a soft glow.
class Avatar3D extends StatelessWidget {
  const Avatar3D({super.key, required this.initials, this.size = 42});

  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.brandGradient,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: AppShadows.glow(
          AppColors.amber,
          context.palette.glowStrength,
        ),
      ),
      child: Text(
        initials,
        style: TextStyle(
          color: AppColors.onAmber,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.36,
        ),
      ),
    );
  }
}

/// Small outlined pill for use on top of a [HeroPanel].
class GlassPill extends StatelessWidget {
  const GlassPill({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final accent = context.palette.accentText;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.amber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: accent),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: accent,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Raised menu row with an instrument-style icon, used on "More" screens.
class MenuTile extends StatelessWidget {
  const MenuTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.badge = 0,
    this.color = AppColors.amber,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final int badge;
  final Color color;

  /// Replaces the chevron, e.g. with the current value of a setting.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
      child: Surface3D(
        onTap: onTap,
        tint: color,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        child: Row(
          children: [
            GlossyIcon(icon, color: color, size: 38),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            if (badge > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.amber,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$badge',
                  style: const TextStyle(
                    color: AppColors.onAmber,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            const SizedBox(width: AppSpacing.xs),
            trailing ?? Icon(Icons.chevron_right_rounded, color: p.textMuted),
          ],
        ),
      ),
    );
  }
}

/// Large amber call-to-action pill, as used for the main action on a screen.
class AmberPillButton extends StatelessWidget {
  const AmberPillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onPressed,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: AppColors.brandGradient,
          boxShadow: AppShadows.glow(
            AppColors.amber,
            context.palette.glowStrength,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: 16,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.onAmber,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  if (icon != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Icon(icon, color: AppColors.onAmber, size: 20),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
