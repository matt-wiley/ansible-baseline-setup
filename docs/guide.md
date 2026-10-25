# Usage guide

How to run, verify and change this repo. Terms such as Bootstrap, Phase 1 and manual gate are defined in [CONTEXT.md](../CONTEXT.md).

## What you get

After the Bootstrap and Phase 1, the machine has:

- the apps in `vars/apps.yml` (zsh, git, curl, zoxide, openssh-server, 1Password, Librewolf), installed natively
- zsh as your login shell
- mise, with shims on `PATH` for GUI-launched apps
- sshd, hardened (no password or root login), accepting the public keys from `https://github.com/<github_user>.keys`
- Librewolf as the default browser (the launcher is read from the installed package), with Firefox Accounts enabled, and 1Password allowed to talk to it

See the [decision records](adr/) for why each choice was made.

## Quick start

On a fresh install, as your normal user, in an interactive terminal:

```bash
curl -fsSL https://raw.githubusercontent.com/matt-wiley/ansible-baseline-setup/main/bootstrap.sh | bash
```

The Bootstrap:

1. Detects the OS family from `/etc/os-release` (Debian, RedHat or Archlinux).
2. Installs `git` and `ansible`, and nothing else.
3. On Ubuntu with `sudo-rs`, switches to classic sudo, because Ansible cannot escalate through `sudo-rs`.
4. Clones this repo over HTTPS to `~/ansible-baseline-setup`, or fast-forwards an existing checkout.
5. Installs the Ansible collections in `requirements.yml`.
6. Runs `phase1.yml` and prints the manual steps.

You get one sudo password prompt (`-K`). Phase 1 needs no credentials and no sign-in.

### Overrides

Set these in the environment before running the script:

| Variable | Default | Meaning |
|---|---|---|
| `REPO_OWNER` | `matt-wiley` | GitHub account used to build `SETUP_REPO` |
| `SETUP_REPO` | `https://github.com/$REPO_OWNER/ansible-baseline-setup.git` | Repo to clone |
| `SETUP_BRANCH` | `main` | Branch to check out |
| `SETUP_DIR` | `~/ansible-baseline-setup` | Where to clone |

## The manual gate

Phase 1 cannot do these. The Bootstrap prints them when it finishes:

1. Open 1Password and sign in. Turn on the SSH agent under Settings > Developer. Turn on the browser integration under Settings > Browser if it is off.
2. Open Librewolf and sign in to your Firefox account. Firefox Accounts is already enabled, so no restart is needed. The 1Password extension should then find the app and log in on its own.

Phase 2, which needs the SSH agent and sign-in, is not built yet.

## Verify

`verify.yml` is read-only. It checks packages, login shell, mise, sudo, sshd hardening, `authorized_keys` against GitHub, the 1Password and Librewolf wiring, and the Firefox Accounts setting. It reports the 1Password SSH agent socket separately, since that depends on the manual gate.

```bash
ansible-playbook -i localhost, -c local ~/ansible-baseline-setup/verify.yml -K
```

It exits non-zero if any check fails. `-K` is needed for one check that reads sshd's effective config as root.

To confirm Phase 1 is idempotent, run it a second time. The recap should show `changed=0`.

## Running Phase 1 by hand

If the repo is already cloned:

```bash
cd ~/ansible-baseline-setup
ansible-galaxy collection install -r requirements.yml
ansible-playbook -i localhost, -c local phase1.yml -K
```

Note the trailing comma after `localhost`. Without it Ansible reads the argument as an inventory file.

## Changing the setup

- **Add an app:** follow [apps.md](apps.md). Most apps are one line in `vars/apps.yml`.
- **Runtimes and CLI tools:** add them to `mise_tools` in `vars/apps.yml`, not to the app matrix.
- **Different GitHub keys for SSH:** change `github_user` in `vars/main.yml`.
- **Anything private** (keys, tokens, passwords) stays out of this repo, which is public.

## Developing and testing

Use VM snapshots so every test starts clean.

- **Base snapshot:** pristine install. Revert to it and run the real `curl | bash` Bootstrap to test the whole path.
- **Dev snapshot:** the base plus `openssh-server` and your key, so you can run the playbook from your host while iterating.

To make the dev snapshot, install and start `openssh-server` in the VM, copy your host key in, then shut down and snapshot:

```bash
ssh-copy-id <vm-user>@<vm-ip>
```

Then run from the host. Keep the comma after the address:

```bash
ansible-playbook -i <vm-ip>, -u <vm-user> phase1.yml -K
```

Things that catch people:

- **Key wipe:** Phase 1 writes `authorized_keys` from GitHub with `exclusive: true`. A key that is not on your GitHub account is removed. Use a key that is, or you will lose SSH access to the VM after the run.
- **Missing keys stop the run:** if GitHub returns no keys, Phase 1 stops before it disables password login.
- **Test other families** in their own VMs when a row in the app matrix has per-family values.

## Troubleshooting

| Symptom | Cause and fix |
|---|---|
| `Timeout waiting for privilege escalation prompt` | The system uses `sudo-rs`. The Bootstrap switches to classic sudo. For a dev-snapshot run, do it by hand: `sudo apt install sudo`, then `sudo update-alternatives --set sudo /usr/bin/sudo.ws`. |
| `Unable to parse ... as an inventory source` | Missing trailing comma in `-i <host>,`. |
| `no terminal available for the sudo prompt` | Run from an interactive shell. Over SSH, use `ssh -t`. |
| `run as your normal user, not root` | Run as the regular user. Phase 1 escalates with sudo where needed. |
| `deb822_repository` fails on Debian 12 | It needs ansible-core 2.15 or newer, and Debian 12 ships 2.14. Debian 13 and Ubuntu 26.04 are fine. |
| `Refuse to continue without keys` | `https://github.com/<github_user>.keys` returned nothing. Check `github_user` and the network. |
| 1Password manifest task fails | The package lists neither a native messaging manifest nor `1Password-BrowserSupport`. Check what the package installed with `dpkg -L 1password`. |

## Limits

- Convergent, not reproducible: removing an item from a list does not uninstall it, and there is no rollback.
- Needs network at run time, for packages, vendor repos and the GitHub key list.
- WAN access (Tailscale and similar) is out of scope for now.
