# ~/.config/shell/aliases.sh — managed by cfg (chezmoi).
#
# Shared POSIX aliases, sourced by ~/.bashrc (Linux/WSL) and ~/.zshrc (macOS).
# Keep this file POSIX-compatible so both shells can read it.
#
# Git shortcuts are NOT here — they live in dot_gitconfig.tmpl ([alias]) so they
# also work in Windows PowerShell. Windows gets its own wrappers in $PROFILE.

# --- General ---------------------------------------------------------------
alias oc='opencode'
alias c='code .'
alias g='git'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# --- Projects --------------------------------------------------------------
# Jump to the chezmoi source tree (the real one, wherever chezmoi keeps it).
alias cfg='cd "$(chezmoi source-path)"'

# cd to the root of the current git repository.
cdg() {
    local root
    root=$(git rev-parse --show-toplevel 2>/dev/null) || {
        echo "cdg: not inside a git repository" >&2
        return 1
    }
    cd "$root" || return 1
}

# --- File manager ----------------------------------------------------------
# Open a directory (default: current) in the OS file manager.
#   WSL   -> Windows Explorer
#   macOS -> Finder
#   Linux -> xdg-open
openhere() {
    local target="${1:-.}"
    case "$(uname -s)" in
        Linux)
            if command -v explorer.exe >/dev/null 2>&1; then
                explorer.exe "$(wslpath -w "$target" 2>/dev/null || echo "$target")" >/dev/null 2>&1
            elif command -v xdg-open >/dev/null 2>&1; then
                xdg-open "$target" >/dev/null 2>&1 &
            elif command -v open >/dev/null 2>&1; then
                open "$target" >/dev/null 2>&1 &
            else
                echo "openhere: no file-manager opener found" >&2
                return 1
            fi
            ;;
        Darwin)
            open "$target"
            ;;
        *)
            echo "openhere: unsupported OS: $(uname -s)" >&2
            return 1
            ;;
    esac
}

# --- Shell quality-of-life -------------------------------------------------
alias h='history | tail -n 30'
alias dfh='df -h'
alias dus='du -sh'
alias freeh='free -h'
alias ports='ss -tulpn'
alias myip='curl -s https://ifconfig.me; echo'
alias serve='python3 -m http.server'

# Find a running process by name (excludes the grep itself).
psg() {
    ps aux | grep -i --color=never "$1" | grep -v grep
}

# --- tmux ------------------------------------------------------------------
alias t='tmux'
alias tl='tmux list-sessions'
alias ta='tmux attach -t'
alias tn='tmux new -s'
alias tk='tmux kill-session -t'
alias td='tmux detach'
alias tks='tmux kill-server'
alias tkw='tmux kill-window'
alias treload='tmux source-file ~/.tmux.conf'
