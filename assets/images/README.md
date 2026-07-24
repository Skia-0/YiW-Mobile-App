# Assets Directory

This directory contains all the assets for the YiW Field Report mobile app.

## Images
- `yiw_logo.png` - Main app logo (recommended size: 512x512)
- `splash_logo.png` - Splash screen logo (recommended size: 1024x1024)
- `placeholder.png` - Placeholder image for empty states

## Icons
- App icons for Android and iOS
- Custom icons for form sections

## Fonts
- `Poppins-Regular.ttf` - Regular weight
- `Poppins-Medium.ttf` - Medium weight (500)
- `Poppins-SemiBold.ttf` - Semi-bold weight (600)
- `Poppins-Bold.ttf` - Bold weight (700)

## Lottie Animations
- `loading.json` - Loading animation
- `success.json` - Success animation
- `error.json` - Error animation

## How to Add Assets

1. Place your image files in the appropriate subdirectory
2. Update the `pubspec.yaml` file to include the new assets
3. Reference the assets in your code using `AssetImage` or `Image.asset`

## Asset Guidelines

- **Images**: Use PNG format for logos and icons, JPEG for photos
- **Icons**: Prefer SVG for scalable icons
- **Fonts**: Include only the weights you need to reduce app size
- **Animations**: Keep Lottie files small and optimized

## Image Sizes

- App icon: 512x512 px
- Splash screen: 1024x1024 px
- Thumbnail: 200x200 px
- Background: 1920x1080 px (landscape) or 1080x1920 px (portrait)