import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../constants/app_strings.dart';

class QuickStatsRow extends StatelessWidget {
  final int totalTrips;
  final int upcomingCount;
  final int completedCount;

  const QuickStatsRow({
    super.key,
    required this.totalTrips,
    required this.upcomingCount,
    required this.completedCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCard(
          value: totalTrips.toString(),
          label: AppStrings.statsTotalTrips,
          icon: Icons.flight_takeoff_rounded,
          color: AppColors.primary,
        ),
        const SizedBox(width: 10),
        _StatCard(
          value: upcomingCount.toString(),
          label: AppStrings.statsUpcoming,
          icon: Icons.event_rounded,
          color: AppColors.secondary,
        ),
        const SizedBox(width: 10),
        _StatCard(
          value: completedCount.toString(),
          label: AppStrings.statsCompleted,
          icon: Icons.check_circle_rounded,
          color: AppColors.success,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
