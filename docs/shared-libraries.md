# Shared Libraries

To maintain code quality and reusability across multiple [DataFortress.cloud](https://datafortress.cloud/) projects, several core functionalities of GOATLY are extracted into a shared library repository: [df_flutter_shared](https://github.com/JustinGuese/df_flutter_shared).

## Core Shared Packages

The following packages from the shared repository are utilized in this project:

| Package | Purpose in GOATLY |
|---------|-------------------|
| **`df_ui_widgets`** | Provides reusable UI components like the `AudioLevelBar`, `RecordingTimer`, and `KeywordChipList`. |
| **`df_audio_capture`** | A unified, cross-platform interface for microphone and system/loopback audio recording. |
| **`df_firebase_rest`** | A custom REST-based implementation of Firebase Auth to support Windows and Linux platforms. |
| **`df_device_id`** | Generates and securely stores a persistent unique identifier for the device. |
| **`df_ai_consent`** | Manages GDPR-compliant consent for AI-driven data processing. |

## Why Shared Libraries?

- **Platform Parity:** Many features (like REST-based Auth or Desktop audio loopback) require complex platform-specific implementations. Sharing these ensures consistent behavior across all our applications.
- **Maintainability:** Bug fixes and performance improvements in audio capture or UI widgets automatically benefit all apps using the shared library.
- **Development Speed:** New projects can bootstrap features like authentication and recording by simply importing the shared packages.

## Local Development

If you are contributing to GOATLY and need to modify these shared libraries, we recommend cloning the shared repository into a sibling directory and using Flutter's `dependency_overrides` in your `pubspec.yaml`:

```yaml
dependency_overrides:
  df_audio_capture:
    path: ../df_flutter_shared/df_audio_capture
  # ... other packages
```

For more details on setting up a local development environment, see the [Contributing Guide](contributing.md).
