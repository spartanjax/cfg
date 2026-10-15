# Microsoft.PowerShell_profile.ps1 (PowerShell 7+)
#
# Managed by cfg (chezmoi). On a synced machine don't edit here by hand:
# edit the repo, or run `chezmoi re-add` after a local change.
#
# Windows wrappers for the cfg-* helpers. The real implementations are POSIX
# shell scripts inside WSL (dot_local/bin/), so these functions just forward to
# them. They use a login shell (`bash -lc`) so ~/.local/bin is on PATH, and
# single-quote each argument for bash so spaces/apostrophes survive wsl.exe.
#
#   cfg-apply             chezmoi apply
#   cfg-pull               chezmoi update
#   cfg-push ["message"]   commit + push

function ConvertTo-CfgCommand {
    param(
        [Parameter(Mandatory)][string]$Name,
        [string[]]$Arguments
    )
    $quoted = foreach ($a in $Arguments) { "'" + ($a -replace "'", "'\''") + "'" }
    (@($Name) + $quoted) -join ' '
}

function cfg-apply { wsl.exe -e bash -lc (ConvertTo-CfgCommand 'cfg-apply' $args) }
function cfg-pull   { wsl.exe -e bash -lc (ConvertTo-CfgCommand 'cfg-pull'   $args) }
function cfg-push   { wsl.exe -e bash -lc (ConvertTo-CfgCommand 'cfg-push'   $args) }

# Shortcuts. PowerShell aliases can't take arguments, so these are functions.
# The POSIX equivalents live in dot_config/shell/aliases.sh. All git shortcuts
# (ga, gpf, gcm, …) come from ~/.gitconfig (dot_gitconfig.tmpl) and work here
# automatically — nothing to define.
function oc  { opencode @args }
