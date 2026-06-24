import 'dart:convert';

enum DocumentType { flight, hotel, visa, insurance, other }

class TravelDocument {
  final String id;
  final String tripId;
  final DocumentType type;
  final String title;
  final Map<String, String> fields;

  const TravelDocument({
    required this.id,
    required this.tripId,
    required this.type,
    required this.title,
    required this.fields,
  });

  TravelDocument copyWith({
    DocumentType? type,
    String? title,
    Map<String, String>? fields,
  }) =>
      TravelDocument(
        id: id,
        tripId: tripId,
        type: type ?? this.type,
        title: title ?? this.title,
        fields: fields ?? Map<String, String>.from(this.fields),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'tripId': tripId,
        'type': type.name,
        'title': title,
        'fields': fields,
      };

  factory TravelDocument.fromJson(Map<String, dynamic> json) => TravelDocument(
        id: json['id'] as String,
        tripId: json['tripId'] as String,
        type: DocumentType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => DocumentType.other,
        ),
        title: json['title'] as String,
        fields: Map<String, String>.from(json['fields'] as Map),
      );

  String toJsonString() => jsonEncode(toJson());

  factory TravelDocument.fromJsonString(String raw) =>
      TravelDocument.fromJson(jsonDecode(raw) as Map<String, dynamic>);

  static List<String> fieldsForType(DocumentType type) {
    switch (type) {
      case DocumentType.flight:
        return [
          'Flight Number',
          'Airline',
          'From Airport',
          'To Airport',
          'Departure',
          'Arrival',
          'Seat',
          'Booking Ref',
        ];
      case DocumentType.hotel:
        return [
          'Hotel Name',
          'Address',
          'Check-in',
          'Check-out',
          'Room Type',
          'Booking Ref',
          'Phone',
        ];
      case DocumentType.visa:
        return [
          'Visa Type',
          'Visa Number',
          'Issue Date',
          'Expiry Date',
          'Entry Type',
        ];
      case DocumentType.insurance:
        return [
          'Provider',
          'Policy Number',
          'Coverage',
          'Emergency Phone',
          'Valid Until',
        ];
      case DocumentType.other:
        return ['Reference', 'Details', 'Date', 'Notes'];
    }
  }
}
