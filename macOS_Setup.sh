#!/usr/bin/env bash
###############################################################################
#  Mac Bootstrap – Preferences, Homebrew, MAS apps, Installomator, Oh My Zsh
#  Compatible with /bin/bash 3.2 on macOS
#  (c) 2026 Mort • MIT License
###############################################################################

###############################################################################
#  Colors + logging helpers
###############################################################################
GREEN=$'\033[0;32m'; BLUE=$'\033[0;34m'
RED=$'\033[0;31m';   YELLOW=$'\033[1;33m'
NC=$'\033[0m';       BOLD=$'\033[1m'

log_info()    { printf '%sℹ️  %s%s\n'  "$BLUE"   "$1" "$NC"; }
log_success() { printf '%s✅ %s%s\n'   "$GREEN"  "$1" "$NC"; }
log_warning() { printf '%s⚠️  %s%s\n'  "$YELLOW" "$1" "$NC"; }
log_error()   { printf '%s❌ %s%s\n'   "$RED"    "$1" "$NC"; }

###############################################################################
#  Robust shell behavior + cleanup
###############################################################################
set -Eeuo pipefail

cleanup() {
  # Restore cursor visibility (if hidden by any future UX changes)
  tput cnorm 2>/dev/null || true
}
trap cleanup EXIT
trap 'log_error "Interrupted"; exit 1' INT HUP TERM
trap 'log_error "Line $LINENO (exit $?) – $BASH_COMMAND"; exit 1' ERR

###############################################################################
#  Progress-bar helpers (simple text progress for long installs)
###############################################################################
BAR_W=30

show_bar() {  # usage: show_bar <pct> <message>  (no trailing newline)
  local pct=$1 msg=$2
  local done=$(( BAR_W * pct / 100 ))
  local todo=$(( BAR_W - done ))

  printf '\r\033[K%s┃%s' "$BLUE" "$NC"
  printf '%*s' "$done" '' | tr ' ' '█'
  printf '%*s' "$todo" '' | tr ' ' '░'
  printf '%s┃ %3d%% %s%s' "$BLUE" "$pct" "$msg" "$NC"
}

newline_below_bar() { printf '\n'; }

###############################################################################
#  Welcome / preflight
###############################################################################
welcome() {
  echo "======================================================"
  log_info "🎯  Mac Setup Script – Preferences & Apps"
  echo "======================================================"
  log_warning "You'll be prompted for your password when needed."
  echo "1) Sign in to the Mac App Store"
  echo "2) Review this script (recommended)"
  echo "3) Ensure a stable internet connection"
  echo
  read -r -p "Press RETURN to continue or CTRL-C to quit…"
  echo
}

###############################################################################
#  Preferences (macOS defaults)
###############################################################################
configure_system() {
  # Helpful reference: https://macos-defaults.com
  log_info "Configuring System Preferences…"

  # --- Dock ---
  defaults write com.apple.dock orientation -string bottom            # Dock position: bottom
  defaults write com.apple.dock autohide -bool true                  # Dock autohide: enabled
  defaults write com.apple.dock show-recents -bool false             # Dock: hide recent apps
  defaults write com.apple.dock mru-spaces -bool false               # Spaces: do not auto-reorder

  # --- Finder ---
  defaults write com.apple.finder ShowPathbar -bool true             # Finder: show path bar
  defaults write com.apple.finder ShowStatusBar -bool true           # Finder: show status bar
  defaults write com.apple.finder FXPreferredGroupBy -string Kind    # Finder: group by Kind
  defaults write com.apple.finder FXRemoveOldTrashItems -bool true   # Finder: auto-remove old Trash items
  defaults write com.apple.finder QLEnableTextSelection -bool true   # Quick Look: allow text selection
  defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false # Finder: no extension warning
  defaults write com.apple.finder FXPreferredViewStyle -string Clmv  # Finder: column view default

  # --- Global ---
  defaults write NSGlobalDomain AppleShowAllExtensions -bool true    # Show all file extensions
  defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true # Expand save panel
  defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true   # Expand print panel (legacy)
  defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true  # Expand print panel (modern)
  defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false # Disable smart quotes
  defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false  # Disable smart dashes

  # --- Time Machine ---
  defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true # No new-disk prompts

  # --- Filesystem ---
  defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true # No .DS_Store on network

  # Apply immediately where possible
  killall Dock Finder SystemUIServer 2>/dev/null || true
  log_success "System Preferences applied."
}

###############################################################################
#  Homebrew – install or update/upgrade
###############################################################################
brew_bootstrap() {
  if ! command -v brew &>/dev/null; then
    log_info "Homebrew not found → installing…"
    bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  else
    log_info "Homebrew found → updating & upgrading…"
    brew update
    brew upgrade
    brew cleanup
  fi

  # Ensure brew works for Apple Silicon shells in future sessions
  if [[ $(uname -m) == arm64 ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    grep -q "/opt/homebrew" ~/.zprofile 2>/dev/null || \
      echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
  fi
}

###############################################################################
#  Package Lists
#  APPS format: "name:kind[:flag]" where kind is cask|formula
###############################################################################
APPS=(
  # --- Casks ---
  "alfred:cask"
  "arc:cask"
  "bbedit:cask"
  "bettertouchtool:cask"
  "coderunner:cask"
  "git-credential-manager:cask"
  "github:cask"
  "little-snitch:cask"
  "postman:cask"
  "proxyman:cask"
  "suspicious-package:cask"
  "telegram:cask"
  "vlc:cask"
  "antigravity:cask"
  "betterdisplay:cask"
  "chatgpt:cask"
  "discord:cask"
  "iterm2:cask"
  "keeper-password-manager:cask"
  "sf-symbols:cask"
  "visual-studio-code:cask"
  "windows-app:cask"

  # --- Formulae ---
  "autoconf:formula"
  "bat:formula"
  "ca-certificates:formula"
  "fd:formula"
  "jq:formula"
  "libgit2:formula"
  "libssh2:formula"
  "m4:formula"
  "oniguruma:formula"
  "openssl@3:formula"
  "pkgconf:formula"
  "pyenv:formula"
  "readline:formula"
  "terraform:formula"
  "xmlstarlet:formula"
  "mas:formula"
  "dockutil:formula"
)

MAS_APPS=(
  "1006087419:SnippetsLab"
  "497799835:Xcode"
  "409183694:Keynote"
  "409201541:Pages"
  "409203825:Numbers"
  "429449079:Patterns - The Regex App"
  "1487860882:iMazing Profile Editor"
  "1157491961:PLIST Editor"
  "1133234759:MUT"
  "425424353:The Unarchiver"
  "1037126344:Apple Configurator"
)

INSTALLOMATOR_APPS=(
  "jamfconnectconfiguration"
  "jamfcpr"
  "Prune"
  "jamfpppcutility"
)

# Dock items (path|label). Add Finder explicitly if you want it first.
DOCK_APPS=(
  "/System/Library/CoreServices/Finder.app|Finder"
  "/Applications/Microsoft Outlook.app|Microsoft Outlook"
  "/Applications/Daylite.app|Daylite"
  "/Applications/Slack.app|Slack"
  "/Applications/ChatGPT.app|ChatGPT"
  "/Applications/Arc.app|Arc"
  "/Applications/Photos.app|Photos"
  "/Applications/Messages.app|Messages"
  "/Applications/iTerm.app|iTerm"
  "/Applications/Antigravity.app|Antigravity"
  "/Applications/Visual Studio Code.app|Visual Studio Code"
  "/Applications/CodeRunner.app|CodeRunner"
  "/Applications/Notes.app|Notes"
  "/Applications/Reminders.app|Reminders"
)

###############################################################################
#  Utility: fill an array with command output (bash 3.2 compatible)
#  cmd_to_array <array_name> "<command string>"
###############################################################################
cmd_to_array() {
  local arr_name=$1 cmd=$2 line
  eval "$arr_name=()"
  while IFS= read -r line; do
    eval "$arr_name+=(\"\$line\")"
  done < <(eval "$cmd")
}

###############################################################################
#  Install Brew items (skips already installed)
###############################################################################
install_brew_items() {
  log_info "Installing Homebrew apps…"

  local INST_FORMULAE=()
  local INST_CASKS=()
  cmd_to_array INST_FORMULAE "brew list --formula"
  cmd_to_array INST_CASKS    "brew list --cask 2>/dev/null || true"

  local total=${#APPS[@]} current=0 pct name kind flag

  show_bar 0 "starting…"; newline_below_bar
  for entry in "${APPS[@]}"; do
    current=$((current+1))
    pct=$(( current * 100 / total ))

    # Parse "name:kind[:flag]"
    IFS=':' read -r name kind flag <<< "$entry"

    # Skip already installed
    if [[ $kind == cask ]] && [[ " ${INST_CASKS[*]-} " == *" $name "* ]]; then
      show_bar "$pct" "✓ already installed $name"; newline_below_bar
      continue
    fi
    if [[ $kind == formula ]] && [[ " ${INST_FORMULAE[*]-} " == *" $name "* ]]; then
      show_bar "$pct" "✓ already installed $name"; newline_below_bar
      continue
    fi

    show_bar "$pct" "↓ installing $name"; newline_below_bar

    if [[ $kind == cask ]]; then
      if [[ ${flag:-} == "no-quarantine" ]]; then
        brew install --cask --no-quarantine "$name"
      else
        brew install --cask "$name"
      fi
    else
      brew install "$name"
    fi

    show_bar "$pct" "✔︎ installed $name"; newline_below_bar
  done

  brew upgrade
  brew cleanup
  log_success "Homebrew installs complete."
}

###############################################################################
#  Install Mac App Store items (MAS)
###############################################################################
install_mas_items() {
  log_info "Installing Mac App Store apps…"

  command -v mas >/dev/null || brew install mas

  # Try to read installed list; on newer macOS this can fail if MAS isn't signed in
  local INST_IDS=()
  if mas list 1>/tmp/mas_installed 2>/dev/null; then
    INST_IDS=($(awk '{print $1}' /tmp/mas_installed))
  else
    log_warning "Cannot read App Store account status; installs may prompt or fail."
  fi
  rm -f /tmp/mas_installed

  local total=${#MAS_APPS[@]} current=0 pct id name

  show_bar 0 "starting…"; newline_below_bar
  for entry in "${MAS_APPS[@]}"; do
    current=$((current+1))
    pct=$(( current * 100 / total ))

    id=${entry%%:*}
    name=${entry#*:}

    if [[ " ${INST_IDS[*]-} " == *" $id "* ]]; then
      show_bar "$pct" "✓ already installed $name"; newline_below_bar
      continue
    fi

    show_bar "$pct" "↓ installing $name"; newline_below_bar
    if mas install "$id"; then
      show_bar "$pct" "✔︎ installed $name"; newline_below_bar
    else
      log_warning "Failed: $name"
    fi
  done

  mas upgrade || true
  log_success "Mac App Store installs complete."
}

###############################################################################
#  Installomator – install/update + run labels
###############################################################################
installomator_bootstrap() {
	local installomator_path="/usr/local/Installomator/Installomator.sh"
	local tmp_pkg="/tmp/Installomator.pkg"
	
	if [[ -x "$installomator_path" ]]; then
		log_info "Installomator found → upgrading to latest…"
	else
		log_info "Installomator not found → installing latest…"
	fi
	
	# Resolve the latest tag via redirect:
	# https://github.com/Installomator/Installomator/releases/latest
	# → https://github.com/Installomator/Installomator/releases/tag/v10.8
	local final_url tag version pkg_url
	final_url="$(curl -fsSLI -o /dev/null -w '%{url_effective}' \
		"https://github.com/Installomator/Installomator/releases/latest" 2>/dev/null || true)"
	
	tag="${final_url##*/}"     # e.g. v10.8
	version="${tag#v}"         # e.g. 10.8
	
	if [[ -z "$tag" || -z "$version" || "$tag" == "$final_url" ]]; then
		log_error "Could not determine latest Installomator release tag."
		log_error "Resolved URL: ${final_url:-<empty>}"
		return 1
	fi
	
	pkg_url="https://github.com/Installomator/Installomator/releases/download/${tag}/Installomator-${version}.pkg"
	log_info "Latest Installomator pkg → $pkg_url"
	
	# Download the pkg
	curl -fL --retry 3 --retry-delay 1 -o "$tmp_pkg" "$pkg_url" || {
		log_error "Failed to download Installomator pkg."
		return 1
	}
	
	# Install the pkg
	sudo installer -pkg "$tmp_pkg" -target / || {
		log_error "Installomator pkg install failed."
		rm -f "$tmp_pkg"
		return 1
	}
	
	rm -f "$tmp_pkg"
	
	# Verify install
	if [[ -x "$installomator_path" ]]; then
		log_success "Installomator installed successfully → $installomator_path"
	else
		log_error "Install completed, but Installomator.sh not found at expected path."
		return 1
	fi
}

installomator_install_labels() {
  local installomator="/usr/local/Installomator/Installomator.sh"
  local default_flags=("DEBUG=0" "NOTIFY=silent")

  [[ -x "$installomator" ]] || { log_error "Installomator not found at $installomator"; return 1; }

  if [[ ${#INSTALLOMATOR_APPS[@]} -eq 0 ]]; then
    log_info "INSTALLOMATOR_APPS is empty → nothing to install."
    return 0
  fi

  # Must run as root
  if [[ $EUID -ne 0 ]]; then
    log_info "Re-running Installomator installs as root…"
    sudo bash -c "$(declare -p INSTALLOMATOR_APPS; declare -f log_info log_error log_success installomator_install_labels); installomator_install_labels"
    return $?
  fi

  cd "$(dirname "$installomator")" || return 1

  log_info "Running Installomator labels: ${INSTALLOMATOR_APPS[*]}"
  for label in "${INSTALLOMATOR_APPS[@]}"; do
    log_info "Installing: $label"
    ./Installomator.sh "$label" "${default_flags[@]}" || { log_error "Install failed: $label"; return 1; }
    log_success "Installed: $label"
  done

  log_success "Installomator installs complete."
}

###############################################################################
#  Tart – install latest binary from GitHub (not via brew)
###############################################################################
tart_bootstrap() {
  local url="https://github.com/cirruslabs/tart/releases/latest/download/tart.tar.gz"
  local tmp_dir tarball install_dir tart_bin

  tmp_dir="$(mktemp -d)"
  tarball="$tmp_dir/tart.tar.gz"

  # Choose install dir
  install_dir="/usr/local/bin"
  [[ $(uname -m) == "arm64" && -d /opt/homebrew/bin ]] && install_dir="/opt/homebrew/bin"

  if command -v tart &>/dev/null; then
    log_info "tart found → updating to latest…"
  else
    log_info "tart not found → installing latest…"
  fi

  ( cd "$tmp_dir" && curl -LO "$url" ) || { log_error "Failed to download tart."; rm -rf "$tmp_dir"; return 1; }
  tar -xzf "$tarball" -C "$tmp_dir" || { log_error "Failed to extract tart."; rm -rf "$tmp_dir"; return 1; }

  tart_bin="$(find "$tmp_dir" -maxdepth 2 -type f -name tart 2>/dev/null | head -n 1 || true)"
  [[ -n "$tart_bin" ]] || { log_error "Could not locate tart binary."; rm -rf "$tmp_dir"; return 1; }
  chmod +x "$tart_bin"

  log_info "Installing tart → $install_dir/tart"
  if [[ -w "$install_dir" ]]; then
    install -m 0755 "$tart_bin" "$install_dir/tart"
  else
    sudo install -m 0755 "$tart_bin" "$install_dir/tart"
  fi

  rm -rf "$tmp_dir"
  command -v tart &>/dev/null || { log_error "tart install finished but tart not in PATH."; return 1; }
  log_success "tart installed → $(command -v tart)"
}

###############################################################################
#  Dock – configure Dock for the current console user using dockutil
###############################################################################
dock_setup() {
  local console_user user_home dockutil_bin
  console_user="$(stat -f%Su /dev/console)"
  user_home="$(dscl . -read /Users/"$console_user" NFSHomeDirectory 2>/dev/null | awk '{print $2}')"
  dockutil_bin="$(command -v dockutil 2>/dev/null || true)"

  [[ -n "$dockutil_bin" ]] || { log_error "dockutil not found in PATH."; return 1; }
  [[ -n "$console_user" && "$console_user" != "root" ]] || { log_error "No GUI user logged in; cannot set Dock."; return 1; }
  [[ -n "$user_home" && -d "$user_home" ]] || { log_error "Could not determine home directory for $console_user."; return 1; }

  if [[ ${#DOCK_APPS[@]} -eq 0 ]]; then
    log_info "DOCK_APPS empty → skipping Dock setup."
    return 0
  fi

  # Dock changes must run as the user, not root.
  log_info "Configuring Dock for user: $console_user"
  log_info "Clearing Dock…"
  sudo -u "$console_user" "$dockutil_bin" --remove all --no-restart "$user_home"

  local entry app_path app_name
  for entry in "${DOCK_APPS[@]}"; do
    app_path="${entry%%|*}"
    app_name="${entry#*|}"

    if [[ -d "$app_path" ]]; then
      log_info "Adding to Dock: $app_name"
      sudo -u "$console_user" "$dockutil_bin" --add "$app_path" --no-restart "$user_home"
    else
      log_warning "Missing app (skipped): $app_name → $app_path"
    fi
  done

  # Add Downloads stack (optional)
  sudo -u "$console_user" "$dockutil_bin" --add "$user_home/Downloads" --view grid --no-restart "$user_home"

  killall Dock >/dev/null 2>&1 || true
  log_success "Dock configured."
}

###############################################################################
#  Touch ID for sudo – enable pam_tid for sudo authentication
###############################################################################
sudo_touchid_bootstrap() {
  local pam_file="/etc/pam.d/sudo"
  local touchid_line="auth       sufficient     pam_tid.so"

  # Detect Touch ID PAM module (supports pam_tid.so, pam_tid.so.2, etc.)
  local tid_matches
  shopt -s nullglob
  tid_matches=(/usr/lib/pam/pam_tid.so*)
  shopt -u nullglob

  if [[ ${#tid_matches[@]} -eq 0 ]]; then
    log_warning "Touch ID PAM module not found → skipping Touch ID for sudo."
    return 0
  fi

  # Must run as root to edit /etc/pam.d/sudo
  if [[ $EUID -ne 0 ]]; then
    log_info "Enabling Touch ID for sudo (requires admin)…"
    sudo bash -c "$(declare -f log_info log_warning log_error sudo_touchid_bootstrap); sudo_touchid_bootstrap"
    return $?
  fi

  # Sanity check
  if [[ ! -f "$pam_file" ]]; then
    log_error "PAM file not found: $pam_file"
    return 1
  fi

  # If already enabled, no-op
  if grep -qE '^\s*auth\s+sufficient\s+pam_tid\.so\s*$' "$pam_file"; then
    log_info "Touch ID for sudo already enabled → nothing to do."
    return 0
  fi

  # Backup
  local backup tmp
  backup="${pam_file}.bak.$(date +%Y%m%d%H%M%S)"
  cp -p "$pam_file" "$backup"
  log_info "Backup created: $backup"

  log_info "Adding Touch ID auth line to sudo PAM config…"

  # Insert after leading comments/blank lines at top of file
  tmp="$(mktemp)"
  awk -v line="$touchid_line" '
    BEGIN { inserted=0 }
    {
      if (!inserted) {
        if ($0 ~ /^[[:space:]]*#/ || $0 ~ /^[[:space:]]*$/) { print $0; next }
        print line; inserted=1
      }
      print $0
    }
    END { if (!inserted) print line }
  ' "$pam_file" > "$tmp"

  cp "$tmp" "$pam_file"
  rm -f "$tmp"

  log_success "Touch ID for sudo enabled."
  log_info "Top of $pam_file now:"
  head -n 12 "$pam_file" | sed 's/^/  /'
}

###############################################################################
#  Oh My Zsh – install/update + link iCloud-managed .zshrc
###############################################################################
ohmyzsh_bootstrap() {
  local omz_dir="${ZSH:-$HOME/.oh-my-zsh}"
  local install_url="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
  local zshrc_icloud="$HOME/Library/Mobile Documents/com~apple~CloudDocs/Documents/profiles/.zshrc"

  if [[ ! -d "$omz_dir" ]]; then
    log_info "Oh My Zsh not found → installing…"
    RUNZSH=no CHSH=yes bash -c "$(curl -fsSL "$install_url")"
  else
    log_info "Oh My Zsh found → updating…"
    if command -v omz &>/dev/null; then
      omz update
    elif command -v git &>/dev/null; then
      git -C "$omz_dir" pull --rebase --autostash
    else
      log_warning "git not found → cannot update Oh My Zsh automatically."
    fi
  fi

  # Symlink iCloud .zshrc into $HOME
  if [[ -f "$zshrc_icloud" ]]; then
    ln -sf "$zshrc_icloud" "$HOME/.zshrc"
    log_success "Linked .zshrc → $zshrc_icloud"
  else
    log_warning "iCloud .zshrc not found → skipping symlink ($zshrc_icloud)"
  fi
}

###############################################################################
#  Main
###############################################################################
main() {
  welcome

  # Cache sudo auth early so subsequent sudo calls are smoother
  log_info "Checking sudo access…"
  sudo -v

  sudo_touchid_bootstrap
  configure_system
  brew_bootstrap
  install_brew_items
  install_mas_items

  installomator_bootstrap
  installomator_install_labels
  tart_bootstrap
  
  dock_setup
  ohmyzsh_bootstrap

  echo -e "\n${GREEN}${BOLD}✨  All done! Consider rebooting.${NC}"
}

main "$@"
