# Microsoft.PowerShell_profile.ps1 (PowerShell 7+)
#
# Managed by jf-config (chezmoi). On a synced machine don't edit here by hand:
# edit the repo, or run `chezmoi re-add` after a local change.
#
# Windows wrappers for the jf-* helpers. The real implementations are POSIX
# shell scripts inside WSL (dot_local/bin/), so these functions just forward to
# them. They use a login shell (`bash -lc`) so ~/.local/bin is on PATH, and
# single-quote each argument for bash so spaces/apostrophes survive wsl.exe.
#
#   jf-config             chezmoi apply
#   jf-pull               chezmoi update
#   jf-push ["message"]   commit + push

function ConvertTo-JfCommand {
    param(
        [Parameter(Mandatory)][string]$Name,
        [string[]]$Arguments
    )
    $quoted = foreach ($a in $Arguments) { "'" + ($a -replace "'", "'\''") + "'" }
    (@($Name) + $quoted) -join ' '
}

function jf-config { wsl.exe -e bash -lc (ConvertTo-JfCommand 'jf-config' $args) }
function jf-pull   { wsl.exe -e bash -lc (ConvertTo-JfCommand 'jf-pull'   $args) }
function jf-push   { wsl.exe -e bash -lc (ConvertTo-JfCommand 'jf-push'   $args) }

# Shortcuts. PowerShell aliases can't take arguments, so these are functions.
# The POSIX equivalents live in dot_config/shell/aliases.sh. `git recent` comes
# from ~/.gitconfig (dot_gitconfig.tmpl) and needs nothing here.
function oc  { opencode @args }
function gpf { git push --force-with-lease @args }
function gsw { git switch @args }
function gpl { git pull @args }
function gp  { git push @args }
function gst { git status @args }
function gco { git checkout @args }
function gcm { git commit -m @args }
function gd  { git diff @args }
function gl  { git log --oneline --graph --decorate @args }
function gb  { git branch @args }
