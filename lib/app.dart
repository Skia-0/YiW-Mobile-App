import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yiw_field_report/theme/app_theme.dart';
import 'package:yiw_field_report/screens/login_screen.dart';
import 'package:yiw_field_report/screens/home_screen.dart';
import 'package:yiw_field_report/screens/report_form_screen.dart';
import 'package:yiw_field_report/screens/saved_reports_screen.dart';
import 'package:yiw_field_report/screens/settings_screen.dart';
import 'package:yiw_field_report/screens/register_screen.dart';
import 'package:yiw_field_report/services/auth_service.dart';

class YiWFieldReportApp extends StatelessWidget {
  const YiWFieldReportApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YiW Field Report',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/new-report': (context) => const ReportFormScreen(),
        '/saved-reports': (context) => const SavedReportsScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/register': (context) => const RegisterScreen(),
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    final authService = Provider.of<AuthService>(context, listen: false);
    final isAuthenticated = authService.isAuthenticated;
    
    if (isAuthenticated) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/yiw_logo.png',
              width: 150,
              height: 150,
            ),
            const SizedBox(height: 24),
            const Text(
              'YiW Field Report',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'SEG Ghana — Youth in Work Programme',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
            ),
          ],
        ),
      ),
    );
  }
}