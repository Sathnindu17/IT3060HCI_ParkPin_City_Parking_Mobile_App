import 'package:flutter/material.dart';
import 'package:parkpin/app.dart';
import 'package:parkpin/core/config/supabase_config.dart';
import 'package:parkpin/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Start Supabase in the background so the first frame (the splash) is drawn
  // straight away instead of waiting behind Android's launch screen. The
  // splash waits for SupabaseService.ready before leaving.
  SupabaseService.ready = Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  )..ignore(); // errors are handled where `ready` is awaited
  runApp(const ParkPinApp());
}
