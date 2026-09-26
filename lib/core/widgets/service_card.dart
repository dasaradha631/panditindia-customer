import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../../models/service_model.dart';

/// Featured service tile (cream icon well, title, price, rating).
class ServiceCard extends StatelessWidget {
  const ServiceCard({super.key, required this.service, this.onTap, this.width});

  final ServiceModel service;
  final VoidCallback? onTap;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return SizedBox(
      width: width,
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        color: AppColors.primarySoft,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _iconFor(service.icon),
                        color: AppColors.primary,
                        size: 21,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.star_rounded,
                        size: 16, color: AppColors.gold),
                    const SizedBox(width: 3),
                    Text(
                      service.rating.toStringAsFixed(1),
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  service.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  service.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
                const Spacer(),
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        service.priceLabel,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (service.duration != null)
                      Text(
                        service.duration!,
                        style: theme.textTheme.labelSmall,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static IconData _iconFor(String? key) => switch (key) {
        'fire' => Icons.local_fire_department_rounded,
        'home' => Icons.home_rounded,
        'stars' => Icons.auto_awesome_rounded,
        'book' => Icons.menu_book_rounded,
        'rings' => Icons.favorite_rounded,
        'flame' => Icons.whatshot_rounded,
        _ => Icons.temple_buddhist_rounded,
      };
}
