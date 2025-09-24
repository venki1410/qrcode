# QR Code Scanner & Generator

A comprehensive Flutter app for scanning and generating QR codes with save functionality.

## Features

### 🔍 QR Code Scanner
- Real-time QR code scanning using device camera
- Flash toggle for low-light conditions
- Automatic scanning with visual feedback
- Copy scanned content to clipboard
- Save scanned codes for later reference

### 🎨 QR Code Generator
- Generate QR codes from text, URLs, or any data
- Customizable colors (foreground and background)
- Adjustable QR code size
- Real-time preview
- Save generated codes to gallery and app storage

### 💾 Save & Manage Codes
- Local storage using SharedPreferences
- View all saved QR codes (scanned and generated)
- Detailed view with QR code preview
- Copy, delete, or clear all saved codes
- Organized by creation date and type

## Screenshots

The app includes three main screens:
1. **Home Screen** - Navigation hub with quick access to all features
2. **Scanner Screen** - Camera-based QR code scanning
3. **Generator Screen** - Create custom QR codes with customization options
4. **Saved Codes Screen** - Manage all saved QR codes

## Installation

1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. Run `flutter run` to start the app

## Dependencies

- `mobile_scanner` - For camera-based QR code scanning
- `qr_flutter` - For generating QR codes
- `permission_handler` - For camera and storage permissions
- `shared_preferences` - For local data storage
- `gal` - For saving QR codes to device gallery
- `path_provider` - For file system access

## Permissions

### Android
- `CAMERA` - Required for QR code scanning
- `WRITE_EXTERNAL_STORAGE` - For saving QR codes to gallery
- `READ_EXTERNAL_STORAGE` - For accessing saved files

### iOS
- `NSCameraUsageDescription` - Camera access for scanning
- `NSPhotoLibraryAddUsageDescription` - Photo library access for saving

## Usage

1. **Scanning QR Codes**: Tap "Scan QR Code" and point your camera at a QR code
2. **Generating QR Codes**: Tap "Generate QR Code", enter your text, and customize the appearance
3. **Managing Saved Codes**: Tap "Saved Codes" to view, copy, or delete previously saved QR codes

## Features in Detail

- **Real-time Scanning**: Instant QR code detection with visual feedback
- **Customization**: Choose colors and size for generated QR codes
- **Offline Storage**: All data is stored locally on the device
- **Cross-platform**: Works on both Android and iOS
- **Modern UI**: Clean, intuitive interface following Material Design principles

## Development

This app is built with Flutter and follows best practices for:
- State management
- Error handling
- Permission management
- Local storage
- Cross-platform compatibility