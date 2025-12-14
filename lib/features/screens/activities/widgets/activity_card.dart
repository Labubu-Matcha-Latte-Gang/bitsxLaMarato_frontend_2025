import 'package:flutter/material.dart';

import '../../../../models/activity_models.dart';
import '../../../../utils/app_colors.dart';

class ActivityCard extends StatelessWidget {
  final Activity activity;
  final bool isDarkMode;
  final VoidCallback? onTap;

  const ActivityCard({
    super.key,
    required this.activity,
    required this.isDarkMode,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: AppColors.getSecondaryBackgroundColor(isDarkMode)
                .withOpacity(0.92),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.containerShadow,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color:
                  AppColors.getPrimaryButtonColor(isDarkMode).withOpacity(0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.local_activity_outlined,
                    color: AppColors.getPrimaryButtonColor(isDarkMode),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      activity.title.startsWith('ACTIVITAT - ')
                          ? activity.title.substring(12)
                          : activity.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.getPrimaryTextColor(isDarkMode),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                activity.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.getSecondaryTextColor(isDarkMode),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoChip(
                    label: 'Tipus: ${activity.activityType}',
                    icon: Icons.category_outlined,
                    isDarkMode: isDarkMode,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isDarkMode;

  const _InfoChip({
    required this.label,
    required this.icon,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.getBlurContainerColor(isDarkMode),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: AppColors.getPrimaryButtonColor(isDarkMode),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: AppColors.getPrimaryTextColor(isDarkMode),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
