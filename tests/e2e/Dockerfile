FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV SHELL=/bin/zsh

# 1. Install minimal bootstrap dependencies
RUN apt-get update && apt-get install -y \
    sudo git make curl zsh python3 python3-pip python3-venv build-essential && \
    rm -rf /var/lib/apt/lists/*

# 2. Setup Test User
RUN useradd -ms /bin/zsh testuser && echo "testuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
USER testuser
WORKDIR /home/testuser

# 3. Clean up default bash files to avoid stow conflicts
RUN rm -rf .bashrc .bash_logout .profile

# 4. Copy current dotfiles into the container
COPY --chown=testuser:testuser . /home/testuser/.dotfiles

# 5. Truly E2E: Run the pinned installation via Makefile
# We enable full pyenv installation to test the complete logic
RUN cd /home/testuser/.dotfiles && \
    make setup

# 6. Pre-cache plugins (Zinit & LazyVim)
# We use a non-interactive shell but source the RC to trigger downloads
RUN zsh -c "source ~/.zshrc; exit" || true
# Headless Neovim sync (LazyVim) - using our pinned version installed by make
RUN nvim --headless "+Lazy! sync" +qa || true

# 7. Provide Linux-compatible mocks for macOS-only binaries referenced in configs
RUN mkdir -p /home/testuser/bin && \
    echo '#!/bin/bash\necho "Linux Mock: blueutil not available"' > /home/testuser/bin/blueutil && \
    echo '#!/bin/bash\necho "Linux Mock: SwitchAudioSource not available"' > /home/testuser/bin/SwitchAudioSource && \
    chmod +x /home/testuser/bin/blueutil /home/testuser/bin/SwitchAudioSource

ENV PATH="/home/testuser/bin:${PATH}"

# 8. Configure Git for tests
RUN git config --global user.email "test@example.com" && \
    git config --global user.name "Test User" && \
    git config --global init.defaultBranch main

# 9. Execute the E2E Test Suite
CMD ["python3", "/home/testuser/.dotfiles/tests/e2e/test_suite.py"]
