# anvil

kruxlab's [exe.dev](https://exe.dev) base image. exeuntu plus zsh + tmux + a minimal CLI toolkit and Tailscale auto-join. Built so that spinning up a VM is one command and SSHing in feels like home.

## Quick start

```bash
ssh exe.dev new --image ghcr.io/kruxlab/anvil:latest \
  --env TS_AUTHKEY=tskey-... \
  --name foo
```

Then from any device on your tailnet:

```bash
ssh exedev@foo                    # Tailscale SSH, no browser tap
```

Inside the VM, expose a service to your tailnet over HTTPS:

```bash
serve-me 3000                     # https://foo.<ts-net>.ts.net/  →  localhost:3000
```

That's the steady state. The setup below only happens once.

## One-time setup

### Tailnet policy

Open [tailscale admin → Access Controls](https://login.tailscale.com/admin/acls) and merge the following blocks:

```jsonc
{
  "tagOwners": {
    "tag:exe": ["autogroup:admin"]
  },

  "acls": [
    // members can reach all ports on tag:exe nodes (HTTP, SSH, etc.)
    {"action": "accept", "src": ["autogroup:member"], "dst": ["tag:exe:*"]}
  ],

  "ssh": [
    // accept = no browser confirmation; check = browser confirmation
    {
      "action": "accept",
      "src":    ["autogroup:member"],
      "dst":    ["tag:exe"],
      "users":  ["root", "autogroup:nonroot"]
    }
  ]
}
```

### Enable Tailscale Serve

Click once: <https://login.tailscale.com/f/serve>. Survives forever, every node can use Serve.

### Generate an auth key

[tailscale admin → Keys → Generate auth key](https://login.tailscale.com/admin/settings/keys):

- ✓ **Reusable**
- ✓ **Ephemeral** *(critical — deleted VMs auto-deregister, no stale node pile-up)*
- ✓ **Pre-approved**
- Tag: `tag:exe`

Save it somewhere; pass via `--env TS_AUTHKEY=...` on every `new`.

## What's in the image

On top of [exeuntu](https://github.com/boldsoftware/exeuntu):

- **Shell:** zsh as the default shell, zsh-vi-mode, starship prompt, OSC52 clipboard
- **tmux:** auto-attaches to a `main` session on every interactive SSH login
- **Tools (via mise):** eza, fzf, bat, fd, zoxide, direnv, lazygit
- **Networking:**
  - `anvil-boot` runs at first boot, fetches latest `tsup` from this repo, executes it
  - `tsup` joins the tailnet (`--ssh`, `--accept-routes`, operator = exedev)
  - `serve-me <port>` exposes a local port at `https://<vm>.<ts-net>.ts.net/`
- **Dotfiles:** baked into the image — `~/.zshrc`, `tmux.conf`, `gitconfig`, `starship.toml`

No language runtimes are pre-installed. Add per-VM as needed: `mise use -g node@lts python@3 …`.

## Image caching note

exe.dev caches the `:latest` tag per-org. After publishing a new image, you may need to use a SHA tag **once** (e.g. `ghcr.io/kruxlab/anvil:sha-XXXXXXX`) to force a pull. From then on, the cached image's `anvil-boot` fetches `tsup` fresh from GitHub master on every reboot, so future `tsup` fixes don't require a re-pull.

Image-baked changes (zshrc, configs, the boot wrapper itself) still need a tag bump. `tsup` changes flow through automatically.

## Build & release

GitHub Actions builds and pushes to `ghcr.io/kruxlab/anvil:latest` and `:sha-<short>` on every push to `master`. The package is public.

To rebuild manually:

```bash
gh workflow run build --repo kruxlab/anvil
```
