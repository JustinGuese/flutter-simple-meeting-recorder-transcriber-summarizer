# GOATLY Meeting Summarizer

![GOATLY screenshot](../screenshot.png)

**GOATLY** is a cross-platform desktop (and mobile) app for recording meetings and automatically transcribing and summarizing them using AI — no cloud subscription, no browser extension, just a native app.

## Features

- **One-click recording** — start/stop your microphone with a single button
- **AI transcription** — powered by [FAL Wizper](https://fal.ai/models/fal-ai/wizper), a fast speech-to-text model
- **AI summarization** — key points extracted automatically via OpenRouter LLMs
- **Search & sort** — full-text search across all your past recordings; sort by date or name
- **Secure key storage** — encrypted per-device storage via `flutter_secure_storage`
- **Cross-platform** — Windows, macOS, Linux (desktop); iOS & Android (mobile)

## Deployment modes

### Fully open source
Bring your own [FAL](https://fal.ai) and [OpenRouter](https://openrouter.ai) API keys. No sign-in required. Complete control over your data and keys.

**Cost:** Free while on free-tier quotas (FAL: $5 monthly spend; OpenRouter: variable). After that, pay-as-you-go.

### Managed mode (free-tier)
Sign in with Google or email. GOATLY provisions API keys automatically — no manual setup. Covers ~500 minutes of transcription + summaries per month for free.

**Cost:** Free (with monthly limits). Upgrade to paid tier for higher limits.

### Managed mode (paid)
Higher monthly limits on transcription and summarization. Manage billing in-app.

**Cost:** Varies by tier (check the app for current pricing).

## Download

Pre-built binaries are attached to every [GitHub Release](https://github.com/JustinGuese/flutter-simple-meeting-recorder-transcriber-summarizer/releases).

| Platform | File |
|----------|------|
| Windows  | `goatly-windows.zip` — extract and run the `.exe` |
| macOS    | `goatly-macos.zip` — extract and drag `.app` to Applications |
| Linux    | `goatly-linux.tar.gz` — extract and run the binary |

## Quick links

- [Getting Started](getting-started.md) — install and first run
- [Usage](usage.md) — record → transcribe → summarize walkthrough
- [Configuration](configuration.md) — managed mode vs. bring-your-own-key
- [Contributing](contributing.md) — dev setup and local path deps
