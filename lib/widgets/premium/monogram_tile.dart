import 'package:flutter/material.dart';

class MonogramTile extends StatelessWidget {
  const MonogramTile({
    super.key,
    required this.label,
    this.size = 52,
    this.borderRadius = 14,
  });

  final String label;
  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final initial =
        label.trim().isEmpty ? '?' : label.trim()[0].toUpperCase();
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: scheme.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
