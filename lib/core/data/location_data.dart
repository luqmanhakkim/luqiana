class CountryData {
  final String name;
  final String flag;
  final List<String> cities;

  const CountryData({
    required this.name,
    required this.flag,
    required this.cities,
  });
}

const List<CountryData> availableCountries = [
  CountryData(
    name: 'Malaysia',
    flag: '🇲🇾',
    cities: ['Kuala Lumpur', 'Penang', 'Langkawi', 'Johor Bahru', 'Malacca', 'Kota Kinabalu'],
  ),
  CountryData(
    name: 'Japan',
    flag: '🇯🇵',
    cities: ['Tokyo', 'Osaka', 'Kyoto', 'Sapporo', 'Fukuoka', 'Okinawa', 'Nara'],
  ),
  CountryData(
    name: 'South Korea',
    flag: '🇰🇷',
    cities: ['Seoul', 'Busan', 'Jeju', 'Incheon', 'Gyeongju', 'Daegu'],
  ),
  CountryData(
    name: 'Thailand',
    flag: '🇹🇭',
    cities: ['Bangkok', 'Phuket', 'Chiang Mai', 'Pattaya', 'Krabi', 'Hua Hin'],
  ),
  CountryData(
    name: 'Indonesia',
    flag: '🇮🇩',
    cities: ['Bali', 'Jakarta', 'Bandung', 'Surabaya', 'Lombok', 'Yogyakarta'],
  ),
  CountryData(
    name: 'Singapore',
    flag: '🇸🇬',
    cities: ['Singapore'],
  ),
  CountryData(
    name: 'Vietnam',
    flag: '🇻🇳',
    cities: ['Ho Chi Minh City', 'Hanoi', 'Da Nang', 'Hoi An', 'Nha Trang', 'Phu Quoc'],
  ),
  CountryData(
    name: 'Taiwan',
    flag: '🇹🇼',
    cities: ['Taipei', 'Kaohsiung', 'Taichung', 'Tainan', 'Hualien'],
  ),
  CountryData(
    name: 'China',
    flag: '🇨🇳',
    cities: ['Beijing', 'Shanghai', 'Guangzhou', 'Shenzhen', 'Chengdu', 'Hangzhou'],
  ),
  CountryData(
    name: 'Australia',
    flag: '🇦🇺',
    cities: ['Sydney', 'Melbourne', 'Brisbane', 'Perth', 'Gold Coast', 'Adelaide'],
  ),
  CountryData(
    name: 'New Zealand',
    flag: '🇳🇿',
    cities: ['Auckland', 'Wellington', 'Christchurch', 'Queenstown', 'Hamilton'],
  ),
  CountryData(
    name: 'United Kingdom',
    flag: '🇬🇧',
    cities: ['London', 'Edinburgh', 'Manchester', 'Birmingham', 'Glasgow', 'Bath'],
  ),
  CountryData(
    name: 'France',
    flag: '🇫🇷',
    cities: ['Paris', 'Nice', 'Lyon', 'Marseille', 'Bordeaux', 'Strasbourg'],
  ),
  CountryData(
    name: 'Italy',
    flag: '🇮🇹',
    cities: ['Rome', 'Milan', 'Venice', 'Florence', 'Naples', 'Amalfi'],
  ),
  CountryData(
    name: 'United States',
    flag: '🇺🇸',
    cities: ['New York', 'Los Angeles', 'San Francisco', 'Las Vegas', 'Chicago', 'Miami', 'Honolulu'],
  ),
  CountryData(
    name: 'Turkey',
    flag: '🇹🇷',
    cities: ['Istanbul', 'Cappadocia', 'Antalya', 'Ankara', 'Izmir'],
  ),
  CountryData(
    name: 'Switzerland',
    flag: '🇨🇭',
    cities: ['Zurich', 'Geneva', 'Lucerne', 'Bern', 'Interlaken', 'Zermatt'],
  ),
  CountryData(
    name: 'United Arab Emirates',
    flag: '🇦🇪',
    cities: ['Dubai', 'Abu Dhabi', 'Sharjah'],
  ),
];