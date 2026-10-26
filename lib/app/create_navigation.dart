import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final _openCreateRoutes = Expando<bool>();

/// A full page above the tab shell, with a guard against repeated activation.
void openCreatePage(BuildContext context) {
  final router = GoRouter.of(context);
  if (_openCreateRoutes[router] == true ||
      router.routerDelegate.currentConfiguration.last.route.path == '/create') {
    return;
  }
  _openCreateRoutes[router] = true;
  router
      .push<void>('/create')
      .whenComplete(() => _openCreateRoutes[router] = false);
}
