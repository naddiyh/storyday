import 'package:flutter/material.dart';
import '../design/app_theme.dart';

/// A raised central action with its entire circle inside the hit-test bounds.
class JournalNavigationBar extends StatelessWidget {
  const JournalNavigationBar(
      {super.key, this.selectedIndex, required this.onSelect});
  final int? selectedIndex;
  final ValueChanged<int> onSelect;
  static const labels = ['Home', 'Memories', 'Create', 'Recap', 'Profile'];
  static const icons = [
    Icons.home_outlined,
    Icons.photo_library_outlined,
    Icons.add,
    Icons.bar_chart_outlined,
    Icons.person_outline
  ];
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
        top: false,
        child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppSpacing.pageWidth),
              child: Stack(children: [
                Positioned.fill(
                    top: 16,
                    child: DecoratedBox(
                        decoration: BoxDecoration(
                            color: colors.surfaceContainerLowest,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(28))))),
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var i = 0; i < labels.length; i++)
                            Expanded(
                                child: Semantics(
                              button: true,
                              selected: selectedIndex == i,
                              label: labels[i],
                              child: Tooltip(
                                  message: labels[i],
                                  excludeFromSemantics: true,
                                  child: InkWell(
                                    key: ValueKey(
                                        'nav-${labels[i].toLowerCase()}'),
                                    onTap: () => onSelect(i),
                                    borderRadius: BorderRadius.circular(18),
                                    child: ExcludeSemantics(
                                        child: ConstrainedBox(
                                            constraints: const BoxConstraints(
                                                minHeight: 84),
                                            child: Padding(
                                              padding: EdgeInsets.only(
                                                  top: i == 2 ? 0 : 28,
                                                  bottom: 12),
                                              child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    if (i == 2)
                                                      Container(
                                                          width: 64,
                                                          height: 64,
                                                          decoration: BoxDecoration(
                                                              color: colors
                                                                  .primary,
                                                              shape: BoxShape
                                                                  .circle,
                                                              border: Border.all(
                                                                  color: colors
                                                                      .surface,
                                                                  width: 4),
                                                              boxShadow: [
                                                                BoxShadow(
                                                                    color: colors
                                                                        .primary
                                                                        .withOpacity(
                                                                            .18),
                                                                    blurRadius:
                                                                        16,
                                                                    offset:
                                                                        const Offset(
                                                                            0,
                                                                            5))
                                                              ]),
                                                          child: Icon(Icons.add,
                                                              size: 32,
                                                              color: colors
                                                                  .onPrimary))
                                                    else ...[
                                                      Icon(icons[i],
                                                          size: 23,
                                                          color: selectedIndex ==
                                                                  i
                                                              ? colors.primary
                                                              : colors
                                                                  .onSurfaceVariant),
                                                      const SizedBox(height: 5),
                                                      Text(labels[i],
                                                          textAlign:
                                                              TextAlign.center,
                                                          style: Theme.of(
                                                                  context)
                                                              .textTheme
                                                              .labelSmall
                                                              ?.copyWith(
                                                                  fontSize: 10,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w700,
                                                                  color: selectedIndex ==
                                                                          i
                                                                      ? colors
                                                                          .primary
                                                                      : colors
                                                                          .onSurfaceVariant)),
                                                    ],
                                                  ]),
                                            ))),
                                  )),
                            )),
                        ])),
              ]),
            )));
  }
}
