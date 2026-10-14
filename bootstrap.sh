#!/bin/sh
# bootstrap.sh — provision a fresh macOS or Linux/WSL machine with the
# prerequisites for the cfg dotfiles, then apply them with chezmoi.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/spartanjax/cfg/main/bootstrap.sh | sh
#
# It installs, only if missing:
#   - Homebrew        (macOS)
#   - git + curl      (base tools)
#   - chezmoi
#   - opencode
#
# Then it clones the cfg repo and applies it. Everything the dotfiles need
# (tmux, ripgrep, fzf, …) is installed by the repo's own run_ scripts during
# the apply, so it is not duplicated here.
#
# Environment overrides:
#   CFG_REPO        git URL to clone (default: SSH, falling back to HTTPS)
#   CFG_AGE_KEY     age identity used to decrypt secrets. Either the
#                   "AGE-SECRET-KEY-1..." text or a path to the key file.
#   CFG_NO_SECRETS  set to 1 to silence the missing-key warning.
#
# Safe to re-run: already-installed pieces are skipped.

set -u

REPO_SSH="git@github.com:spartanjax/cfg.git"
REPO_HTTPS="https://github.com/spartanjax/cfg.git"
KEYFILE="$HOME/.config/chezmoi/key.txt"
SRC="$HOME/.local/share/chezmoi"

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mwarning:\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

OS="$(uname -s)"

# Put the directories our tools install into on PATH for this run and for the
# run_ scripts chezmoi executes later.
PATH="$HOME/.local/bin:$HOME/.opencode/bin:$PATH"
export PATH

# --- Homebrew (macOS only) -------------------------------------------------
if [ "$OS" = "Darwin" ]; then
    if [ -x /opt/homebrew/bin/brew ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -x /usr/local/bin/brew ]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi

    if ! have brew; then
        log "Installing Homebrew..."
        NONINTERACTIVE=1 /bin/bash -c \
            "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" \
            || die "Homebrew installation failed"
        if [ -x /opt/homebrew/bin/brew ]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        elif [ -x /usr/local/bin/brew ]; then
            eval "$(/usr/local/bin/brew shellenv)"
        fi
        have brew || die "Homebrew installed but not found on PATH"
    fi
fi

# --- base tools: git + curl ------------------------------------------------
if ! have git || ! have curl; then
    log "Installing git and curl..."
    if [ "$OS" = "Darwin" ]; then
        have git  || brew install git
        have curl || brew install curl
    elif have apt-get; then
        sudo apt-get update
        sudo apt-get install -y git curl ca-certificates
    else
        die "Please install git and curl, then re-run."
    fi
    have git || die "git not available"
    have curl || die "curl not available"
fi

# --- chezmoi ---------------------------------------------------------------
if ! have chezmoi; then
    log "Installing chezmoi..."
    if [ "$OS" = "Darwin" ] && have brew; then
        brew install chezmoi || die "brew install chezmoi failed"
    else
        sh -c "$(curl -fsSL https://get.chezmoi.io)" -- -b "$HOME/.local/bin" \
            || die "chezmoi installation failed"
    fi
    have chezmoi || die "chezmoi installed but not found on PATH"
fi

# --- opencode --------------------------------------------------------------
# Use the OpenCode 2 installer. The legacy https://opencode.ai/install endpoint
# installs the frozen v1 line (1.19.x); v2 is the current release and is served
# from https://opencode.ai/v2/install.
#
# --no-modify-path: the shell rc files are managed by chezmoi and would
# clobber the PATH line opencode would add. The cfg dotfiles already put
# ~/.opencode/bin on PATH.
opencode_major() {
    v="$(opencode --version 2>/dev/null | tr -d '\r' | awk '{print $NF}')"
    v="${v#v}"
    printf '%s\n' "${v%%.*}"
}

if have opencode && [ "$(opencode_major)" = "2" ]; then
    log "opencode v2 already installed; skipping."
else
    if have opencode; then
        log "Upgrading opencode to the latest v2..."
    else
        log "Installing opencode (v2)..."
    fi
    curl -fsSL https://opencode.ai/v2/install | bash -s -- --no-modify-path \
        || die "opencode installation failed"
    have opencode || die "opencode installed to ~/.opencode/bin but not on PATH"
    log "opencode $(opencode --version 2>/dev/null | tr -d '\r') installed"
fi

# --- age key (secrets) -----------------------------------------------------
have_key=false
if [ -f "$KEYFILE" ]; then
    have_key=true
elif [ -n "${CFG_AGE_KEY:-}" ]; then
    mkdir -p "$(dirname "$KEYFILE")"
    if [ -f "$CFG_AGE_KEY" ]; then
        cp "$CFG_AGE_KEY" "$KEYFILE"
    else
        printf '%s\n' "$CFG_AGE_KEY" > "$KEYFILE"
    fi
    chmod 600 "$KEYFILE"
    have_key=true
    log "Installed age key from CFG_AGE_KEY"
fi

# --- choose a repo URL -----------------------------------------------------
repo="${CFG_REPO:-}"
if [ -z "$repo" ]; then
    if GIT_SSH_COMMAND="ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new" \
        git ls-remote "$REPO_SSH" >/dev/null 2>&1; then
        repo="$REPO_SSH"
    else
        repo="$REPO_HTTPS"
    fi
fi
log "Using repo: $repo"

# --- clone/update + apply --------------------------------------------------
if [ -d "$SRC/.git" ]; then
    log "Updating existing chezmoi source..."
    git -C "$SRC" pull --ff-only || warn "git pull failed; continuing with local state"
else
    log "Cloning dotfiles with chezmoi..."
    chezmoi init "$repo" || die "chezmoi init failed"
fi

if [ "$have_key" = true ]; then
    log "Applying dotfiles (with secrets)..."
    chezmoi apply || die "chezmoi apply failed"
else
    if [ "${CFG_NO_SECRETS:-}" != "1" ]; then
        warn "No age key found (set CFG_AGE_KEY to include it); applying without the sealed secret."
    fi
    chezmoi apply --exclude=encrypted || die "chezmoi apply failed"
fi

log "Done. Start a new shell, then run 'cfg-apply' any time to re-apply."
