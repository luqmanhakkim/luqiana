import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../core/models/shopping.dart';

class ShoppingNotifier extends Notifier<List<ShoppingItem>> {
  static const _boxName = 'shopping';

  Box<String> get _box => Hive.box<String>(_boxName);

  @override
  List<ShoppingItem> build() {
    return _box.values
        .map((raw) =>
            ShoppingItem.fromJson(jsonDecode(raw) as Map<String, dynamic>))
        .toList();
  }

  void addItem(ShoppingItem item) {
    _box.put(item.id, item.toJsonString());
    state = [...state, item];
  }

  void toggleItem(String id) {
    final newState = state
        .map((item) =>
            item.id == id ? item.copyWith(isPurchased: !item.isPurchased) : item)
        .toList();
    state = newState;
    final updated = newState.firstWhere((i) => i.id == id);
    _box.put(updated.id, updated.toJsonString());
  }

  void updateItem(ShoppingItem item) {
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

final shoppingProvider =
    NotifierProvider<ShoppingNotifier, List<ShoppingItem>>(
  ShoppingNotifier.new,
);
