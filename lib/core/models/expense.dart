import 'dart:convert';

enum ExpenseCategory { food, transport, accommodation, activities, shopping, other }

class Expense {
  final String id;
  final String tripId;
  final String title;
  final double amount;
  final ExpenseCategory category;
  final DateTime date;
  final String note;

  const Expense({
    required this.id,
    required this.tripId,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.note = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'tripId': tripId,
        'title': title,
        'amount': amount,
        'category': category.name,
        'date': date.toIso8601String(),
        'note': note,
      };

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
        id: json['id'] as String,
        tripId: json['tripId'] as String,
        title: json['title'] as String,
        amount: (json['amount'] as num).toDouble(),
        category: ExpenseCategory.values.firstWhere(
          (e) => e.name == json['category'],
          orElse: () => ExpenseCategory.other,
        ),
        date: DateTime.parse(json['date'] as String),
        note: json['note'] as String? ?? '',
      );

  String toJsonString() => jsonEncode(toJson());

  factory Expense.fromJsonString(String raw) =>
      Expense.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}
