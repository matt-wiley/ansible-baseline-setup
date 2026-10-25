# Apps

The starting app list, and how to add more. See ADR 0002 (native first) and ADR 0003 (mise).

## Starting list

| App | Type | Source | `default` | `Archlinux` | Notes |
|---|---|---|---|---|---|
| zsh | Native | Distro repo | `zsh` | — | Set as login shell in Phase 1 |
| git | Native | Distro repo | `git` | — | Also installed by the Bootstrap |
| curl | Native | Distro repo | `curl` | — | Needed by the Bootstrap; usually preinstalled |
| zoxide | Native | Distro repo | `zoxide` | — | Shell init lives in the Dotfiles tool |
| 1Password | Native | Vendor repo | `1password` | AUR `1password` | Must be native (ADR 0005) |
| Librewolf | Native | Vendor repo | `librewolf` | AUR `librewolf-bin` | Must be native (ADR 0005) |
| gh | Native | Vendor repo | `gh` | `github-cli` | Debian and Fedora use GitHub's repo; Arch uses `extra` |
| openssh-server | Native | Distro repo | `openssh-server` | `openssh` | Hardened by Phase 1 (ADR 0006) |

"—" means the `default` value applies.

## How to add an app

Pick the first type that fits:

1. **Native, distro repo** (most apps). Add a row to `native_apps` in `vars/apps.yml`:
   ```yaml
   ripgrep: { default: ripgrep }
   ```
   Add a key only where the name differs: a distribution (`Ubuntu`, `Fedora`), or an OS family (`Debian`, `RedHat`, `Archlinux`). Use `skip` to leave it out on a distro.
2. **Native, vendor repo** (VS Code, Docker, etc.). Do step 1, add `repo: <name>` to the row, and add the repo setup to each `repos/<family>.yml`. On Arch, use `{ aur: <pkg> }` instead of a vendor repo.
3. **Language runtime or distro-independent CLI tool**: add it to the global mise config, not the matrix.
4. **Flatpak** (non-dev GUI apps only): add the Flathub ID to `flatpak_apps`.
5. **Oddball**: AppImage or Distrobox, as a dedicated task.

Each app's config files belong to the Dotfiles tool, not Ansible.

## Checking an addition

Run Phase 1 on the dev snapshot, then rerun it to confirm the second run makes no changes. Test on Fedora and Arch VMs when a row has per-family values.
