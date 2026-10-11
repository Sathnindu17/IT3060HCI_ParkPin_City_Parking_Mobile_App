import 'package:flutter/material.dart';
import 'package:parkpin/app.dart';
import 'package:parkpin/core/config/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  // Initialize the Flutter framework.
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase before launching ParkPin.
  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );

  // Launch the ParkPin application.
  runApp(const ParkPinApp());
}
