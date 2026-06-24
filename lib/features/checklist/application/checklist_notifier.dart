import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../core/models/checklist.dart';

class ChecklistNotifier extends Notifier<List<ChecklistItem>> {
  static const _boxName = 'checklist';

  Box<String> get _box => Hive.box<String>(_boxName);

  @override
  List<ChecklistItem> build() {
    return _box.values
        .map((raw) =>
            ChecklistItem.fromJson(jsonDecode(raw) as Map<String, dynamic>))
        .toList();
  }

  void addItem(ChecklistItem item) {
    _box.put(item.id, item.toJsonString());
    state = [...state, item];
  }

  void toggleItem(String id) {
    final newState = state
        .map((item) =>
            item.id == id ? item.copyWith(isChecked: !item.isChecked) : item)
        .toList();
    state = newState;
    final updated = newState.firstWhere((i) => i.id == id);
    _box.put(updated.id, updated.toJsonString());
  }

  void updateItem(ChecklistItem item) {
    _box.put(item.id, item.toJsonString());
    state = [for (final i in state) if (i.id == item.id) item else i];
  }

  void deleteItem(String id) {
    _box.delete(id);
    state = state.where((i) => i.id != id).toList();
  }

  void deleteAllForTrip(String tripId) {
    final toDelete = state.where((i) => i.tripId == tripId).toList();
    for (final i in toDelete) {
      _box.delete(i.id);
    }
    state = state.where((i) => i.tripId != tripId).toList();
  }
}

final checklistProvider =
    NotifierProvider<ChecklistNotifier, List<ChecklistItem>>(
  ChecklistNotifier.new,
);
