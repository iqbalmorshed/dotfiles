#!/usr/bin/env bash
# install.sh — bootstrap a fresh Mac from this dotfiles repo.
#
# Intended flow on a brand-new (or freshly reset) Mac:
#   1. Sign in with personal Apple ID
#   2. xcode-select --install     (gets you git)
#   3. git clone <this repo> ~/.dotfiles
#   4. cd ~/.dotfiles && ./install.sh
#
# Optional: if you also have an inventory directory from inventory.sh,
# pass it as an argument to get VS Code extension restore + cross-check:
#   ./install.sh --inventory ~/personal-handoff/inventory
#
# What this script does:
#   - Confirms macOS, detects Apple Silicon vs Intel
#   - Installs Xcode Command Line Tools (if missing)
#   - Installs Homebrew (if missing) and runs `brew bundle` against repo's Brewfile
#   - Symlinks dotfiles into $HOME (backing up anything it overwrites)
#   - Initializes git submodules (zsh plugins)
#   - VS Code extensions are installed by `brew bundle` itself (Brewfile has
#     `vscode "extension.id"` lines), so no separate step is needed
#   - Optionally applies macos-defaults.sh
#   - Generates a fresh personal SSH key
#   - Prints a checklist for everything that can't be automated
#
# Safe to re-run. Idempotent.

set -uo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOME_DIR="$HOME"
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
INVENTORY_DIR=""

# Parse args
while [[ $# -gt 0 ]]; do
    case "$1" in
        --inventory)
            INVENTORY_DIR="$2"; shift 2 ;;
        --help|-h)
            sed -n '2,30p' "$0"; exit 0 ;;
        *)
            echo "Unknown arg: $1"; exit 1 ;;
    esac
done

log()  { printf '\n==> %s\n' "$1"; }
note() { printf '    %s\n' "$1"; }
err()  { printf '\nERROR: %s\n' "$1" >&2; }

# ---------------------------------------------------------------------------
# 0. Sanity
# ---------------------------------------------------------------------------
[[ "$(uname)" != "Darwin" ]] && { err "macOS only."; exit 1; }
log "Bootstrapping from: $REPO_DIR"
log "Backups (if anything is overwritten): $BACKUP_DIR"
[ -n "$INVENTORY_DIR" ] && log "Inventory: $INVENTORY_DIR"

# ---------------------------------------------------------------------------
# 1. Xcode Command Line Tools
# ---------------------------------------------------------------------------
if ! xcode-select -p >/dev/null 2>&1; then
    log "Installing Xcode Command Line Tools (GUI dialog will appear)"
    xcode-select --install
    note "Press ENTER once the installer completes…"
    read -r
fi

# ---------------------------------------------------------------------------
# 2. Homebrew + Brewfile
# ---------------------------------------------------------------------------
if ! command -v brew >/dev/null 2>&1; then
    log "Installing Homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
if   [ -x /opt/homebrew/bin/brew ]; then eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ];    then eval "$(/usr/local/bin/brew shellenv)"
fi
command -v brew >/dev/null 2>&1 || { err "brew not found on PATH after install."; exit 1; }

if [ -f "$REPO_DIR/Brewfile" ]; then
    log "Running brew bundle from repo's Brewfile (slow step — 20-40 min)"
    brew bundle --file="$REPO_DIR/Brewfile" || \
        note "brew bundle finished with non-zero exit. Review output."
else
    note "No Brewfile in repo. Skipping."
fi

# ---------------------------------------------------------------------------
# 2b. npm globals (parsed from Brewfile — `brew bundle` doesn't natively
#     understand the `npm "..."` directive, so we handle it ourselves)
# ---------------------------------------------------------------------------
if [ -f "$REPO_DIR/Brewfile" ] && grep -q '^npm ' "$REPO_DIR/Brewfile"; then
    log "Installing npm globals declared in Brewfile"
    # nvm-based environments need sourcing before npm is on PATH
    if [ -s "$HOME/.nvm/nvm.sh" ]; then
        export NVM_DIR="$HOME/.nvm"
        # shellcheck source=/dev/null
        \. "$NVM_DIR/nvm.sh"
    fi
    if command -v npm >/dev/null 2>&1; then
        grep '^npm ' "$REPO_DIR/Brewfile" | sed -E 's/^npm "([^"]+)".*/\1/' | while read -r pkg; do
            [ -n "$pkg" ] && npm install -g "$pkg" || note "npm install -g $pkg failed"
        done
    else
        note "npm not on PATH — install Node first, then re-run: grep '^npm ' Brewfile | sed -E 's/^npm \"([^\"]+)\".*/\\1/' | xargs -n1 npm install -g"
    fi
fi

# ---------------------------------------------------------------------------
# 3. Symlink dotfiles into $HOME
# ---------------------------------------------------------------------------
log "Linking dotfiles into \$HOME"

TOP_LEVEL_DOTFILES=(
    .zshrc
    .zprofile
    .zshenv
    .p10k.zsh
    .gitconfig
    .gitignore_global
    .tmux.conf
    .vimrc
    .editorconfig
)
CONFIG_DIRS=()
# Note: Karabiner is intentionally NOT in CONFIG_DIRS because karabiner.edn
# is the source of truth (compiled by Goku into karabiner.json). See below.
# Note: yabai + skhd removed — no longer used.

mkdir -p "$HOME/.config"

for f in "${TOP_LEVEL_DOTFILES[@]}"; do
    src="$REPO_DIR/$f"
    dst="$HOME/$f"
    if [ -e "$src" ]; then
        if [ -e "$dst" ] && [ ! -L "$dst" ]; then
            mkdir -p "$BACKUP_DIR"
            mv "$dst" "$BACKUP_DIR/"
            note "Backed up existing $dst → $BACKUP_DIR/"
        fi
        ln -sfn "$src" "$dst"
        note "Linked $f"
    fi
done

for d in "${CONFIG_DIRS[@]}"; do
    src="$REPO_DIR/.config/$d"
    dst="$HOME/.config/$d"
    if [ -d "$src" ]; then
        if [ -e "$dst" ] && [ ! -L "$dst" ]; then
            mkdir -p "$BACKUP_DIR/.config"
            mv "$dst" "$BACKUP_DIR/.config/"
            note "Backed up existing $dst → $BACKUP_DIR/.config/"
        fi
        ln -sfn "$src" "$dst"
        note "Linked .config/$d"
    fi
done

# Karabiner via Goku: source-of-truth is karabiner.edn; Goku compiles it
# into ~/.config/karabiner/karabiner.json (which is gitignored).
if [ -f "$REPO_DIR/.config/karabiner.edn" ]; then
    ln -sfn "$REPO_DIR/.config/karabiner.edn" "$HOME/.config/karabiner.edn"
    note "Linked .config/karabiner.edn"

    # Make sure the karabiner config dir exists so Goku can write into it
    mkdir -p "$HOME/.config/karabiner"

    # Run Goku once to compile karabiner.edn → karabiner.json
    if command -v goku >/dev/null 2>&1; then
        log "Compiling Karabiner config with Goku"
        goku || note "goku failed — check .config/karabiner.edn for syntax errors"
    else
        note "goku not found yet — install with 'brew install yqrashawn/goku/goku' then run 'goku'"
    fi
fi

# VS Code user settings (settings.json + keybindings.json live at repo root in vscode/)
if [ -d "$REPO_DIR/vscode" ]; then
    VSCODE_USER_DIR="$HOME/Library/Application Support/Code/User"
    mkdir -p "$VSCODE_USER_DIR"
    for f in settings.json keybindings.json; do
        src="$REPO_DIR/vscode/$f"
        dst="$VSCODE_USER_DIR/$f"
        if [ -f "$src" ]; then
            if [ -e "$dst" ] && [ ! -L "$dst" ]; then
                mkdir -p "$BACKUP_DIR/vscode"
                mv "$dst" "$BACKUP_DIR/vscode/"
            fi
            ln -sfn "$src" "$dst"
            note "Linked vscode/$f → $dst"
        fi
    done
fi

# ---------------------------------------------------------------------------
# 4. Submodules (zsh plugins, themes)
# ---------------------------------------------------------------------------
if [ -f "$REPO_DIR/.gitmodules" ]; then
    log "Initializing git submodules"
    (cd "$REPO_DIR" && git submodule update --init --recursive)
fi

if [[ "$SHELL" != *"/zsh" ]]; then
    log "Switching login shell to zsh"
    sudo chsh -s "$(which zsh)" "$USER" || note "chsh failed — switch manually later."
fi

# ---------------------------------------------------------------------------
# 5. VS Code extensions
# ---------------------------------------------------------------------------
# Note: extensions are installed by brew bundle itself if Brewfile has
# `vscode "ext.id"` lines. Only fall back to a separate file if inventory
# provides one (i.e. someone is restoring from a different repo's snapshot).
if [ -n "$INVENTORY_DIR" ] && [ -f "$INVENTORY_DIR/vscode-extensions.txt" ] && command -v code >/dev/null 2>&1; then
    log "Installing VS Code extensions from inventory (supplemental)"
    while IFS= read -r ext; do
        [ -n "$ext" ] && code --install-extension "$ext" --force
    done < "$INVENTORY_DIR/vscode-extensions.txt"
fi

# ---------------------------------------------------------------------------
# 6. macOS defaults
# ---------------------------------------------------------------------------
if [ -x "$REPO_DIR/macos-defaults.sh" ]; then
    log "Applying macOS defaults"
    "$REPO_DIR/macos-defaults.sh"
fi

# ---------------------------------------------------------------------------
# 7. Fresh SSH key (never restore from old)
# ---------------------------------------------------------------------------
if [ ! -f "$HOME/.ssh/id_ed25519" ]; then
    log "Generating fresh SSH key"
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    ssh-keygen -t ed25519 -C "iqbal.morshed24@gmail.com" -f "$HOME/.ssh/id_ed25519" -N ""
    note "Public key (add to personal GitHub):"
    cat "$HOME/.ssh/id_ed25519.pub"
fi

# ---------------------------------------------------------------------------
# 8. Cross-check inventory against installed apps (if inventory provided)
# ---------------------------------------------------------------------------
if [ -n "$INVENTORY_DIR" ] && [ -f "$INVENTORY_DIR/apps-system.txt" ]; then
    log "Cross-checking inventory app list against /Applications"
    MISSING=$(comm -23 \
        <(sort "$INVENTORY_DIR/apps-system.txt") \
        <(ls -1 /Applications 2>/dev/null | grep -E '\.app$' | sed 's/\.app$//' | sort) \
        2>/dev/null)
    if [ -n "$MISSING" ]; then
        note "Apps in inventory but NOT yet installed (manual install needed):"
        echo "$MISSING" | sed 's/^/      - /'
    fi
fi

# ---------------------------------------------------------------------------
# Done — manual steps
# ---------------------------------------------------------------------------
cat <<EOF


================================================================
  AUTOMATED PORTION COMPLETE.  See POST-RESET.md for full flow.
================================================================

CLOUD-SYNCED APPS (sign in, do NOT copy local files):
  - Raycast → Settings → General → Cloud Sync → sign in
  - VS Code → File → Settings Sync → sign in (if you use it)
  - JetBrains → Settings Sync per IDE (if you use one)
  - 1Password / Bitwarden → fresh install + sign in

DROPBOX (install + sign in BEFORE Keyboard Maestro / Alfred):
  - Install (Brewfile cask 'dropbox')
  - Sign in to personal Dropbox account
  - Wait for ~/Dropbox/config_backup/ to finish syncing (verify the
    file 'Keyboard Maestro Macros.kmsync' is present and ~4MB)

KEYBOARD MAESTRO:
  - Open app, enter license
  - Preferences → Macro Sync → "Open Macro Sync File…"
    Point at: ~/Dropbox/config_backup/Keyboard Maestro Macros.kmsync
  - "Use this file as Macro Sync" → macros load

ALFRED:
  - Open app, enter Powerpack license
  - Preferences → Advanced → "Set sync folder…"
    Point at: ~/Dropbox/config_backup/
    (Alfred will find Alfred.alfredpreferences/ there automatically)

PERSONAL DATA:
  - Plug in flash drive
  - Copy ~/Education, ~/Business, ~/Personal Projects, ~/Media, ~/Documents,
    ~/Health, ~/Pictures, ~/Music, ~/Movies into place
  - Verify 3-4 random files opened correctly

SSH / VERIFICATION:
  - Add the SSH public key above to personal GitHub
  - sudo profiles status -type enrollment → confirm 'No / No'

Backups of anything we replaced: $BACKUP_DIR

EOF
