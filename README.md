## GOATLY Meeting Summarizer

![GOATLY logo](logo.jpg)

![App screenshot](screenshot.png)

**GOATLY** is a cross-platform desktop (and mobile) app for recording meetings and automatically transcribing and summarizing them using AI.

**[Full documentation →](https://justinguese.github.io/flutter-simple-meeting-recorder-transcriber-summarizer/)**

### Features

- One-click microphone recording written to a local WAV file
- AI transcription via [FAL Wizper](https://fal.ai/models/fal-ai/wizper)
- AI summarization via OpenRouter LLMs
- Search and sort across all past recordings
- Secure per-device key storage via `flutter_secure_storage`
- Windows, macOS, Linux (desktop) + iOS, Android (mobile)

### Deployment modes

**Fully open source** — Bring your own [FAL](https://fal.ai) and [OpenRouter](https://openrouter.ai) API keys. No sign-in required. Complete control, zero cost after free-tier quotas are exhausted (FAL: $5 monthly spend, OpenRouter: variable).

**Managed mode (free-tier)** — Sign in with Google/email. GOATLY provisions API keys automatically. Free tier covers ~500 minutes of transcription + summaries per month. For more usage, upgrade to a paid tier.

**Managed mode (paid)** — Upgrade from free tier within the app for higher transcription and summarization limits.

### Download

Pre-built binaries are attached to every [GitHub Release](../../releases).

| Platform | File |
|----------|------|
| Windows  | `goatly-windows.zip` — extract and run the `.exe` |
| macOS    | `goatly-macos.zip` — extract and drag `.app` to Applications |
| Linux    | `goatly-linux.tar.gz` — extract and run the binary |

### Setup (build from source)

1. **Install dependencies**

   ```bash
   flutter pub get
   ```

2. **Generate app icons**

   ```bash
   dart run flutter_launcher_icons
   ```

3. **Run the app**

   ```bash
   flutter run -d windows   # or macos / linux
   ```

   Sign in on first launch — in managed mode no API keys are needed.

4. **Optional: bring your own FAL key**

   ```bash
   export FAL_KEY="fal-…"   # bash/zsh
   $env:FAL_KEY = "fal-…"   # PowerShell
   ```

   Or use the in-app key dialog (key icon in the app bar).

### Notes

- Currently records the **microphone**; system/loopback capture can be layered on top of `AudioCaptureService`.
- See the [docs site](https://justinguese.github.io/flutter-simple-meeting-recorder-transcriber-summarizer/) for the full usage guide, configuration reference, and contributing instructions.
