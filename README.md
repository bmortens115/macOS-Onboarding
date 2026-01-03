# macOS Onboarding Script

A one-command macOS bootstrap script to configure system preferences and install common developer tools and apps.

✅ Compatible with macOS default `/bin/bash` (Bash 3.2)  
✅ Designed for fresh setups / onboarding  
✅ Installs apps via **Homebrew**, **Mac App Store (mas)**, and **Installomator**  
✅ Applies common macOS defaults, configures Dock, enables Touch ID for sudo, and installs Oh My Zsh

---

## What This Script Does

### 1) System Preferences / macOS Defaults
Applies common defaults using `defaults write`, including:

- Dock positioning and behavior  
  - Dock at bottom  
  - Auto-hide enabled  
  - Recent apps disabled  
  - Spaces not reordered automatically
- Finder improvements  
  - Show Path Bar + Status Bar  
  - Group by Kind  
  - Column view by default  
  - Allow text selection in Quick Look  
  - Disable extension-change warning
- Global UI behavior  
  - Expand Save/Print dialogs by default  
  - Show all file extensions  
  - Disable smart quotes and smart dashes (better for coding)
- Time Machine  
  - Disable prompts to use newly connected disks for backup
- Filesystem hygiene  
  - Prevent `.DS_Store` creation on network volumes

After applying preferences, the script restarts Dock/Finder/SystemUIServer where needed.

---

### 2) Installs / Updates Homebrew
- If Homebrew is missing, it installs it
- If Homebrew exists, it runs:
  - `brew update`
  - `brew upgrade`
  - `brew cleanup`
- On Apple Silicon (arm64), it ensures Homebrew shell env is configured for future sessions

---

### 3) Installs Homebrew Apps (Formula + Casks)
The script installs a defined list of apps from Homebrew:
- GUI apps via **casks**
- CLI utilities via **formulae**

It skips anything already installed and shows a progress bar while installing.

---

### 4) Installs Mac App Store Apps (via `mas`)
Installs Mac App Store apps by ID (e.g. Xcode, Keynote, Pages, Numbers, etc.).  
If you’re not signed into the App Store, installs may prompt or fail.

Also attempts:
- `mas upgrade`

---

### 5) Installs Installomator + Installs Labels (as root)
- Installs the latest Installomator `.pkg` dynamically from GitHub Releases
- Runs a list of Installomator **labels**
- Installomator runs as **root** using `sudo`
- Default Installomator flags:
  - `DEBUG=0`
  - `NOTIFY=silent`

Installomator path used:
- `/usr/local/Installomator/Installomator.sh`

---

### 6) Installs Tart from GitHub Release
Downloads and installs the latest Tart release from GitHub into:
- `/opt/homebrew/bin` (Apple Silicon if available)  
- `/usr/local/bin` (Intel / fallback)

---

### 7) Configures the Dock
Uses **dockutil** to set the Dock to a specific app layout for the currently logged-in user.

- Clears existing Dock items
- Adds apps in order from the `DOCK_APPS` list
- Adds Downloads stack

---

### 8) Enables Touch ID for `sudo`
If the system supports Touch ID PAM modules (e.g. `pam_tid.so*`), the script:

- Backs up `/etc/pam.d/sudo`
- Inserts the Touch ID line after any header comments:

    auth sufficient pam_tid.so

This allows Touch ID authentication when running `sudo`.

---

### 9) Installs / Updates Oh My Zsh + Links `.zshrc`
- Installs Oh My Zsh (or updates it if already present)
- Creates a symlink from an iCloud-managed `.zshrc` into `$HOME/.zshrc`

Expected iCloud `.zshrc` location:

    ~/Library/Mobile Documents/com~apple~CloudDocs/Documents/profiles/.zshrc

---

## Requirements / Assumptions

Before running:
- ✅ macOS with Terminal access
- ✅ Stable internet connection
- ✅ You can authenticate with `sudo`
- ✅ You are signed in to the **Mac App Store** (recommended)
- ✅ You trust what the script installs/configures

---

## How to Run

### Option A — Run Directly from GitHub (Recommended)



```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/bmortens115/macOS-Onboarding/main/macOS_Setup.sh)" ```

---

### Option B — Download, Review, Then Run (Safer)

    curl -fsSL https://raw.githubusercontent.com/<YOUR_USER>/<YOUR_REPO>/main/macOS_Setup.sh -o macOS_Setup.sh
    less macOS_Setup.sh
    chmod +x macOS_Setup.sh
    ./macOS_Setup.sh

---

### Option C — Clone Repo and Run

    git clone https://github.com/<YOUR_USER>/<YOUR_REPO>.git
    cd <YOUR_REPO>
    chmod +x macOS_Setup.sh
    ./macOS_Setup.sh

---

## Customization

This script is designed to be easy to customize by editing these lists:

- `APPS` — Homebrew formulae & casks  
- `MAS_APPS` — Mac App Store apps (IDs)  
- `INSTALLOMATOR_APPS` — Installomator labels  
- `DOCK_APPS` — Dock app layout (path|label)

---

## Troubleshooting

### Mac App Store installs fail
Make sure you are signed in:
- Open **App Store** and sign in
- Re-run the script

### Touch ID for sudo doesn’t work
- Confirm Touch ID is supported and enrolled in **System Settings**
- macOS updates may overwrite `/etc/pam.d/sudo` — re-run script if needed

### Dock apps missing
The script skips apps that do not exist at the listed paths.  
Make sure the apps are installed and located in `/Applications`.

---

## Security Note

This script makes system changes and installs software.  
Always review scripts before running:

✅ Use the download/review method if running on a corporate or production machine.

---

## License
MIT License (c) 2026 Mort


