import 'package:flutter/material.dart';
import '../design/app_theme.dart';

class PageContent extends StatelessWidget {
  const PageContent({required this.children, super.key});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Center(
            child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSpacing.pageWidth),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children),
        )),
      );
}

class PageHeading extends StatelessWidget {
  const PageHeading(
      {required this.eyebrow,
      required this.title,
      required this.subtitle,
      super.key});
  final String eyebrow;
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(eyebrow.toUpperCase(),
            style: theme.textTheme.labelMedium
                ?.copyWith(color: theme.colorScheme.primary, letterSpacing: 1)),
        const SizedBox(height: 10),
        Text(title, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 10),
        Text(subtitle,
            style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant, height: 1.5)),
      ]),
    );
  }
}

class EmptyPanel extends StatelessWidget {
  const EmptyPanel(
      {required this.icon,
      required this.title,
      required this.message,
      this.action,
      super.key});
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Card(
          child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(children: [
          CircleAvatar(
              radius: 30,
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              foregroundColor:
                  Theme.of(context).colorScheme.onSecondaryContainer,
              child: Icon(icon, size: 28)),
          const SizedBox(height: 20),
          Text(title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center),
          const SizedBox(height: 10),
          Text(message,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(height: 1.6)),
          if (action != null) ...[const SizedBox(height: 24), action!],
        ]),
      ));
}
