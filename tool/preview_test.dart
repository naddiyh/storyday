// Run with: flutter --no-version-check test tool/preview_test.dart
// Renders the actual Flutter UI without an emulator. Outputs stay in build/.
import 'dart:io';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lenote/app/app.dart';
import 'package:lenote/app/router.dart';
import 'package:lenote/core/design/app_theme.dart';
import 'package:lenote/features/themes/data/appearance_store.dart';
import 'package:lenote/features/themes/domain/appearance.dart';

class _PreviewStore implements AppearanceStore {
  @override
  Future<Appearance> load() async => const Appearance();
  @override
  Future<void> save(Appearance appearance) async {}
}

void main() {
  testWidgets('render foundation previews', (tester) async {
    await tester.runAsync(() async {
      final config = jsonDecode(
              await File('.dart_tool/package_config.json').readAsString())
          as Map<String, dynamic>;
      final flutter = (config['packages'] as List)
          .cast<Map<String, dynamic>>()
          .firstWhere((p) => p['name'] == 'flutter');
      final flutterRoot = Uri.parse('${flutter['rootUri']}/');
      final fontRoot =
          flutterRoot.resolve('../../bin/cache/artifacts/material_fonts/');
      for (final font in {
        'Roboto': 'roboto-regular.ttf',
        'MaterialIcons': 'materialicons-regular.otf'
      }.entries) {
        final bytes =
            await File.fromUri(fontRoot.resolve(font.value)).readAsBytes();
        await (FontLoader(font.key)
              ..addFont(Future.value(ByteData.sublistView(bytes))))
            .load();
      }
    });
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer(overrides: [
      appearanceStoreProvider.overrideWithValue(_PreviewStore())
    ]);
    addTearDown(container.dispose);
    final boundaryKey = GlobalKey();
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: RepaintBoundary(key: boundaryKey, child: const LenoteApp())));
    await tester.pumpAndSettle();
    Future<void> capture(String name) async {
      final boundary = boundaryKey.currentContext!.findRenderObject()!
          as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage();
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('build/previews/$name.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
      });
    }

    await capture('calendar');
    for (final route in ['/search', '/create', '/recap', '/profile']) {
      container.read(routerProvider).go(route);
      await tester.pumpAndSettle();
      await capture('scrapbook-${route.substring(1)}');
    }

    container.read(routerProvider).go('/themes');
    await tester.pumpAndSettle();
    await capture('themes');
    container.read(routerProvider).go('/calendar');
    for (final style in JournalTheme.values) {
      for (final mode in [ThemeMode.light, ThemeMode.dark]) {
        await container
            .read(appearanceProvider.notifier)
            .update(Appearance(theme: style, mode: mode));
        await tester.pumpAndSettle();
        await capture('${style.id}-${mode.name}');
      }
    }
    expect(tester.takeException(), isNull);
  });
}
