#!/bin/bash

# YiW Field Report Mobile App - GitHub Push Script
# This script helps you push the project to GitHub

set -e  # Exit on any error

echo "🚀 YiW Field Report Mobile App - GitHub Push Script"
echo "=================================================="

# Check if git is installed
if ! command -v git &> /dev/null; then
    echo "❌ Git is not installed. Please install Git first."
    echo "   Visit: https://git-scm.com/downloads"
    exit 1
fi

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Please run this script from the yiw_mobile_app directory"
    exit 1
fi

# Initialize git if not already done
if [ ! -d ".git" ]; then
    echo "📁 Initializing Git repository..."
    git init
    echo "✅ Git repository initialized"
fi

# Configure git user (if not set)
if [ -z "$(git config user.name)" ]; then
    read -p "Enter your name for Git commits: " git_name
    git config user.name "$git_name"
    echo "✅ Git name set to: $git_name"
fi

if [ -z "$(git config user.email)" ]; then
    read -p "Enter your email for Git commits: " git_email
    git config user.email "$git_email"
    echo "✅ Git email set to: $git_email"
fi

# Add all files
echo "📦 Adding files to Git..."
git add .
echo "✅ Files added"

# Create commit
echo "💾 Creating commit..."
git commit -m "Initial commit: YiW Field Report Mobile App

- Complete Flutter app for YiW Daily Field Report
- Multi-step form with all 8 sections
- Automatic email distribution to CEO, Registration Officer, and Sender
- Google Sheets integration for central database
- Offline support with Hive local storage
- Media capture (photos, videos, documents)
- PDF generation for email attachments
- Firebase authentication and storage
- Material Design 3 UI with dark mode support
- Comprehensive documentation and setup guides"
echo "✅ Commit created"

# Add remote
echo "🔗 Adding GitHub remote..."
git remote add origin https://github.com/Skia-0/YiW-Mobile-App.git 2>/dev/null || echo "Remote already exists"
echo "✅ Remote added"

# Rename branch to main
echo "🔄 Renaming branch to main..."
git branch -M main
echo "✅ Branch renamed"

# Push to GitHub
echo "🚀 Pushing to GitHub..."
echo "   You may be prompted for your GitHub credentials."
git push -u origin main

echo ""
echo "🎉 Success! Project pushed to GitHub!"
echo "   Repository: https://github.com/Skia-0/YiW-Mobile-App"
echo ""
echo "📋 Next steps:"
echo "1. Clone the repository on your local machine:"
echo "   git clone https://github.com/Skia-0/YiW-Mobile-App.git"
echo ""
echo "2. Set up the project:"
echo "   cd YiW-Mobile-App"
echo "   flutter pub get"
echo ""
echo "3. Configure Firebase (see SETUP_GUIDE.md)"
echo "4. Run the app: flutter run"
echo ""
echo "📚 Documentation:"
echo "   - README.md: Project overview"
echo "   - SETUP_GUIDE.md: Detailed setup instructions"
echo "   - USER_GUIDE.md: End-user documentation"
echo ""
echo "Happy coding! 🚀"