# jf-config

My dotfiles, managed with [chezmoi](https://chezmoi.io), across **Windows** and
**WSL**. One source of truth, applied to every machine.

## Layout

This repo *is* the chezmoi source state. Files are named with chezmoi's
attributes:

| Source path                                    | Becomes                                        |
| ---------------------------------------------- | ---------------------------------------------- |
| `dot_config/opencode/opencode.json`            | `~/.config/opencode/opencode.json`             |
| `dot_config/opencode/agents/*.md`              | `~/.config/opencode/agents/*.md`               |
| `dot_config/opencode/encrypted_service.json.age` | `~/.config/opencode/service.json` (decrypted)  |
| `dot_gitconfig.tmpl`                           | `~/.gitconfig` (templated)                     |
| `dot_local/bin/executable_jf-*`                | `~/.local/bin/jf-*` (Linux/WSL only)           |

- `dot_` prefix → leading dot in the destination path.
- `executable_` prefix → destination is made executable.
- `.tmpl` suffix → rendered as a Go template.
- `encrypted_….age` → stored age-encrypted, decrypted on apply.

## Commands

| Command     | Does                                                       |
| ----------- | ---------------------------------------------------------- |
| `jf-config` | Apply the repo to this machine (`chezmoi apply`)           |
| `jf-pull`   | Pull latest changes and apply them (`chezmoi update`)      |
| `jf-push`   | Commit and push local changes (`chezmoi push`)             |

Day-to-day: edit a file (`chezmoi edit ~/.gitconfig`), then `jf-push`. On another
machine, `jf-pull`.

## New machine

1. Install chezmoi — Windows `winget install twpayne.chezmoi`,
   Linux/WSL `sh -c "$(curl -fsSL get.chezmoi.io)" -- -b "$HOME/.local/bin"`.
2. Restore your age identity to `~/.config/chezmoi/key.txt` (see *Secrets*).
3. Apply:
   ```
   chezmoi init --apply --ssh git@github.com:spartanjax/jf-config.git
   ```

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
