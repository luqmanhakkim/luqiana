import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../core/models/itinerary.dart';

class ItineraryNotifier extends Notifier<List<ItineraryDay>> {
  @override
  List<ItineraryDay> build() => sampleItinerary;

  void toggleActivity({
    required String tripId,
    required DateTime date,
    required String activityId,
  }) {
    state = [
      for (final day in state)
        if (day.tripId == tripId &&
            day.date.year == date.year &&
            day.date.month == date.month &&
            day.date.day == date.day)
          day.copyWith(
            activities: [
              for (final activity in day.activities)
                if (activity.id == activityId)
                  activity.copyWith(isDone: !activity.isDone)
                else
                  activity,
            ],
          )
        else
          day,
    ];
  }
}

final itineraryProvider =
    NotifierProvider<ItineraryNotifier, List<ItineraryDay>>(
  ItineraryNotifier.new,
);
