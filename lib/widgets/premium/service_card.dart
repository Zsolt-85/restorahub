import 'package:flutter/material.dart';

import '../../helpers/format_helper.dart';
import '../../models/service.dart';
import 'brand_image.dart';

class ServiceCard extends StatelessWidget {
  const ServiceCard({
    super.key,
    required this.service,
    this.imageUrl,
    this.catalogKey,
    this.rating,
    required this.onTap,
  });

  final Service service;
  final String? imageUrl;
  final String? catalogKey;
  final double? rating;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label: service.name,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BrandImage(
                catalogKey: catalogKey,
                imageUrl: imageUrl,
                fallbackLabel: service.name,
                height: 96,
                borderRadius: 18,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.name,
                      style: text.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _subtitle(context),
                      style: text.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 6),
                    if (service.price != null)
                      Text(
                        FormatHelper.formatCurrency(service.price!),
                        style: text.titleMedium?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _subtitle(BuildContext context) {
    final parts = <String>[];
    if (service.durationMinutes != null) {
      parts.add('${service.durationMinutes} min');
    }
    if (rating != null) {
      parts.add('★ ${rating!.toStringAsFixed(1)}');
    }
    return parts.join(' · ');
  }
}
