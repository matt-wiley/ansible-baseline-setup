# Context — Machine Setup

Automated first-run setup for a frequently re-installed (distro-hopped) Linux workstation. Goal: productive on a fresh install as fast as possible.

## Glossary

- **Bootstrap** — the one-line `curl | bash` script that installs git + Ansible, clones the setup repo, and runs Phase 1.
- **Setup repo** — the public git repo holding the bootstrap, playbooks and vars. Contains no secrets.
- **Phase 1** — playbook run before any sign-in: packages, repos, drivers, system config, sshd, dev tooling. Must work with no credentials.
- **Manual gate** — the human steps between phases: sign into 1Password, enable its SSH agent and browser integration, sign into Firefox Sync.
- **Phase 2** — playbook run after the manual gate: anything needing auth (private repos, dotfiles tool). Not yet in scope for code; to be researched once the Bootstrap and Phase 1 are solid.
- **App matrix** — the `native_apps` map of app → package name, resolved by lookup order *distribution → OS family → `default`*. The value `skip` means "don't install here".
- **Native app** — installed from the distro package manager or a vendor repo. The default.
- **Flatpak app** — explicitly listed in `flatpak_apps`; opt-in only, never for dev tools, IDEs, terminals or browsers.
- **Oddball app** — not cleanly packaged natively; handled via AppImage or Distrobox.
- **Vendor repo** — a third-party package source (VS Code, 1Password, etc.) added per OS family before installing.
- **OS family** — Ansible's `ansible_os_family`: `Debian` (primary), `RedHat` (Fedora), `Archlinux`.
- **Dotfiles tool** — the user's own custom dotfiles manager. Owns all dotfiles, including `~/.ssh/config`. Run as the last Phase 2 task.
- **Base snapshot** — pristine Ubuntu 26.04.1 LTS VM snapshot used for end-to-end bootstrap tests.
- **Dev snapshot** — base snapshot + sshd + user key, for running the playbook from the host during iteration.

## Terms to avoid

- "Dotfiles" for app/package setup — dotfiles are owned by the Dotfiles tool, not Ansible.
- "Remote access" — WAN access is out of scope for now; say "inbound SSH" for LAN/direct SSH.
