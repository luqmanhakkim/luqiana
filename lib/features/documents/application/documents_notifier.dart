import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/models/travel_document.dart';

class DocumentsNotifier extends Notifier<List<TravelDocument>> {
  static const _boxName = 'documents';

  Box<String> get _box => Hive.box<String>(_boxName);

  @override
  List<TravelDocument> build() {
    return _box.values
        .map((raw) =>
            TravelDocument.fromJson(jsonDecode(raw) as Map<String, dynamic>))
        .toList();
  }

  void addDocument(TravelDocument doc) {
    _box.put(doc.id, doc.toJsonString());
    state = [...state, doc];
  }

  void updateDocument(TravelDocument doc) {
    _box.put(doc.id, doc.toJsonString());
    state = [for (final d in state) if (d.id == doc.id) doc else d];
  }

  void deleteDocument(String id) {
    _box.delete(id);
    state = state.where((d) => d.id != id).toList();
  }

  void deleteAllForTrip(String tripId) {
    final toDelete = state.where((d) => d.tripId == tripId).toList();
    for (final d in toDelete) {
      _box.delete(d.id);
    }
    state = state.where((d) => d.tripId != tripId).toList();
  }
}

final documentsProvider =
    NotifierProvider<DocumentsNotifier, List<TravelDocument>>(
  DocumentsNotifier.new,
);
