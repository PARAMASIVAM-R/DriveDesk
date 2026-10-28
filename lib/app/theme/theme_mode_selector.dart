import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/common_widgets.dart';
import 'app_theme.dart';
import 'theme_mode_provider.dart';

/// Appearance card with a System / Light / Dark switch. The choice is saved
/// on the device.
class ThemeModeSelector extends ConsumerWidget {
  const ThemeModeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    return Surface3D(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              GlossyIcon(mode.icon, size: 38),
              const SizedBox(width: AppSpacing.md),
              const Expanded(
                child: Text(
                  'Theme',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SegmentedButton<ThemeMode>(
            showSelectedIcon: false,
            segments: [
              for (final m in const [
                ThemeMode.system,
                ThemeMode.light,
                ThemeMode.dark,
              ])
                ButtonSegment(
                  value: m,
                  icon: Icon(m.icon, size: 18),
                  label: Text(m.label),
                ),
            ],
            selected: {mode},
            onSelectionChanged: (s) =>
                ref.read(themeModeProvider.notifier).set(s.first),
          ),
        ],
      ),
    );
  }
}
