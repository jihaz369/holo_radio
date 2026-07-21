# HoloRadio Digital Modem - Flutter Port

Complete functional Flutter port of the HoloRadio Digital Modem with all features working.

## Features

- **Text Encoding**: Convert text to binary with live visualization
- **Audio Transmission**: Generate and play real audio signals via speaker
- **WAV Export**: Create and download real .wav files
- **Frame Building**: Split binary into frames with packet monitor
- **AES-GCM-256 Encryption**: Real encryption with passphrase-derived keys
- **Microphone Recording**: Record audio and decode signals
- **WAV File Loading**: Load and decode WAV files from storage
- **File Operations**: Copy, save, share all data types
- **Live Visualizations**: Spectrum, waterfall, oscilloscope, bit stream, constellation
- **System Logs**: Real-time logging on all screens

## Setup

1. Install Flutter SDK
2. Run: `flutter pub get`
3. Build APK: `flutter build apk --release`

## Dependencies

- audioplayers: Audio playback
- record: Microphone recording
- path_provider: File system access
- file_picker: File selection
- share_plus: Share files
- encrypt: AES-GCM-256 encryption
- crypto: PBKDF2 key derivation
- wav: WAV file handling
- permission_handler: Runtime permissions

## Permissions Required

- Microphone (RECORD_AUDIO)
- Storage (READ/WRITE_EXTERNAL_STORAGE)
- Manage External Storage (Android 11+)

## Build APK

```bash
flutter build apk --release
```

APK will be at: `build/app/outputs/flutter-apk/app-release.apk`
