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

    // — Guard: no trips yet —
    if (trips.isEmpty) {
      return const Scaffold(
        body: Center(child: Text(AppStrings.emptyTitle)),
      );
    }

    // — Selectable trip (default to ongoing, else first) —
    final defaultTripIdx =
        trips.indexWhere((t) => t.status == TripStatus.ongoing);
    final selectedTripIndex =
        useState(defaultTripIdx == -1 ? 0 : defaultTripIdx);
    final trip = trips[selectedTripIndex.value];

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

    // Clamp prevents index-out-of-range during the single frame before the
    // useEffect resets selectedDayIndex after a trip switch.
    final safeDay =
        days.isEmpty ? 0 : selectedDayIndex.value.clamp(0, days.length - 1);

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

    void onAddActivity() {
      final initialDate = days.isNotEmpty ? days[safeDay].date : trip.startDate;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _AddActivitySheet(
          tripId: trip.id,
          initialDate: initialDate,
          tripStart: trip.startDate,
          tripEnd: trip.endDate,
        ),
      );
    }

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        _buildAppBar(trip, onAdd: onAddActivity),
        if (trips.length > 1)
          SliverToBoxAdapter(
            child: _TripSelectorRow(
              trips: trips,
              selectedIndex: selectedTripIndex.value,
              onSelected: (i) => selectedTripIndex.value = i,
            ),
          ),
        if (days.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyItinerary(),
          )
        else ...[
          SliverToBoxAdapter(
            child: _buildDayTabs(
              days: days,
              selectedIndex: safeDay,
              onDaySelected: (i) => selectedDayIndex.value = i,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: _buildActivities(
                day: days[safeDay],
                onToggle: (activityId) =>
                    onToggleActivity(days[safeDay], activityId),
                onDelete: (activityId) =>
                    ref.read(itineraryProvider.notifier).deleteActivity(
                          tripId: trip.id,
                          date: days[safeDay].date,
                          activityId: activityId,
                        ),
              ),
            ),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildAppBar(Trip trip, {required VoidCallback? onAdd}) {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      stretch: true,
      backgroundColor: AppColors.primaryDark,
      actions: [
        IconButton(
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          onPressed: onAdd,
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
    required ValueChanged<String> onDelete,
  }) {
    if (day.activities.isEmpty) return const _EmptyDay();

    return Column(
      children: List.generate(day.activities.length, (index) {
        final activity = day.activities[index];
        return _ActivityTile(
          key: ValueKey(activity.id),
          activity: activity,
          isLast: index == day.activities.length - 1,
          onToggle: () => onToggle(activity.id),
          onDelete: () => onDelete(activity.id),
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
  final VoidCallback onDelete;

  const _ActivityTile({
    super.key,
    required this.activity,
    required this.isLast,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(activity.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        margin: EdgeInsets.only(bottom: isLast ? 0 : 10),
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_rounded, color: Colors.white, size: 22),
            SizedBox(height: 4),
            Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      child: IntrinsicHeight(
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
    ),    // closes IntrinsicHeight
  );      // closes Dismissible
  }
}

// ---------------------------------------------------------------------------
// Category icon helper
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// Trip selector row — shown when the user has more than one trip
// ---------------------------------------------------------------------------

class _TripSelectorRow extends StatelessWidget {
  final List<Trip> trips;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _TripSelectorRow({
    required this.trips,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: List.generate(trips.length, (index) {
            final t = trips[index];
            final isSelected = index == selectedIndex;
            final dotColor = AppColors
                .tripGradients[t.gradientIndex % AppColors.tripGradients.length]
                    [0];

            return GestureDetector(
              onTap: () => onSelected(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.divider,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white70 : dotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          t.name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          t.destination,
                          style: TextStyle(
                            fontSize: 11,
                            color: isSelected
                                ? Colors.white70
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// Add Activity bottom sheet
// ---------------------------------------------------------------------------

class _AddActivitySheet extends HookConsumerWidget {
  final String tripId;
  final DateTime initialDate;
  final DateTime tripStart;
  final DateTime tripEnd;

  const _AddActivitySheet({
    required this.tripId,
    required this.initialDate,
    required this.tripStart,
    required this.tripEnd,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final titleCtrl = useTextEditingController();
    final locationCtrl = useTextEditingController();
    final notesCtrl = useTextEditingController();
    final now = TimeOfDay.now();
    final selectedTime = useState(TimeOfDay(hour: now.hour, minute: 0));
    final selectedDate = useState(initialDate);
    final selectedCategory = useState(ActivityCategory.sightseeing);

    String formatTime(TimeOfDay t) =>
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

    String formatDate(DateTime d) {
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${d.day} ${months[d.month - 1]} ${d.year}';
    }

    Future<void> pickTime() async {
      final picked = await showTimePicker(
        context: context,
        initialTime: selectedTime.value,
        builder: (ctx, child) => MediaQuery(
          data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        ),
      );
      if (picked != null) selectedTime.value = picked;
    }

    Future<void> pickDate() async {
      final picked = await showDatePicker(
        context: context,
        initialDate: selectedDate.value,
        firstDate: tripStart,
        lastDate: tripEnd,
      );
      if (picked != null) selectedDate.value = picked;
    }

    void submit() {
      if (!formKey.currentState!.validate()) return;
      final notesText = notesCtrl.text.trim();
      final activity = ItineraryActivity(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        time: formatTime(selectedTime.value),
        title: titleCtrl.text.trim(),
        location: locationCtrl.text.trim(),
        category: selectedCategory.value,
        notes: notesText.isEmpty ? null : notesText,
      );
      ref.read(itineraryProvider.notifier).addActivity(
            tripId: tripId,
            date: selectedDate.value,
            activity: activity,
          );
      Navigator.of(context).pop();
    }

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
          const SizedBox(height: 4),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
            child: Row(
              children: [
                const Text(
                  'Add Activity',
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
          // Scrollable form body
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20,
                4,
                20,
                MediaQuery.of(context).viewInsets.bottom + 28,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // — Date picker row —
                    GestureDetector(
                      onTap: pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Date',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              formatDate(selectedDate.value),
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.textHint,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // — Time picker row —
                    GestureDetector(
                      onTap: pickTime,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.access_time_rounded,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Time',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              formatTime(selectedTime.value),
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.textHint,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // — Title —
                    TextFormField(
                      controller: titleCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: _inputDecoration(
                        'Activity Title',
                        Icons.title_rounded,
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    // — Location —
                    TextFormField(
                      controller: locationCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: _inputDecoration(
                        'Location',
                        Icons.location_on_outlined,
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 20),
                    // — Category —
                    const Text(
                      'Category',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _CategorySelector(
                      selected: selectedCategory.value,
                      onChanged: (c) => selectedCategory.value = c,
                    ),
                    const SizedBox(height: 20),
                    // — Notes (optional) —
                    const Text(
                      'Notes  (optional)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: notesCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'e.g. Book tickets in advance',
                        hintStyle: const TextStyle(
                          color: AppColors.textHint,
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: AppColors.surfaceVariant,
                        contentPadding: const EdgeInsets.all(16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.divider),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.divider),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    // — Submit button —
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Add Activity',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
      prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
      filled: true,
      fillColor: AppColors.surfaceVariant,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Category chip selector
// ---------------------------------------------------------------------------

class _CategorySelector extends StatelessWidget {
  final ActivityCategory selected;
  final ValueChanged<ActivityCategory> onChanged;

  const _CategorySelector({
    required this.selected,
    required this.onChanged,
  });

  static IconData _icon(ActivityCategory cat) {
    switch (cat) {
      case ActivityCategory.food:
        return Icons.restaurant_rounded;
      case ActivityCategory.transport:
        return Icons.directions_car_rounded;
      case ActivityCategory.hotel:
        return Icons.hotel_rounded;
      case ActivityCategory.sightseeing:
        return Icons.photo_camera_rounded;
      case ActivityCategory.shopping:
        return Icons.shopping_bag_rounded;
      case ActivityCategory.other:
        return Icons.more_horiz_rounded;
    }
  }

  static Color _color(ActivityCategory cat) {
    switch (cat) {
      case ActivityCategory.food:
        return const Color(0xFFEA580C);
      case ActivityCategory.transport:
        return const Color(0xFF0284C7);
      case ActivityCategory.hotel:
        return const Color(0xFF7C3AED);
      case ActivityCategory.sightseeing:
        return const Color(0xFF0D9488);
      case ActivityCategory.shopping:
        return const Color(0xFFBE185D);
      case ActivityCategory.other:
        return AppColors.textSecondary;
    }
  }

  static String _label(ActivityCategory cat) {
    switch (cat) {
      case ActivityCategory.food:
        return 'Food';
      case ActivityCategory.transport:
        return 'Transport';
      case ActivityCategory.hotel:
        return 'Hotel';
      case ActivityCategory.sightseeing:
        return 'Sightseeing';
      case ActivityCategory.shopping:
        return 'Shopping';
      case ActivityCategory.other:
        return 'Other';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ActivityCategory.values.map((cat) {
        final isSelected = cat == selected;
        final color = _color(cat);
        return GestureDetector(
          onTap: () => onChanged(cat),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withOpacity(0.12)
                  : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? color : AppColors.divider,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _icon(cat),
                  size: 15,
                  color: isSelected ? color : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  _label(cat),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? color : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
