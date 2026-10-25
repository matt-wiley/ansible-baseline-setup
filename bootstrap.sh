#!/usr/bin/env bash
# Bootstrap: install git + Ansible, clone the setup repo over HTTPS, run Phase 1.
# Usage: curl -fsSL <raw-url>/bootstrap.sh | bash
#
# Overrides (environment):
#   SETUP_REPO    git URL of the setup repo
#   SETUP_BRANCH  branch to check out (default: main)
#   SETUP_DIR     where to clone (default: ~/ansible-baseline-setup)
#
# Contains no secrets. Phase 1 must work with no credentials (ADR 0004).

set -euo pipefail

REPO_OWNER=${REPO_OWNER:-matt-wiley}
SETUP_REPO="${SETUP_REPO:-https://github.com/$REPO_OWNER/ansible-baseline-setup.git}"
SETUP_BRANCH="${SETUP_BRANCH:-main}"
SETUP_DIR="${SETUP_DIR:-$HOME/ansible-baseline-setup}"

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
die() { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }

# Run a command as root, via sudo when not already root.
as_root() {
    if [ "$(id -u)" -eq 0 ]; then "$@"; else sudo "$@"; fi
}

# Map /etc/os-release to an Ansible OS family: Debian, RedHat or Archlinux.
detect_family() {
    [ -r /etc/os-release ] || die "/etc/os-release not found; cannot detect distro"
    # shellcheck disable=SC1091
    . /etc/os-release
    local ids=" ${ID:-} ${ID_LIKE:-} "
    case "$ids" in
        *" debian "* | *" ubuntu "*) echo Debian ;;
        *" fedora "* | *" rhel "*)   echo RedHat ;;
        *" arch "*)                  echo Archlinux ;;
        *) die "unsupported distro: ID=${ID:-?} ID_LIKE=${ID_LIKE:-?}" ;;
    esac
}

install_prereqs() {
    case "$1" in
        Debian)
            as_root apt-get update
            as_root env DEBIAN_FRONTEND=noninteractive apt-get install -y git ansible
            ;;
        RedHat)
            as_root dnf install -y git ansible
            ;;
        Archlinux)
            as_root pacman -Syu --needed --noconfirm git ansible
            ;;
    esac
}

# Ansible's become prompt handling times out with sudo-rs (Ubuntu's default since 25.10),
# so switch to the original sudo (the `sudo` package, binary sudo.ws) before Phase 1. See Launchpad bug 2122414.
ensure_classic_sudo() {
    [ "$1" = Debian ] || return 0
    sudo --version 2>&1 | grep -qi 'sudo-rs' || return 0
    log "sudo-rs detected; switching to classic sudo (sudo.ws) for Ansible"
    as_root apt-get install -y sudo
    [ -x /usr/bin/sudo.ws ] || die "sudo installed but /usr/bin/sudo.ws not found"
    as_root update-alternatives --set sudo /usr/bin/sudo.ws
}

sync_repo() {
    if [ -d "$SETUP_DIR/.git" ]; then
        log "Updating $SETUP_DIR"
        git -C "$SETUP_DIR" fetch --quiet origin "$SETUP_BRANCH"
        git -C "$SETUP_DIR" checkout --quiet "$SETUP_BRANCH"
        git -C "$SETUP_DIR" pull --ff-only --quiet origin "$SETUP_BRANCH"
    elif [ -e "$SETUP_DIR" ]; then
        die "$SETUP_DIR exists and is not a git checkout"
    else
        log "Cloning $SETUP_REPO to $SETUP_DIR"
        git clone --branch "$SETUP_BRANCH" "$SETUP_REPO" "$SETUP_DIR"
    fi
}

run_phase1() {
    cd "$SETUP_DIR"
    [ -f phase1.yml ] || die "phase1.yml not found in $SETUP_DIR"
    if [ -f requirements.yml ]; then
        log "Installing Ansible collections"
        ansible-galaxy collection install -r requirements.yml
    fi
    log "Running Phase 1"
    # </dev/tty so the -K sudo prompt works when the script itself arrives on stdin.
    ansible-playbook -i localhost, -c local phase1.yml -K </dev/tty
}

print_next_steps() {
    log "Phase 1 complete. Manual steps (the manual gate):"
    cat <<STEPS

  1. Open 1Password and sign in.
     Settings > Developer > turn on "Use the SSH agent".
     Settings > Browser > turn on the browser integration, if it is off.
  2. Open Librewolf and sign in to your Firefox account.
     Firefox Accounts is already enabled, so no restart is needed.
     The 1Password extension should then find the app and log in on its own.
  3. Check the result:
       ansible-playbook -i localhost, -c local $SETUP_DIR/verify.yml -K

Then run Phase 2 (not built yet).
STEPS
}

# Wrapped in a function so a truncated `curl | bash` download runs nothing.
main() {
    [ "$(id -u)" -ne 0 ] || die "run as your normal user, not root; Phase 1 escalates with sudo"
    (: </dev/tty) 2>/dev/null || die "no terminal available for the sudo prompt; run from an interactive shell (ssh -t)"
    local family
    family="$(detect_family)"
    log "Detected OS family: $family"
    install_prereqs "$family"
    ensure_classic_sudo "$family"
    sync_repo
    run_phase1
    print_next_steps
}

main "$@"
