import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class AppointmentCardSkeleton extends StatelessWidget {
  const AppointmentCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final baseColor = scheme.surfaceContainerHighest;
    final highlightColor = scheme.surfaceContainerLow;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Shimmer.fromColors(
                  baseColor: baseColor,
                  highlightColor: highlightColor,
                  child: const CircleAvatar(radius: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _shimmerBlock(context, width: 140, height: 16),
                      const SizedBox(height: 6),
                      _shimmerBlock(context, width: 180, height: 12),
                      const SizedBox(height: 4),
                      _shimmerBlock(context, width: 100, height: 12),
                      const SizedBox(height: 8),
                      _shimmerBlock(context, width: 80, height: 12),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _shimmerBlock(context, width: 120, height: 14),
            const SizedBox(height: 8),
            ...List.generate(3, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    _shimmerBlock(context, width: 16, height: 16),
                    const SizedBox(width: 8),
                    Expanded(child: _shimmerBlock(context, height: 12)),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _shimmerBlock(context, height: 36)),
                const SizedBox(width: 12),
                Expanded(child: _shimmerBlock(context, height: 36)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _shimmerBlock(BuildContext context,
      {double? width, required double height}) {
    final scheme = Theme.of(context).colorScheme;
    return Shimmer.fromColors(
      baseColor: scheme.surfaceContainerHighest,
      highlightColor: scheme.surfaceContainerLow,
      child: Container(
        width: width ?? double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}
