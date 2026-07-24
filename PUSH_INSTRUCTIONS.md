# 🚀 How to Push YiW Mobile App to GitHub

The project is ready at: `/home/user/yiw_mobile_app/`

## Quick Option: Use the Provided Script

I've created a script that automates the push process:

```bash
# Navigate to the project directory
cd /home/user/yiw_mobile_app

# Run the push script
./push_to_github.sh
```

The script will:
1. Initialize Git (if needed)
2. Configure your Git name and email
3. Add all files
4. Create a commit
5. Add the GitHub remote
6. Push to your repository

## Manual Option: Step-by-Step Instructions

### Step 1: Copy the Project to Your Local Machine

You have several options:

#### Option A: Download as ZIP
1. The project files are at `/home/user/yiw_mobile_app/`
2. Download/zip the entire directory
3. Extract on your local machine

#### Option B: Use SCP/SFTP (if you have access)
```bash
# From your local machine
scp -r username@server:/home/user/yiw_mobile_app ./
```

### Step 2: Push to GitHub

Open terminal/command prompt on your local machine:

```bash
# Navigate to the project directory
cd path/to/yiw_mobile_app

# Initialize Git repository
git init

# Add all files
git add .

# Create initial commit
git commit -m "Initial commit: YiW Field Report Mobile App"

# Add your GitHub repository as remote
git remote add origin https://github.com/Skia-0/YiW-Mobile-App.git

# Rename branch to main
git branch -M main

# Push to GitHub
git push -u origin main
```

### Step 3: Authenticate with GitHub

When prompted for credentials:
1. **Username**: Your GitHub username
2. **Password**: Your GitHub Personal Access Token (NOT your password)

#### How to Create a Personal Access Token:
1. Go to [GitHub Settings → Developer settings → Personal access tokens](https://github.com/settings/tokens)
2. Click "Generate new token"
3. Give it a name (e.g., "YiW Mobile App")
4. Select scopes: `repo` (Full control of private repositories)
5. Click "Generate token"
6. **Copy the token immediately** (you won't see it again)

## Alternative: Use GitHub Desktop (Easier)

1. Download [GitHub Desktop](https://desktop.github.com)
2. Sign in with your GitHub account
3. Click "Add an Existing Repository from your Hard Drive"
4. Select the `yiw_mobile_app` folder
5. Click "Publish repository"
6. Name: `YiW-Mobile-App`
7. Click "Publish Repository"

## After Pushing

Once pushed successfully, you can:

### Clone on Another Machine
```bash
git clone https://github.com/Skia-0/YiW-Mobile-App.git
cd YiW-Mobile-App
```

### Set Up the Project
```bash
# Install Flutter dependencies
flutter pub get

# Configure Firebase (see SETUP_GUIDE.md)
# Add google-services.json (Android)
# Add GoogleService-Info.plist (iOS)

# Run the app
flutter run
```

## Troubleshooting

### "Permission denied" Error
- Make sure you're using your Personal Access Token, not your password
- Check that the token has `repo` scope

### "Repository not found" Error
- Verify the repository URL: https://github.com/Skia-0/YiW-Mobile-App
- Make sure the repository exists on GitHub

### "Failed to push" Error
- Try force push (use with caution):
  ```bash
  git push -u origin main --force
  ```

### Files Not Showing Up
- Check `.gitignore` - some files might be ignored
- Run `git status` to see what's tracked

## Important Notes

### Files NOT to Commit (Already in .gitignore):
- `**/android/app/google-services.json`
- `**/ios/Runner/GoogleService-Info.plist`
- `.env` files
- API keys

### Create These Files After Cloning:
1. `android/app/google-services.json` (from Firebase)
2. `ios/Runner/GoogleService-Info.plist` (from Firebase)
3. `.env` with your API keys

## Need Help?

- **GitHub Documentation**: [docs.github.com](https://docs.github.com)
- **Git Tutorial**: [git-scm.com/book](https://git-scm.com/book)
- **Contact Support**: support@seghana.net

---

**Repository URL**: https://github.com/Skia-0/YiW-Mobile-App

**Next Steps After Push**:
1. Set up Firebase project
2. Configure SendGrid for emails
3. Set up Google Sheets API
4. Test the app locally
5. Deploy to app stores

Good luck! 🎉