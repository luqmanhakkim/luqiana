import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../core/models/itinerary.dart';

class ItineraryNotifier extends Notifier<List<ItineraryDay>> {
  static const _boxName = 'itinerary';

  Box<String> get _box => Hive.box<String>(_boxName);

  // Stable key: "<tripId>|YYYY-MM-DD"
  String _key(String tripId, DateTime date) {
    final d =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return '$tripId|$d';
  }

  bool _sameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _persist(ItineraryDay day) {
    _box.put(_key(day.tripId, day.date), jsonEncode(day.toJson()));
  }

  void _remove(String tripId, DateTime date) {
    _box.delete(_key(tripId, date));
  }

  @override
  List<ItineraryDay> build() {
    return _box.values
        .map((raw) =>
            ItineraryDay.fromJson(jsonDecode(raw) as Map<String, dynamic>))
        .toList();
  }

  void addActivity({
    required String tripId,
    required DateTime date,
    required ItineraryActivity activity,
  }) {
    final dayExists =
        state.any((d) => d.tripId == tripId && _sameDate(d.date, date));

    final List<ItineraryDay> newState;
    if (dayExists) {
      newState = [
        for (final day in state)
          if (day.tripId == tripId && _sameDate(day.date, date))
            day.copyWith(activities: [...day.activities, activity])
          else
            day,
      ];
    } else {
      newState = [
        ...state,
        ItineraryDay(tripId: tripId, date: date, activities: [activity]),
      ];
    }

    state = newState;
    _persist(
      newState.firstWhere(
        (d) => d.tripId == tripId && _sameDate(d.date, date),
      ),
    );
  }

  void toggleActivity({
    required String tripId,
    required DateTime date,
    required String activityId,
  }) {
    final newState = [
      for (final day in state)
        if (day.tripId == tripId && _sameDate(day.date, date))
          day.copyWith(
            activities: [
              for (final a in day.activities)
                if (a.id == activityId) a.copyWith(isDone: !a.isDone) else a,
            ],
          )
        else
          day,
    ];

    state = newState;
    _persist(
      newState.firstWhere(
        (d) => d.tripId == tripId && _sameDate(d.date, date),
      ),
    );
  }

  void updateActivity({
    required String tripId,
    required DateTime date,
    required ItineraryActivity activity,
  }) {
    final newState = [
      for (final day in state)
        if (day.tripId == tripId && _sameDate(day.date, date))
          day.copyWith(
            activities: [
              for (final a in day.activities)
                if (a.id == activity.id) activity else a,
            ],
          )
        else
          day,
    ];
    state = newState;
    _persist(
      newState.firstWhere(
        (d) => d.tripId == tripId && _sameDate(d.date, date),
      ),
    );
  }

  void deleteActivity({
    required String tripId,
    required DateTime date,
    required String activityId,
  }) {
    final newState = [
      for (final day in state)
        if (day.tripId == tripId && _sameDate(day.date, date))
          day.copyWith(
            activities:
                day.activities.where((a) => a.id != activityId).toList(),
          )
        else
          day,
    ];

    final affected = newState.firstWhere(
      (d) => d.tripId == tripId && _sameDate(d.date, date),
      orElse: () =>
          ItineraryDay(tripId: tripId, date: date, activities: const []),
    );

    if (affected.activities.isEmpty) {
      // Day is now empty — remove it entirely from state and box
      state = newState
          .where((d) => !(d.tripId == tripId && _sameDate(d.date, date)))
          .toList();
      _remove(tripId, date);
    } else {
      state = newState;
      _persist(affected);
    }
  }

  void deleteAllForTrip(String tripId) {
    final toDelete = state.where((d) => d.tripId == tripId).toList();
    for (final day in toDelete) {
      _remove(tripId, day.date);
    }
    state = state.where((d) => d.tripId != tripId).toList();
  }
}

final itineraryProvider =
    NotifierProvider<ItineraryNotifier, List<ItineraryDay>>(
  ItineraryNotifier.new,
);
