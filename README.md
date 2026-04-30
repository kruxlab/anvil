# anvil

kruxlab's exe.dev base image. exeuntu plus zsh + tmux + a minimal CLI toolkit, with optional Tailscale auto-join.

## Use

```bash
ssh exe.dev new --image ghcr.io/kruxlab/anvil:latest --name foo
ssh foo.exe.xyz   # lands in zsh + tmux 'main'
```

## With Tailscale

### One-time tailnet setup

In your [tailnet policy](https://login.tailscale.com/admin/acls), add:

```jsonc
{
  "tagOwners": { "tag:exe": ["autogroup:admin"] },
  "acls": [
    {"action": "accept", "src": ["autogroup:member"], "dst": ["tag:exe:*"]}
  ],
  "ssh": [
    {
      "action": "accept",
      "src":    ["autogroup:member"],
      "dst":    ["tag:exe"],
      "users":  ["root", "autogroup:nonroot"]
    }
  ]
}
```

Then enable Serve once at https://login.tailscale.com/f/serve.

After that, every VM is zero-config.

### Per VM

Pass a reusable, pre-approved auth key tagged `tag:exe` via `--env TS_AUTHKEY`:

```bash
ssh exe.dev new --image ghcr.io/kruxlab/anvil:latest \
  --env TS_AUTHKEY=tskey-... \
  --name foo
```

On first boot, the VM joins your tailnet with:
- `--ssh` — Tailscale SSH (identity-based, governed by your ACLs)
- hostname matching the VM name

You can then SSH via Tailscale (`ssh foo` on any tailnet device) instead of the public exe.dev URL.

To re-up manually inside a VM:
```bash
TS_AUTHKEY=tskey-... tsup
```

## Expose a service to your tailnet

Inside the VM, after Tailscale is up:

```bash
serve-me 3000   # https://foo.tail-XXXX.ts.net/  ->  http://localhost:3000
```

- Real LE cert, no public exposure.
- Reachable from any tailnet device (Mac, phone with Tailscale app, etc.).
- Persists across reboots.

For multi-port or path-based mapping, use `tailscale serve` directly.

## What's in the image

On top of [exeuntu](https://github.com/boldsoftware/exeuntu):

- **Shell:** zsh, zsh-vi-mode, starship prompt, tmux (auto-attaches `main` on SSH)
- **Tools:** eza, fzf, bat, fd, zoxide, direnv, lazygit (via mise)
- **Networking:** Tailscale boot-time auto-up (when `TS_AUTHKEY` set), `tsup` and `serve-me` helpers
- **Configs:** dotfiles baked in at build time — no runtime bootstrap

No language runtimes are pre-installed. Add per-VM with `mise use -g node@lts` etc.

## Build & release

GitHub Actions builds and pushes to `ghcr.io/kruxlab/anvil:latest` on every push to `master`. After the first build, flip the GHCR package visibility to **public** so exe.dev can pull without auth.
