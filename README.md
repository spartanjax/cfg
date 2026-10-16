# cfg

My dotfiles, managed with [chezmoi](https://chezmoi.io), across **Windows**,
**WSL/Linux** and **macOS**. One source of truth, applied to every machine.

## Layout

This repo *is* the chezmoi source state. Files are named with chezmoi's
attributes:

| Source path                                    | Becomes                                        |
| ---------------------------------------------- | ---------------------------------------------- |
| `dot_config/opencode/opencode.json`            | `~/.config/opencode/opencode.json`             |
| `dot_config/opencode/AGENTS.md`                | `~/.config/opencode/AGENTS.md` (global instructions) |
| `dot_config/opencode/agents/*.md`              | `~/.config/opencode/agents/*.md`               |
| `dot_config/opencode/encrypted_private_service.json.age` | `~/.config/opencode/private_service.json` (decrypted) |
| `dot_gitconfig.tmpl`                           | `~/.gitconfig` (templated)                     |
| `dot_config/shell/aliases.sh`                  | `~/.config/shell/aliases.sh` (sourced by bash/zsh) |
| `dot_bashrc`                                   | `~/.bashrc` (Linux/WSL only)                   |
| `dot_zshrc`                                    | `~/.zshrc` (macOS only)                        |
| `dot_tmux.conf`                                | `~/.tmux.conf` (Linux/WSL + macOS)             |
| `dot_local/bin/executable_cfg-*`                | `~/.local/bin/cfg-*` (Linux/WSL + macOS)        |
| `OneDrive/Documents/…/Microsoft.PowerShell_profile.ps1` | Windows PowerShell `$PROFILE`          |
| `Brewfile`                                     | *not applied* — macOS package list             |
| `bootstrap.sh`                                 | *not applied* — one-line new-machine setup      |
| `.env.example`                                 | *not applied* — template for the local `.env`  |

- `dot_` prefix → leading dot in the destination path.
- `executable_` prefix → destination is made executable.
- `.tmpl` suffix → rendered as a Go template.
- `encrypted_….age` → stored age-encrypted, decrypted on apply.
- `run_*` scripts → executed by `chezmoi apply` (see *Packages*).

## Commands

| Command     | Does                                                       |
| ----------- | ---------------------------------------------------------- |
| `cfg-apply` | Apply the repo to this machine (`chezmoi apply`)           |
| `cfg-pull`   | Pull latest changes and apply them (`chezmoi update`)      |
| `cfg-push`   | Commit and push local changes (`chezmoi push`)             |

Day-to-day: edit a file (`chezmoi edit ~/.gitconfig`), then `cfg-push`. On another
machine, `cfg-pull`.

The source tree chezmoi actually applies lives at `$(chezmoi source-path)`
(normally `~/.local/share/chezmoi`) — edit **there**, or use `chezmoi edit`.
Keep a single clone: a second checkout elsewhere is *not* what gets applied.

On **Windows** these are PowerShell functions in `$PROFILE` (both Windows
PowerShell 5.1 and PowerShell 7) that forward to the WSL implementations:
`function cfg-push { wsl.exe -e bash -lc … }`. So they behave identically in a
Windows terminal — they just run inside WSL. The `$PROFILE` path here is under
`OneDrive\Documents`; on a Windows machine where Documents is *not* redirected,
adjust the source path accordingly.

## Aliases

**Git shortcuts** live in `dot_gitconfig.tmpl` (`[alias]`) and so work in *every*
shell — Linux/WSL, macOS and Windows PowerShell — because git reads its own
config. Invoke them as `git <name>` (e.g. `git gpf`):

| Alias        | Runs                                     |
| ------------ | ---------------------------------------- |
| `git recent` | 20 most recently committed local branches |
| `git ga`     | `git add .`                              |
| `git gp`     | `git push`                               |
| `git gpl`    | `git pull`                               |
| `git gpf`    | `git push --force-with-lease`            |
| `git gfa`    | `git fetch --all --prune`                |
| `git gcl`    | `git clone`                              |
| `git gcm`    | `git commit -m`                          |
| `git gd`     | `git diff`                               |
| `git gl`     | `git log --oneline --graph --decorate`   |
| `git gb`     | `git branch`                             |
| `git gst`    | `git status -sb`                         |
| `git gco`    | `git checkout`                           |
| `git gsw`    | `git switch`                             |
| `git gprev`  | `git switch -`                           |
| `git grh`    | `git reset --hard`                       |

**Shared POSIX aliases** live in `dot_config/shell/aliases.sh` (→
`~/.config/shell/aliases.sh`) and are sourced by both `~/.bashrc` and
`~/.zshrc`, so they are identical on Linux/WSL and macOS:

| Alias       | Runs                                   |
| ----------- | -------------------------------------- |
| `oc`        | `opencode`                             |
| `c`         | `code .`                               |
| `g`         | `git`                                  |
| `..` `...` `....` | parent directories               |
| `cfg`       | `cd $(chezmoi source-path)`            |
| `cdg`       | `cd` to the current git repo root      |
| `openhere`  | open CWD in Explorer/Finder/`xdg-open` |
| `h`         | `history \| tail -n 30`                |
| `dfh` `dus` `freeh` | `df -h`, `du -sh`, `free -h`    |
| `ports`     | `ss -tulpn`                            |
| `myip`      | public IP via ifconfig.me              |
| `serve`     | `python3 -m http.server`               |
| `psg`       | `ps aux \| grep` for a process name    |
| `t` `tl` `ta` `tn` `tk` | tmux: run/list/attach/new/kill-session |
| `td` `tks` `tkw` | tmux: detach/kill-server/kill-window |
| `treload`   | `tmux source-file ~/.tmux.conf`        |

On **Windows** only `oc` is a PowerShell function in `$PROFILE`; the git
shortcuts need no wrapper — they come from `~/.gitconfig`.

## Packages

Installed by scripts that `chezmoi apply` runs (skipped on Windows):

| Script                                          | Machine   | Does                                |
| ----------------------------------------------- | --------- | ----------------------------------- |
| `run_once_before_install-homebrew.sh.tmpl`      | macOS     | installs Homebrew if missing        |
| `run_onchange_after_install-packages.sh.tmpl`   | macOS     | `brew bundle` from `Brewfile`       |
| `run_onchange_after_install-packages.sh.tmpl`   | Linux/WSL | `apt-get install` the CLI set       |
| `run_onchange_after_tpm-install.sh.tmpl`        | both      | installs TPM + tmux plugins         |

Package installs are `after_` scripts so chezmoi lays down the managed files
(including the `~/.zshrc`/`~/.bashrc` `PATH` that exposes `opencode` and the
`cfg-*` wrappers) *before* Homebrew/apt runs. A slow or failed package step can
no longer leave a fresh machine without a working shell.

The tmux bar is themed with
[tokyo-night-tmux](https://github.com/janoamaral/tokyo-night-tmux) and includes
tmux-resurrect / continuum / yank / fzf — all configured in `dot_tmux.conf`.

`run_onchange_` re-runs only when its content changes — so **edit the package
list** (or the `Brewfile`) and the next `cfg-apply`/`cfg-pull` reinstalls.
`run_once_` runs a single time. To force a re-run:

```
chezmoi state delete-bucket --bucket=entryState    # run_onchange_
chezmoi state delete-bucket --bucket=scriptState   # run_once_
```

## Terminal appearance (fonts)

The tmux bar and the Windows Terminal scheme draw **Nerd Font** glyphs. Install
[JetBrainsMono Nerd Font](https://www.nerdfonts.com/) (v3+) once per machine:

- **Windows:** `winget install DEVCOM.JetBrainsMonoNerdFont` — registers the
  families `JetBrainsMono NF` / `NFM` / `NFP`. Windows Terminal uses
  **`JetBrainsMono NFM`** (the single-width "Mono" variant, best for the tmux
  status bar).
- **macOS:** `brew install --cask font-jetbrains-mono-nerd-font` — family
  `JetBrainsMono Nerd Font Mono`. Point your terminal app at it.

Windows Terminal already points at `JetBrainsMono NFM` and the `Tokyo Night`
scheme (both in the managed `settings.json`). The font is a system install, so
chezmoi does not manage it.

## New machine

### One-line bootstrap (macOS, Linux/WSL)

```sh
curl -fsSL https://raw.githubusercontent.com/spartanjax/cfg/main/bootstrap.sh | sh
```

`bootstrap.sh` installs the **prerequisites only** — Homebrew on macOS, then
git, curl, chezmoi and opencode — clones the repo, and applies it. Everything
else (tmux, ripgrep, fzf, …) is installed by the repo's `run_` scripts during
the apply. Pass the age key so the sealed secret can be decrypted:

```sh
CFG_AGE_KEY="$(cat ~/key.txt)" sh -c \
  "$(curl -fsSL https://raw.githubusercontent.com/spartanjax/cfg/main/bootstrap.sh)"
```

`CFG_AGE_KEY` may be the `AGE-SECRET-KEY-1…` text itself or a path to a key
file. With no key, the sealed secret is skipped and a warning is printed.
`CFG_REPO` overrides the clone URL (default: SSH, falling back to HTTPS).
The script is idempotent — re-run it any time.

### Manual / Windows

1. Install chezmoi — Windows `winget install twpayne.chezmoi`; Linux/WSL/macOS
   `sh -c "$(curl -fsSL get.chezmoi.io)" -- -b "$HOME/.local/bin"`.
2. Restore your age identity to `~/.config/chezmoi/key.txt` (see *Secrets*), and
   your SSH key if you want git-over-SSH.
3. Apply (this also installs packages and tmux plugins):
   ```
   chezmoi init --apply --ssh git@github.com:spartanjax/cfg.git
   ```
4. Install the Nerd Font (see *Terminal appearance* above).

Per-OS behaviour is driven by templates and `.chezmoiignore`: `~/.bashrc` only on
Linux/WSL, `~/.zshrc` only on macOS, Windows Terminal settings only on Windows.

## Secrets

Secrets are committed **age-encrypted** (files named `encrypted_*.age`). The age
recipient is public and lives in `.chezmoi.toml.tmpl`. The private identity is
`~/.config/chezmoi/key.txt` — it is per-machine and never committed.

- Add a secret: `chezmoi add --encrypt ~/.config/opencode/service.json`
- **Restore the key on a new machine:** write the identity
  (`AGE-SECRET-KEY-1…`) to `~/.config/chezmoi/key.txt` and `chmod 600` it — or
  pass it to `bootstrap.sh` as `CFG_AGE_KEY` (raw text or a path to the file).
  Without it, `chezmoi apply`/`status` fail on every `encrypted_*.age` file; use
  `chezmoi apply --exclude=encrypted` to apply everything else meanwhile.
- **Verify** it matches this repo before relying on it:
  `chezmoi age-keygen -y ~/.config/chezmoi/key.txt` must print the `recipient`
  from `.chezmoi.toml.tmpl`.

### Local-only secrets (`.env`)

Machine-only tokens that should never be committed or synced live in `.env` at
the repo root. It is git-ignored (`.env`, `.env.*`) and chezmoi never applies it —
chezmoi ignores any source file whose name starts with `.` — so it stays on this
machine.

```sh
cp .env.example .env && chmod 600 .env   # once, then edit in your tokens
set -a; . ./.env; set +a                 # load into the current shell
```

Use this only for throwaway/local values. Anything needed on every machine
belongs in an `encrypted_*.age` file above; GitHub tokens are best left to
`gh auth login`.

## Per-machine values

`~/.config/chezmoi/chezmoi.toml` is generated on each machine and holds that
machine's `[data]` (name/email, etc.). Edit it locally to differ from the
defaults — it is not part of the repo.

## Editing notes

- **Windows Terminal** rewrites its `settings.json` when you change settings in
  the UI. After a UI change run `chezmoi re-add` then `cfg-push` to capture it;
  otherwise `cfg-apply` will overwrite it with the repo version.
- **Shell rc files** are copied (not symlinked). `~/.bashrc` was captured from
  the original; the repo version adds `~/.local/bin` to `PATH`, aliases
  `fd`/`bat`, and sources the shared `~/.config/shell/aliases.sh`.
