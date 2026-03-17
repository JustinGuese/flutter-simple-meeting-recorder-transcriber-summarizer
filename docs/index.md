---
description: GOATLY is a free and easy meeting transcription and AI summarization tool. Open-source, cross-platform, and privacy-first.
keywords: meeting transcription, meeting summarizer, AI transcription, free meeting recorder, open source, managed mode
---

# GOATLY Meeting Summarizer

![GOATLY screenshot](../screenshot.png)

**GOATLY** is a cross-platform desktop and mobile application designed for **free and easy meeting transcription** and **AI-powered summarization**. Whether you're a student, professional, or researcher, GOATLY helps you focus on the conversation while AI handles the notes.

## Our Vision

We believe that high-quality **meeting transcription** and **summarization** should be accessible to everyone. Our vision is to provide a powerful, privacy-first tool that offers the best of both worlds:

1.  **Complete Freedom:** A fully **open-source** experience where you bring your own API keys and maintain total control over your data.
2.  **Effortless Productivity:** An **optional managed mode** for those who want a "just works" experience without managing API keys or infrastructure.

By bridging the gap between open-source flexibility and managed convenience, GOATLY aims to be the go-to solution for anyone looking to transcribe and summarize meetings across Windows, macOS, Linux, iOS, and Android.

## Features

- **One-click recording** — Start and stop your microphone with a single button.
- **AI transcription** — Lightning-fast speech-to-text powered by [FAL Wizper](https://fal.ai/models/fal-ai/wizper).
- **AI summarization** — Get key points and action items automatically via OpenRouter LLMs.
- **Search & sort** — Powerful full-text search across all your past recordings.
- **Secure key storage** — Your API keys are encrypted and stored locally on your device.
- **Cross-platform** — Native performance on Windows, macOS, Linux, iOS, and Android.

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

- [Best Meeting Summarizers 2026](best-meeting-summarizers.md) — How GOATLY compares to the competition.
- [Tutorial: Transcribe for Free on Windows](how-to-transcribe-free-windows.md) — Step-by-step guide for Windows users.
- [Getting Started](getting-started.md) — install and first run
- [Usage](usage.md) — record → transcribe → summarize walkthrough
- [Configuration](configuration.md) — managed mode vs. bring-your-own-key
- [Shared Libraries](shared-libraries.md) — reusable components from `df_flutter_shared`
- [Contributing](contributing.md) — dev setup and local path deps
