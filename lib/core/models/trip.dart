import 'dart:convert';

enum TripStatus { upcoming, ongoing, completed }

class Trip {
  final String id;
  final String name;
  final String destination;
  final String country;
  final DateTime startDate;
  final DateTime endDate;
  final double budget;
  final String currency;
  final int gradientIndex;

  const Trip({
    required this.id,
    required this.name,
    required this.destination,
    required this.country,
    required this.startDate,
    required this.endDate,
    this.budget = 0,
    this.currency = 'MYR',
    this.gradientIndex = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'destination': destination,
        'country': country,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'budget': budget,
        'currency': currency,
        'gradientIndex': gradientIndex,
      };

  factory Trip.fromJson(Map<String, dynamic> json) => Trip(
        id: json['id'] as String,
        name: json['name'] as String,
        destination: json['destination'] as String,
        country: json['country'] as String,
        startDate: DateTime.parse(json['startDate'] as String),
        endDate: DateTime.parse(json['endDate'] as String),
        budget: (json['budget'] as num).toDouble(),
        currency: json['currency'] as String,
        gradientIndex: json['gradientIndex'] as int,
      );

  Trip copyWith({
    String? name,
    String? destination,
    String? country,
    DateTime? startDate,
    DateTime? endDate,
    double? budget,
    String? currency,
  }) =>
      Trip(
        id: id,
        name: name ?? this.name,
        destination: destination ?? this.destination,
        country: country ?? this.country,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        budget: budget ?? this.budget,
        currency: currency ?? this.currency,
        gradientIndex: gradientIndex,
      );

  String toJsonString() => jsonEncode(toJson());

  factory Trip.fromJsonString(String raw) =>
      Trip.fromJson(jsonDecode(raw) as Map<String, dynamic>);

  TripStatus get status {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);

    if (today.isBefore(start)) {
      return TripStatus.upcoming;
    } else if (today.isAfter(end)) {
      return TripStatus.completed;
    } else {
      return TripStatus.ongoing;
    }
  }

  int get daysUntilTrip {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    return start.difference(today).inDays;
  }

  int get daysLeft {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    return end.difference(today).inDays;
  }

  int get tripDuration {
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    final days = end.difference(start).inDays + 1;
    return days < 1 ? 1 : days;
  }

  int get dayOfTrip {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final day = today.difference(start).inDays + 1;
    return day < 1 ? 1 : day;
  }

  String get formattedDateRange {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final s = startDate;
    final e = endDate;
    if (s.year == e.year && s.month == e.month) {
      return '${s.day}–${e.day} ${months[s.month - 1]} ${s.year}';
    } else if (s.year == e.year) {
      return '${s.day} ${months[s.month - 1]} – ${e.day} ${months[e.month - 1]} ${s.year}';
    } else {
      return '${s.day} ${months[s.month - 1]} ${s.year} – ${e.day} ${months[e.month - 1]} ${e.year}';
    }
  }
}

final List<Trip> sampleTrips = [
  Trip(
    id: '1',
    name: 'Japan 2026',
    destination: 'Tokyo',
    country: 'Japan',
    startDate: DateTime(2026, 6, 10),
    endDate: DateTime(2026, 6, 17),
    budget: 5000,
    currency: 'MYR',
    gradientIndex: 0,
  ),
  Trip(
    id: '2',
    name: 'Europe Road Trip',
    destination: 'Paris',
    country: 'France',
    startDate: DateTime(2026, 8, 1),
    endDate: DateTime(2026, 8, 21),
    budget: 12000,
    currency: 'MYR',
    gradientIndex: 3,
  ),
  Trip(
    id: '3',
    name: 'Bali Escape',
    destination: 'Bali',
    country: 'Indonesia',
    startDate: DateTime(2026, 3, 1),
    endDate: DateTime(2026, 3, 7),
    budget: 3000,
    currency: 'MYR',
    gradientIndex: 1,
  ),
  Trip(
    id: '4',
    name: 'London Winter',
    destination: 'London',
    country: 'UK',
    startDate: DateTime(2025, 12, 20),
    endDate: DateTime(2025, 12, 27),
    budget: 8000,
    currency: 'MYR',
    gradientIndex: 4,
  ),
];
