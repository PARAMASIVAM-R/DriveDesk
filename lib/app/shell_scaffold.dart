import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'theme/app_theme.dart';

class ShellDestination {
  const ShellDestination(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

const staffDestinations = [
  ShellDestination('Dashboard', Icons.dashboard_outlined, Icons.dashboard),
  ShellDestination('Students', Icons.people_outline, Icons.people),
  ShellDestination('Classes', Icons.event_outlined, Icons.event),
  ShellDestination('Fees', Icons.payments_outlined, Icons.payments),
  ShellDestination('More', Icons.menu, Icons.menu_open),
];

const studentDestinations = [
  ShellDestination('Home', Icons.home_outlined, Icons.home),
  ShellDestination('My classes', Icons.event_outlined, Icons.event),
  ShellDestination('Licence', Icons.badge_outlined, Icons.badge),
  ShellDestination('Fees', Icons.payments_outlined, Icons.payments),
  ShellDestination('More', Icons.menu, Icons.menu_open),
];

/// Bottom-navigation shell shared by the staff and student experiences;
/// each passes its own destinations.
class ShellScaffold extends StatelessWidget {
  const ShellScaffold({
    super.key,
    required this.shell,
    required this.destinations,
  });

  final StatefulNavigationShell shell;
  final List<ShellDestination> destinations;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final radius = BorderRadius.circular(AppRadius.xl);
    return Scaffold(
      body: shell,
      // Floating, raised navigation dock.
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            color: theme.colorScheme.surfaceContainerLowest,
            border: Border.all(
              color: dark ? Colors.white.withValues(alpha: 0.07) : Colors.white,
              width: 1.2,
            ),
            boxShadow: AppShadows.raised(AppColors.brandDeep, dark: dark),
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: MediaQuery.removePadding(
              context: context,
              removeBottom: true,
              child: NavigationBar(
                selectedIndex: shell.currentIndex,
                onDestinationSelected: (i) =>
                    shell.goBranch(i, initialLocation: i == shell.currentIndex),
                destinations: [
                  for (final d in destinations)
                    NavigationDestination(
                      icon: Icon(d.icon),
                      selectedIcon: Icon(d.selectedIcon),
                      label: d.label,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
