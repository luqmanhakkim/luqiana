import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../config/theme.dart';
import '../../constants/app_strings.dart';
import '../../core/models/itinerary.dart';
import '../../core/models/trip.dart';
import '../home/application/trips_notifier.dart';
import 'application/itinerary_notifier.dart';

class ItineraryScreen extends HookConsumerWidget {
  const ItineraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // — Watch providers —
    final allDays = ref.watch(itineraryProvider);
    final trips = ref.watch(tripsProvider);

    // — Derive active trip (ongoing, else first) —
    final trip = trips.firstWhere(
      (t) => t.status == TripStatus.ongoing,
      orElse: () => trips.first,
    );

    // — Derive days for this trip, sorted by date —
    final days = allDays
        .where((d) => d.tripId == trip.id)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    // — Compute index of today inside the days list —
    final today = DateTime.now();
    final todayIndex = days.indexWhere(
      (d) =>
          d.date.year == today.year &&
          d.date.month == today.month &&
          d.date.day == today.day,
    );

    // — Local hook state: selected day tab —
    final selectedDayIndex = useState(todayIndex == -1 ? 0 : todayIndex);

    // — useEffect: reset selected day whenever the active trip changes —
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final idx = days.indexWhere(
          (d) =>
              d.date.year == today.year &&
              d.date.month == today.month &&
              d.date.day == today.day,
        );
        selectedDayIndex.value = idx == -1 ? 0 : idx;
      });
      return null;
    }, [trip.id]);

    // — Callback that calls the notifier —
    void onToggleActivity(ItineraryDay day, String activityId) {
      ref.read(itineraryProvider.notifier).toggleActivity(
        tripId: trip.id,
        date: day.date,
        activityId: activityId,
      );
    }

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        _buildAppBar(trip),
        if (days.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyItinerary(),
          )
        else ...[
          SliverToBoxAdapter(
            child: _buildDayTabs(
              days: days,
              selectedIndex: selectedDayIndex.value,
              onDaySelected: (i) => selectedDayIndex.value = i,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: _buildActivities(
                day: days[selectedDayIndex.value],
                onToggle: (activityId) =>
                    onToggleActivity(days[selectedDayIndex.value], activityId),
              ),
            ),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildAppBar(Trip trip) {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      stretch: true,
      backgroundColor: AppColors.primaryDark,
      actions: [
        IconButton(
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          onPressed: () {},
        ),
        const SizedBox(width: 4),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primaryDark, AppColors.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 60, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    AppStrings.itineraryTitle,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        color: Colors.white60,
                        size: 13,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${trip.name} · ${trip.destination}',
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDayTabs({
    required List<ItineraryDay> days,
    required int selectedIndex,
    required ValueChanged<int> onDaySelected,
  }) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final today = DateTime.now();

    return Container(
      color: AppColors.surface,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          children: List.generate(days.length, (index) {
            final day = days[index];
            final isSelected = index == selectedIndex;
            final isToday = day.date.year == today.year &&
                day.date.month == today.month &&
                day.date.day == today.day;

            return GestureDetector(
              onTap: () => onDaySelected(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: isToday && !isSelected
                      ? Border.all(color: AppColors.primary, width: 1.5)
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${AppStrings.itineraryDay} ${index + 1}',
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white70
                            : AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${day.date.day} ${months[day.date.month - 1]}',
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isToday) ...[
                      const SizedBox(height: 4),
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildActivities({
    required ItineraryDay day,
    required ValueChanged<String> onToggle,
  }) {
    if (day.activities.isEmpty) return const _EmptyDay();

    return Column(
      children: List.generate(day.activities.length, (index) {
        return _ActivityTile(
          activity: day.activities[index],
          isLast: index == day.activities.length - 1,
          onToggle: () => onToggle(day.activities[index].id),
        );
      }),
    );
  }
}

// ---------------------------------------------------------------------------
// Private stateless widgets — pure UI, no state needed
// ---------------------------------------------------------------------------

class _ActivityTile extends StatelessWidget {
  final ItineraryActivity activity;
  final bool isLast;
  final VoidCallback onToggle;

  const _ActivityTile({
    required this.activity,
    required this.isLast,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 48,
            child: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Text(
                activity.time,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              const SizedBox(height: 16),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color:
                      activity.isDone ? AppColors.success : AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: activity.isDone
                        ? AppColors.success
                        : AppColors.primary.withOpacity(0.3),
                    width: 2,
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: AppColors.divider,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              margin: EdgeInsets.only(bottom: isLast ? 0 : 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: onToggle,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _CategoryIcon(category: activity.category),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activity.title,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: activity.isDone
                                      ? AppColors.textHint
                                      : AppColors.textPrimary,
                                  decoration: activity.isDone
                                      ? TextDecoration.lineThrough
                                      : null,
                                  decorationColor: AppColors.textHint,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_outlined,
                                    size: 12,
                                    color: AppColors.textHint,
                                  ),
                                  const SizedBox(width: 3),
                                  Expanded(
                                    child: Text(
                                      activity.location,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textHint,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              if (activity.notes != null) ...[
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        AppColors.warning.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.lightbulb_outline_rounded,
                                        size: 12,
                                        color: AppColors.warning,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          activity.notes!,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.warning,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          activity.isDone
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: activity.isDone
                              ? AppColors.success
                              : AppColors.textHint,
                          size: 22,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryIcon extends StatelessWidget {
  final ActivityCategory category;

  const _CategoryIcon({required this.category});

  @override
  Widget build(BuildContext context) {
    final IconData icon;
    final Color color;

    switch (category) {
      case ActivityCategory.food:
        icon = Icons.restaurant_rounded;
        color = const Color(0xFFEA580C);
        break;
      case ActivityCategory.transport:
        icon = Icons.directions_car_rounded;
        color = const Color(0xFF0284C7);
        break;
      case ActivityCategory.hotel:
        icon = Icons.hotel_rounded;
        color = const Color(0xFF7C3AED);
        break;
      case ActivityCategory.sightseeing:
        icon = Icons.photo_camera_rounded;
        color = const Color(0xFF0D9488);
        break;
      case ActivityCategory.shopping:
        icon = Icons.shopping_bag_rounded;
        color = const Color(0xFFBE185D);
        break;
      case ActivityCategory.other:
        icon = Icons.more_horiz_rounded;
        color = AppColors.textSecondary;
        break;
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }
}

class _EmptyItinerary extends StatelessWidget {
  const _EmptyItinerary();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.map_outlined,
                size: 44,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              AppStrings.itineraryNoData,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              AppStrings.itineraryNoDataSub,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyDay extends StatelessWidget {
  const _EmptyDay();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.event_note_rounded,
              size: 48,
              color: AppColors.textHint.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No activities for this day',
              style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tap + to add one',
              style: TextStyle(fontSize: 13, color: AppColors.textHint),
            ),
          ],
        ),
      ),
    );
  }
}
