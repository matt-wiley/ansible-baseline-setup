# ansible-baseline-setup

Automated first-run setup for a frequently re-installed Linux workstation. One command takes a fresh install to a working machine: packages, vendor repos, shell, runtimes, inbound SSH, and the browser and password manager wired together.

```bash
curl -fsSL https://raw.githubusercontent.com/matt-wiley/ansible-baseline-setup/main/bootstrap.sh | bash
```

Run it as your normal user, not root, from an interactive terminal. It asks for your sudo password once, and Phase 1 prints your manual next steps when it finishes.

**Read the [usage guide](docs/guide.md)** for what it does, the manual steps afterward, how to verify the result, and how to develop and test changes.

## Status

- Bootstrap and Phase 1 are built and have run end to end on Ubuntu 26.04.
- Debian, Fedora and Arch code paths exist but are untested.
- Phase 2 (anything needing sign-in) is built but only partly: it creates `~/projects` and clones `zsh-config`. Run its `init.sh` by hand afterward.

## Layout

| Path | Purpose |
|---|---|
| `bootstrap.sh` | Installs git and Ansible, clones this repo, runs Phase 1 |
| `ansible.cfg` | Prints multi-line playbook messages readably; applies when run from the repo directory |
| `phase1.yml` | The playbook for everything that needs no credentials |
| `phase2.yml` | The playbook for what needs sign-in, run after the manual gate |
| `verify.yml` | Read-only check that Phase 1 left the machine as intended |
| `vars/apps.yml` | The app matrix, Flatpak list and mise tools |
| `repos/`, `tasks/`, `templates/` | Per-OS-family vendor repos, task files and templates |
| `docs/` | [Usage guide](docs/guide.md), [app list](docs/apps.md), [decision records](docs/adr/) |
| `CONTEXT.md` | Glossary and terms to avoid |

This repo is public and must never contain secrets.
