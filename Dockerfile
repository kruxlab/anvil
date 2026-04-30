# anvil — kruxlab's exe.dev base image.
# FROM exeuntu, plus zsh/tmux + a minimal CLI toolkit baked in.

FROM ghcr.io/boldsoftware/exeuntu:latest

# zsh + tmux are not in exeuntu. Other tools (ripgrep, git, gh,
# build-essential, ca-certificates, curl, unzip) already are.
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      zsh tmux && \
    rm -rf /var/lib/apt/lists/*

USER exedev
WORKDIR /home/exedev

# mise — runtime/tool manager. Tools install per-VM as needed; we only
# bake in the shell-experience CLIs.
RUN curl -fsSL https://mise.run | sh && \
    ~/.local/bin/mise use -g \
      starship@latest \
      zoxide@latest \
      eza@latest \
      fzf@latest \
      bat@latest \
      fd@latest \
      direnv@latest \
      lazygit@latest

# zsh-vi-mode plugin (no apt package)
RUN git clone --depth 1 https://github.com/jeffreytse/zsh-vi-mode.git \
      /home/exedev/.zsh/zsh-vi-mode

# Shell + terminal configs
RUN mkdir -p /home/exedev/.config/tmux \
             /home/exedev/.config/git \
             /home/exedev/.config/starship
COPY --chown=exedev:exedev zshrc         /home/exedev/.zshrc
COPY --chown=exedev:exedev tmux.conf     /home/exedev/.config/tmux/tmux.conf
COPY --chown=exedev:exedev gitconfig     /home/exedev/.config/git/config
COPY --chown=exedev:exedev starship.toml /home/exedev/.config/starship/starship.toml

# Default shell to zsh + Tailscale auto-up service
USER root
RUN chsh -s /usr/bin/zsh exedev
COPY tsup /usr/local/bin/tsup
COPY anvil-tailscale.service /etc/systemd/system/anvil-tailscale.service
RUN chmod +x /usr/local/bin/tsup && \
    systemctl enable anvil-tailscale.service
USER exedev

# Inherit exeuntu's CMD/init — don't override.
