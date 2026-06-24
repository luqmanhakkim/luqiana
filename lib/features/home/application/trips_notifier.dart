import 'package:hive_flutter/hive_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../core/models/trip.dart';
import '../../checklist/application/checklist_notifier.dart';
import '../../documents/application/documents_notifier.dart';
import '../../expenses/application/expenses_notifier.dart';
import '../../itinerary/application/itinerary_notifier.dart';
import '../../shopping/application/shopping_notifier.dart';

class TripsNotifier extends Notifier<List<Trip>> {
  static const _boxName = 'trips';

  Box<String> get _box => Hive.box<String>(_boxName);

  @override
  List<Trip> build() {
    return _box.values.map(Trip.fromJsonString).toList();
  }

  void addTrip(Trip trip) {
    _box.put(trip.id, trip.toJsonString());
    state = [...state, trip];
  }

  void updateTrip(Trip trip) {
    _box.put(trip.id, trip.toJsonString());
    state = [for (final t in state) if (t.id == trip.id) trip else t];
  }

  void removeTrip(String id) {
    _box.delete(id);
    state = state.where((t) => t.id != id).toList();
    ref.read(expensesProvider.notifier).deleteAllForTrip(id);
    ref.read(checklistProvider.notifier).deleteAllForTrip(id);
    ref.read(shoppingProvider.notifier).deleteAllForTrip(id);
    ref.read(itineraryProvider.notifier).deleteAllForTrip(id);
    ref.read(documentsProvider.notifier).deleteAllForTrip(id);
  }
}

final tripsProvider = NotifierProvider<TripsNotifier, List<Trip>>(
  TripsNotifier.new,
);
