import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../core/models/trip.dart';

class TripsNotifier extends Notifier<List<Trip>> {
  @override
  List<Trip> build() => [];

  void addTrip(Trip trip) {
    state = [...state, trip];
  }

  void removeTrip(String id) {
    state = state.where((trip) => trip.id != id).toList();
  }
}

final tripsProvider = NotifierProvider<TripsNotifier, List<Trip>>(
  TripsNotifier.new,
);
