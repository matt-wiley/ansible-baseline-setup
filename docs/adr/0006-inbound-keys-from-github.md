# ADR 0006: Inbound SSH keys come from GitHub's public key URL

**Status:** Accepted

## Context
Each machine needs an `authorized_keys` list without manual copying.

## Decision
Ansible installs and hardens `openssh-server` (drop-in in `/etc/ssh/sshd_config.d/`: no password auth, no root login) and writes keys with `ansible.posix.authorized_key`, `key: https://github.com/<user>.keys`, `exclusive: true`. Keys update when the playbook reruns.

## Alternatives rejected
- **Keys committed to the setup repo** — offline and versioned, but a second source to maintain. Kept as fallback.
- **AuthorizedKeysCommand (live fetch)** — login depends on network and GitHub.
- **Other hosted URL** — works, but GitHub already holds the keys behind 2FA.

## Consequences
GitHub account security is SSH security (keep 2FA on). Needs network at run time.
