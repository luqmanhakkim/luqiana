import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../core/models/trip.dart';

class TripsNotifier extends Notifier<List<Trip>> {
  @override
  List<Trip> build() => sampleTrips;
}

final tripsProvider = NotifierProvider<TripsNotifier, List<Trip>>(
  TripsNotifier.new,
);
