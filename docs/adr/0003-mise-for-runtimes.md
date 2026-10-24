# ADR 0003: mise manages language runtimes and CLI tools

**Status:** Accepted

## Context
nvm, pyenv, jenv etc. each need separate setup; distro package names for CLI tools differ.

## Decision
Ansible installs mise. A global mise config declares runtimes and distro-independent CLI tools. Shims are activated in `~/.profile` so GUI-launched IDEs see them. Python projects use a mise-created per-project `.venv`.

## Alternatives rejected
- **nvm/pyenv/jenv** — one tool per language, inconsistent IDE integration.
- **Homebrew on Linux** — fine for CLI tools, doesn't replace version managers.
- **Nix devshells** — deferred with Home Manager.

## Consequences
One-time migration from nvm/pyenv (remove their shell init, reinstall globals). Versioned interpreter paths still exist; `.venv` keeps IDEs insulated.
