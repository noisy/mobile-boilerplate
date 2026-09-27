import 'package:flutter/widgets.dart';

/// Widest a column of text and buttons gets, so tablets do not stretch it.
const contentMaxWidth = 480.0;

/// Centers [child] with the standard page padding and caps its width at
/// [contentMaxWidth]. [child] gets at least the screen's height, so a
/// Column with Spacers fills it, and scrolls when it needs more (small
/// phones, large text).
class ContentColumn extends StatelessWidget {
  const ContentColumn({super.key, required this.child});

  static const _padding = 24.0;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: contentMaxWidth,
              minHeight: constraints.maxHeight,
            ),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.all(_padding),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
