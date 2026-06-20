import 'dart:convert';

enum ShoppingCategory {
  clothing,
  electronics,
  food,
  souvenirs,
  beauty,
  accessories,
  other,
}

class ShoppingItem {
  final String id;
  final String tripId;
  final String name;
  final int quantity;
  final double? estimatedPrice;
  final ShoppingCategory category;
  final bool isPurchased;

  const ShoppingItem({
    required this.id,
    required this.tripId,
    required this.name,
    this.quantity = 1,
    this.estimatedPrice,
    required this.category,
    this.isPurchased = false,
  });

  ShoppingItem copyWith({bool? isPurchased}) => ShoppingItem(
        id: id,
        tripId: tripId,
        name: name,
        quantity: quantity,
        estimatedPrice: estimatedPrice,
        category: category,
        isPurchased: isPurchased ?? this.isPurchased,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'tripId': tripId,
        'name': name,
        'quantity': quantity,
        'estimatedPrice': estimatedPrice,
        'category': category.name,
        'isPurchased': isPurchased,
      };

  factory ShoppingItem.fromJson(Map<String, dynamic> json) => ShoppingItem(
        id: json['id'] as String,
        tripId: json['tripId'] as String,
        name: json['name'] as String,
        quantity: (json['quantity'] as int?) ?? 1,
        estimatedPrice: (json['estimatedPrice'] as num?)?.toDouble(),
        category: ShoppingCategory.values
            .firstWhere((e) => e.name == json['category']),
        isPurchased: json['isPurchased'] as bool,
      );

  String toJsonString() => jsonEncode(toJson());

  factory ShoppingItem.fromJsonString(String raw) =>
      ShoppingItem.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}
