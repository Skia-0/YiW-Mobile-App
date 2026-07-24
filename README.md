# YiW Field Report Mobile App

## Quick Start

### 🚀 Push to GitHub
```bash
# Option 1: Use the provided script
./push_to_github.sh

# Option 2: Manual push
git init
git add .
git commit -m "Initial commit"
git remote add origin https://github.com/Skia-0/YiW-Mobile-App.git
git branch -M main
git push -u origin main
```

### 📱 Setup on Your Machine
```bash
# Clone the repository
git clone https://github.com/Skia-0/YiW-Mobile-App.git
cd YiW-Mobile-App

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### ⚙️ Configuration Required
1. **Firebase**: Set up Firebase project and add configuration files
2. **SendGrid**: Configure email API key
3. **Google Sheets**: Set up API access and spreadsheet

See [SETUP_GUIDE.md](SETUP_GUIDE.md) for detailed instructions.

---

## Project Overview
This Flutter mobile app digitizes the YiW Daily Field Report form for SEG Ghana's Youth in Work Programme. It enables field officers to submit reports on-the-go with automatic distribution to stakeholders.

## Key Features
1. **Complete Form Replication**: All sections from the web form
2. **Offline Capability**: Save drafts locally when offline
3. **Automatic Email Distribution**:
   - CEO receives full report
   - Registration officer receives report for their assigned users
4. **Cloud Excel Integration**: Automatic data sync to Google Sheets/OneDrive
5. **Media Capture**: Camera integration for photos/videos
6. **Document Scanning**: Scan and attach documents
7. **Safeguarding Compliance**: Built-in safeguarding checklist

## Architecture
- **Frontend**: Flutter (Dart) - Cross-platform (iOS & Android)
- **Backend**: Firebase (Authentication, Firestore, Cloud Functions)
- **Email Service**: SendGrid (recommended for reliability and ease of integration)
- **Database**: Google Sheets (via Google Sheets API) + Firestore for real-time sync
- **Storage**: Firebase Storage for media files

## Form Sections Implemented
1. Focal Person Details
2. Training Centre Details
3. Attendance Count
4. Employment & Placement Outcomes
5. Training Enrolment
6. Training Centre Quality Rating
7. Issues Flagged
8. Facilities & Resources
9. Activities Observed
10. Assessment Narrative
11. Partner Companies Engaged (table format)
12. Document Uploads
13. Photos & Videos
14. Safeguarding Checklist
15. Concern Reporting
16. Report Summary

## Technical Stack
- Flutter 3.x
- Dart 3.x
- Firebase Suite (Auth, Firestore, Storage, Functions)
- Google Sheets API
- SendGrid API
- Camera & Image Picker
- PDF generation for email reports

## Setup Instructions
1. Install Flutter SDK
2. Clone this repository
3. Run `flutter pub get`
4. Configure Firebase project
5. Set up Google Sheets API credentials
6. Configure SendGrid API key
7. Run `flutter run`

## Project Structure
```
lib/
├── main.dart
├── app.dart
├── config/
│   ├── app_config.dart
│   ├── firebase_config.dart
│   └── api_keys.dart
├── models/
│   ├── field_report.dart
│   ├── focal_person.dart
│   ├── training_centre.dart
│   ├── attendance.dart
│   ├── employment_outcome.dart
│   ├── partner_company.dart
│   └── safeguarding.dart
├── screens/
│   ├── splash_screen.dart
│   ├── login_screen.dart
│   ├── home_screen.dart
│   ├── report_form_screen.dart
│   ├── report_preview_screen.dart
│   ├── saved_reports_screen.dart
│   └── settings_screen.dart
├── widgets/
│   ├── form_section.dart
│   ├── counter_widget.dart
│   ├── dropdown_widget.dart
│   ├── checkbox_group.dart
│   ├── date_time_picker.dart
│   ├── media_capture.dart
│   ├── document_scanner.dart
│   └── partner_table.dart
├── services/
│   ├── auth_service.dart
│   ├── report_service.dart
│   ├── email_service.dart
│   ├── sheets_service.dart
│   ├── storage_service.dart
│   └── offline_service.dart
├── utils/
│   ├── validators.dart
│   ├── formatters.dart
│   ├── pdf_generator.dart
│   └── constants.dart
└── theme/
    ├── app_theme.dart
    └── colors.dart
```

## Email Distribution Logic
1. **CEO Email**: Full report with all details, attachments, and media
2. **Registration Officer**: Report for youth they registered (filtered by officer ID)
3. **Confirmation**: Sender receives confirmation email

## Data Flow
1. User fills form → saves locally (offline support)
2. When online → submits to Firebase
3. Cloud Function triggers:
   - Generates PDF report
   - Sends emails via SendGrid
   - Updates Google Sheet
   - Stores media in Firebase Storage

## Security & Privacy
- Firebase Authentication for user access
- Role-based access control
- Data encryption in transit and at rest
- GDPR-compliant data handling
- Audit trail for all submissions