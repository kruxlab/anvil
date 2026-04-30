# anvil

kruxlab's exe.dev base image. exeuntu plus zsh + tmux + a minimal CLI toolkit.

## Use

```bash
ssh exe.dev new --image ghcr.io/kruxlab/anvil:latest --name foo
ssh foo.exe.xyz   # lands in zsh + tmux 'main'
```

## What's in the image

On top of [exeuntu](https://github.com/boldsoftware/exeuntu):

- **Shell:** zsh, zsh-vi-mode, starship prompt, tmux (auto-attaches `main` on SSH)
- **Tools:** eza, fzf, bat, fd, zoxide, direnv, lazygit (via mise)
- **Configs:** dotfiles baked in at build time — no runtime bootstrap

No language runtimes are pre-installed. Add per-VM with `mise use -g node@lts` etc.

## Build & release

GitHub Actions builds and pushes to `ghcr.io/kruxlab/anvil:latest` on every push to `master`. After the first build, flip the GHCR package visibility to **public** in the repo's package settings so exe.dev can pull without auth.
