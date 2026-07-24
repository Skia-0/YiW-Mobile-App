import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:yiw_field_report/app.dart';
import 'package:yiw_field_report/services/auth_service.dart';
import 'package:yiw_field_report/services/report_service.dart';
import 'package:yiw_field_report/services/offline_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase (uses platform-specific config files)
  await Firebase.initializeApp();
  
  // Initialize Hive for offline storage
  await Hive.initFlutter();
  await Hive.openBox('reports');
  await Hive.openBox('drafts');
  await Hive.openBox('settings');
  
  // Initialize services
  final authService = AuthService();
  final reportService = ReportService();
  final offlineService = OfflineService();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => authService),
        ChangeNotifierProvider(create: (_) => reportService),
        ChangeNotifierProvider(create: (_) => offlineService),
      ],
      child: const YiWFieldReportApp(),
    ),
  );
}
