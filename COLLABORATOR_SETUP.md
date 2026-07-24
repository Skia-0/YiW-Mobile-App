# YiW Field Report - Collaborator Setup Guide

Welcome to the YiW Field Report project! Follow these steps to get the app running on your machine.

---

## Prerequisites

Install these before starting:

### 1. Flutter SDK
- Download: https://flutter.dev/docs/get-started/install
- Add to PATH
- Verify: `flutter doctor`

### 2. Git
- Download: https://git-scm.com/downloads
- Verify: `git --version`

### 3. VS Code (Recommended)
- Download: https://code.visualstudio.com
- Install Flutter extension

### 4. Android Studio (for Android)
- Download: https://developer.android.com/studio
- Install Android SDK

---

## Step 1: Clone the Repository

Open terminal/command prompt and run:

```bash
git clone https://github.com/Skia-0/YiW-Mobile-App.git
cd YiW-Mobile-App
```

---

## Step 2: Install Dependencies

```bash
flutter pub get
```

---

## Step 3: Create Secrets File

Create a file at `lib/config/secrets.json` with this content:

```json
{
  "sendgrid_api_key": "PASTE_SENDGRID_API_KEY_HERE",
  "sender_email": "PASTE_SENDER_EMAIL_HERE",
  "spreadsheet_id": "1vC3HSNrd78N4IGftTSXEdr39_zjZcliaenxwBAnw4pM",
  "service_account_email": "yiw-sheets@yiw-app.iam.gserviceaccount.com",
  "private_key": "PASTE_PRIVATE_KEY_HERE",
  "ceo_email": "execdir@seghana.net",
  "yiw_email": "yiw@seghana.net"
}
```

**Ask the project owner for:**
- SendGrid API key
- Sender email
- Service account private key (from the JSON file)

---

## Step 4: Add Firebase Configuration

### Android
1. Go to Firebase Console: https://console.firebase.google.com
2. Select the project
3. Click ⚙️ → Project Settings
4. Download `google-services.json`
5. Place it in: `android/app/google-services.json`

### iOS (if building for iOS)
1. Download `GoogleService-Info.plist`
2. Place it in: `ios/Runner/GoogleService-Info.plist`

**Ask the project owner for Firebase access or the config files.**

---

## Step 5: Run the App

### Connect your Android phone:
1. Enable Developer Options on your phone
2. Enable USB Debugging
3. Connect via USB

### Run:
```bash
flutter run
```

Or specify device:
```bash
flutter run -d <device_id>
```

To see connected devices:
```bash
flutter devices
```

---

## Step 6: Create an Account

1. Open the app on your phone
2. Click "Create New Account"
3. Fill in your details
4. Sign in with your new account

---

## Daily Workflow

### Pull latest changes before starting work:
```bash
git pull origin main
```

### After making changes:
```bash
git add -A
git commit -m "Description of your changes"
git push origin main
```

### If you get conflicts:
```bash
git pull origin main
# Fix conflicts in VS Code
git add -A
git commit -m "Merge and resolve conflicts"
git push origin main
```

---

## Project Structure

```
YiW-Mobile-App/
├── lib/
│   ├── main.dart              # App entry point
│   ├── app.dart               # Routes and theme
│   ├── config/
│   │   ├── app_config.dart    # App constants
│   │   ├── firebase_config.dart
│   │   └── secrets.json       # API keys (NOT in git)
│   ├── models/                # Data models
│   ├── screens/               # App screens
│   ├── services/              # Business logic
│   ├── widgets/               # Reusable components
│   ├── theme/                 # Colors and styles
│   └── utils/                 # Utilities
├── android/                   # Android config
├── ios/                       # iOS config
├── assets/                    # Images
└── pubspec.yaml               # Dependencies
```

---

## Key Files

| File | Purpose |
|------|---------|
| `lib/main.dart` | App entry point |
| `lib/screens/report_form_screen.dart` | Main form (8 steps) |
| `lib/services/email_service.dart` | SendGrid email sending |
| `lib/services/sheets_service.dart` | Google Sheets integration |
| `lib/services/auth_service.dart` | Firebase authentication |
| `lib/config/secrets.json` | API keys (create locally) |

---

## Troubleshooting

### "Flutter not found"
- Add Flutter to your PATH
- Restart terminal

### "Dependencies failed"
```bash
flutter clean
flutter pub get
```

### "Gradle build failed"
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

### "Firebase not configured"
- Ensure `google-services.json` is in `android/app/`

### "secrets.json not found"
- Create the file at `lib/config/secrets.json`
- Ask project owner for the keys

### App crashes on launch
- Check if `google-services.json` exists
- Check if `secrets.json` exists
- Run `flutter clean` then `flutter run`

---

## Important Notes

1. **NEVER commit `secrets.json`** - it's in `.gitignore`
2. **NEVER commit `google-services.json`** - it's in `.gitignore`
3. **Always pull before starting work**
4. **Test on a real device** (not emulator for camera features)

---

## Contact

For questions or issues:
- **Project Owner**: [Ask for contact]
- **Email**: yiw@seghana.net

---

## Quick Reference

```bash
# Clone
git clone https://github.com/Skia-0/YiW-Mobile-App.git

# Install
cd YiW-Mobile-App
flutter pub get

# Run
flutter run

# Pull changes
git pull origin main

# Push changes
git add -A
git commit -m "Your message"
git push origin main
```

Good luck! 🚀
