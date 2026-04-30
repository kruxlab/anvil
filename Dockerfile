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
# bake in the shell-experience CLIs (plus node@lts for opencode + npx-based MCPs).
RUN curl -fsSL https://mise.run | sh && \
    ~/.local/bin/mise use -g \
      node@lts \
      starship@latest \
      zoxide@latest \
      eza@latest \
      fzf@latest \
      bat@latest \
      fd@latest \
      direnv@latest \
      lazygit@latest

# opencode — AI coding agent. Config baked in below; opencode-zen auth
# flows in via OPENCODE_API_KEY env (passthrough'd by anvil-env.sh).
RUN ~/.local/bin/mise exec -- npm install -g opencode-ai && \
    ~/.local/bin/mise reshim

# zsh-vi-mode plugin (no apt package)
RUN git clone --depth 1 https://github.com/jeffreytse/zsh-vi-mode.git \
      /home/exedev/.zsh/zsh-vi-mode

# Shell + terminal configs
RUN mkdir -p /home/exedev/.config/tmux \
             /home/exedev/.config/git \
             /home/exedev/.config/starship \
             /home/exedev/.config/opencode
COPY --chown=exedev:exedev zshrc         /home/exedev/.zshrc
COPY --chown=exedev:exedev tmux.conf     /home/exedev/.config/tmux/tmux.conf
COPY --chown=exedev:exedev gitconfig     /home/exedev/.config/git/config
COPY --chown=exedev:exedev starship.toml /home/exedev/.config/starship/starship.toml
COPY --chown=exedev:exedev opencode.json /home/exedev/.config/opencode/opencode.json

# Default shell to zsh + Tailscale auto-up service
USER root
RUN chsh -s /usr/bin/zsh exedev

# github-mcp-server — official GitHub MCP. Reads GITHUB_PERSONAL_ACCESS_TOKEN
# from env; opencode.json maps that from {env:GITHUB_TOKEN} (passthrough'd by
# anvil-env.sh from `--env GITHUB_TOKEN=...` on `exe.dev new`).
RUN GH_MCP_VERSION=$(curl -fsSL https://api.github.com/repos/github/github-mcp-server/releases/latest \
      | sed -n 's/.*"tag_name": *"v\([^"]*\)".*/\1/p') && \
    curl -fsSL "https://github.com/github/github-mcp-server/releases/download/v${GH_MCP_VERSION}/github-mcp-server_Linux_x86_64.tar.gz" \
      | tar -xz -C /usr/local/bin github-mcp-server && \
    chmod +x /usr/local/bin/github-mcp-server

COPY tsup /usr/local/bin/tsup
COPY anvil-boot /usr/local/bin/anvil-boot
COPY anvil-tailscale.service /etc/systemd/system/anvil-tailscale.service
COPY anvil-env.sh /etc/profile.d/anvil-env.sh
RUN chmod +x /usr/local/bin/tsup /usr/local/bin/anvil-boot && \
    chmod 644 /etc/profile.d/anvil-env.sh && \
    mkdir -p /etc/zsh && touch /etc/zsh/zshenv && \
    echo '[ -f /etc/profile.d/anvil-env.sh ] && . /etc/profile.d/anvil-env.sh' \
      >> /etc/zsh/zshenv && \
    systemctl enable anvil-tailscale.service
USER exedev

# Inherit exeuntu's CMD/init — don't override.
