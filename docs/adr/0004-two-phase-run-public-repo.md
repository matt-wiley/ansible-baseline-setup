# ADR 0004: Two-phase run from a public, secret-free setup repo

**Status:** Accepted

## Context
Before sign-in, a fresh machine has no credentials: it can't clone private repos or use the SSH agent.

## Decision
The setup repo is public and contains no secrets. A curl-able `bootstrap.sh` detects the distro (`/etc/os-release`), installs git + Ansible, clones the repo over HTTPS, and runs Phase 1. After the manual gate, Phase 2 runs anything needing auth. Both phases: `ansible-playbook -i localhost, -c local <phase>.yml -K`.

## Alternatives rejected
- **Secrets in repo (Ansible Vault)** — still needs a secret to unlock; adds risk.
- **Private repo + token at bootstrap** — a credential must exist before 1Password does.
- **USB-only delivery** — offline, but copies go stale.

## Scope
Initial code covers only `bootstrap.sh` and `phase1.yml`. Phase 2 stays a defined slot with no code until Phase 1 runs reliably; its automations will be researched then.

## Consequences
Nothing private may land in the repo. 1Password sign-in/toggles and Firefox Sync stay manual.
