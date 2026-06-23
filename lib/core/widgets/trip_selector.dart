import 'package:flutter/material.dart';

import '../../config/theme.dart';
import '../../constants/app_strings.dart';
import '../models/trip.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Public API
// ─────────────────────────────────────────────────────────────────────────────
//
// Drop-in replacement for the old _TripSelectorRow.
// Shows a compact selector button; tapping it opens a bottom-sheet picker.
//
// Usage (shown only when trips.length > 1):
//
//   if (trips.length > 1)
//     SliverToBoxAdapter(
//       child: TripSelectorButton(
//         trips: trips,
//         selectedIndex: selectedIdx.value,
//         onSelected: (i) => selectedIdx.value = i,
//       ),
//     ),

class TripSelectorButton extends StatelessWidget {
  final List<Trip> trips;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const TripSelectorButton({
    super.key,
    required this.trips,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final trip = trips[selectedIndex];
    final gradient = AppColors
        .tripGradients[trip.gradientIndex % AppColors.tripGradients.length];
    final dotColor = gradient[0];

    return Container(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: GestureDetector(
          onTap: () => _openSheet(context),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                // Gradient color indicator
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                // Trip name + destination
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        trip.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${trip.destination}, ${trip.country}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Status badge
                _StatusChip(status: trip.status),
                const SizedBox(width: 8),
                // "N trips" count + chevron
                Text(
                  '${trips.length} trips',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textHint,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: dotColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TripSelectorSheet(
        trips: trips,
        selectedIndex: selectedIndex,
        onSelected: (i) {
          onSelected(i);
          Navigator.of(context).pop();
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _TripSelectorSheet extends StatelessWidget {
  final List<Trip> trips;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _TripSelectorSheet({
    required this.trips,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 8, 4),
            child: Row(
              children: [
                const Text(
                  'Switch Trip',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.divider, height: 1),
          // Trip list
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.55,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: trips.length,
              separatorBuilder: (_, __) => const Divider(
                color: AppColors.divider,
                height: 1,
                indent: 20,
                endIndent: 20,
              ),
              itemBuilder: (context, index) {
                final trip = trips[index];
                final isSelected = index == selectedIndex;
                final gradient = AppColors.tripGradients[
                    trip.gradientIndex % AppColors.tripGradients.length];

                return InkWell(
                  onTap: () => onSelected(index),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        // Gradient avatar circle
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: gradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              trip.destination[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Trip details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                trip.name,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? context.appPrimary
                                      : AppColors.textPrimary,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${trip.destination}, ${trip.country}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Status badge
                        _StatusChip(status: trip.status),
                        const SizedBox(width: 10),
                        // Selected checkmark
                        AnimatedOpacity(
                          opacity: isSelected ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 150),
                          child: Icon(
                            Icons.check_circle_rounded,
                            size: 20,
                            color: context.appPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status chip — reused in button and list rows
// ─────────────────────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final TripStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final String label;

    switch (status) {
      case TripStatus.ongoing:
        bg = AppColors.success.withOpacity(0.12);
        fg = AppColors.success;
        label = AppStrings.statusOngoing;
      case TripStatus.upcoming:
        bg = context.appPrimary.withOpacity(0.1);
        fg = context.appPrimary;
        label = AppStrings.statusUpcoming;
      case TripStatus.completed:
        bg = AppColors.textHint.withOpacity(0.12);
        fg = AppColors.textSecondary;
        label = AppStrings.statusCompleted;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: fg,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
