import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:yiw_field_report/app.dart';
import 'package:yiw_field_report/services/auth_service.dart';
import 'package:yiw_field_report/services/report_service.dart';
import 'package:yiw_field_report/services/offline_service.dart';
import 'package:yiw_field_report/services/theme_service.dart';
import 'package:yiw_field_report/services/draft_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase (uses platform-specific config files)
  await Firebase.initializeApp();
  
  // Initialize Hive for offline storage
  await Hive.initFlutter();
  // Must be Box<String> to match OfflineService. Previously these were opened
  // untyped, which made Hive throw on every later access - silently breaking
  // all settings persistence.
  await Hive.openBox<String>('reports');
  await Hive.openBox<String>('drafts');
  await Hive.openBox<String>('settings');
  
  // Initialize services
  final authService = AuthService();
  final reportService = ReportService();
  final offlineService = OfflineService();
  await offlineService.initialize();

  final themeService = ThemeService(offlineService);
  await themeService.load();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => authService),
        ChangeNotifierProvider(create: (_) => reportService),
        ChangeNotifierProvider(create: (_) => offlineService),
        ChangeNotifierProvider(create: (_) => themeService),
        Provider<DraftService>(create: (_) => DraftService()),
      ],
      child: const YiWFieldReportApp(),
    ),
  );
}
