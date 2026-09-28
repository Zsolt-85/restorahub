import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'monogram_tile.dart';

class BrandImage extends StatelessWidget {
  const BrandImage({
    super.key,
    required this.imageUrl,
    required this.fallbackLabel,
    this.catalogKey,
    this.width,
    this.height,
    this.borderRadius = 14,
    this.fit = BoxFit.cover,
  });

  final String? imageUrl;
  final String fallbackLabel;
  final String? catalogKey;
  final double? width;
  final double? height;
  final double borderRadius;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (catalogKey != null && catalogKey!.startsWith('assets/')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.asset(
          catalogKey!,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, _, __) => MonogramTile(
            label: fallbackLabel,
            size: height ?? width ?? 52,
            borderRadius: 0,
          ),
        ),
      );
    }
    if (catalogKey != null &&
        catalogKey!.isNotEmpty &&
        !catalogKey!.startsWith('assets/')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: CachedNetworkImage(
          imageUrl: catalogKey!,
          width: width,
          height: height,
          fit: fit,
          fadeInDuration: MediaQuery.of(context).disableAnimations
              ? Duration.zero
              : const Duration(milliseconds: 200),
          placeholder: (context, _) => const _ShimmerBlock(),
          errorWidget: (context, _, __) => MonogramTile(
            label: fallbackLabel,
            size: height ?? width ?? 52,
            borderRadius: 0,
          ),
        ),
      );
    }
    final url = imageUrl?.trim() ?? '';
    if (url.isEmpty) {
      return MonogramTile(
        label: fallbackLabel,
        size: height ?? width ?? 52,
        borderRadius: borderRadius,
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CachedNetworkImage(
        imageUrl: url,
        width: width,
        height: height,
        fit: fit,
        fadeInDuration: MediaQuery.of(context).disableAnimations
            ? Duration.zero
            : const Duration(milliseconds: 200),
        placeholder: (context, _) => const _ShimmerBlock(),
        errorWidget: (context, _, __) => MonogramTile(
          label: fallbackLabel,
          size: height ?? width ?? 52,
          borderRadius: 0,
        ),
      ),
    );
  }
}

class _ShimmerBlock extends StatelessWidget {
  const _ShimmerBlock();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
    );
  }
}
