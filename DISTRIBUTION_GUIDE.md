# Distribution Guide: Homebrew & Winget

This guide explains how to submit GOATLY to official package managers for easier installation.

## 1. Homebrew (macOS) - Custom Tap
Since we are using a custom tap, users will install GOATLY via `brew install justinguese/tap/goatly`.

### Prerequisites
- A GitHub repository named `homebrew-tap` (or similar) under your account.

### Steps to set up the Tap
1.  **Create the Repository:** Create a new public repo on GitHub called `homebrew-tap`.
2.  **Add the Cask:**
    - Create a folder named `Casks` in that repo.
    - Move `goatly.rb` into that folder.
3.  **Generate SHA256:**
    Download the latest macOS release and run:
    ```bash
    shasum -a 256 goatly-macos.zip
    ```
4.  **Update Cask File:**
    Ensure `Casks/goatly.rb` has the correct `version` and `sha256`.
5.  **Usage for Users:**
    Users can now install GOATLY by running:
    ```bash
    brew install justinguese/tap/goatly
    ```

### Local Testing
To test the tap locally before pushing:
```bash
brew install --cask ./goatly.rb
```

---

## 2. Winget (Windows)
Winget manifests are submitted to the [winget-pkgs repository](https://github.com/microsoft/winget-pkgs).

### Prerequisites
- [Winget-create](https://github.com/microsoft/winget-create) tool (recommended).

### Steps
1.  **Generate SHA256:**
    Download the latest Windows release and run:
    ```powershell
    CertUtil -hashfile goatly-windows.zip SHA256
    ```
2.  **Update Template:**
    Open `winget-goatly.yaml` and update the `PackageVersion`, `InstallerUrl`, and `InstallerSha256`.
3.  **Test Locally:**
    ```powershell
    winget install --manifest .\winget-goatly.yaml
    ```
4.  **Submit PR:**
    The easiest way is using `winget-create`:
    ```powershell
    winget-create submit https://github.com/JustinGuese/flutter-simple-meeting-recorder-transcriber-summarizer/releases/download/v0.0.0/goatly-windows.zip
    ```
    Or manually fork `winget-pkgs` and follow their [manifest structure](https://github.com/microsoft/winget-pkgs/tree/master/manifests/j/JustinGuese/GOATLY).

---

## Next Steps
Once these are live, update the documentation website to include:
- `brew install --cask goatly`
- `winget install goatly`
