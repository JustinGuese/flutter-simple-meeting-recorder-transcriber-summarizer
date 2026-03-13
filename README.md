## GOATLY

![GOATLY logo](logo.jpg)

GOATLY is a desktop Flutter app for recording meetings and sending them to FAL Wizper for transcription (with in-app summaries).

### Features

- Microphone recording using `desktop_audio_capture`, written to a local WAV file.
- One-click "Stop & transcribe" flow using `fal_client` and `fal-ai/wizper`.
- Secure override for `FAL_KEY` using `flutter_secure_storage` (per-device).
- Desktop window management via `window_manager`.

### Setup

1. **Create Flutter desktop scaffolding (if not already)**

   From this directory:

   ```bash
   flutter create .
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Generate app icons**

   ```bash
   dart run flutter_launcher_icons
   ```

4. **Configure your FAL API key**

   Recommended for development:

   ```bash
   # PowerShell
   $env:FAL_KEY = "YOUR_FAL_KEY"

   # or bash
   export FAL_KEY="YOUR_FAL_KEY"
   ```

   You can also open the in-app key dialog (key icon in the app bar) to store an override key in `flutter_secure_storage`.

5. **Run the app (desktop)**

   ```bash
   flutter run -d windows
   ```

### Notes

- Currently the app records the **microphone**; adding separate system/loopback capture can be layered on top of `AudioCaptureService`.
- For long meetings you may switch from the blocking `subscribe` call to the queue-based pattern described in `PLAN.md`.

