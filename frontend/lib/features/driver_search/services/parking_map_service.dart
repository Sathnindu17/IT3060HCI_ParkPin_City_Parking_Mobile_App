import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/parking_map_facility.dart';

class ParkingMapService {
  final SupabaseClient _client;

  ParkingMapService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  Future<List<ParkingMapFacility>> loadDemoFacilities() async {
    final rows = await _client
        .from('parking_facilities')
        .select(
          'id,name,address,latitude,longitude,'
          'rate_per_hour,reservation_fee',
        )
        .eq('is_demo', true)
        .order('name');

    return rows
        .map((row) => ParkingMapFacility.fromJson(row))
        .toList();
  }

  Stream<List<Map<String, dynamic>>> watchBays(
    List<String> facilityIds,
  ) {
    return _client
        .from('bays')
        .stream(primaryKey: ['id'])
        .inFilter('facility_id', facilityIds);
  }
}