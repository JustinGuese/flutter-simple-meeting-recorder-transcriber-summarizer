# Privacy Policy

**Effective Date:** March 16, 2026

At **GOATLY**, we believe your meetings are your business. Our goal is to provide a powerful tool for transcription and summarization while respecting your privacy.

## 1. Data Collection

### Fully Open Source Mode
In this mode, GOATLY acts as a local-first application. 
- **Audio Recordings:** Audio is recorded locally on your device and never sent to our servers.
- **Transcription/Summarization:** Audio and transcripts are sent directly to your chosen API providers (e.g., FAL.ai, OpenRouter) using your own API keys. We do not have access to this data.

### Managed Mode
When you use Managed Mode, we collect minimal information necessary to provide the service:
- **Authentication:** We use Firebase Auth (Google or Email) to manage your account.
- **Usage Metadata:** We track the number of minutes transcribed to manage your tier limits.
- **Audio Processing:** Audio is processed through our managed API keys with third-party providers. We do not store your raw audio after processing is complete.

## 2. Third-Party Services

GOATLY integrates with several third-party services:
- **FAL.ai:** For high-speed transcription (Wizper).
- **OpenRouter:** For AI-powered summarization (LLMs).
- **Firebase:** For authentication and tier management in Managed Mode.

Please refer to their respective privacy policies for more information on how they handle data.

## 3. Data Storage

All transcripts and meeting metadata are stored **locally on your device** in a SQLite database. GOATLY does not maintain a cloud database of your meeting content. If you delete the app or clear its data, your meetings are permanently removed unless you have backed them up manually.

## 4. Your Rights

You have the right to:
- Access the transcripts stored on your device.
- Delete your account and associated metadata in Managed Mode.
- Revert to Open Source mode at any time to maintain 100% control over your data.

## 5. Contact Us

For any questions regarding this Privacy Policy, please contact us via GitHub.
