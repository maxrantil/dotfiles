# ABOUTME: Docker test environment for dotfiles validation (fresh Ubuntu machine)
FROM ubuntu:24.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive
ENV TERM=xterm-256color

# Core dependencies (what a fresh server gets before cloning the dotfiles)
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    zsh \
    tmux \
    neovim \
    fzf \
    && rm -rf /var/lib/apt/lists/*

# Starship from a pinned release, verified against its published checksum
# (instead of piping an unpinned install script into sh)
ARG STARSHIP_VERSION=1.27.0
ARG STARSHIP_SHA256=10c8eb4cb3b761d9bf59ea828444c2dab36c900b7d69a69e08814b286969df89
RUN curl -fsSLo /tmp/starship.tgz \
    "https://github.com/starship/starship/releases/download/v${STARSHIP_VERSION}/starship-x86_64-unknown-linux-musl.tar.gz" \
    && echo "${STARSHIP_SHA256}  /tmp/starship.tgz" | sha256sum -c - \
    && tar -xzf /tmp/starship.tgz -C /usr/local/bin starship \
    && rm /tmp/starship.tgz \
    && starship --version

# Non-root test user (mirrors production; exercises safe_source ownership checks)
RUN useradd -m -s /bin/zsh testuser
USER testuser
WORKDIR /home/testuser

COPY --chown=testuser:testuser . /home/testuser/.dotfiles

# The documented one-command install
RUN /home/testuser/.dotfiles/install.sh

CMD ["zsh", "-i"]
