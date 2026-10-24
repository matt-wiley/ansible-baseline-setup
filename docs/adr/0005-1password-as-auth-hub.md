# ADR 0005: 1Password is the auth hub for SSH and browser

**Status:** Accepted

## Context
Private SSH keys shouldn't be copied between frequently rebuilt machines. Browser logins should unlock from one place.

## Decision
- Install the **native** 1Password app from its vendor repo (AUR on Arch).
- Outbound SSH uses the 1Password SSH agent: `IdentityAgent ~/.1password/agent.sock` in `~/.ssh/config` (owned by the Dotfiles tool). Git commit signing uses `op-ssh-sign`.
- Browser is **native Librewolf** with Firefox Sync for extensions. The 1Password extension connects to the desktop app: Ansible adds `librewolf` to `/etc/1password/custom_allowed_browsers` and links the native messaging manifest into `~/.librewolf/native-messaging-hosts/`.

## Alternatives rejected
- **Per-machine keys** — most secure, too much churn when hopping.
- **Copying one private key around** — risky.
- **Hardware key** — robust, but 1Password is already in use.
- **Flatpak 1Password or Librewolf** — sandbox breaks the agent and native messaging.

## Consequences
SSH and git signing work only while 1Password is running and unlocked. Enabling the agent and browser integration is manual.
