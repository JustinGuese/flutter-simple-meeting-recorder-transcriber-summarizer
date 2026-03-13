# Configuration

## Managed mode (default)

Sign in with a Google or email account. GOATLY provisions FAL and OpenRouter API keys on your behalf — no manual key management required.

**Free tier** covers ~500 minutes of transcription + summaries per month. After reaching the limit, you can upgrade to a paid tier in the app.

**Recommended for:** Most users who want the easiest setup with optional paid upgrades.

---

## Bring-your-own-key mode (fully open source)

Run GOATLY completely standalone with your own API accounts. No sign-in required. You control where your data goes and which API providers you use.

### Prerequisites

- [FAL account](https://fal.ai) with an API key (free tier: $5 monthly spend)
- [OpenRouter account](https://openrouter.ai) with an API key (free tier: limited credits)

### Setup

#### Option 1: Environment variables (recommended for dev)

```bash
# bash / zsh
export FAL_KEY="fal-…"
export OPENROUTER_KEY="sk-or-…"

# PowerShell
$env:FAL_KEY = "fal-…"
$env:OPENROUTER_KEY = "sk-or-…"
```

Then run the app:

```bash
flutter run -d windows
```

#### Option 2: In-app key dialog (recommended for released builds)

1. Launch the app without signing in (skip the Firebase login).
2. Open the **key icon** in the app bar.
3. Paste your FAL and OpenRouter keys.

Keys are stored in `flutter_secure_storage` (encrypted on-device) and take precedence over environment variables.

**Cost:** Free while on free-tier quotas. After that, pay-as-you-go to both services.

**Recommended for:** Developers, privacy-conscious users, or those wanting to bring their own billing.

---

## Firebase / Auth (managed mode only)

Managed mode uses Firebase Auth. The Firebase configuration (`google-services.json` / `GoogleService-Info.plist`) is included in the repository for the managed deployment.

If you are self-hosting the managed backend, replace these files with your own Firebase project credentials.
