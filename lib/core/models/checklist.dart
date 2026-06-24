import 'dart:convert';

enum ChecklistCategory {
  documents,
  clothing,
  electronics,
  toiletries,
  health,
  money,
  other,
}

class ChecklistItem {
  final String id;
  final String tripId;
  final String title;
  final ChecklistCategory category;
  final bool isChecked;

  const ChecklistItem({
    required this.id,
    required this.tripId,
    required this.title,
    required this.category,
    this.isChecked = false,
  });

  ChecklistItem copyWith({
    String? title,
    ChecklistCategory? category,
    bool? isChecked,
  }) =>
      ChecklistItem(
        id: id,
        tripId: tripId,
        title: title ?? this.title,
        category: category ?? this.category,
        isChecked: isChecked ?? this.isChecked,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'tripId': tripId,
        'title': title,
        'category': category.name,
        'isChecked': isChecked,
      };

  factory ChecklistItem.fromJson(Map<String, dynamic> json) => ChecklistItem(
        id: json['id'] as String,
        tripId: json['tripId'] as String,
        title: json['title'] as String,
        category: ChecklistCategory.values
            .firstWhere((e) => e.name == json['category']),
        isChecked: json['isChecked'] as bool,
      );

  String toJsonString() => jsonEncode(toJson());

  factory ChecklistItem.fromJsonString(String raw) =>
      ChecklistItem.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}
