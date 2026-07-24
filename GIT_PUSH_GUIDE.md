# Git Push Instructions

## Option 1: Clone and Push from Your Local Machine

### Step 1: Download the project
The project is ready at: `/home/user/yiw_mobile_app/`

You can download it as a zip or copy the files to your local machine.

### Step 2: Initialize Git (if not already done)
```bash
cd yiw_mobile_app
git init
git add .
git commit -m "Initial commit: YiW Field Report Mobile App"
```

### Step 3: Add your GitHub repository
```bash
git remote add origin https://github.com/Skia-0/YiW-Mobile-App.git
git branch -M main
```

### Step 4: Push to GitHub
```bash
git push -u origin main
```

## Option 2: Use GitHub CLI (Recommended)

### Install GitHub CLI
```bash
# macOS
brew install gh

# Windows
winget install gh

# Linux (Ubuntu/Debian)
sudo apt install gh
```

### Login to GitHub
```bash
gh auth login
```

### Push the project
```bash
cd yiw_mobile_app
gh repo create YiW-Mobile-App --public --source=. --push
```

## Option 3: Use GitHub Desktop

1. Download GitHub Desktop from [desktop.github.com](https://desktop.github.com)
2. Sign in with your GitHub account
3. Click "Add an Existing Repository from your Hard Drive"
4. Select the `yiw_mobile_app` folder
5. Click "Publish repository"
6. Choose name: `YiW-Mobile-App`
7. Click "Publish Repository"

## Option 4: Manual Upload via GitHub Web

1. Go to [github.com/new](https://github.com/new)
2. Repository name: `YiW-Mobile-App`
3. Click "Create repository"
4. Click "uploading an existing file"
5. Drag and drop all files from `yiw_mobile_app/`
6. Click "Commit changes"

## After Pushing

Once pushed, you can:

### Clone on your local machine
```bash
git clone https://github.com/Skia-0/YiW-Mobile-App.git
cd YiW-Mobile-App
```

### Set up the project
```bash
flutter pub get
```

### Run the app
```bash
flutter run
```

## Important Notes

1. **Do NOT commit sensitive files**:
   - `google-services.json` (Firebase)
   - `GoogleService-Info.plist` (iOS Firebase)
   - `.env` files
   - API keys

2. **Add these to .gitignore** (already done):
   ```
   **/android/app/google-services.json
   **/ios/Runner/GoogleService-Info.plist
   .env
   ```

3. **Create a `.env.example` file** with placeholder values for other developers.

## Need Help?

If you encounter issues:
1. Check GitHub's documentation: [docs.github.com](https://docs.github.com)
2. Use GitHub's community forum: [github.community](https://github.community)
3. Contact support: support@seghana.net

---

**Project URL**: https://github.com/Skia-0/YiW-Mobile-App

Happy coding! 🚀