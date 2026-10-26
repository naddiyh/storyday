import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/design/app_theme.dart';
import '../domain/appearance.dart';

abstract interface class AppearanceStore {
  Future<Appearance> load();
  Future<void> save(Appearance appearance);
}

class PreferencesAppearanceStore implements AppearanceStore {
  PreferencesAppearanceStore(this.preferences);
  final SharedPreferencesAsync preferences;
  static const key = 'appearance.v1';
  @override
  Future<Appearance> load() async {
    try {
      final raw = await preferences.getString(key);
      if (raw == null) return const Appearance();
      final data = jsonDecode(raw) as Map<String, dynamic>;
      return Appearance(
        mode: ThemeMode.values.firstWhere((m) => m.name == data["mode"],
            orElse: () => ThemeMode.system),
        theme: JournalTheme.fromId(data['theme'] as String?),
        decorated: data['decorated'] as bool? ?? true,
      );
    } catch (_) {
      // A corrupt/nonessential preference must not prevent app startup.
      return const Appearance();
    }
  }

  @override
  Future<void> save(Appearance appearance) => preferences.setString(
        key,
        jsonEncode({
          'mode': appearance.mode.name,
          'theme': appearance.theme.id,
          'decorated': appearance.decorated
        }),
      );
}

final appearanceStoreProvider = Provider<AppearanceStore>((ref) {
  throw StateError('Provide an AppearanceStore at bootstrap.');
});
final initialAppearanceProvider =
    Provider<Appearance>((ref) => const Appearance());
final appearanceProvider =
    StateNotifierProvider<AppearanceController, Appearance>((ref) {
  return AppearanceController(
      ref.watch(appearanceStoreProvider), ref.watch(initialAppearanceProvider));
});

class AppearanceController extends StateNotifier<Appearance> {
  AppearanceController(this.store, super.state);
  final AppearanceStore store;
  Future<void> _pending = Future.value();
  Future<bool> update(Appearance next) async {
    state = next;
    // Serialize writes so rapid theme changes cannot persist out of order.
    final write = _pending.then((_) => store.save(next));
    _pending = write.catchError((Object _) {});
    try {
      await write;
      return true;
    } catch (_) {
      return false;
    }
  }
}
