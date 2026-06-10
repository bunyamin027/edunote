import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/app_constants.dart';
import 'core/config/injection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // System UI style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  // Preferred orientations (tablet-first, allow all)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Initialize Hive
  await Hive.initFlutter();

  // Initialize Supabase (skip if placeholders are used)
  if (AppConstants.supabaseUrl != 'YOUR_SUPABASE_URL_HERE' && 
      AppConstants.supabaseAnonKey != 'YOUR_SUPABASE_ANON_KEY_HERE') {
    try {
      await Supabase.initialize(
        url: AppConstants.supabaseUrl,
        anonKey: AppConstants.supabaseAnonKey,
      );
      debugPrint('Supabase initialized successfully.');
    } catch (e) {
      debugPrint('Failed to initialize Supabase: $e');
    }
  } else {
    debugPrint('Supabase initialization skipped: keys are missing.');
  }

  // Initialize dependencies
  await initDependencies();

  runApp(const EduNoteApp());
}
