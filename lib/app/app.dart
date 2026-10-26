import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/themes/data/appearance_store.dart';
import 'router.dart';

class LenoteApp extends ConsumerWidget {
  const LenoteApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
        title: 'Lenote',
        debugShowCheckedModeBanner: false,
        theme: ref
            .watch(appearanceProvider)
            .theme
            .build(brightness: Brightness.light),
        darkTheme: ref
            .watch(appearanceProvider)
            .theme
            .build(brightness: Brightness.dark),
        themeMode: ref.watch(appearanceProvider).mode,
        themeAnimationDuration: WidgetsBinding.instance.platformDispatcher
                .accessibilityFeatures.disableAnimations
            ? Duration.zero
            : const Duration(milliseconds: 180),
        routerConfig: ref.watch(routerProvider),
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        locale: const Locale('en', 'GB'),
        supportedLocales: const [Locale('en', 'GB')],
      );
}
