import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/widgets/journal_navigation_bar.dart';
import 'create_navigation.dart';

class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});
  final StatefulNavigationShell navigationShell;
  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(child: navigationShell),
        bottomNavigationBar: JournalNavigationBar(
            selectedIndex: navigationShell.currentIndex >= 2
                ? navigationShell.currentIndex + 1
                : navigationShell.currentIndex,
            onSelect: (i) => i == 2
                ? openCreatePage(context)
                : navigationShell.goBranch(i > 2 ? i - 1 : i)),
      );
}
