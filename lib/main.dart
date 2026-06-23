import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Hive.initFlutter();
  await Hive.openBox<String>('trips');
  await Hive.openBox<String>('itinerary');
  await Hive.openBox<String>('checklist');
  await Hive.openBox<String>('shopping');
  await Hive.openBox<String>('expenses');
  await Hive.openBox('settings');

  runApp(const ProviderScope(child: LuqianaApp()));
}
