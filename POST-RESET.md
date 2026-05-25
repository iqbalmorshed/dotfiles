# Post-reset bootstrap

The flow for the fresh Mac, in order. Designed so that most of the time is `brew bundle` running in the background while you sign in to cloud-synced apps.

Total wall-clock: 1–2 hours. Active hands-on time: 30–45 minutes.

---

## Step 1 — Critical first-boot check

Before doing anything else, watch the screens during Setup Assistant.

- [ ] At the language selection screen, connect to Wi-Fi
- [ ] **Watch for a "Remote Management" screen.** If you see it — power off the Mac immediately and contact IT. The ABM release was not done; signing in past this point would re-enroll the device into corporate MDM.
- [ ] If no Remote Management screen appears → proceed
- [ ] When asked "Transfer your information to this Mac" → choose **"Don't transfer any information now."** Never restore from a Time Machine backup of the work Mac.
- [ ] Create a new local user account — your name, a new strong password
- [ ] Sign in with your **personal Apple ID**
- [ ] Decline any optional services you don't want (Siri, analytics sharing, etc.)
- [ ] Reach the desktop on the new account

---

## Step 2 — Get git, clone the repo

```bash
xcode-select --install     # installs git (and the CLT — GUI dialog appears)
```

Wait for the installer to complete. Then clone the dotfiles repo:

**Option A — Clone via HTTPS with PAT (no SSH key yet):**

```bash
git clone https://github.com/<your-username>/dotfiles.git ~/.dotfiles
# Username: your GitHub username
# Password: paste the Personal Access Token from your password manager
```

**Option B — Clone from flash drive backup:**

```bash
cp -R /Volumes/<flash-drive>/personal/dotfiles-backup-YYYYMMDD ~/.dotfiles
cd ~/.dotfiles
git status   # confirm git history is intact
```

**Option C — Use GitHub CLI (cleaner if you want to set up gh auth):**

```bash
# Install gh first (one-line homebrew install)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)"
brew install gh
gh auth login                  # browser flow
gh repo clone <your-username>/dotfiles ~/.dotfiles
```

---

## Step 3 — Run the bootstrap

```bash
cd ~/.dotfiles
./install.sh
# OR, if you also brought the inventory directory from the flash drive:
./install.sh --inventory ~/personal-handoff/inventory
```

This step takes 20–40 minutes — it installs Xcode CLT (if not already), Homebrew, runs `brew bundle` against your Brewfile, symlinks dotfiles, installs VS Code extensions, generates a fresh SSH key, and applies macOS defaults.

**While it runs**, work through Step 4 in parallel.

---

## Step 4 — Cloud sign-ins (do this WHILE install.sh runs)

These are the sources of truth that aren't in the repo. Each is a sign-in step, no manual restore.

- [ ] **Raycast** → install (if not done by Brewfile), open app, sign in, Settings → General → Cloud Sync → confirm sync pulled your config
- [ ] **VS Code** → open, File → Settings Sync → sign in with personal GitHub → confirm settings/keybindings/snippets pulled down
- [ ] **JetBrains IDEs** (per IDE, if used) → Settings → Settings Sync → enable
- [ ] **1Password / Bitwarden** → install, sign in with account + master password + 2FA, confirm vault loaded
- [ ] **iCloud Drive** → already syncing from Apple ID sign-in; verify your `~/iCloud Drive` files appear
- [ ] **Dropbox** → install (cask `dropbox`), sign in to personal account (NOT work). **Wait for full sync** — the `config_backup/` folder must be local before Step 5 (Keyboard Maestro + Alfred restore depend on it)
- [ ] **Slack** (personal) → install, sign in to personal workspaces only
- [ ] **Notion / Obsidian / Bear / etc.** (whatever personal note app) → install, sign in

---

## Step 5 — Apps that need manual restore after install.sh finishes

These are the four automation apps. See `app-config-guide.md` in this repo for detail.

### Keyboard Maestro

KM syncs via Dropbox, not the dotfiles repo. **Dropbox must be signed in and fully synced before this step.**

- Confirm `~/Dropbox/config_backup/Keyboard Maestro Macros.kmsync` is present (~4MB)
- Brewfile should have installed KM (cask `keyboard-maestro`)
- Open app → enter license
- Preferences → Macro Sync → "Open Macro Sync File…"
  → pick `~/Dropbox/config_backup/Keyboard Maestro Macros.kmsync`
  → "Use this file as Macro Sync"
- Macros load automatically. Confirm a daily-use macro actually fires.

### Karabiner-Elements

- Brewfile should have installed it (cask `karabiner-elements`)
- `install.sh` already symlinked `~/.config/karabiner/` → repo
- macOS will prompt to approve the DriverKit extension — System Settings → Privacy & Security → Allow
- Grant Input Monitoring + Accessibility permissions when asked
- Confirm a remapping works (e.g., your Caps Lock binding)

### Alfred

Alfred also syncs via Dropbox.

- Confirm `~/Dropbox/config_backup/Alfred.alfredpreferences/` is present
- Brewfile should have installed Alfred (cask `alfred`)
- Open Alfred → enter Powerpack license
- Preferences → Advanced → "Set sync folder…"
  → pick `~/Dropbox/config_backup/`
  → Alfred detects `Alfred.alfredpreferences/` in that folder and offers to use it
- Wait for sync to complete. Verify workflows are present in the Workflows tab.

### Raycast

- Already handled in Step 4 (cloud sync)
- Settings → Extensions → reconnect personal accounts where needed (Slack, calendar, etc.)
- **Do NOT reconnect SCT-related extensions** — those should have been disconnected pre-reset

---

## Step 6 — Personal data restore

- [ ] Plug in flash drive
- [ ] Copy back the directories you backed up:
  - `~/Education/`
  - `~/Business/`
  - `~/Personal Projects/`
  - `~/Media/`
  - `~/Documents/`, `~/Health/`, `~/Pictures/`, `~/Music/`, `~/Movies/`, `~/Downloads/`
- [ ] Open 3–4 random files to verify they read correctly

---

## Step 7 — GitHub SSH key

`install.sh` printed your new SSH public key. Add it to GitHub:

- [ ] GitHub → Settings → SSH and GPG keys → New SSH key → paste the contents of `~/.ssh/id_ed25519.pub`
- [ ] Test: `ssh -T git@github.com` should show "Hi <username>!"
- [ ] If you cloned via HTTPS earlier, switch the remote to SSH:
  ```bash
  cd ~/.dotfiles
  git remote set-url origin git@github.com:<your-username>/dotfiles.git
  ```

---

## Step 8 — Verification

Final confirmations before considering the migration complete.

- [ ] `sudo profiles status -type enrollment` → `No / No`
- [ ] `sudo profiles list` → no configuration profiles installed
- [ ] System Settings → General → Device Management → "No profiles installed"
- [ ] System Settings → Network → no company VPN configs
- [ ] No company root CAs in Keychain Access (search for company name)
- [ ] `whoami` shows your new personal username
- [ ] iMessage / FaceTime only show personal phone & email
- [ ] Save the post-reset profile-status screenshot alongside the pre-reset baseline in `personal/handoff-evidence/`

---

## Step 9 — Sanity-check the automation works

Don't trust "the app launched and the config loaded" — actually trigger your daily workflows. This is the time to find broken bindings, not three weeks from now.

- [ ] Trigger a Keyboard Maestro macro you use every day
- [ ] Test your most-used Karabiner remapping
- [ ] Run an Alfred workflow you rely on
- [ ] Run a Raycast command/snippet
- [ ] Open the project in VS Code where you use multiple keybindings + extensions — verify everything

If anything doesn't work, fix it now while the comparison to the old Mac is still mental-cache-warm.

---

## Done.

The Mac is yours. The work environment is wiped. Personal data restored. Configs versioned in git. Cloud accounts properly partitioned to personal-only.

Next: schedule a follow-up to set up an ongoing backup strategy (see the open item in the workspace handoff checklist) so that future Mac losses are recoverable in hours, not weeks.
