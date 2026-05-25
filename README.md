# Iqbal's dotfiles

Personal macOS setup as code: shell, editor, window manager, automation app configs, and the scripts to deploy them onto a fresh Mac.

## What this repo is — and isn't

**It is** the orchestration layer for reproducing my macOS dev environment on any Mac in under two hours. Clone it, run `./install.sh`, and the bulk of the work happens automatically.

**It is not** a single source of truth for everything. By design, several categories of state live elsewhere:

| Lives here (in this repo) | Lives elsewhere |
|---|---|
| Shell (`.zshrc`, `.p10k.zsh`), git config, dotfiles | Keyboard Maestro macros → `~/Dropbox/config_backup/Keyboard Maestro Macros.kmsync` |
| Karabiner DSL (`karabiner.edn`, compiled via Goku) | Alfred preferences → `~/Dropbox/config_backup/Alfred.alfredpreferences/` |
| Brewfile (formulae, casks, mas, VS Code extensions, npm globals) | Raycast settings + extensions → Raycast Cloud Sync |
| VS Code user settings (`vscode/settings.json`, `keybindings.json`) | VS Code drift → VS Code Settings Sync (optional, complements repo) |
| `install.sh`, `inventory.sh`, `macos-defaults.sh` | 1Password / Bitwarden vault → password manager cloud |
| App config guide + migration docs (`PRE-RESET.md`, `POST-RESET.md`) | SSH / GPG keys → regenerate fresh on new Mac |
| | Personal data (photos, documents, projects) → flash drive / iCloud Drive |

This separation is deliberate. Each category lives in the place that handles it best.

---

## Quick start — bootstrap a fresh Mac

```bash
xcode-select --install                  # installs git
git clone https://github.com/<me>/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
```

Then work through `POST-RESET.md` for the manual sign-ins (Raycast, VS Code, Alfred license entry, etc.).

If you also have an inventory snapshot from `inventory.sh`:

```bash
./install.sh --inventory ~/personal-handoff/inventory
```

---

## Files

- **`install.sh`** — main bootstrap. Installs Xcode CLT + Homebrew, runs `brew bundle`, symlinks dotfiles, installs VS Code extensions, applies macOS defaults, generates fresh SSH key.
- **`inventory.sh`** — pre-reset capture. Snapshots installed apps, Brewfile, language packages, VS Code extensions, app configs (KM/Karabiner/Alfred/Raycast). Output goes to `~/personal-handoff/inventory/`.
- **`macos-defaults.sh`** — `defaults write` commands for macOS system preferences (keyboard repeat, Finder, Dock, etc.). Run from `install.sh`, or standalone any time.
- **`Brewfile`** — declarative install list for Homebrew formulae, casks, Mac App Store apps, AND VS Code extensions (`brew bundle` installs `vscode "ext.id"` lines natively). npm globals are listed as `npm "..."` lines and installed by `install.sh` (since `brew bundle` doesn't understand that directive). Regenerate with `brew bundle dump --force`.

### Configs NOT in this repo (intentionally)

These live elsewhere because they're a better fit for their own sync mechanism:

- **Keyboard Maestro macros** → `~/Dropbox/config_backup/Keyboard Maestro Macros.kmsync` (4MB binary plist, updates constantly — git would be a terrible fit, and public repo would expose macro contents)
- **Alfred preferences** → `~/Dropbox/config_backup/Alfred.alfredpreferences/` (binary package directory)
- **Raycast** → Raycast Cloud Sync
- **VS Code settings beyond user keybindings/settings** → VS Code Settings Sync
- **Personal data, photos, documents** → flash drive / iCloud Drive

### Docs

- **`PRE-RESET.md`** — checklist for the current Mac before the factory reset
- **`POST-RESET.md`** — bootstrap flow for the new Mac after reset
- **`app-config-guide.md`** — reference for Keyboard Maestro, Karabiner-Elements, Alfred, Raycast — config locations, recommended backup path, restore steps

### Configs (under `.config/`)

- **`karabiner.edn`** — Karabiner-Elements config in Goku DSL (source of truth). `karabiner.json` is the generated output (run `goku` to compile); gitignored.

### VS Code (at repo root, not under `.config/`)

- **`vscode/settings.json`** + **`vscode/keybindings.json`** — VS Code user settings. `install.sh` symlinks these into `~/Library/Application Support/Code/User/`.
- Extensions themselves are declared in `Brewfile` via `vscode "ext.id"` lines and installed by `brew bundle`.

### Shell

- **`.zshrc`**, **`.zprofile`**, **`.p10k.zsh`** — zsh + powerlevel10k
- **`.zsh/`** — custom completions (git etc.)
- **`.gitmodules`** — references the zsh plugins as submodules

---

## Maintenance

Periodically run `brew bundle dump --file=Brewfile --force` to refresh the install list (includes VS Code extensions automatically). Commit the diff.

The Brewfile is a *snapshot* — it drifts from reality between manual refreshes. Set a reminder to refresh quarterly if you don't want to be surprised when bootstrapping a new machine.

---

## License

See `LICENSE`.
