import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/brand_config.dart';
import '../../providers/business_provider.dart';
import 'brand_image.dart';

class TenantHero extends StatelessWidget {
  const TenantHero({super.key});

  @override
  Widget build(BuildContext context) {
    final business = context.watch<BusinessProvider>().currentBusiness;
    final name = business?.name ?? BrandConfig.current.displayName;
    final logoUrl =
        business?.branding?.logo ?? business?.logoUrl;
    final tagline = business?.address ?? BrandConfig.current.tagline;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        BrandImage(
          imageUrl: logoUrl,
          fallbackLabel: name,
          width: 72,
          height: 72,
          borderRadius: 20,
        ),
        const SizedBox(height: 16),
        Text(
          name,
          style: Theme.of(context).textTheme.displaySmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          tagline,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
