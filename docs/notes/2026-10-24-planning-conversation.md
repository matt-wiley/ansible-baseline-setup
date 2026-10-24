# Planning conversation — 2026-10-24

Record of the conversation that produced `CONTEXT.md`, `docs/adr/0001–0006` and `docs/apps.md`. User questions are verbatim; answers are condensed to their substance.

---

**Q: I like to distro hop, a lot. I'm looking for ways to automate my first-run setup. I'm curious how well ansible would fit here. What are the pros and cons to using it? What are the alternatives?**

Ansible fits cross-distro package and system setup well; it's overkill for dotfiles alone.
- Pros: mature, industry standard; per-distro package names as vars; idempotent-ish, readable YAML; handles repos, services, users, flatpaks.
- Cons: needs Python/Ansible bootstrapped; verbose; arbitrary scripts break idempotence; convergent rather than reproducible (unlike Nix).
- Alternatives: chezmoi (dotfiles + templating), Nix + Home Manager (distro-agnostic packages and dotfiles, steep curve), bash + GNU Stow, Salt, separate `/home` partition.
- Common combo: Ansible for packages/system + a dotfiles tool.

**Q: I have a custom alternative for chezmoi and Stow. I'm primarily looking for setup pathways for packages, common apps, app configurations, etc.**

Options for the package layer: Ansible (`package` module + per-family vars, per-distro repo tasks), Nix (same packages everywhere, weak for system-level), Flatpak/Homebrew/mise/pipx/cargo (distro-agnostic layers), Distrobox, a bash bootstrap, pyinfra.
Suggested stack: bash bootstrap → Ansible for native packages/repos/services/DE settings → Flatpak for GUI apps, Homebrew/mise for CLI → custom dotfiles tool last. Test in VMs.

**Q: Why Flatpak? What's mise?**

- Flatpak: same app IDs on every distro, newer versions, sandboxed. Downsides: disk use, theming/permission quirks, weak for CLI/dev tools.
- mise: polyglot tool version manager (asdf successor). One config declares runtimes and CLI tools; installs to `$HOME`, same on any distro; also per-project versions, env vars, tasks.

**Q: Does mise replace nvm and pyenv and jenv, etc.?**

Yes — also rbenv, goenv, tfenv. Reads `.nvmrc`, `.python-version`, `.java-version`, `.tool-versions`. Caveats: Python build deps, Java vendor naming, manages versions not virtualenvs (can auto-create a venv).

**Q: If I'm already using nvm and pyenv, is the migration path to mise difficult?**

No, usually under an hour: install + activate mise; remove nvm/pyenv init; `mise use -g node@22 python@3.12`; projects keep working; reinstall global packages; delete `~/.nvm`, `~/.pyenv`. Gotchas: leftover PATH, IDE interpreter paths, Python compiling unless precompiled builds are used.

**Q: How does mise work with IDEs and Python interpreter paths? Does it make that easier, or is it the same experience as pyenv?**

Mostly the same: versioned interpreter paths; GUI IDEs miss shell activation (fix: shims in `~/.profile`). Easier: auto per-project `.venv` (IDEs detect natively), community VS Code/JetBrains plugins, one mechanism for all languages.

**Q: Are there alternatives to Flatpak? I've had some rough times with those apps in the past.**

Native + vendor repos (most reliable), AppImage (with AM/AppMan or Gear Lever), Nix packages (GUI friction), Distrobox + `distrobox-export`, Snap (not an improvement). Suggestion: native first, AppImage/Distrobox for oddballs, Flatpak only where clearly best. Flatseal fixes most permission issues.

**Q: If I go with Flatpak, what are the common difficulties for software developers?**

IDEs can't see host tools; integrated terminal runs in the sandbox; limited filesystem access; sockets/devices (Docker, SSH agent, GPG, USB) need permissions; restricted debugging; config in `~/.var/app/<id>/`; extensions that shell out break. Keep IDEs, terminals and dev tooling native.

**Q: Ok. I think I'd default to native apps, and be selective about which I choose to run as Flatpaks.**

Agreed. Keep two lists, `native_apps` and `flatpak_apps`, so moving an app is a one-line change.

**Q: I'd like to do native apps as a matrix of app vs. distro with a "common" or "default" column. I'm largely running on Debian-based systems, so I don't expect a lot of differentiation there.**

`vars/apps.yml` maps app → `{ default, <Distribution>, <OsFamily> }`, with `skip` to exclude. A loop resolves distribution → OS family → `default`, then one `package` task installs the list. Vendor repos handled separately via a `repo` field.

**Q: What are the best (easiest, most robust, most common) ways to handle and manage SSH? Both in accessing the machine, and making sure the machine is setup to access other machine I use often?**

- Inbound: Ansible installs/hardens `openssh-server`; `authorized_keys` from `https://github.com/<you>.keys`; optional Tailscale.
- Outbound: password-manager SSH agent (1Password/Bitwarden), hardware key, or per-machine keys; don't copy private keys.
- Config: `~/.ssh/config` in dotfiles with `Host` aliases and `Include config.d/*`.

**Q: That work really well! I use 1Password right now.**

Install native 1Password from its vendor repo; manually enable the SSH agent; `IdentityAgent ~/.1password/agent.sock`; `op-ssh-sign` for git signing. Agent only works while the app is running and unlocked.

**Q: "GitHub keys for inbound" explain this a bit more**

GitHub publishes public keys at `https://github.com/<user>.keys`. `ansible.posix.authorized_key` with `exclusive: true` writes them to `authorized_keys`. Needs network; GitHub account security becomes SSH security (keep 2FA on).

**Q: I can, in theory, put those keys anywhere right? Any public server?**

Yes, any HTTPS URL in `authorized_keys` format. Whoever can edit the file can get in. Simplest alternative: commit public keys into the setup repo.

**Q: "though you need to rerun the playbook to update" explain**

`authorized_keys` only changes when Ansible rewrites it — true for the GitHub URL approach too. Auto-sync options: `ansible-pull` on a systemd timer, or `AuthorizedKeysCommand` (live fetch at login). For a few machines, manual reruns are fine.

**Q: I often use 1password to handle my browser logins and auth as well. I prefer to use Librewolf with Firefox Accounts enabled for extension syncing… Is there an alternative option where I can centralize my login to the 1password OS app, and let the browser use some auth agent to access it?**

Yes: the extension integrates with the desktop app via native messaging, unlocking with it. Librewolf needs `librewolf` in `/etc/1password/custom_allowed_browsers` and the native messaging manifest in `~/.librewolf/native-messaging-hosts/`. Doesn't work with Flatpak Librewolf.

**Q: What's the plan we have so for?**

Bootstrap → Ansible (app matrix, vendor repos, selective Flatpak, Distrobox/AppImage) → mise + per-project `.venv` → SSH (GitHub keys inbound, 1Password agent outbound) → native Librewolf + 1Password integration → dotfiles tool last → manual sign-ins → VM testing. Open: sync strategy, Tailscale.

**Q: How much of this installation and configuration is fully automated? Where do I need to step into manually configure things?**

Automated: packages, repos, Flatpaks, mise, sshd, keys, configs, 1Password/Librewolf wiring. Manual: running the bootstrap + sudo password; 1Password sign-in and toggles; Firefox Sync; Tailscale login; private repos after the agent works; possibly NVIDIA/Secure Boot and DE settings. Flow: phase 1 → manual sign-ins → phase 2.

**Q: Let's pin tailscale and repos as something to talk more about later. Can we not automate the NVIDIA driver installations?**

Mostly yes: detect via `lspci`; Ubuntu `ubuntu-drivers install`; Debian `nvidia-driver` + headers from non-free; Pop `system76-driver-nvidia`; Fedora RPM Fusion `akmod-nvidia`; Arch `nvidia-open`; then reboot. Manual: Secure Boot MOK enrollment (by design). Avoid by disabling Secure Boot or using pre-signed modules.

**Q: Let's talk about Tailscale. I like it in concept and theory, but I don't necessarily trust having to shuttle my connection through third party servers (other than my ISP)**

Traffic is peer-to-peer WireGuard; the coordination server sees metadata only; DERP relays carry encrypted packets only when NAT blocks direct connections. Tailnet Lock mitigates control-plane risk. Self-hosted options: Headscale (recommended), NetBird, plain WireGuard, Nebula.

**Q: Let's park Tailscale and remote (WAN) access for now… How do we get the playbook and run once we're bootstrapped?**

Public repo + `curl -fsSL …/bootstrap.sh | bash`. The script detects the distro, installs git + Ansible, clones over HTTPS, runs `ansible-playbook -i localhost, -c local phase1.yml -K`. Phase 2 the same way after the manual gate. Alternative: `ansible-pull`. Keep secrets out of the repo.

**Q: So, we've imagined this as mostly Debian-based (ubuntu), how do we make more flexible so that it can work with fedora and arch as well? Are we already there?**

Mostly. Gaps: `include_tasks` per OS family; vendor repos differ (deb822 / yum_repository + RPM Fusion / AUR); AUR via `paru` + `kewlfft.aur` as a normal user; small differences (build tools, Flathub on Fedora, multilib, service names); a test VM per family.

**Q: So what's the trade-off analysis between this and something like NixOS?**

NixOS replaces distro hopping; Ansible enables it. Ansible: any distro, familiar, but convergent with no rollback. NixOS: fully reproducible with rollbacks and no name mapping, but one distro, steep curve, non-FHS friction. Middle ground: Nix + Home Manager on any distro.

**Q: I think I'm looking for both… I want the Ansible setup now. I might want to look into the Nix with HomeManager setup, but I want to understand how it differs and what it does/provides.**

Nix installs into `/nix/store` on any distro; Home Manager declares the user environment, removes what's dropped from config, and supports rollbacks and pinning via flakes. It doesn't handle system-level setup; GUI apps can be rough. It overlaps with mise and the dotfiles tool. Suggested: Ansible now, try Home Manager for CLI tools later in a VM.

**Q: I have a base install snapshot of an Ubuntu 26.04.1 LTS VM. How do I use that as a foundational starting point for my VM-based testing?**

Loop: revert → run bootstrap → check → rerun for idempotence → revert. Faster: a second snapshot with sshd + key, run the playbook from the host. Snapshot after phase 1 to test phase 2; linked clones for parallel tests.

**Q: Use the /grill-docs skill and your own judgement and recommendations to create the baseline project docs based on what we've discussed…**

Created `CONTEXT.md` and ADRs 0001–0006 (Ansible system layer; native-first apps; mise; two-phase public repo; 1Password auth hub; GitHub inbound keys). Parked: Tailscale/WAN, private repos, sync strategy, Nix + Home Manager.

**Q: Does this plan already include some target native apps?**

Only 1Password and Librewolf as decisions; other names were examples.

**Q: Start with 1Password and Librewolf. Make sure the plan explains how to add others as needed. The core CLI apps are zsh, git, curl, zoxide.**

Created `docs/apps.md`: all six native (four from distro repos; 1Password and Librewolf from vendor repos or AUR), plus a five-step guide for adding apps.

**Q: The code (the playbook and scripts) should only account for bootstrapping and phase 1 for now. Once that is up and running well, I'll start researching phase 2 automations.**

Updated `CONTEXT.md` and ADR 0004: code scope is `bootstrap.sh` and `phase1.yml` only. Running the dotfiles tool and anything needing the 1Password agent wait for Phase 2.
