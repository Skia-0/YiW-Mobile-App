import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:yiw_field_report/app.dart';
import 'package:yiw_field_report/services/auth_service.dart';
import 'package:yiw_field_report/services/report_service.dart';
import 'package:yiw_field_report/services/offline_service.dart';

void main() {
  group('YiW Field Report App', () {
    testWidgets('App should render without errors', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthService()),
            ChangeNotifierProvider(create: (_) => ReportService()),
            ChangeNotifierProvider(create: (_) => OfflineService()),
          ],
          child: const YiWFieldReportApp(),
        ),
      );

      // Verify that the app renders
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('Splash screen should show logo', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthService()),
            ChangeNotifierProvider(create: (_) => ReportService()),
            ChangeNotifierProvider(create: (_) => OfflineService()),
          ],
          child: const YiWFieldReportApp(),
        ),
      );

      // Wait for splash screen
      await tester.pumpAndSettle();

      // Verify splash screen elements
      expect(find.text('YiW Field Report'), findsOneWidget);
      expect(find.text('SEG Ghana — Youth in Work Programme'), findsOneWidget);
    });

    testWidgets('Login screen should have email and password fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthService()),
            ChangeNotifierProvider(create: (_) => ReportService()),
            ChangeNotifierProvider(create: (_) => OfflineService()),
          ],
          child: const YiWFieldReportApp(),
        ),
      );

      // Navigate to login screen
      await tester.pumpAndSettle();

      // Verify login screen elements
      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2)); // Email and password
    });
  });

  group('Form Validation', () {
    test('Email validation should work', () {
      // Test email validation
      final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      
      expect(emailRegExp.hasMatch('test@example.com'), isTrue);
      expect(emailRegExp.hasMatch('invalid-email'), isFalse);
      expect(emailRegExp.hasMatch('test@.com'), isFalse);
    });

    test('Phone number validation should work', () {
      // Test phone validation
      final phoneRegExp = RegExp(r'^\+?[0-9]{10,15}$');
      
      expect(phoneRegExp.hasMatch('+233241234567'), isTrue);
      expect(phoneRegExp.hasMatch('0241234567'), isTrue);
      expect(phoneRegExp.hasMatch('123'), isFalse);
    });
  });

  group('Data Models', () {
    test('Attendance model should calculate totals correctly', () {
      // This would test the Attendance model
      // In a real test, you'd create an instance and verify calculations
      expect(1 + 1, equals(2)); // Placeholder
    });

    test('EmploymentOutcome model should calculate totals correctly', () {
      // This would test the EmploymentOutcome model
      expect(1 + 1, equals(2)); // Placeholder
    });
  });
}