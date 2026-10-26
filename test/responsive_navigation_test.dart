import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lenote/app/app.dart';
import 'package:lenote/app/router.dart';
import 'package:lenote/core/widgets/journal_character.dart';
import 'package:lenote/core/design/app_theme.dart';
import 'package:lenote/features/calendar/presentation/calendar_screen.dart';
import 'package:lenote/features/memories/demo_memories.dart';
import 'package:lenote/features/themes/data/appearance_store.dart';
import 'foundation_test.dart' show MemoryPreferences;

void main() {
  setUpAll(() async {
    final loader = FontLoader('PlusJakartaSans')
      ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'));
    await loader.load();
  });
  testWidgets('theme preview cards announce button roles', (tester) async {
    final semantics = tester.ensureSemantics();
    final container = ProviderContainer(overrides: [
      appearanceStoreProvider
          .overrideWithValue(PreferencesAppearanceStore(MemoryPreferences()))
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container, child: const LenoteApp()));
    container.read(routerProvider).go('/themes');
    await tester.pumpAndSettle();
    expect(
        tester
            .getSemantics(find.byKey(const ValueKey('preview-calm_natural')))
            .hasFlag(SemanticsFlag.isButton),
        isTrue);
    semantics.dispose();
  });
  testWidgets(
      'repeated theme activation opens one preview and Apply dismisses it',
      (tester) async {
    final container = ProviderContainer(overrides: [
      appearanceStoreProvider
          .overrideWithValue(PreferencesAppearanceStore(MemoryPreferences()))
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container, child: const LenoteApp()));
    container.read(routerProvider).go('/themes');
    await tester.pumpAndSettle();
    final card = find.byKey(const ValueKey('theme-calm_natural'));
    // Browser semantics can deliver duplicate activation before a new frame.
    final activate = tester.widget<InkWell>(card).onTap!;
    activate();
    activate();
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.text('Apply theme'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(container.read(appearanceProvider).theme, JournalTheme.sage);
    expect(tester.takeException(), isNull);
  });
  const sizes = [
    Size(320, 568),
    Size(390, 844),
    Size(844, 390),
    Size(768, 1024),
    Size(1440, 900)
  ];
  for (final size in sizes) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
          'all destinations fit ${size.width}x${size.height}, text $scale',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final container = ProviderContainer(overrides: [
          appearanceStoreProvider.overrideWithValue(
              PreferencesAppearanceStore(MemoryPreferences()))
        ]);
        addTearDown(container.dispose);
        await tester.pumpWidget(UncontrolledProviderScope(
            container: container, child: const LenoteApp()));
        await tester.pumpAndSettle();
        for (final route in [
          '/calendar',
          '/search',
          '/create',
          '/recap',
          '/profile',
          '/profile/edit',
          '/themes'
        ]) {
          container.read(routerProvider).go(route);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull,
              reason: '$route at $size, scale $scale');
        }
      });
    }
  }

  testWidgets(
      'plus opens one Create page and preserves selected date; filters follow month',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final date = DateTime(2026, 10, 22);
    final container = ProviderContainer(overrides: [
      appearanceStoreProvider
          .overrideWithValue(PreferencesAppearanceStore(MemoryPreferences())),
      selectedDateProvider.overrideWith((ref) => date),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container, child: const LenoteApp()));
    await tester.pumpAndSettle();
    expect(find.text('Week'), findsNothing);
    expect(find.text('Month'), findsNothing);
    expect(find.text('Create'), findsNothing);
    final filters = find.byKey(const Key('calendar-filters'));
    expect(
        tester.getTopLeft(filters).dy,
        greaterThan(
            tester.getBottomLeft(find.byKey(const Key('calendar-month'))).dy));
    expect(tester.getTopLeft(find.text('All')).dy,
        tester.getTopLeft(find.text('Schedule')).dy);
    await tester.tap(find.text('Journal'));
    await tester.pumpAndSettle();
    expect(container.read(calendarFilterProvider), 'Journal');
    await tester.tap(find.byTooltip('Create'));
    await tester.tap(find.byTooltip('Create'));
    await tester.pumpAndSettle();
    expect(
        container
            .read(routerProvider)
            .routerDelegate
            .currentConfiguration
            .last
            .route
            .path,
        '/create');
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.text('Create a moment'), findsOneWidget);
    expect(find.text('October 22, 2026'), findsOneWidget);
    expect(
        tester
            .getSize(find.byKey(const ValueKey('format-Journal / Note')))
            .height,
        tester
            .getSize(find.byKey(const ValueKey('format-Checklist / To-do')))
            .height);
    expect(container.read(selectedDateProvider), date);
    expect(find.byType(JournalCharacter), findsOneWidget);
    final image = tester.widget<Image>(find.descendant(
        of: find.byType(JournalCharacter), matching: find.byType(Image)));
    expect(image.fit, BoxFit.contain);
    expect(tester.takeException(), isNull);
    expect(find.text('Home'), findsNothing);
    await tester.tap(find.byTooltip('Close Create'));
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Create a moment'), findsNothing);
    expect(container.read(selectedDateProvider), date);
    expect(container.read(calendarFilterProvider), 'Journal');
  });
}
