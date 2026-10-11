# jf-config

My dotfiles, managed with [chezmoi](https://chezmoi.io), across **Windows**,
**WSL/Linux** and **macOS**. One source of truth, applied to every machine.

## Layout

This repo *is* the chezmoi source state. Files are named with chezmoi's
attributes:

| Source path                                    | Becomes                                        |
| ---------------------------------------------- | ---------------------------------------------- |
| `dot_config/opencode/opencode.json`            | `~/.config/opencode/opencode.json`             |
| `dot_config/opencode/agents/*.md`              | `~/.config/opencode/agents/*.md`               |
| `dot_config/opencode/encrypted_service.json.age` | `~/.config/opencode/service.json` (decrypted)  |
| `dot_gitconfig.tmpl`                           | `~/.gitconfig` (templated)                     |
| `dot_bashrc`                                   | `~/.bashrc` (Linux/WSL only)                   |
| `dot_zshrc`                                    | `~/.zshrc` (macOS only)                        |
| `dot_tmux.conf`                                | `~/.tmux.conf` (Linux/WSL + macOS)             |
| `dot_local/bin/executable_jf-*`                | `~/.local/bin/jf-*` (Linux/WSL + macOS)        |
| `OneDrive/Documents/…/Microsoft.PowerShell_profile.ps1` | Windows PowerShell `$PROFILE`          |
| `Brewfile`                                     | *not applied* — macOS package list             |

- `dot_` prefix → leading dot in the destination path.
- `executable_` prefix → destination is made executable.
- `.tmpl` suffix → rendered as a Go template.
- `encrypted_….age` → stored age-encrypted, decrypted on apply.
- `run_*` scripts → executed by `chezmoi apply` (see *Packages*).

## Commands

| Command     | Does                                                       |
| ----------- | ---------------------------------------------------------- |
| `jf-config` | Apply the repo to this machine (`chezmoi apply`)           |
| `jf-pull`   | Pull latest changes and apply them (`chezmoi update`)      |
| `jf-push`   | Commit and push local changes (`chezmoi push`)             |

Day-to-day: edit a file (`chezmoi edit ~/.gitconfig`), then `jf-push`. On another
machine, `jf-pull`.

On **Windows** these are PowerShell functions in `$PROFILE` (both Windows
PowerShell 5.1 and PowerShell 7) that forward to the WSL implementations:
`function jf-push { wsl.exe -e bash -lc … }`. So they behave identically in a
Windows terminal — they just run inside WSL. The `$PROFILE` path here is under
`OneDrive\Documents`; on a Windows machine where Documents is *not* redirected,
adjust the source path accordingly.

## Packages

Installed by scripts that `chezmoi apply` runs (skipped on Windows):

| Script                                          | Machine   | Does                                |
| ----------------------------------------------- | --------- | ----------------------------------- |
| `run_once_before_install-homebrew.sh.tmpl`      | macOS     | installs Homebrew if missing        |
| `run_onchange_before_install-packages.sh.tmpl`  | macOS     | `brew bundle` from `Brewfile`       |
| `run_onchange_before_install-packages.sh.tmpl`  | Linux/WSL | `apt-get install` the CLI set       |
| `run_onchange_after_tpm-install.sh.tmpl`        | both      | installs TPM + tmux plugins         |

The tmux bar is themed with
[tokyo-night-tmux](https://github.com/janoamaral/tokyo-night-tmux) and includes
tmux-resurrect / continuum / yank / fzf — all configured in `dot_tmux.conf`.

`run_onchange_` re-runs only when its content changes — so **edit the package
list** (or the `Brewfile`) and the next `jf-config`/`jf-pull` reinstalls.
`run_once_` runs a single time. To force a re-run:

```
chezmoi state delete-bucket --bucket=entryState    # run_onchange_
chezmoi state delete-bucket --bucket=scriptState   # run_once_
```

## Terminal appearance (fonts)

The tmux bar and the Windows Terminal scheme draw **Nerd Font** glyphs. Install
[JetBrainsMono Nerd Font](https://www.nerdfonts.com/) (v3+) once per machine:

- **Windows:** `winget install DEVCOM.JetBrainsMonoNerdFont`
- **macOS:** `brew install --cask font-jetbrains-mono-nerd-font`

Windows Terminal already points at `JetBrainsMono Nerd Font` and the `Tokyo
Night` scheme (both in the managed `settings.json`). The font is a system
install, so chezmoi does not manage it.

## New machine

1. Install chezmoi — Windows `winget install twpayne.chezmoi`; Linux/WSL/macOS
   `sh -c "$(curl -fsSL get.chezmoi.io)" -- -b "$HOME/.local/bin"`.
2. Restore your age identity to `~/.config/chezmoi/key.txt` (see *Secrets*), and
   your SSH key if you want git-over-SSH.
3. Apply (this also installs packages and tmux plugins):
   ```
   chezmoi init --apply --ssh git@github.com:spartanjax/jf-config.git
   ```
4. Install the Nerd Font (see *Terminal appearance* above).

Per-OS behaviour is driven by templates and `.chezmoiignore`: `~/.bashrc` only on
Linux/WSL, `~/.zshrc` only on macOS, Windows Terminal settings only on Windows.

## Secrets

Secrets are committed **age-encrypted** (files named `encrypted_*.age`). The age
recipient is public and lives in `.chezmoi.toml.tmpl`. The private identity is
`~/.config/chezmoi/key.txt` — it is per-machine and never committed.

- Add a secret: `chezmoi add --encrypt ~/.config/opencode/service.json`
- The private key must be copied to each new machine (e.g. from your password
  manager) before `chezmoi apply` can decrypt secrets.

## Per-machine values

`~/.config/chezmoi/chezmoi.toml` is generated on each machine and holds that
machine's `[data]` (name/email, etc.). Edit it locally to differ from the
defaults — it is not part of the repo.

## Editing notes

- **Windows Terminal** rewrites its `settings.json` when you change settings in
  the UI. After a UI change run `chezmoi re-add` then `jf-push` to capture it;
  otherwise `jf-config` will overwrite it with the repo version.
- **Shell rc files** are copied (not symlinked). `~/.bashrc` was captured from
  the original; the repo version adds `~/.local/bin` to `PATH` and `fd`/`bat`
  aliases.
