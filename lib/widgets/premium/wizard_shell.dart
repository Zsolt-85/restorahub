import 'package:flutter/material.dart';

class WizardShell extends StatelessWidget {
  const WizardShell({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.title,
    required this.child,
    this.footer,
    this.onBack,
  });

  final int currentStep;
  final int totalSteps;
  final String title;
  final Widget child;
  final Widget? footer;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        leading: onBack == null
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Back',
                onPressed: onBack,
              ),
        title: Text(title),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: List.generate(totalSteps, (i) {
                final filled = i <= currentStep;
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: EdgeInsets.only(
                        right: i == totalSteps - 1 ? 0 : 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: filled
                          ? scheme.primary
                          : scheme.surfaceContainerHighest,
                    ),
                  ),
                );
              }),
            ),
          ),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar:
          footer == null ? null : SafeArea(child: footer!),
    );
  }
}
