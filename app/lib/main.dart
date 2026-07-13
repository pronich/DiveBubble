import 'package:flutter/material.dart';

import 'data/repositories/trip_repository.dart';
import 'data/services/trip_api_service.dart';
import 'ui/features/trips/view_models/trips_list_view_model.dart';
import 'ui/features/trips/views/trips_list_view.dart';

const _apiBaseUrl = 'http://localhost:8080';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final tripRepository = TripRepository(
      service: TripApiService(baseUrl: _apiBaseUrl),
    );
    final tripsListViewModel = TripsListViewModel(repository: tripRepository);

    return MaterialApp(
      title: 'DiveBuddy',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),
      home: TripsListView(viewModel: tripsListViewModel),
    );
  }
}
