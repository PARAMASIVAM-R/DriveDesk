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

/// Raised card with a light top edge, soft gradient face and layered
/// shadow: the base "3D" surface used across the app.
class Surface3D extends StatelessWidget {
  const Surface3D({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.radius = AppRadius.lg,
    this.tint,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double radius;

  /// Colour the shadow and face are lightly tinted with.
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final face = theme.colorScheme.surfaceContainerLowest;
    final tintColor = tint ?? theme.colorScheme.primary;
    final shape = BorderRadius.circular(radius);

    final surface = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: shape,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.alphaBlend(
              Colors.white.withValues(alpha: dark ? 0.04 : 0.6),
              face,
            ),
            Color.alphaBlend(tintColor.withValues(alpha: 0.04), face),
          ],
        ),
        border: Border.all(
          color: dark
              ? Colors.white.withValues(alpha: 0.07)
              : Colors.white.withValues(alpha: 0.95),
          width: 1.2,
        ),
        boxShadow: AppShadows.raised(tintColor, dark: dark),
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
    return onTap == null ? surface : Pressable(onTap: onTap, child: surface);
  }
}

/// Glossy, extruded icon "orb": a gradient tile with a specular highlight
/// and a coloured glow underneath.
class GlossyIcon extends StatelessWidget {
  const GlossyIcon(
    this.icon, {
    super.key,
    this.color = AppColors.brand,
    this.size = 44,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final hsl = HSLColor.fromColor(color);
    final light = hsl
        .withLightness((hsl.lightness + 0.14).clamp(0, 1))
        .toColor();
    final deep = hsl
        .withLightness((hsl.lightness - 0.12).clamp(0, 1))
        .toColor();
    final r = BorderRadius.circular(size * 0.32);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: r,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [light, color, deep],
        ),
        boxShadow: AppShadows.glow(color),
      ),
      child: ClipRRect(
        borderRadius: r,
        child: Stack(
          children: [
            // Specular highlight across the top half.
            Positioned(
              left: -size * 0.2,
              right: -size * 0.2,
              top: -size * 0.55,
              height: size * 0.95,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.45),
                      Colors.white.withValues(alpha: 0.05),
                    ],
                  ),
                ),
              ),
            ),
            Center(
              child: Icon(
                icon,
                color: Colors.white,
                size: size * 0.5,
                shadows: [
                  Shadow(
                    color: deep.withValues(alpha: 0.6),
                    blurRadius: 4,
                    offset: const Offset(0, 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Gradient hero panel with soft floating "bubbles" for depth. Used at the
/// top of the login screen and home dashboards.
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
    final r = BorderRadius.circular(radius);
    return Container(
      decoration: BoxDecoration(
        borderRadius: r,
        gradient: AppColors.brandGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.brandDeep.withValues(alpha: 0.45),
            blurRadius: 30,
            spreadRadius: -8,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: r,
        child: Stack(
          children: [
            const Positioned(right: -40, top: -50, child: _Bubble(170, 0.16)),
            const Positioned(left: -30, bottom: -60, child: _Bubble(140, 0.10)),
            const Positioned(right: 60, bottom: -30, child: _Bubble(70, 0.12)),
            // Top sheen gives the panel a curved glass edge.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.center,
                    colors: [
                      Colors.white.withValues(alpha: 0.18),
                      Colors.white.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: padding,
              child: DefaultTextStyle.merge(
                style: const TextStyle(color: Colors.white),
                child: IconTheme.merge(
                  data: const IconThemeData(color: Colors.white),
                  child: child,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble(this.size, this.opacity);

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.3, -0.4),
          colors: [
            Colors.white.withValues(alpha: opacity * 1.6),
            Colors.white.withValues(alpha: opacity * 0.2),
          ],
        ),
      ),
    );
  }
}

/// Gradient initials avatar with a soft glow.
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
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
        boxShadow: AppShadows.glow(AppColors.brand),
      ),
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.36,
        ),
      ),
    );
  }
}

/// Small frosted pill for use on top of a [HeroPanel].
class GlassPill extends StatelessWidget {
  const GlassPill({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
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
