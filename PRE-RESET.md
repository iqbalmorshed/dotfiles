# Pre-reset checklist

Everything you need to do on the **current** Mac before handing it over for the factory reset. The goal is to make sure that when you clone this repo on the new Mac and run `./install.sh`, every config, every macro, every cloud-synced setting is already where it needs to be.

Work top to bottom. Each section explains *why* the step matters — skim past the explanation if you're in a hurry, but don't skip the action.

---

## Stage 1 — Verify the device state

Before anything else, confirm what state the Mac is actually in. Evidence of these checks is your protection if anything ever goes wrong with the handover.

- [ ] `sudo profiles status -type enrollment` → confirm `Enrolled via DEP: No` and `MDM enrollment: No`
- [ ] `sudo profiles list` → confirm `There are no configuration profiles installed in the system domain`
- [ ] Screenshot both outputs, save to `personal/handoff-evidence/` with date in filename
- [ ] Get IT's written commitment that the device will NOT be added to Apple Business Manager before the reset (see Stage 0b of the workspace-level `macbook_handoff_checklist.md`)

---

## Stage 2 — Refresh the repo state

Your repo only restores what's actually in it. Two things to update before the reset.

### Brewfile

Your committed `Brewfile` may be stale. Regenerate it from current installed state:

```bash
brew bundle dump --file=~/.dotfiles/Brewfile --force
```

Then review the diff. Things to check before committing:

- Anything work-specific (private taps, internal tools) — remove from the file
- Tools you don't actually use anymore — prune to keep the install lean
- Spurious version pins from older formulae

```bash
cd ~/.dotfiles
git diff Brewfile        # review
git add Brewfile
git commit -m "Refresh Brewfile pre-reset"
```

### npm globals in Brewfile

Your Brewfile has lines like `npm "@angular/cli"`. The `install.sh` script knows how to handle these (it parses them out and runs `npm install -g`), but `brew bundle` itself doesn't. If you bundle-dump again, those lines may not be regenerated — they came from a previous manual addition. To preserve them:

```bash
# Save the existing npm lines
grep '^npm ' ~/.dotfiles/Brewfile > /tmp/npm-lines.txt

# Dump fresh
brew bundle dump --file=~/.dotfiles/Brewfile --force

# Append the npm lines back
cat /tmp/npm-lines.txt >> ~/.dotfiles/Brewfile
```

Also refresh the list itself before reset:

```bash
# Get current globals
npm list -g --depth=0 --parseable | tail -n +2 | xargs -L1 basename
```

Compare against what's currently in your Brewfile. Add any missing ones as `npm "package-name"` lines.

### Karabiner: confirm Goku flow works

You compile `karabiner.edn` → `karabiner.json` via Goku. Before reset, sanity-check:

```bash
goku                                           # should print "Done!" with no errors
cat ~/.config/karabiner/karabiner.json | head  # should show generated JSON
```

If goku errors, the install.sh can't fully restore Karabiner on the new Mac. Fix syntax issues in `.config/karabiner.edn` now.

### iTerm2 symlink — recommend removal

Your repo currently has `.config/iterm2/AppSupport` as a symlink pointing at `~/Library/Application Support/iTerm2`. This pattern doesn't actually back up iTerm2 settings — git only tracks the symlink path, not what it points at. On the new Mac the target won't exist yet.

The apply script removes this. To properly version iTerm2 prefs:

1. Open iTerm2 → Settings → General → Preferences
2. Check "Load preferences from a custom folder or URL"
3. Point at `~/.dotfiles/iterm2/`
4. Click "Save Current Settings to Folder" — iTerm2 writes prefs there
5. Commit the result

This way iTerm2 itself is the writer and the repo is the storage. Optional — skip if iTerm2 prefs don't matter to you.

### Keyboard Maestro + Alfred — already on Dropbox

These two apps already sync via `~/Dropbox/config_backup/`:

- `~/Dropbox/config_backup/Keyboard Maestro Macros.kmsync` — KM's live sync target
- `~/Dropbox/config_backup/Alfred.alfredpreferences/` — Alfred's sync folder

This is the right architecture for these specific apps. Don't move them into the git repo (they're binary, change constantly, and the repo is public). The apply script removes the stale 2021 `.kmsync` that was in the dotfiles repo — Dropbox is now the only source for KM macros.

What to verify pre-reset:

```bash
# Confirm KM is actually syncing to Dropbox
open -a "Keyboard Maestro"
# Preferences → Macro Sync → confirm path is ~/Dropbox/config_backup/Keyboard Maestro Macros.kmsync

# Confirm Alfred is syncing to Dropbox
open -a "Alfred Preferences"
# Preferences → Advanced → Syncing → confirm folder is ~/Dropbox/config_backup/

# Force-flush by making a trivial change in each app (rename and rename back a macro,
# rename and rename back an Alfred workflow), then verify Dropbox shows the sync timestamp updated.
```

Then verify Dropbox itself is fully synced (menu bar icon → "Up to date"). Once that's green, your KM and Alfred state is safe in Dropbox cloud regardless of what happens to the laptop.

### VS Code extensions

Good news — `brew bundle dump` already captures these as `vscode "extension.id"` lines in your Brewfile. No separate file needed. Just confirm the Brewfile has those lines after the refresh; if not, your VS Code might not have been picked up by the `code` CLI when brew dumped. Quick check:

```bash
grep '^vscode' ~/.dotfiles/Brewfile | head
```

If the section is empty or missing, install the `code` CLI shim first (in VS Code: ⌘⇧P → "Shell Command: Install 'code' command in PATH"), then re-run the dump.

---

## Stage 2b — Public-repo privacy audit (since this repo is public)

Because the repo is public, every past and future commit is world-readable. Before the next push, do a one-time history scan for anything that shouldn't be there:

```bash
cd ~/.dotfiles

# Look for likely sensitive strings in ALL history (commits, deleted files, branches)
git log --all -p -S 'sct' -i | head -100
git log --all -p -S 'aws_access_key_id' | head
git log --all -p -S 'api_key' -i | head
git log --all -p -S 'secret' -i | head
git log --all -p -S '@sct' | head    # work email patterns

# List files ever committed under sensitive paths
git log --all --diff-filter=A --name-only | grep -E '(credentials|secret|token|password|\.env)' || echo "clean"

# Find references to internal hostnames (replace 'sct' with the actual domain pattern)
git grep -i 'sct' $(git log --all --pretty=format:%H | head -20) 2>/dev/null | head
```

Specific things in the current repo state worth a look:

- **`Keyboard Maestro Macros.kmsync`** — binary plist, but parseable. Any macros that reference work file paths, work URLs, SCT-internal hostnames, or credentials? Easiest check: `strings ~/.dotfiles/Keyboard\ Maestro\ Macros.kmsync | grep -i sct | head` (and similar greps for your work domain or any credential-like strings).
- **`.zshrc`** — aliases, exported env vars, function definitions. Anything referencing SCT internal services or work-only paths?
- **`.gitconfig`** — the `user.email` setting. If it's your work email, change it now to your personal one for any new commits (`git config --global user.email "iqbal.morshed24@gmail.com"`).
- **`.config/raycast/extensions/`** — about to be removed by the apply script, but those files have been public for however long they've been in the repo. The code itself is open source (extracted from the Raycast store), so probably fine, but it does signal which extensions you use.

If you find anything actually sensitive in the history, the fix is `git filter-repo` (or BFG Repo-Cleaner) to rewrite history, then force-push. Public-repo history rewrites are noisy but necessary if real secrets leaked.

If the scans come up clean, you're good to proceed.

---

## Stage 3 — Push the repo to your personal remote

If `~/.dotfiles` only lives on this Mac, the reset wipes it. Verify the remote and push.

```bash
cd ~/.dotfiles
git remote -v                  # confirm personal-account remote is set
git push origin master         # or main, depending on branch
git push --all origin          # all branches (including 'configs')
```

If the remote is on your work GitHub account: **switch it to your personal account first.** A repo tied to your work GitHub disappears the moment your work account is offboarded.

```bash
git remote set-url origin git@github.com:<personal-username>/dotfiles.git
git push origin master
```

**Belt-and-suspenders:** also copy the repo onto the flash drive before reset.

```bash
cp -R ~/.dotfiles /Volumes/<flash-drive-name>/personal/dotfiles-backup-$(date +%Y%m%d)
```

That way, even if GitHub auth is a hassle on the new Mac, you have a local clone to copy back.

---

## Stage 4 — Save the auth credentials

You'll need to clone the repo onto the new Mac before any of your usual auth (SSH keys, gh CLI) exists yet.

- [ ] Create a Personal Access Token (GitHub → Settings → Developer Settings → Personal Access Tokens) with `repo` scope
- [ ] Save it to your password manager (1Password / Bitwarden) — labelled clearly, e.g., "GitHub PAT for dotfiles bootstrap"
- [ ] Verify your password manager is itself cloud-synced (1Password account active, Bitwarden sync working)
- [ ] Note your password manager's master password is memorized — not stored on the laptop

---

## Stage 5 — Enable cloud sync on the right apps

These apps sync state to vendor cloud, not git. Enable each one *now* so the state is in the cloud before reset.

- [ ] **Raycast** → Settings → General → Cloud Sync → sign in. Verify last-sync timestamp updates.
  - **Also**: Settings → Extensions → check which workspaces are connected to Slack and similar extensions. **Disconnect SCT Slack** before sync captures that state going forward.
- [ ] **VS Code** → File → Settings Sync → Sign in with personal GitHub. Choose what to sync (settings, keybindings, snippets, extensions). Force a sync.
- [ ] **JetBrains IDEs** (if used) → Settings → Settings Sync → enable
- [ ] **1Password / Bitwarden** → confirm vault is synced; back up your account recovery key somewhere off the laptop
- [ ] **iCloud Drive** → confirm signed in with personal Apple ID, files are syncing
- [ ] **Dropbox** (if used) → confirm signed into personal account, not work

---

## Stage 6 — Run the inventory snapshot

The repo + cloud sync covers the core. The inventory script captures supplementary state (current app list, language ecosystem packages, dotfiles in case something diverged from the repo).

```bash
~/.dotfiles/inventory.sh
```

This writes to `~/personal-handoff/inventory/`. Copy that directory to the flash drive too.

---

## Stage 7 — Stage 1 audit (personal data)

Refer to `macbook_handoff_checklist.md` in the project root for the full inventory table. Backup to flash drive:

- `~/Education/` (27G)
- `~/Business/` (11G)
- `~/Personal Projects/` (3.7G)
- `~/Media/` (1.5G)
- `~/Documents/` (284M)
- `~/Health/` (12M)
- `~/Pictures/`, `~/Music/`, `~/Movies/`, `~/Downloads/` (all tiny)

Do **not** copy:
- `~/sct-projects/` (company code)
- `~/Parallels/` (work VM)
- `~/.aws/`, `~/.ssh/private-keys`, `~/.docker/`, `~/.kube/`, `~/.minikube/` (work configs/credentials)
- `~/Library/` (system-app state, drags in work artifacts)

---

## Stage 8 — Final cleanup before reset

The day of (or morning of) the reset.

- [ ] Run `sudo profiles status -type enrollment` one more time. Screenshot. Compare to pre-handoff baseline.
- [ ] Push any final repo changes to remote
- [ ] Confirm flash drive has: personal data + `dotfiles-backup-*` + `inventory/`
- [ ] Sign out of personal Apple ID (System Settings → Apple ID → Sign Out) — only after Find My Mac is off
- [ ] Sign out of personal cloud services (iCloud, Dropbox, Adobe, JetBrains, Microsoft, etc.) — for each, choose "deauthorize from this device" where offered
- [ ] Sign out of company services (Slack, work GitHub, work Outlook, work password manager, company VPN)

Then proceed to the factory reset.

---

## Sanity check before you hand the laptop over

- [ ] The dotfiles repo is on a personal GitHub remote AND on the flash drive
- [ ] GitHub PAT is in your password manager
- [ ] Brewfile is fresh (includes `vscode "..."` and `npm "..."` lines) and pushed
- [ ] Dropbox menu bar shows "Up to date" — `~/Dropbox/config_backup/` has current KM `.kmsync` and `Alfred.alfredpreferences/`
- [ ] Raycast / VS Code Settings Sync / JetBrains / 1Password Cloud Sync are confirmed active
- [ ] Personal-data inventory on flash drive
- [ ] handoff-evidence/ screenshots saved off the laptop
- [ ] All sign-outs completed
- [ ] Re-verified ABM/MDM state right before handover

When all of the above is green, the reset itself is uneventful.
