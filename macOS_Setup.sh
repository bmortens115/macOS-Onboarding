#!/usr/bin/env bash
###############################################################################
#  Mac Bootstrap – Preferences, Homebrew, MAS apps, Installomator, ohmyzsh
#  Works with the stock /bin/bash 3.2 on macOS
#  (c) 2026 Mort • MIT License
###############################################################################

###############################################################################
#  Colours / log helpers
###############################################################################
GREEN=$'\033[0;32m'; BLUE=$'\033[0;34m'
RED=$'\033[0;31m';   YELLOW=$'\033[1;33m'; NC=$'\033[0m'; BOLD=$'\033[1m'

log_info()    { printf '%sℹ️  %s%s\n'  "$BLUE"  "$1" "$NC"; }
log_success() { printf '%s✅ %s%s\n'  "$GREEN" "$1" "$NC"; }
log_warning() { printf '%s⚠️  %s%s\n' "$YELLOW" "$1" "$NC"; }
log_error()   { printf '%s❌ %s%s\n'  "$RED"   "$1" "$NC"; }

###############################################################################
#  Robust shell behaviour & cleanup
###############################################################################
set -Eeuo pipefail

cleanup() {
  tput cnorm || true
}
trap cleanup EXIT
trap 'log_error "Interrupted"; exit 1' INT HUP TERM
trap 'log_error "Line $LINENO (exit $?) – $BASH_COMMAND"; exit 1' ERR

###############################################################################
#  Progress-bar helpers
###############################################################################
BAR_W=30
show_bar() {                   # no trailing newline
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
#  Welcome
###############################################################################
welcome() {
  echo "======================================================"
  log_info   "🎯  Mac Setup Script – Preferences & Apps"
  echo "======================================================"
  log_warning "You'll be prompted for your password when needed."
  echo "1. Sign in to the Mac App Store"
  echo "2. Review this script"
  echo "3. Ensure a stable internet connection"
  echo
  read -p "Press RETURN to continue or CTRL-C to quit…"
}

###############################################################################
#  Preferences (abridged)
###############################################################################
configure_system() {
  # https://macos-defaults.com
  log_info "Configuring System Preferences…"
  ###
  # Dock
  ###
  defaults write com.apple.dock orientation -string bottom            # Sets Dock position to the bottom of the screen
  defaults write com.apple.dock autohide -bool true                  # Automatically hides/shows the Dock
  defaults write com.apple.dock show-recents -bool false             # Disables "Show recent applications" in the Dock
  defaults write com.apple.dock mru-spaces -bool false               # Prevents macOS from automatically reordering Spaces based on most recent use
  
  ###
  # Finder
  ###
  defaults write com.apple.finder ShowPathbar -bool true              # Shows the path bar at the bottom of Finder windows
  defaults write com.apple.finder ShowStatusBar -bool true            # Shows the status bar at the bottom of Finder windows
  defaults write com.apple.finder FXPreferredGroupBy -string Kind     # Groups Finder items by Kind by default
  defaults write com.apple.finder FXRemoveOldTrashItems -bool true    # Automatically removes old items from Trash (Finder-managed cleanup)
  defaults write com.apple.finder QLEnableTextSelection -bool true    # Enables text selection in Quick Look
  defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false # Disables the warning when changing a file extension
  defaults write com.apple.finder FXPreferredViewStyle -string Clmv   # Sets Finder default view style to Column View
  
  ###
  # Global (System-wide)
  ###
  defaults write NSGlobalDomain AppleShowAllExtensions -bool true     # Shows all file extensions in Finder and across macOS
  defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true # Expands the Save dialog by default
  defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true   # Expands the Print dialog by default (legacy key)
  defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true  # Expands the Print dialog by default (modern key)
  defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false # Disables smart quotes (helpful for coding)
  defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false  # Disables smart dashes (helpful for coding)
  
  ###
  # Time Machine
  ###
  defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true # Prevents Time Machine from prompting to use new disks for backup
  
  ###
  # Filesystem / Desktop Services
  ###
  defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true # Prevents .DS_Store creation on network volumes

  # https://dev.to/darrinndeal/setting-mac-hot-corners-in-the-terminal-3de

  killall Dock Finder SystemUIServer 2>/dev/null || true
  log_success "System Preferences applied"
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
    brew update; brew upgrade; brew cleanup
  fi
  [[ $(uname -m) == arm64 ]] &&
    { eval "$(/opt/homebrew/bin/brew shellenv)";
      grep -q "/opt/homebrew" ~/.zprofile 2>/dev/null ||
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile; }
}

###############################################################################
#  Lists
###############################################################################
APPS=(
  # Casks
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

  # Formula
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
  "tart:formula"
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
  "jamfmigrator"
  "Prune"
  "jamfpppcutility"
)

DOCK_APPS=(
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
#  Portable helper – fill array with command output (no mapfile needed)
###############################################################################
cmd_to_array() {                                 # $1 = array-name  $2 = cmd…
  local _line
  eval "$1=()"
  while IFS= read -r _line; do
    eval "$1+=(\"\$_line\")"
  done < <(eval "$2")
}

###############################################################################
#  Install Brew items (skip already installed)
###############################################################################
install_brew_items() {
  INST_FORMULAE=()
  INST_CASKS=()
  cmd_to_array INST_FORMULAE "brew list --formula"
  cmd_to_array INST_CASKS    "brew list --cask 2>/dev/null || true"

  local total=${#APPS[@]} current=0 kind name pct
  show_bar 0 "starting…"; newline_below_bar
  for entry in "${APPS[@]}"; do
    current=$((current+1)); pct=$(( current * 100 / total ))
    IFS=':' read -r name kind flag <<< "$entry"

    if [[ $kind == cask ]] && [[ " ${INST_CASKS[@]-} " == *" $name "* ]] ||
       [[ $kind == formula ]] && [[ " ${INST_FORMULAE[@]-} " == *" $name "* ]]; then
      show_bar "$pct" "✓ already installed $name"; newline_below_bar; continue
    fi

    show_bar "$pct" "↓ $name"; newline_below_bar
    if [[ $kind == cask ]]; then
      if [[ $flag == "no-quarantine" ]]; then
        brew install --cask --no-quarantine "$name"
      else
        brew install --cask "$name"
      fi
    else
      brew install "$name"
    fi
    show_bar "$pct" "✔︎ $name"; newline_below_bar
  done
  brew upgrade; brew cleanup
}

###############################################################################
#  Install MAS items – tolerant of the "command not supported" issue
###############################################################################
install_mas_items() {
  # make sure mas exists
  command -v mas >/dev/null || brew install mas

  # try to capture the list of IDs already on the machine
  if mas list 1>/tmp/mas_installed 2>/dev/null; then
    # success → build INST_IDS array from the tmp file
    INST_IDS=($(awk '{print $1}' /tmp/mas_installed))
  else
    # macOS 14+ (or similar) where mas can't read the account
    INST_IDS=()   # pretend nothing is installed
    log_warning "Cannot read App Store account status; installs may prompt or fail."
  fi
  rm -f /tmp/mas_installed

  local total=${#MAS_APPS[@]} current=0 id name pct
  show_bar 0 "starting…"; newline_below_bar
  for entry in "${MAS_APPS[@]}"; do
    current=$((current+1)); pct=$(( current * 100 / total ))
    id=${entry%%:*}; name=${entry#*:}

    if [[ " ${INST_IDS[@]-} " == *" $id "* ]]; then
      show_bar "$pct" "✓ already installed $name"; newline_below_bar; continue
    fi

    show_bar "$pct" "↓ $name"; newline_below_bar
    if mas install "$id"; then
      show_bar "$pct" "✔︎ $name"; newline_below_bar
    else
      log_warning "failed: $name"
    fi
  done

  # attempt a bulk upgrade; ignore errors
  mas upgrade || true
}

###############################################################################
#  Installomator installs - for items that are not in brew
###############################################################################

installomator_bootstrap() {
  local installomator_path="/usr/local/Installomator/Installomator.sh"
  local pkg_url="https://github.com/Installomator/Installomator/releases/download/v10.8/Installomator-10.8.pkg"
  local tmp_pkg="/tmp/Installomator.pkg"
  
  if [[ ! -x "$installomator_path" ]]; then
    log_info "Installomator not found → downloading & installing…"
  else
    log_info "Installomator found → downloading & upgrading…"
  fi
  
  # Download the pkg
  curl -fsSL "$pkg_url" -o "$tmp_pkg" || {
    log_info "Failed to download Installomator pkg."
    return 1
  }
  
  # Install the pkg
  sudo installer -pkg "$tmp_pkg" -target / || {
    log_info "Installomator pkg install failed."
    rm -f "$tmp_pkg"
    return 1
  }
  
  # Cleanup
  rm -f "$tmp_pkg"
  
  # Verify install
  if [[ -x "$installomator_path" ]]; then
    log_info "Installomator installed successfully → $installomator_path"
  else
    log_info "Installomator install completed, but Installomator.sh was not found at expected path."
    return 1
  fi
}

installomator_install_labels() {
  local installomator="/usr/local/Installomator/Installomator.sh"
  local default_flags=("DEBUG=0" "NOTIFY=silent")
  
  # Ensure Installomator exists
  if [[ ! -x "$installomator" ]]; then
    log_info "Installomator not found at $installomator → aborting."
    return 1
  fi
  
  # Ensure INSTALLOMATOR_APPS exists and has values
  if [[ ${#INSTALLOMATOR_APPS[@]} -eq 0 ]]; then
    log_info "INSTALLOMATOR_APPS is empty or not defined → nothing to install."
    return 0
  fi
  
  # Ensure we are root (Installomator must run as root)
  if [[ $EUID -ne 0 ]]; then
    log_info "Not running as root → re-running with sudo…"
    sudo bash -c "$(declare -p INSTALLOMATOR_APPS; declare -f log_info installomator_install_labels); installomator_install_labels"
    return $?
  fi
  
  # Move to Installomator directory so './Installomator.sh' matches your desired invocation
  cd "$(dirname "$installomator")" || return 1
  
  log_info "Running Installomator as root with default flags: ${default_flags[*]}"
  log_info "Apps to install: ${INSTALLOMATOR_APPS[*]}"
  
  for label in "${INSTALLOMATOR_APPS[@]}"; do
    log_info "Installing: $label"
    ./Installomator.sh "$label" "${default_flags[@]}" || {
      log_info "❌ Install failed for label: $label"
      return 1
    }
    log_info "✅ Installed: $label"
  done
  
  log_info "All Installomator installs completed successfully."
}

###############################################################################
#  Setting the Dock
###############################################################################

dock_setup() {
  local console_user
  console_user="$(stat -f%Su /dev/console)"
  
  local user_home
  user_home="$(dscl . -read /Users/"$console_user" NFSHomeDirectory 2>/dev/null | awk '{print $2}')"
  
  local dockutil_bin
  dockutil_bin="$(command -v dockutil 2>/dev/null || true)"
  
  # Sanity checks
  if [[ -z "$dockutil_bin" ]]; then
    log_info "dockutil not found in PATH → aborting."
    return 1
  fi
  if [[ -z "$console_user" || "$console_user" == "root" ]]; then
    log_info "No GUI user logged in → cannot set Dock."
    return 1
  fi
  if [[ -z "$user_home" || ! -d "$user_home" ]]; then
    log_info "Could not determine home directory for $console_user → aborting."
    return 1
  fi
  if [[ ${#DOCK_APPS[@]} -eq 0 ]]; then
    log_info "DOCK_APPS is empty or not defined → nothing to do."
    return 0
  fi
  
  # If the function is re-run with sudo, we must preserve DOCK_APPS
  if [[ $EUID -ne 0 ]]; then
    log_info "Not running as root → re-running with sudo…"
    sudo bash -c "$(declare -p DOCK_APPS; declare -f log_info dock_bootstrap_from_list); dock_bootstrap_from_list"
    return $?
  fi
  
  log_info "Configuring Dock for user: $console_user"
  log_info "Clearing existing Dock items…"
  sudo -u "$console_user" "$dockutil_bin" --remove all --no-restart "$user_home"
  
  for entry in "${DOCK_APPS[@]}"; do
    local app_path="${entry%%|*}"
    local app_name="${entry#*|}"
    
    if [[ -d "$app_path" ]]; then
      log_info "Adding: $app_name"
      sudo -u "$console_user" "$dockutil_bin" --add "$app_path" --no-restart "$user_home"
    else
      log_info "⚠️ Skipping (not found): $app_name → $app_path"
    fi
  done

  sudo -u "$console_user" "$dockutil_bin" --add "$user_home"/Downloads --view grid --no-restart "$user_home"
  
  log_info "Restarting Dock to apply changes…"
  killall Dock >/dev/null 2>&1 || true
  
  log_info "Dock configured successfully."
}

###############################################################################
#  Enabling touchID for sudo
###############################################################################

sudo_touchid_bootstrap() {
  local pam_file="/etc/pam.d/sudo"
  local touchid_line="auth       sufficient     pam_tid.so"
  
  # Must run as root (self-elevate)
  if [[ $EUID -ne 0 ]]; then
    log_info "Not running as root → re-running with sudo…"
    sudo bash -c "$(declare -f log_info sudo_touchid_bootstrap); sudo_touchid_bootstrap"
    return $?
  fi
  
  # Sanity check
  if [[ ! -f "$pam_file" ]]; then
    log_info "ERROR: $pam_file not found → aborting."
    return 1
  fi
  
  # If already present, no-op
  if grep -qE '^\s*auth\s+sufficient\s+pam_tid\.so\s*$' "$pam_file"; then
    log_info "Touch ID sudo PAM already enabled → nothing to do."
    return 0
  fi
  
  # Backup
  local backup="${pam_file}.bak.$(date +%Y%m%d%H%M%S)"
  cp -p "$pam_file" "$backup"
  log_info "Backup created: $backup"
  
  log_info "Enabling Touch ID for sudo…"
  
  # Insert line after any leading comments/blank lines at top of file
  local tmp
  tmp="$(mktemp)"
  
  awk -v line="$touchid_line" '
    BEGIN { inserted=0 }
    {
      if (!inserted) {
        if ($0 ~ /^[[:space:]]*#/ || $0 ~ /^[[:space:]]*$/) {
          print $0
          next
        } else {
          print line
          inserted=1
        }
      }
      print $0
    }
    END {
      if (!inserted) print line
    }
  ' "$pam_file" > "$tmp"
  
  # Replace the original file
  cp "$tmp" "$pam_file"
  rm -f "$tmp"
  
  log_info "Touch ID line added successfully."
  
  # Show top of file for quick verification
  log_info "Top of $pam_file now:"
  head -n 12 "$pam_file" | sed 's/^/  /'
  
}


###############################################################################
#  Z-shell config (same as previous)
###############################################################################
ohmyzsh_bootstrap() {
  local omz_dir="${ZSH:-$HOME/.oh-my-zsh}"
  local install_url="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
  
  if [[ ! -d "$omz_dir" ]]; then
    log_info "Oh My Zsh not found → installing…"
    
    # Install without launching a new zsh shell afterwards
    RUNZSH=no CHSH=yes bash -c "$(curl -fsSL "$install_url")"
    
  else
    log_info "Oh My Zsh found → updating…"
    
    # Update OMZ (works if installed normally)
    if command -v omz &>/dev/null; then
      omz update
    else
      # Fallback: update via git directly
      if command -v git &>/dev/null; then
        git -C "$omz_dir" pull --rebase --autostash
      else
        log_info "git not found → cannot update Oh My Zsh automatically."
      fi
    fi
  fi
  
  # create a sym link from iCloud zshrc to home folder path
  ln -sf "$HOME/Library/Mobile Documents/com~apple~CloudDocs/Documents/profiles/.zshrc" "$HOME/.zshrc"
  source "$HOME/.zshrc"
}

###############################################################################
#  Main
###############################################################################
main() {
  welcome
  newline_below_bar
  brew_bootstrap
  newline_below_bar
  configure_system
  newline_below_bar
  log_info "Installing Homebrew apps…"; newline_below_bar
  install_brew_items
  newline_below_bar
  log_info "Installing Mac App Store apps…"; newline_below_bar
  install_mas_items
  newline_below_bar
  log_info "Installing Installomator and installing labels and setting up the dock": newline_below_bar
  installomator_bootstrap
  installomator_install_labels
  dock_setup
  log_info "Settign up TouchID for sudo and ohmyzsh": newline_below_bar
  sudo_touchid_bootstrap
  ohmyzsh_bootstrap
  echo -e "\n${GREEN}${BOLD}✨  All done! Consider rebooting.${NC}"
}

main "$@"
