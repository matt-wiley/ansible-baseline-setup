# ADR 0001: Ansible owns the system and package layer

**Status:** Accepted

## Context
Distro hopping is part of the fun, but a fresh install must be productive fast. Must work across Ubuntu/Debian (primary), Fedora and Arch.

## Decision
Use Ansible, run locally (`-i localhost, -c local`), for packages, vendor repos, drivers, system config and sshd. Distro-specific work is split per OS family via `include_tasks: "repos/{{ ansible_os_family | lower }}.yml"`.

## Alternatives rejected
- **NixOS** — reproducible with rollbacks, but ends distro hopping.
- **Plain bash** — fast to start, unmaintainable across three families.
- **Nix + Home Manager** — can't own drivers/system services; may be evaluated later for CLI tools only.
- **Salt / pyinfra** — viable; Ansible is more mature and a transferable skill.

## Consequences
Convergent, not reproducible: removing an item doesn't uninstall it; no rollback. Per-family maintenance for repos and the AUR.
