import 'package:flutter/material.dart';

/// Equal-height pairs without a fixed aspect ratio that clips larger text.
class ResponsiveCardGrid extends StatelessWidget {
  const ResponsiveCardGrid({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        final columns = constraints.maxWidth < 250 ||
                MediaQuery.textScalerOf(context).scale(14) > 20
            ? 1
            : 2;
        return Column(children: [
          for (var start = 0; start < children.length; start += columns)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: IntrinsicHeight(
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var column = 0; column < columns; column++) ...[
                        if (column > 0) const SizedBox(width: 10),
                        Expanded(
                            child: start + column < children.length
                                ? children[start + column]
                                : const SizedBox.shrink()),
                      ],
                    ]),
              ),
            ),
        ]);
      });
}
