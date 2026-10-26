import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lenote/app/app.dart';
import 'package:lenote/app/router.dart';
import 'package:lenote/core/design/app_theme.dart';
import 'package:lenote/features/calendar/domain/calendar_month.dart';
import 'package:lenote/features/notes/data/note_repository.dart';
import 'package:lenote/features/themes/data/appearance_store.dart';
import 'package:lenote/features/themes/domain/appearance.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lenote/features/memories/demo_memories.dart';

class MemoryPreferences extends Fake implements SharedPreferencesAsync {
  final Map<String, Object?> values = {};
  String? get raw => values['raw'] as String?;
  set raw(String? value) => values['raw'] = value;
  bool get fail => values['fail'] == true;
  set fail(bool value) => values['fail'] = value;
  @override
  Future<String?> getString(String key) async => raw;
  @override
  Future<void> setString(String key, String value) async {
    if (fail) throw StateError('Unavailable storage');
    raw = value;
  }
}

void main() {
  group('Calendar date arithmetic', () {
    test('handles leap years, week starts, and year rollover', () {
      expect(CalendarMonth(2024, 2).days, 29);
      expect(CalendarMonth(2025, 2).days, 28);
      expect(CalendarMonth(2026, 13).first, DateTime(2027));
      final september = CalendarMonth(2024, 9);
      expect(september.leadingDays(0), 0);
      expect(september.leadingDays(1), 6);
      expect(september.cells(1).length % 7, 0);
      expect(september.cells(1).whereType<DateTime>().length, 30);
    });
  });

  group('Appearance persistence', () {
    test('restores the chosen look from storage and tolerates corrupt values',
        () async {
      final preferences = MemoryPreferences();
      final store = PreferencesAppearanceStore(preferences);
      await store.save(
          const Appearance(theme: JournalTheme.midnight, decorated: false));
      final restored = await PreferencesAppearanceStore(preferences).load();
      expect(restored.theme, JournalTheme.midnight);
      expect(restored.decorated, false);
      preferences.raw = '{broken';
      expect((await store.load()).theme, JournalTheme.lavender);
      preferences.raw = '{"theme":"future-theme","decorated":false}';
      expect((await store.load()).theme, JournalTheme.lavender);
    });

    test('rapid changes preserve the last choice and report failed writes',
        () async {
      final preferences = MemoryPreferences();
      final store = PreferencesAppearanceStore(preferences);
      final controller = AppearanceController(store, const Appearance());
      addTearDown(controller.dispose);
      await Future.wait([
        controller.update(const Appearance(theme: JournalTheme.sage)),
        controller.update(const Appearance(theme: JournalTheme.lavender)),
      ]);
      expect((await store.load()).theme, JournalTheme.lavender);
      preferences.fail = true;
      expect(
          await controller
              .update(const Appearance(theme: JournalTheme.midnight)),
          false);
      preferences.fail = false;
      expect(
          await controller.update(const Appearance(theme: JournalTheme.sage)),
          true);
      expect((await store.load()).theme, JournalTheme.sage);
    });
  });

  test('all palettes have readable primary and surface text', () {
    double contrast(Color a, Color b) {
      final first = a.computeLuminance();
      final second = b.computeLuminance();
      return ((first > second ? first : second) + 0.05) /
          ((first > second ? second : first) + 0.05);
    }

    for (final palette in JournalTheme.values) {
      final colors = palette.build().colorScheme;
      expect(
          contrast(colors.primary, colors.onPrimary), greaterThanOrEqualTo(4.5),
          reason: palette.id);
      expect(
          contrast(colors.surface, colors.onSurface), greaterThanOrEqualTo(4.5),
          reason: palette.id);
      expect(contrast(colors.secondaryContainer, colors.onSecondaryContainer),
          greaterThanOrEqualTo(4.5),
          reason: palette.id);
    }
  });

  Future<ProviderContainer> boot(WidgetTester tester,
      {double scale = 1}) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final preferences = MemoryPreferences();
    final container = ProviderContainer(overrides: [
      appearanceStoreProvider
          .overrideWithValue(PreferencesAppearanceStore(preferences)),
      ordinaryNotesRepositoryProvider
          .overrideWithValue(PreferencesOrdinaryNoteRepository(preferences)),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container, child: const LenoteApp()));
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets(
      'calendar is home; destinations and settings preserve calendar state',
      (tester) async {
    await boot(tester);
    expect(find.text('Good morning,\nJournal keeper'), findsOneWidget);
    await tester.tap(find.byTooltip('Next month'));
    await tester.pumpAndSettle();
    final month =
        tester.widget<Text>(find.byKey(const Key('calendar-month'))).data;
    for (final entry in {
      'Memories': 'Memories',
      'Recap': 'Look how much you did this month',
      'Profile': 'Profile'
    }.entries) {
      await tester.tap(find.text(entry.key));
      await tester.pumpAndSettle();
      expect(find.text(entry.value), findsWidgets);
    }
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(find.byKey(const Key('calendar-month'))).data,
        month);
    expect(tester.takeException(), isNull);
  });

  testWidgets('date selection and Today work without clipping at phone width',
      (tester) async {
    await boot(tester);
    await tester.ensureVisible(find.text('15'));
    await tester.tap(find.text('15'));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(find.byKey(const Key('selected-date'))).data,
        contains('15'));
    expect(tester.getRect(find.text('28')).right, lessThanOrEqualTo(390));
    await tester.ensureVisible(find.byKey(const Key('calendar-month')));
    await tester.tap(find.byKey(const Key('calendar-month')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Go to today'));
    await tester.pumpAndSettle();
    final selected =
        tester.widget<Text>(find.byKey(const Key('selected-date'))).data!;
    expect(selected, endsWith('${DateTime.now().day}'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion disables theme animation', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await boot(tester);
    expect(
        tester
            .widget<MaterialApp>(find.byType(MaterialApp))
            .themeAnimationDuration,
        Duration.zero);
  });

  testWidgets('Create exposes four options; appearance modes persist',
      (tester) async {
    final container = await boot(tester);
    await tester.tap(find.byTooltip('Create'));
    await tester.pumpAndSettle();
    for (final label in ['Journal', 'Checklist', 'Schedule', 'Focus session']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.byType(BottomSheet), findsNothing);
    container.read(routerProvider).push('/themes');
    await tester.pumpAndSettle();
    for (final mode in ThemeMode.values) {
      await tester.tap(find.text(mode.name));
      await tester.pumpAndSettle();
      expect(
          tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode, mode);
      expect((await container.read(appearanceStoreProvider).load()).mode, mode);
    }
    expect(demoMemories.every((m) => !m.title.toLowerCase().contains('secret')),
        isTrue);
  });

  test(
      'exactly three themes migrate legacy preferences and support both brightnesses',
      () async {
    expect(JournalTheme.values.map((t) => t.label),
        ['Sweet Pastel', 'Calm & Natural', 'Midnight']);
    expect(JournalTheme.fromId('peach'), JournalTheme.lavender);
    expect(JournalTheme.fromId('monochrome'), JournalTheme.sage);
    for (final theme in JournalTheme.values) {
      for (final mode in ThemeMode.values) {
        final store = PreferencesAppearanceStore(MemoryPreferences());
        await store.save(Appearance(theme: theme, mode: mode));
        final restored = await store.load();
        expect(restored.theme, theme);
        expect(restored.mode, mode);
      }
      for (final brightness in Brightness.values) {
        final colors = theme.build(brightness: brightness).colorScheme;
        expect(colors.brightness, brightness);
        final a = colors.surface.computeLuminance();
        final b = colors.onSurface.computeLuminance();
        expect(((a > b ? a : b) + .05) / ((a > b ? b : a) + .05),
            greaterThanOrEqualTo(4.5));
      }
    }
  });

  testWidgets(
      'preview cancellation preserves selection; applied themes reach every destination',
      (tester) async {
    final container = await boot(tester);
    container.read(routerProvider).push('/themes');
    await tester.pumpAndSettle();
    final card = find.byKey(const ValueKey('theme-midnight'));
    await tester.ensureVisible(card);
    await tester.tap(card);
    await tester.pumpAndSettle();
    expect(container.read(appearanceProvider).theme, JournalTheme.lavender);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(container.read(appearanceProvider).theme, JournalTheme.lavender);
    for (final theme in JournalTheme.values) {
      await container
          .read(appearanceProvider.notifier)
          .update(Appearance(theme: theme, mode: ThemeMode.dark));
      for (final route in [
        '/calendar',
        '/search',
        '/create',
        '/recap',
        '/profile'
      ]) {
        container.read(routerProvider).go(route);
        await tester.pumpAndSettle();
        final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
        expect(app.darkTheme!.colorScheme,
            theme.build(brightness: Brightness.dark).colorScheme);
        expect(app.themeMode, ThemeMode.dark);
        expect(tester.takeException(), isNull, reason: '${theme.id} $route');
      }
    }
  });

  testWidgets('theme selection updates the app and is saved', (tester) async {
    final container = await boot(tester);
    container.read(routerProvider).push('/themes');
    await tester.pumpAndSettle();
    final midnight = find.byKey(const ValueKey('theme-calm_natural'));
    await tester.ensureVisible(midnight);
    await tester.tap(midnight);
    await tester.pumpAndSettle();
    await tester.tap(find.text("Apply theme"));
    await tester.pumpAndSettle();
    expect(container.read(appearanceProvider).theme, JournalTheme.sage);
    expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).theme!.brightness,
        Brightness.light);
    expect((await container.read(appearanceStoreProvider).load()).theme,
        JournalTheme.sage);
    expect(tester.takeException(), isNull);
  });

  testWidgets('large text layouts and unknown route recovery work',
      (tester) async {
    final container = await boot(tester, scale: 2);
    for (final path in [
      '/calendar',
      '/search',
      '/create',
      '/recap',
      '/themes',
      '/settings'
    ]) {
      container.read(routerProvider).go(path);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: path);
    }
    container.read(routerProvider).go('/not-a-page');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Go to calendar'));
    await tester.pumpAndSettle();
    expect(find.text('Good morning,\nJournal keeper'), findsOneWidget);
  });
}
