import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/data/local_store.dart';

/// Where the chosen theme mode is persisted. Defaults to a volatile
/// in-memory store; `main.dart` overrides it with a file-backed store.
final themeStoreProvider = Provider<LocalStore>((ref) => InMemoryLocalStore());

/// Theme mode restored at startup (see `main.dart`).
final initialThemeModeProvider = Provider<ThemeMode>((ref) => ThemeMode.dark);

/// Reads a saved theme mode; falls back to dark (the brand default).
Future<ThemeMode> loadStoredThemeMode(LocalStore store) async {
  try {
    final raw = (await store.read())?.trim();
    return ThemeMode.values.firstWhere(
      (m) => m.name == raw,
      orElse: () => ThemeMode.dark,
    );
  } catch (_) {
    return ThemeMode.dark;
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ref.read(initialThemeModeProvider);

  void set(ThemeMode mode) {
    if (mode == state) return;
    state = mode;
    unawaited(ref.read(themeStoreProvider).write(mode.name).catchError((_) {}));
  }
}

extension ThemeModeLabel on ThemeMode {
  String get label => switch (this) {
    ThemeMode.system => 'System',
    ThemeMode.light => 'Light',
    ThemeMode.dark => 'Dark',
  };

  IconData get icon => switch (this) {
    ThemeMode.system => Icons.brightness_auto_rounded,
    ThemeMode.light => Icons.light_mode_rounded,
    ThemeMode.dark => Icons.dark_mode_rounded,
  };
}
