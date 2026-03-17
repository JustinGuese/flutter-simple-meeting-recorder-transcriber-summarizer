---
description: Contribute to GOATLY. Learn about development setup, project structure, and local path dependencies.
keywords: contribute to GOATLY, open source contribution, Flutter meeting summarizer development, developer guide
---

# Contributing

## Dev setup

```bash
git clone https://github.com/JustinGuese/flutter-simple-meeting-recorder-transcriber-summarizer.git
cd flutter-simple-meeting-recorder-transcriber-summarizer
flutter pub get
flutter run -d windows   # or macos / linux / chrome
```

## Running tests

```bash
flutter test
```

## Local path dependencies

`df_ui_widgets`, `df_ai_consent`, and `df_firebase_rest` are shared packages hosted in a sibling repo. The `pubspec.yaml` references them via git or path. For local development, swap to path overrides:

```yaml
# pubspec.yaml — local dev overrides
dependency_overrides:
  df_ui_widgets:
    path: ../df_flutter_shared/df_ui_widgets
  df_ai_consent:
    path: ../df_flutter_shared/df_ai_consent
  df_firebase_rest:
    path: ../df_flutter_shared/df_firebase_rest
```

Clone the sibling repo first:

```bash
git clone https://github.com/JustinGuese/df_flutter_shared.git ../df_flutter_shared
```

## Submitting changes

1. Fork the repo and create a feature branch.
2. Make your changes, add tests where applicable.
3. Open a pull request against `main`.

## Building a release

Tag a commit with a semver tag (e.g. `v0.2.0`) to trigger the CI release workflow, which builds Windows, macOS, and Linux artifacts and attaches them to a GitHub Release automatically.
