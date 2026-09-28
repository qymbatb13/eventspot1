import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/app.dart';
import 'core/config/app_config.dart';
import 'core/di/service_locator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru');

  if (AppConfig.useMockData) {
    debugPrint(
      'ℹ️  Используются демо-события. Реальные события Ticketmaster: '
      'flutter run --dart-define=TICKETMASTER_API_KEY=your_key_here',
    );
  }

  await configureDependencies(
    ticketmasterApiKey: AppConfig.ticketmasterApiKey,
    useMockData: AppConfig.useMockData,
  );

  runApp(const EventSpotApp());
}
