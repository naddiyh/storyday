import 'package:flutter/material.dart';
import 'journal_character.dart';
import '../design/tokens.dart';
import '../design/scrapbook_palette.dart';

class ScrapbookHeader extends StatelessWidget {
  const ScrapbookHeader(
      {super.key, required this.title, required this.subtitle, this.action});
  final String title, subtitle;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(children: [
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: DesignTokens.pageTitle,
                  letterSpacing: -0.8)),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall)
          ]
        ])),
        if (action != null) action!,
        const SizedBox(width: 12),
        const JournalCharacter()
      ]));
}

class ScrapbookPanel extends StatelessWidget {
  const ScrapbookPanel({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) =>
      Card(child: Padding(padding: const EdgeInsets.all(12), child: child));
}

class ActivityTile extends StatelessWidget {
  const ActivityTile(
      {super.key,
      required this.icon,
      required this.title,
      required this.subtitle,
      this.onTap});
  final IconData icon;
  final String title, subtitle;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: Theme.of(context).extension<ScrapbookPalette>()!.colors[
                  icon == Icons.checklist
                      ? 1
                      : icon == Icons.event_outlined
                          ? 2
                          : 4],
              borderRadius: BorderRadius.circular(14)),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary)),
      title: Text(title,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall),
      onTap: onTap);
}
