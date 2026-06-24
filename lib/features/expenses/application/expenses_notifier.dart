import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/models/expense.dart';

class ExpensesNotifier extends Notifier<List<Expense>> {
  static const _boxName = 'expenses';

  Box<String> get _box => Hive.box<String>(_boxName);

  @override
  List<Expense> build() {
    return _box.values
        .map((raw) =>
            Expense.fromJson(jsonDecode(raw) as Map<String, dynamic>))
        .toList();
  }

  void addExpense(Expense expense) {
    _box.put(expense.id, expense.toJsonString());
    state = [...state, expense];
  }

  void updateExpense(Expense expense) {
    _box.put(expense.id, expense.toJsonString());
    state = [for (final e in state) if (e.id == expense.id) expense else e];
  }

  void deleteExpense(String id) {
    _box.delete(id);
    state = state.where((e) => e.id != id).toList();
  }

  void deleteAllForTrip(String tripId) {
    final toDelete = state.where((e) => e.tripId == tripId).toList();
    for (final e in toDelete) {
      _box.delete(e.id);
    }
    state = state.where((e) => e.tripId != tripId).toList();
  }
}

final expensesProvider =
    NotifierProvider<ExpensesNotifier, List<Expense>>(ExpensesNotifier.new);
