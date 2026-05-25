#!/usr/bin/env bash
# macos-defaults.sh — apply preferred macOS system settings via `defaults write`.
#
# Run by install.sh, or any time you want to re-apply.
#
# How to discover the right `defaults` keys for your own preferences:
#   1. Open System Settings, change the setting you care about
#   2. Run: defaults read > /tmp/before.txt
#   3. Change another setting
#   4. Run: defaults read > /tmp/after.txt
#   5. diff /tmp/before.txt /tmp/after.txt
# That diff shows the key/value that changed — copy it here.
#
# This file is a starting template. Customize for your preferences.

set -uo pipefail

echo "==> Applying macOS defaults"

# ---------------------------------------------------------------------------
# Keyboard
# ---------------------------------------------------------------------------
# Faster keyboard repeat
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15

# Disable press-and-hold for accented chars; re-enable key repeat in apps
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# ---------------------------------------------------------------------------
# Trackpad
# ---------------------------------------------------------------------------
# Tap to click
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults write -currentHost NSGlobalDomain com.apple.mouse.tapBehavior -int 1
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# ---------------------------------------------------------------------------
# Finder
# ---------------------------------------------------------------------------
# Show file extensions always
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Show hidden files
defaults write com.apple.finder AppleShowAllFiles -bool true

# Show path bar and status bar
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true

# Search current folder by default (not the whole Mac)
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

# Don't write .DS_Store on network/USB volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# Disable warning when changing file extension
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# ---------------------------------------------------------------------------
# Dock
# ---------------------------------------------------------------------------
# Auto-hide, fast
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock autohide-time-modifier -float 0.4

# Minimize windows into their app icon
defaults write com.apple.dock minimize-to-application -bool true

# Don't show recent apps
defaults write com.apple.dock show-recents -bool false

# ---------------------------------------------------------------------------
# Screenshots
# ---------------------------------------------------------------------------
# Save to ~/Pictures/Screenshots/ (create if missing)
mkdir -p "$HOME/Pictures/Screenshots"
defaults write com.apple.screencapture location -string "$HOME/Pictures/Screenshots"
defaults write com.apple.screencapture type -string "png"
defaults write com.apple.screencapture disable-shadow -bool true

# ---------------------------------------------------------------------------
# Misc
# ---------------------------------------------------------------------------
# Expand save panel by default
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true

# Expand print panel by default
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true

# Save to disk (not iCloud) by default
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

# ---------------------------------------------------------------------------
# Restart affected apps
# ---------------------------------------------------------------------------
for app in "Finder" "Dock" "SystemUIServer"; do
    killall "$app" >/dev/null 2>&1 || true
done

echo "    macOS defaults applied. Some settings require logout to take full effect."
