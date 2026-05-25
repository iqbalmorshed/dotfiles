#!/usr/bin/env bash
# inventory.sh — capture everything needed to recreate this Mac's setup.
#
# Run BEFORE the factory reset. Output goes to OUTPUT_DIR (default:
# ~/personal-handoff/inventory). Copy the entire output directory to your
# backup drive — it's the input to reinstall.sh on the new Mac.
#
# Usage:
#   ./inventory.sh                    # default: ~/personal-handoff/inventory
#   ./inventory.sh /path/to/output    # custom location
#
# Safe to run multiple times. Existing files in OUTPUT_DIR are overwritten.

set -uo pipefail  # NOTE: no -e — we want best-effort capture, not abort-on-first-error

OUTPUT_DIR="${1:-$HOME/personal-handoff/inventory}"
mkdir -p "$OUTPUT_DIR"

log() { printf '\n==> %s\n' "$1"; }
note() { printf '    %s\n' "$1"; }

log "Inventory output: $OUTPUT_DIR"

# ---------------------------------------------------------------------------
# 1. macOS and hardware info
# ---------------------------------------------------------------------------
log "macOS and hardware"
sw_vers                                          > "$OUTPUT_DIR/macos-version.txt" 2>/dev/null
system_profiler SPHardwareDataType               > "$OUTPUT_DIR/hardware.txt"      2>/dev/null
uname -a                                         > "$OUTPUT_DIR/uname.txt"         2>/dev/null

# ---------------------------------------------------------------------------
# 2. Installed apps (GUI applications)
# ---------------------------------------------------------------------------
log "Installed applications"
{
    ls -1 /Applications 2>/dev/null
} | grep -E '\.app$' | sed 's/\.app$//' | sort > "$OUTPUT_DIR/apps-system.txt"

{
    ls -1 "$HOME/Applications" 2>/dev/null
} | grep -E '\.app$' | sed 's/\.app$//' | sort > "$OUTPUT_DIR/apps-user.txt"

# Setapp / Parallels-installed apps live elsewhere; include for completeness
ls -1 "/Applications/Setapp" 2>/dev/null | grep -E '\.app$' | sed 's/\.app$//' | sort \
    > "$OUTPUT_DIR/apps-setapp.txt"

# ---------------------------------------------------------------------------
# 3. Homebrew — formulae, casks, and a Brewfile dump
# ---------------------------------------------------------------------------
if command -v brew >/dev/null 2>&1; then
    log "Homebrew"
    brew bundle dump --file="$OUTPUT_DIR/Brewfile" --force
    brew leaves                                  > "$OUTPUT_DIR/brew-leaves.txt"
    brew list --formula                          > "$OUTPUT_DIR/brew-formulae.txt"
    brew list --cask                             > "$OUTPUT_DIR/brew-casks.txt"
    brew tap                                     > "$OUTPUT_DIR/brew-taps.txt"
    brew --version                               > "$OUTPUT_DIR/brew-version.txt"
    note "Review Brewfile before restoring — it may contain work-only tools."
else
    note "Homebrew not installed; skipping."
fi

# ---------------------------------------------------------------------------
# 4. Mac App Store apps (requires mas-cli: brew install mas)
# ---------------------------------------------------------------------------
if command -v mas >/dev/null 2>&1; then
    log "Mac App Store apps"
    mas list > "$OUTPUT_DIR/mas-apps.txt"
else
    note "mas-cli not installed (brew install mas). Skipping App Store list."
fi

# ---------------------------------------------------------------------------
# 5. Language ecosystems — globally installed tools
# ---------------------------------------------------------------------------
log "Language ecosystem packages"
command -v npm   >/dev/null 2>&1 && npm list -g --depth=0 > "$OUTPUT_DIR/npm-global.txt"      2>/dev/null
command -v pnpm  >/dev/null 2>&1 && pnpm list -g          > "$OUTPUT_DIR/pnpm-global.txt"     2>/dev/null
command -v yarn  >/dev/null 2>&1 && yarn global list      > "$OUTPUT_DIR/yarn-global.txt"     2>/dev/null
command -v pip   >/dev/null 2>&1 && pip list              > "$OUTPUT_DIR/pip-packages.txt"    2>/dev/null
command -v pip3  >/dev/null 2>&1 && pip3 list             > "$OUTPUT_DIR/pip3-packages.txt"   2>/dev/null
command -v pipx  >/dev/null 2>&1 && pipx list             > "$OUTPUT_DIR/pipx-packages.txt"   2>/dev/null
command -v gem   >/dev/null 2>&1 && gem list              > "$OUTPUT_DIR/gem-packages.txt"    2>/dev/null
command -v cargo >/dev/null 2>&1 && cargo install --list  > "$OUTPUT_DIR/cargo-packages.txt"  2>/dev/null
[ -d "$HOME/go/bin" ] && ls -1 "$HOME/go/bin" > "$OUTPUT_DIR/go-binaries.txt" 2>/dev/null

# ---------------------------------------------------------------------------
# 6. Editor extensions
# ---------------------------------------------------------------------------
if command -v code >/dev/null 2>&1; then
    log "VS Code extensions"
    code --list-extensions > "$OUTPUT_DIR/vscode-extensions.txt"
fi
if command -v cursor >/dev/null 2>&1; then
    log "Cursor extensions"
    cursor --list-extensions > "$OUTPUT_DIR/cursor-extensions.txt" 2>/dev/null
fi

# ---------------------------------------------------------------------------
# 7. Shell config (raw — REVIEW for work hostnames/emails before restoring)
# ---------------------------------------------------------------------------
log "Shell config (unsanitized — review before restoring)"
echo "$SHELL" > "$OUTPUT_DIR/login-shell.txt"
for f in .zshrc .zprofile .zshenv .bashrc .bash_profile .profile .inputrc; do
    [ -f "$HOME/$f" ] && cp "$HOME/$f" "$OUTPUT_DIR/${f#.}.bak"
done

# ---------------------------------------------------------------------------
# 8. Git & SSH — captured but flagged for review
# ---------------------------------------------------------------------------
log "Git/SSH config (REVIEW — likely contains work entries)"
[ -f "$HOME/.gitconfig" ]      && cp "$HOME/.gitconfig"      "$OUTPUT_DIR/gitconfig.bak"
[ -f "$HOME/.gitignore_global" ] && cp "$HOME/.gitignore_global" "$OUTPUT_DIR/gitignore_global.bak"
[ -f "$HOME/.ssh/config" ]     && cp "$HOME/.ssh/config"     "$OUTPUT_DIR/ssh-config.bak"
# Intentionally NOT copying ~/.ssh/id_* private keys — regenerate fresh on new Mac.

# ---------------------------------------------------------------------------
# 9. Critical app configs — Keyboard Maestro, Karabiner, Alfred, Raycast
# ---------------------------------------------------------------------------
log "App config snapshots"
CONFIGS_DIR="$OUTPUT_DIR/configs"
mkdir -p "$CONFIGS_DIR"

# --- Karabiner-Elements ---
if [ -d "$HOME/.config/karabiner" ]; then
    note "Karabiner-Elements"
    cp -R "$HOME/.config/karabiner" "$CONFIGS_DIR/karabiner"
fi

# --- Keyboard Maestro ---
# Preferred: in-app export to .kmlibrary (we can't trigger that from bash).
# Fallback: copy Application Support directory + preferences plist.
KM_DIR="$HOME/Library/Application Support/Keyboard Maestro"
if [ -d "$KM_DIR" ]; then
    note "Keyboard Maestro (also use File → Export Macros in the app for canonical .kmlibrary)"
    mkdir -p "$CONFIGS_DIR/KeyboardMaestro"
    cp -R "$KM_DIR" "$CONFIGS_DIR/KeyboardMaestro/AppSupport" 2>/dev/null
fi
for plist in com.stairways.keyboardmaestro.editor.plist com.stairways.keyboardmaestro.engine.plist; do
    [ -f "$HOME/Library/Preferences/$plist" ] && cp "$HOME/Library/Preferences/$plist" "$CONFIGS_DIR/KeyboardMaestro/"
done

# --- Alfred ---
ALFRED_DIR="$HOME/Library/Application Support/Alfred"
if [ -d "$ALFRED_DIR" ]; then
    note "Alfred"
    mkdir -p "$CONFIGS_DIR/Alfred"
    cp -R "$ALFRED_DIR" "$CONFIGS_DIR/Alfred/AppSupport" 2>/dev/null
fi
for plist in com.runningwithcrayons.Alfred.plist com.runningwithcrayons.Alfred-Preferences.plist; do
    [ -f "$HOME/Library/Preferences/$plist" ] && cp "$HOME/Library/Preferences/$plist" "$CONFIGS_DIR/Alfred/"
done

# --- Raycast ---
# Raycast is sandboxed. Best path is Raycast Cloud Sync (Settings → General).
# This captures what's accessible; some files may be permission-protected.
RAYCAST_DIR="$HOME/Library/Application Support/com.raycast.macos"
if [ -d "$RAYCAST_DIR" ]; then
    note "Raycast (prefer Cloud Sync in app — Settings → General → Cloud Sync)"
    mkdir -p "$CONFIGS_DIR/Raycast"
    cp -R "$RAYCAST_DIR" "$CONFIGS_DIR/Raycast/AppSupport" 2>/dev/null || \
        note "  Some Raycast files protected — cloud sync is the right path."
fi

# ---------------------------------------------------------------------------
# 10. Launch agents (user-level only — system-level are macOS internals)
# ---------------------------------------------------------------------------
log "User launch agents"
if [ -d "$HOME/Library/LaunchAgents" ]; then
    ls -1 "$HOME/Library/LaunchAgents" > "$OUTPUT_DIR/launch-agents-list.txt"
    mkdir -p "$CONFIGS_DIR/LaunchAgents"
    cp "$HOME/Library/LaunchAgents/"*.plist "$CONFIGS_DIR/LaunchAgents/" 2>/dev/null || true
fi

# ---------------------------------------------------------------------------
# 11. Dock layout, default browser, login items
# ---------------------------------------------------------------------------
log "Dock & system preferences snapshots"
defaults read com.apple.dock persistent-apps > "$OUTPUT_DIR/dock-apps.txt"      2>/dev/null
defaults read com.apple.dock persistent-others > "$OUTPUT_DIR/dock-others.txt"  2>/dev/null
defaults read com.apple.LaunchServices/com.apple.launchservices.secure \
    > "$OUTPUT_DIR/launch-services.txt" 2>/dev/null

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------
log "Inventory complete: $OUTPUT_DIR"
echo
echo "Files to REVIEW for work-specific content before restoring:"
echo "  - zshrc.bak / bashrc.bak / zprofile.bak"
echo "  - gitconfig.bak (user.email — make sure it's personal)"
echo "  - ssh-config.bak (almost certainly has work hostnames)"
echo "  - Brewfile (may include work-only tools)"
echo "  - apps-system.txt / apps-user.txt"
echo
echo "Next: copy $OUTPUT_DIR to your backup drive."
