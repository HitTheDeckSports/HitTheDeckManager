import 'package:flutter/material.dart';

class AppPage extends StatelessWidget {
  const AppPage({
    required this.title,
    required this.child,
    this.subtitle,
    this.actions = const [],
    super.key,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              subtitle!,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (actions.isNotEmpty) ...[
                      const SizedBox(width: 16),
                      Wrap(spacing: 12, runSpacing: 12, children: actions),
                    ],
                  ],
                ),
                const SizedBox(height: 24),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
