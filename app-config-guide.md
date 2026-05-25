# App Config Backup & Restore Guide

For each app: where configs live, the **preferred** backup path (use this if available — it's the app vendor's own format), the **fallback** (raw filesystem copy when there's no in-app export), and the restore steps.

The `inventory.sh` script captures the fallback paths automatically. The preferred paths require you to do something inside each app — they're more durable across macOS/app version changes, so use them when offered.

---

## Where macOS apps store config (mental model)

Three places matter:

1. **`~/Library/Preferences/<bundle-id>.plist`** — UI preferences, stored via macOS's `defaults` system. Sometimes binary, sometimes XML.
2. **`~/Library/Application Support/<App Name>/`** — application data: workflows, macros, custom configs, user content. **Usually the most important folder.**
3. **`~/Library/Containers/<bundle-id>/Data/`** — sandboxed App Store apps store data here, often protected from direct access. Cloud sync is the right path for sandboxed apps.

`~/Library/Caches/<bundle-id>/` — skip, regenerable.

What `inventory.sh` does NOT touch: the entire `~/Library` tree. That's 324GB on your Mac, mostly system noise. We extract only what's needed.

---

## 1. Keyboard Maestro

**Setup: Dropbox sync.** KM is configured with `~/Dropbox/config_backup/Keyboard Maestro Macros.kmsync` as the Macro Sync file. Dropbox handles cloud backup natively, and the same file is available on any Mac signed into the same Dropbox account.

**Pre-reset action:** verify Preferences → Macro Sync still points at the Dropbox path, then confirm Dropbox menu bar shows "Up to date."

**Restore on new Mac:**

1. Install Dropbox first (Brewfile cask `dropbox`). Sign in to personal account. Wait for `~/Dropbox/config_backup/` to sync down.
2. Install Keyboard Maestro (Brewfile cask `keyboard-maestro`).
3. Launch KM → enter license.
4. Preferences → Macro Sync → "Open Macro Sync File…" → pick `~/Dropbox/config_backup/Keyboard Maestro Macros.kmsync` → "Use this file as Macro Sync."
5. Macros load.

**Why not git:** the `.kmsync` is a binary plist that updates on every macro tweak — git history would balloon, and the dotfiles repo is public, exposing macro contents (which often include scripts, file paths, sometimes credentials). Dropbox provides 30 days of version history for free, which is what you actually want for this kind of file.

**Fallback if Dropbox is somehow inaccessible:** `File → Export Macros…` in the app produces an `.kmlibrary` file you can carry on the flash drive. Restore via `File → Import Macros…` on the new Mac. Only needed if Dropbox itself becomes a problem.

**Note on triggers:** macros that trigger on specific application bundle IDs — verify those still match if you switched between equivalent apps (e.g., Chrome → Arc).

---

## 2. Karabiner-Elements

**Setup: Goku DSL in the dotfiles repo.** The source of truth is `.config/karabiner.edn` (a Clojure-like DSL). Goku compiles it into `karabiner.json`, which Karabiner-Elements actually reads. The JSON output is gitignored — only the DSL source is committed.

**Restore on new Mac:**

1. Install Karabiner-Elements (Brewfile cask `karabiner-elements`) and Goku (`brew "yqrashawn/goku/goku"`) — both already in the Brewfile.
2. `install.sh` symlinks `.config/karabiner.edn` into `~/.config/karabiner.edn` and runs `goku` to generate `karabiner.json`.
3. Grant Karabiner accessibility + input monitoring permissions when prompted.
4. Approve the Karabiner DriverKit virtual HID extension in System Settings → Privacy & Security.
5. Restart Karabiner-Elements (menu bar icon → Quit, then relaunch).
6. Verify in Preferences → Complex Modifications that your rules are present and enabled.

**Editing later:** edit `~/.config/karabiner.edn`, run `goku` to recompile, then commit the .edn change. Don't edit `karabiner.json` directly — your edits will be lost the next time Goku runs.

---

## 3. Alfred

Alfred has its own first-class sync mechanism that handles this elegantly — but **only if you set it up in advance**.

**Iqbal's actual setup: Dropbox sync.** Alfred is already configured to sync to `~/Dropbox/config_backup/` (which contains `Alfred.alfredpreferences/`). Pre-reset action: verify Alfred Preferences → Advanced → Syncing still points at that folder, and Dropbox menu bar shows "Up to date."

**Restore on new Mac (Dropbox path):**

1. Install Dropbox first (cask `dropbox`). Sign in. Wait for `~/Dropbox/config_backup/Alfred.alfredpreferences/` to sync down.
2. Install Alfred (Brewfile cask `alfred`).
3. Launch Alfred → enter Powerpack license.
4. Preferences → Advanced → "Set sync folder…" → pick `~/Dropbox/config_backup/`. Alfred detects the existing `Alfred.alfredpreferences/` and offers to use it.
5. Verify workflows are present and re-enabled (Workflows tab).

**Caveat on workflows:** any workflow that contains compiled binaries or scripts referencing absolute paths on the old Mac may need adjustment.

---

## 4. Raycast

Raycast is sandboxed. The raw file path approach is unreliable — file permissions can prevent the copy, and even when it works, restoring sandboxed app data on a different machine is fragile.

**Preferred (and really the only sane path): Raycast Cloud Sync.**

1. Open Raycast → Settings → General → Cloud Sync.
2. Sign in / create a Raycast account if you don't have one.
3. Wait for sync to complete (verify in Settings → General that timestamp updates).
4. All your settings, extensions, snippets, quicklinks, AI commands sync to the cloud.

**On new Mac:**

1. Install Raycast (Brewfile cask `raycast`).
2. Sign in to the same Raycast account.
3. Everything restores within a minute.

If you have a Raycast Pro subscription with custom AI commands, those sync too.

**Fallback (captured by inventory.sh, partial):**

- `~/Library/Application Support/com.raycast.macos/` — some files may be permission-blocked

Cloud sync is so much better here that I'd consider it the only realistic restore path. Enable it today if you haven't.

---

## Beyond the four — other configs worth thinking about

| App | Config location | Backup approach |
|---|---|---|
| **iTerm2 / Warp / Ghostty** | `~/Library/Preferences/com.googlecode.iterm2.plist` (iTerm2 has "Preferences → General → Settings → Save to folder" — use it) | App-internal export when available |
| **VS Code / Cursor** | `~/Library/Application Support/Code/User/settings.json`, `keybindings.json`, snippets, plus extensions list | Use Settings Sync (built-in); inventory.sh captures extensions list separately |
| **1Password / Bitwarden** | Vault is in the cloud — don't touch local files | Sign in fresh on new Mac |
| **JetBrains IDEs** | `~/Library/Application Support/JetBrains/<ProductName>/` | JetBrains has Settings Sync built-in |
| **Sublime Text** | `~/Library/Application Support/Sublime Text/Packages/User/` | Copy the User directory |
| **tmux / vim / neovim** | `~/.tmux.conf`, `~/.vimrc`, `~/.config/nvim/` | Sanitize and copy with dotfiles |
| **Homebrew** | n/a — Brewfile IS the config | `brew bundle dump` (inventory.sh does this) |

---

## What to do BEFORE running inventory.sh

Most of your real state is already syncing to its proper home (Dropbox for KM + Alfred, Raycast Cloud, dotfiles repo for everything else). Quick checks first:

1. **Dropbox** menu bar shows "Up to date" — confirms KM `.kmsync` and Alfred preferences are cloud-synced.
2. **Raycast** → Settings → General → Cloud Sync is enabled and showing a recent timestamp.
3. **VS Code** → File → Settings Sync is enabled with personal GitHub account.
4. **`~/.dotfiles`** is committed and pushed (Brewfile fresh, `karabiner.edn` current).

Then run `inventory.sh` to capture the supplemental snapshot (app list, language ecosystem packages, etc.) onto the flash drive.

---

## Sanity check after restore

Verify each app's automations actually work, not just that the app launched:

- Trigger a Keyboard Maestro macro you use daily
- Test a Karabiner remapping
- Open Alfred, run a workflow you rely on
- Run a Raycast command/snippet

If any are missing or broken, the time to find out is right after setup, not three weeks later when you've forgotten what your config looked like.
