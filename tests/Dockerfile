# ABOUTME: Docker test environment for dotfiles validation
FROM ubuntu:24.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive
ENV TERM=xterm-256color

# Install core dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    zsh \
    tmux \
    neovim \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install Starship (required for Issue #7 testing)
RUN curl -sS https://starship.rs/install.sh | sh -s -- -y

# Create test user (mirrors production setup)
RUN useradd -m -s /bin/zsh testuser

# Switch to test user
USER testuser
WORKDIR /home/testuser

# Copy dotfiles to container
COPY --chown=testuser:testuser . /home/testuser/.dotfiles

# Run installation script
RUN cd /home/testuser/.dotfiles && ./install.sh

# Set default command to zsh
CMD ["zsh", "-i"]
