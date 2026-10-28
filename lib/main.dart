import 'dart:async';
import 'core/cloud/cloud_connection.dart';
import 'features/account/presentation/cloud_account_panel.dart';
import 'features/notes/data/journal_sync.dart';
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
  try {
    await startJournal();
  } catch (_) {
    // Do not replace unreadable planner/profile data with defaults that a
    // later write could persist over the original payload.
    runApp(const MaterialApp(
        home: Scaffold(
            body: SafeArea(
                child: Center(
                    child: Padding(
                        padding: EdgeInsets.all(24),
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                          Text(
                              'Saved data could not be opened. Your original data has been kept.'),
                          SizedBox(height: 16),
                          FilledButton(
                              onPressed: main,
                              child: Text('Retry opening journal')),
                        ])))))));
  }
}

Future<void> startJournal() async {
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
  final cloud = await CloudConnection.initialize(CloudConfig.environment());
  runApp(ProviderScope(
    overrides: [
      cloudConnectionProvider.overrideWithValue(cloud),
      guestNotesRepositoryProvider.overrideWithValue(noteRepository),
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
      ordinaryNotesRepositoryProvider.overrideWith((ref) {
        final userId = ref.watch(cloudUserProvider.select((u) => u?.id));
        if (userId == null || cloud.client == null) return noteRepository;
        var active = true;
        final repository = SyncedJournalRepository(
            preferences, userId, SupabaseJournalRemote(cloud.client!, userId),
            onChanged: () async {
          if (active) await ref.read(ordinaryNotesProvider.notifier).load();
        }, onStatus: (status) {
          if (active) {
            ref.read(journalSyncStatusProvider.notifier).state = status;
          }
        });
        final initial =
            Timer(Duration.zero, () => unawaited(repository.sync()));
        final retry = Timer.periodic(
            const Duration(seconds: 30), (_) => unawaited(repository.sync()));
        ref.onDispose(() {
          active = false;
          initial.cancel();
          retry.cancel();
          repository.dispose();
        });
        return repository;
      }),
      initialAppearanceProvider.overrideWithValue(appearance),
    ],
    child: const LenoteApp(),
  ));
}
