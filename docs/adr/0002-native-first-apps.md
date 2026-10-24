# ADR 0002: Native apps by default; Flatpak is opt-in

**Status:** Accepted

## Context
Past Flatpak experience was rough. Sandboxing breaks dev workflows (host toolchains, sockets, debuggers) and blocks native messaging, which 1Password browser integration needs.

## Decision
Install apps natively (distro repo or vendor repo) through the app matrix. Flatpak only for apps listed in `flatpak_apps`, never for IDEs, terminals, dev tooling or browsers. Oddballs use AppImage or Distrobox. Arch vendor apps come from the AUR via `paru` and the `kewlfft.aur` collection, run as the normal user.

## Alternatives rejected
- **Flatpak-first** — no name mapping, but dev and integration friction.
- **Snap** — Ubuntu-centric, same sandbox issues.
- **Nix for GUI apps** — OpenGL/theming friction off NixOS.

## Consequences
Per-distro name mapping and vendor repo tasks are required. Moving an app between native and Flatpak is a one-line list change.
