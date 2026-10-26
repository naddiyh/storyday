import 'features/settings/data/reminder_store.dart';
import 'features/settings/data/profile_store.dart';
import 'features/planner/data/planner_store.dart';
import 'features/calendar/data/demo_calendar.dart';
import 'features/memories/demo_memories.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app/app.dart';
import 'features/notes/data/note_repository.dart';
import 'features/themes/data/appearance_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = SharedPreferencesAsync();
  final store = PreferencesAppearanceStore(preferences);
  final noteRepository = PreferencesOrdinaryNoteRepository(preferences);
  final appearance = await store.load();
  final plannerStore = PreferencesPlannerStore(preferences);
  final plannerData = await plannerStore.load();
  final reminderStore = PreferencesReminderStore(preferences);
  final reminders = await reminderStore.load();
  final profileStore = PreferencesProfileStore(preferences);
  final profile = await profileStore.load() ??
      const LocalProfile(
          name: bool.fromEnvironment('UI_REFERENCE_REVIEW')
              ? 'Nade'
              : 'Journal keeper');
  runApp(ProviderScope(
    overrides: [
      if (const bool.fromEnvironment('UI_REFERENCE_REVIEW')) ...[
        calendarClockProvider.overrideWithValue(() => DateTime(2026, 10, 22)),
        selectedDateProvider.overrideWith((ref) => DateTime(2026, 10, 22)),
      ],
      reminderStoreProvider.overrideWithValue(reminderStore),
      initialReminderProvider.overrideWithValue(reminders),
      profileStoreProvider.overrideWithValue(profileStore),
      initialProfileProvider.overrideWithValue(profile),
      plannerStoreProvider.overrideWithValue(plannerStore),
      initialPlannerProvider.overrideWithValue(plannerData),
      appearanceStoreProvider.overrideWithValue(store),
      ordinaryNotesRepositoryProvider.overrideWithValue(noteRepository),
      initialAppearanceProvider.overrideWithValue(appearance),
    ],
    child: const LenoteApp(),
  ));
}
