enum ActivityCategory { food, transport, hotel, sightseeing, shopping, other }

class ItineraryActivity {
  final String id;
  final String time;
  final String title;
  final String location;
  final ActivityCategory category;
  final String? notes;
  final bool isDone;

  const ItineraryActivity({
    required this.id,
    required this.time,
    required this.title,
    required this.location,
    required this.category,
    this.notes,
    this.isDone = false,
  });

  ItineraryActivity copyWith({bool? isDone}) {
    return ItineraryActivity(
      id: id,
      time: time,
      title: title,
      location: location,
      category: category,
      notes: notes,
      isDone: isDone ?? this.isDone,
    );
  }
}

class ItineraryDay {
  final String tripId;
  final DateTime date;
  final List<ItineraryActivity> activities;

  const ItineraryDay({
    required this.tripId,
    required this.date,
    required this.activities,
  });

  ItineraryDay copyWith({List<ItineraryActivity>? activities}) {
    return ItineraryDay(
      tripId: tripId,
      date: date,
      activities: activities ?? this.activities,
    );
  }
}

List<ItineraryDay> get sampleItinerary => [
      ItineraryDay(
        tripId: '1',
        date: DateTime(2026, 6, 10),
        activities: const [
          ItineraryActivity(
            id: 'a1',
            time: '14:00',
            title: 'Arrive at Narita Airport',
            location: 'Narita International Airport',
            category: ActivityCategory.transport,
            isDone: true,
          ),
          ItineraryActivity(
            id: 'a2',
            time: '16:30',
            title: 'Check-in at Hotel Shinjuku Granbell',
            location: 'Shinjuku, Tokyo',
            category: ActivityCategory.hotel,
            isDone: true,
          ),
          ItineraryActivity(
            id: 'a3',
            time: '19:00',
            title: 'Dinner at Omoide Yokocho',
            location: 'Shinjuku, Tokyo',
            category: ActivityCategory.food,
            notes: 'Try the yakitori!',
            isDone: true,
          ),
        ],
      ),
      ItineraryDay(
        tripId: '1',
        date: DateTime(2026, 6, 11),
        activities: const [
          ItineraryActivity(
            id: 'b1',
            time: '09:00',
            title: 'Akihabara Electric Town',
            location: 'Akihabara, Tokyo',
            category: ActivityCategory.shopping,
            isDone: true,
          ),
          ItineraryActivity(
            id: 'b2',
            time: '12:30',
            title: 'Ramen at Ichiran',
            location: 'Akihabara, Tokyo',
            category: ActivityCategory.food,
            isDone: true,
          ),
          ItineraryActivity(
            id: 'b3',
            time: '14:30',
            title: 'Ueno Park & National Museum',
            location: 'Ueno, Tokyo',
            category: ActivityCategory.sightseeing,
            isDone: true,
          ),
          ItineraryActivity(
            id: 'b4',
            time: '19:30',
            title: 'Shibuya Crossing & Night Walk',
            location: 'Shibuya, Tokyo',
            category: ActivityCategory.sightseeing,
            isDone: true,
          ),
        ],
      ),
      ItineraryDay(
        tripId: '1',
        date: DateTime(2026, 6, 12),
        activities: const [
          ItineraryActivity(
            id: 'c1',
            time: '08:00',
            title: 'Tsukiji Outer Market Breakfast',
            location: 'Tsukiji, Tokyo',
            category: ActivityCategory.food,
            notes: 'Fresh sushi & tamago tamagoyaki',
          ),
          ItineraryActivity(
            id: 'c2',
            time: '10:30',
            title: 'Senso-ji Temple',
            location: 'Asakusa, Tokyo',
            category: ActivityCategory.sightseeing,
            notes: 'Get there early to avoid crowds',
          ),
          ItineraryActivity(
            id: 'c3',
            time: '13:00',
            title: 'Asakusa Street Food Lunch',
            location: 'Nakamise Shopping Street, Asakusa',
            category: ActivityCategory.food,
          ),
          ItineraryActivity(
            id: 'c4',
            time: '15:00',
            title: 'Nakamise Shopping Street',
            location: 'Asakusa, Tokyo',
            category: ActivityCategory.shopping,
            notes: 'Buy omiyage (souvenirs) here',
          ),
          ItineraryActivity(
            id: 'c5',
            time: '19:00',
            title: 'Dinner at Conveyor Belt Sushi',
            location: 'Shibuya, Tokyo',
            category: ActivityCategory.food,
          ),
        ],
      ),
      ItineraryDay(
        tripId: '1',
        date: DateTime(2026, 6, 13),
        activities: const [
          ItineraryActivity(
            id: 'd1',
            time: '09:30',
            title: 'teamLab Planets (Digital Art)',
            location: 'Toyosu, Tokyo',
            category: ActivityCategory.sightseeing,
            notes: 'Pre-book tickets online!',
          ),
          ItineraryActivity(
            id: 'd2',
            time: '13:00',
            title: 'Lunch at Toyosu Market',
            location: 'Toyosu, Tokyo',
            category: ActivityCategory.food,
          ),
          ItineraryActivity(
            id: 'd3',
            time: '16:00',
            title: 'Harajuku & Takeshita Street',
            location: 'Harajuku, Tokyo',
            category: ActivityCategory.shopping,
          ),
          ItineraryActivity(
            id: 'd4',
            time: '20:00',
            title: 'Tokyo Tower Night View',
            location: 'Shiba Park, Tokyo',
            category: ActivityCategory.sightseeing,
          ),
        ],
      ),
    ];
