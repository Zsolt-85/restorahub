import 'package:flutter/material.dart';

import 'brand_image.dart';

class ProProfileHeader extends StatelessWidget {
  const ProProfileHeader({
    super.key,
    required this.name,
    this.specialty,
    this.imageUrl,
    this.catalogKey,
    this.rating,
    this.selected = false,
    this.onTap,
  });

  final String name;
  final String? specialty;
  final String? imageUrl;
  final String? catalogKey;
  final double? rating;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? scheme.primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            BrandImage(
              catalogKey: catalogKey,
              imageUrl: imageUrl,
              fallbackLabel: name,
              width: 52,
              height: 52,
              borderRadius: 999,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style:
                        text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (specialty != null && specialty!.isNotEmpty)
                    Text(
                      specialty!,
                      style: text.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  if (rating != null)
                    Text(
                      '★ ${rating!.toStringAsFixed(1)}',
                      style: text.bodySmall?.copyWith(
                        color: scheme.tertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
            if (selected)
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check,
                    size: 14, color: scheme.onPrimary,
                    semanticLabel: 'Selected'),
              )
            else
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: scheme.outlineVariant, width: 2),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
