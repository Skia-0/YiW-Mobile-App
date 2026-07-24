# YiW Field Report Mobile App - Setup Guide

## Prerequisites

Before setting up the project, ensure you have the following installed:

### 1. Flutter SDK
- Download Flutter SDK from [flutter.dev](https://flutter.dev/docs/get-started/install)
- Add Flutter to your PATH
- Run `flutter doctor` to verify installation

### 2. Android Studio (for Android development)
- Download from [developer.android.com](https://developer.android.com/studio)
- Install Android SDK (API level 21 or higher)
- Set up Android emulator or connect physical device

### 3. Xcode (for iOS development - macOS only)
- Install from App Store
- Install command line tools: `xcode-select --install`
- Set up iOS simulator

### 4. Firebase Account
- Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
- Enable Authentication, Firestore, Storage, and Functions

### 5. Google Cloud Account
- For Google Sheets API access
- Create a service account and download credentials

### 6. SendGrid Account
- For email delivery
- Create an API key with full access

## Project Setup

### Step 1: Clone the Repository
```bash
# If you have the repository
git clone <repository-url>
cd yiw_mobile_app

# Or create a new Flutter project
flutter create --org com.seghana yiw_field_report
cd yiw_field_report
```

### Step 2: Install Dependencies
```bash
flutter pub get
```

### Step 3: Configure Firebase

#### Android Configuration
1. Go to Firebase Console → Project Settings
2. Add Android app with package name: `com.seghana.yiwfieldreport`
3. Download `google-services.json`
4. Place it in `android/app/`

#### iOS Configuration
1. Go to Firebase Console → Project Settings
2. Add iOS app with bundle ID: `com.seghana.yiwfieldreport`
3. Download `GoogleService-Info.plist`
4. Place it in `ios/Runner/`

#### Generate Firebase Options
```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase
flutterfire configure
```

### Step 4: Configure Google Sheets API

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Enable Google Sheets API
3. Create a Service Account
4. Download JSON credentials
5. Create a Google Sheet and share it with the service account email
6. Update `lib/services/sheets_service.dart` with:
   - Spreadsheet ID
   - Service account credentials

### Step 5: Configure SendGrid

1. Sign up at [sendgrid.com](https://sendgrid.com)
2. Create an API key with full access
3. Verify your sender domain
4. Update `lib/services/email_service.dart` with:
   - API key
   - Sender email address

### Step 6: Update Configuration

Edit `lib/config/app_config.dart`:
```dart
// Update these values
static const String sendGridApiKey = 'YOUR_SENDGRID_API_KEY';
static const String googleSheetsId = 'YOUR_GOOGLE_SHEETS_ID';
static const String ceoEmail = 'ceo@seghana.net';
static const String yiwEmail = 'yiw@seghana.net';
```

### Step 7: Add Assets

1. Add your logo to `assets/images/yiw_logo.png`
2. Add Poppins fonts to `assets/fonts/`
3. Add any Lottie animations to `assets/lottie/`

### Step 8: Run the App

#### Android
```bash
# Debug mode
flutter run

# Release mode
flutter run --release
```

#### iOS
```bash
# Debug mode
flutter run -d ios

# Release mode
flutter run --release -d ios
```

## Building for Production

### Android APK
```bash
flutter build apk --release
```

### Android App Bundle
```bash
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── app.dart                  # Main app widget
├── config/                   # Configuration files
│   ├── app_config.dart
│   ├── firebase_config.dart
│   └── api_keys.dart
├── models/                   # Data models
│   ├── field_report.dart
│   ├── focal_person.dart
│   ├── training_centre.dart
│   ├── attendance.dart
│   ├── employment_outcome.dart
│   ├── partner_company.dart
│   ├── safeguarding.dart
│   └── user.dart
├── screens/                  # App screens
│   ├── splash_screen.dart
│   ├── login_screen.dart
│   ├── home_screen.dart
│   ├── report_form_screen.dart
│   ├── report_preview_screen.dart
│   ├── saved_reports_screen.dart
│   └── settings_screen.dart
├── widgets/                  # Reusable widgets
│   ├── form_section.dart
│   ├── counter_widget.dart
│   ├── dropdown_widget.dart
│   ├── checkbox_group.dart
│   ├── date_time_picker.dart
│   ├── media_capture.dart
│   ├── document_scanner.dart
│   └── partner_table.dart
├── services/                 # Business logic
│   ├── auth_service.dart
│   ├── report_service.dart
│   ├── email_service.dart
│   ├── sheets_service.dart
│   ├── storage_service.dart
│   └── offline_service.dart
├── utils/                    # Utility functions
│   ├── validators.dart
│   ├── formatters.dart
│   ├── pdf_generator.dart
│   └── constants.dart
└── theme/                    # App theming
    ├── app_theme.dart
    └── colors.dart
```

## Key Features Implementation

### 1. Form Submission Flow
1. User fills out the multi-step form
2. Data is validated at each step
3. On submit, report is:
   - Saved to Firebase Firestore
   - Emails sent via SendGrid
   - Added to Google Sheet
   - Media files uploaded to Firebase Storage

### 2. Offline Support
- Reports are saved locally using Hive
- When online, data syncs automatically
- Drafts can be saved and edited later

### 3. Email Distribution
- **CEO**: Full report with all details
- **Registration Officer**: Report filtered by zone
- **Sender**: Confirmation email

### 4. Google Sheets Integration
- All report data is appended to a central spreadsheet
- Headers are automatically created
- Data is formatted for easy analysis

## Testing

### Unit Tests
```bash
flutter test
```

### Integration Tests
```bash
flutter test integration_test/
```

### Widget Tests
```bash
flutter test test/widget_test.dart
```

## Deployment

### Google Play Store
1. Create a Google Play Developer account
2. Build app bundle: `flutter build appbundle --release`
3. Upload to Google Play Console
4. Fill in store listing details
5. Submit for review

### Apple App Store
1. Create an Apple Developer account
2. Build iOS app: `flutter build ios --release`
3. Archive in Xcode
4. Upload to App Store Connect
5. Fill in app information
6. Submit for review

## Troubleshooting

### Common Issues

#### 1. Firebase not initializing
- Ensure `google-services.json` (Android) or `GoogleService-Info.plist` (iOS) is in the correct location
- Check Firebase project settings

#### 2. Google Sheets API errors
- Verify service account has access to the spreadsheet
- Check API is enabled in Google Cloud Console

#### 3. Email not sending
- Verify SendGrid API key is correct
- Check sender domain is verified
- Ensure recipient email is valid

#### 4. Camera not working
- Check camera permissions are granted
- Test on physical device (emulator may have issues)

#### 5. Build errors
- Run `flutter clean`
- Run `flutter pub get`
- Check Flutter and Dart SDK versions

### Getting Help

1. Check Flutter documentation: [flutter.dev/docs](https://flutter.dev/docs)
2. Firebase documentation: [firebase.google.com/docs](https://firebase.google.com/docs)
3. Create an issue in the repository

## Security Considerations

1. **API Keys**: Never commit API keys to version control
2. **Firebase Rules**: Set up proper Firestore security rules
3. **Authentication**: Use Firebase Authentication for user management
4. **Data Encryption**: Enable encryption for sensitive data
5. **Permissions**: Request only necessary permissions

## Performance Optimization

1. **Image Compression**: Compress images before upload
2. **Lazy Loading**: Load data only when needed
3. **Caching**: Cache frequently accessed data
4. **Pagination**: Implement pagination for large lists
5. **Background Sync**: Sync data in background when possible

## Maintenance

### Regular Tasks
1. Update dependencies regularly
2. Monitor Firebase usage and costs
3. Review and update email templates
4. Backup Google Sheet data
5. Monitor app crashes and errors

### Version Updates
1. Update version in `pubspec.yaml`
2. Update build number
3. Test thoroughly before release
4. Document changes in CHANGELOG.md

## Support

For technical support:
- Email: support@seghana.net
- Documentation: [GitHub Wiki](link-to-wiki)
- Issues: [GitHub Issues](link-to-issues)

## License

This project is proprietary software owned by SEG Ghana.
Unauthorized copying or distribution is prohibited.

---

**Last Updated**: July 2026
**Version**: 1.0.0