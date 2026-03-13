# Getting Started

## Option A — Download a release (recommended)

1. Go to the [Releases page](https://github.com/JustinGuese/flutter-simple-meeting-recorder-transcriber-summarizer/releases).
2. Download the archive for your platform.
3. Extract and run.

No Flutter SDK or Dart installation required.

---

## Option B — Build from source

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable channel, ≥ 3.3)
- Dart ≥ 3.3
- Platform-specific toolchain:
    - **Windows** — Visual Studio 2022 with "Desktop development with C++" workload
    - **macOS** — Xcode ≥ 14 + CocoaPods
    - **Linux** — `clang cmake ninja-build pkg-config libgtk-3-dev`

### Clone and run

```bash
git clone https://github.com/JustinGuese/flutter-simple-meeting-recorder-transcriber-summarizer.git
cd flutter-simple-meeting-recorder-transcriber-summarizer

flutter pub get
flutter run -d windows   # or macos / linux
```

### Generate app icons (optional)

```bash
dart run flutter_launcher_icons
```

---

## First launch

On first launch you will be prompted to **sign in** (Google or email). After signing in you are in **managed mode** — API keys are provisioned automatically and you can start recording immediately.

See [Configuration](configuration.md) if you prefer to supply your own keys.
