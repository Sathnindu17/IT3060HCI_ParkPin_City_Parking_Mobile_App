import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class ParkingRouteStep {
  final String instruction;
  final String road;
  final double distanceMeters;

  const ParkingRouteStep({
    required this.instruction,
    required this.road,
    required this.distanceMeters,
  });

  factory ParkingRouteStep.fromJson(Map<String, dynamic> json) {
    final maneuver = json['maneuver'] as Map<String, dynamic>;
    final type = maneuver['type'] as String? ?? '';
    final modifier = maneuver['modifier'] as String? ?? '';

    String instruction;

    switch (type) {
      case 'depart':
        instruction = 'Start your journey';
        break;
      case 'arrive':
        instruction = 'Arrive at your destination';
        break;
      case 'turn':
        instruction = modifier.isEmpty ? 'Turn' : 'Turn $modifier';
        break;
      case 'roundabout':
      case 'rotary':
        final exit = maneuver['exit'];
        instruction = exit == null
            ? 'Enter the roundabout'
            : 'Take roundabout exit $exit';
        break;
      case 'merge':
        instruction = modifier.isEmpty ? 'Merge' : 'Merge $modifier';
        break;
      case 'fork':
        instruction = modifier.isEmpty ? 'Keep going' : 'Keep $modifier';
        break;
      case 'end of road':
        instruction = modifier.isEmpty
            ? 'Turn at the end of the road'
            : 'Turn $modifier at the end of the road';
        break;
      default:
        instruction = modifier.isEmpty || modifier == 'straight'
            ? 'Continue'
            : 'Continue $modifier';
    }

    return ParkingRouteStep(
      instruction: instruction,
      road: json['name'] as String? ?? '',
      distanceMeters: (json['distance'] as num).toDouble(),
    );
  }
}

class ParkingRoadRoute {
  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;
  final List<ParkingRouteStep> steps;

  const ParkingRoadRoute({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.steps,
  });

  String get distanceLabel =>
      '${(distanceMeters / 1000).toStringAsFixed(1)} km';

  String get durationLabel {
    final minutes = (durationSeconds / 60).ceil();

    if (minutes < 1) {
      return 'Under 1 min';
    }

    if (minutes < 60) {
      return '$minutes min';
    }

    final hours = minutes ~/ 60;
    final remaining = minutes % 60;

    return remaining == 0
        ? '$hours hr'
        : '$hours hr $remaining min';
  }
}

class ParkingRouteService {
  final http.Client _client = http.Client();
  DateTime? _lastRequest;

  Future<ParkingRoadRoute> loadRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    // Avoid rapid requests to the public demo routing server.
    final previousRequest = _lastRequest;

    if (previousRequest != null) {
      final elapsed = DateTime.now().difference(previousRequest);
      final remaining = 1100 - elapsed.inMilliseconds;

      if (remaining > 0) {
        await Future<void>.delayed(
          Duration(milliseconds: remaining),
        );
      }
    }

    _lastRequest = DateTime.now();

    // OSRM coordinates use longitude first, then latitude.
    final coordinates =
        '${origin.longitude},${origin.latitude};'
        '${destination.longitude},${destination.latitude}';

    final uri = Uri.https(
      'router.project-osrm.org',
      '/route/v1/driving/$coordinates',
      {
        'overview': 'full',
        'geometries': 'geojson',
        'steps': 'true',
        'alternatives': 'false',
      },
    );

    final response = await _client.get(
      uri,
      headers: {
        if (!kIsWeb)
          'User-Agent': 'ParkPin-HCI-WE46/1.0',
      },
    ).timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw StateError(
        'The routing server is unavailable. Please retry.',
      );
    }

    final data = jsonDecode(
      utf8.decode(response.bodyBytes),
    ) as Map<String, dynamic>;

    final routes = data['routes'] as List<dynamic>?;

    if (data['code'] != 'Ok' || routes == null || routes.isEmpty) {
      throw StateError('No driving route was found for these locations.');
    }

    final route = routes.first as Map<String, dynamic>;
    final geometry = route['geometry'] as Map<String, dynamic>;
    final coordinatesList = geometry['coordinates'] as List<dynamic>;

    final points = coordinatesList.map((coordinate) {
      final pair = coordinate as List<dynamic>;

      return LatLng(
        (pair[1] as num).toDouble(),
        (pair[0] as num).toDouble(),
      );
    }).toList();

    if (points.length < 2) {
      throw StateError('The routing server returned an incomplete route.');
    }

    final steps = <ParkingRouteStep>[];

    for (final leg in route['legs'] as List<dynamic>) {
      final legData = leg as Map<String, dynamic>;

      for (final step in legData['steps'] as List<dynamic>) {
        steps.add(
          ParkingRouteStep.fromJson(
            step as Map<String, dynamic>,
          ),
        );
      }
    }

    return ParkingRoadRoute(
      points: points,
      distanceMeters: (route['distance'] as num).toDouble(),
      durationSeconds: (route['duration'] as num).toDouble(),
      steps: steps,
    );
  }

  void dispose() {
    _client.close();
  }
}