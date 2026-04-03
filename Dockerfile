FROM archlinux:base-devel
LABEL maintainer="nemanjan00 nemanjan00@gmail.com"

ARG UID=1000
ARG GID=1000

USER 0

# Install all system packages
RUN pacman -Syu --noconfirm \
    git base-devel curl \
    zsh \
    clang cmake \
    htop ripgrep eza fzf jq unzip \
    ctags \
    python-pynvim neovim \
    tmux \
    docker

# Create user with home at /work
RUN groupadd -g $GID user && \
    useradd -u $UID -g $GID -s /usr/bin/zsh -d /work user && \
    mkdir /work && \
    chown $UID:$GID /work
WORKDIR /work

# Install asdf version manager
USER $UID
ENV ASDF_DATA_DIR=/work/.asdf
RUN curl -fsSL https://github.com/asdf-vm/asdf/releases/download/v0.18.1/asdf-v0.18.1-linux-amd64.tar.gz | tar xz -C /tmp && \
    mkdir -p ~/.local/bin && \
    mv /tmp/asdf ~/.local/bin/asdf
ENV PATH="/work/.local/bin:/work/.asdf/shims:${PATH}"

# Install Node.js and Python via asdf
RUN asdf plugin add nodejs && asdf install nodejs latest && asdf set --home nodejs latest
RUN asdf plugin add python && asdf install python latest && asdf set --home python latest

# Disable cache
#ADD "https://www.random.org/cgi-bin/randbyte?nbytes=10&format=h" /tmp/skipcache

# Setup zsh and plugins
RUN git clone https://github.com/zplug/zplug.git ~/.zplug

COPY ./zplug /tmp/zplug
RUN patch ~/.zplug/base/core/add.zsh /tmp/zplug/patch/pipe_fix.diff

RUN git clone https://github.com/nemanjan00/zsh.git ~/.zsh
RUN echo "source ~/.zsh/index.zsh" > ~/.zshrc

RUN zsh -ic "TERM=xterm-256color ZPLUG_PIPE_FIX=true zplug install"

# Download my dotfiles
USER $UID
RUN git clone https://github.com/nemanjan00/vim.git ~/.config/nvim

# Install plug manager for vim
RUN curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

# Install plugins inside of vim
RUN nvim +PlugInstall +qall

# Coc
RUN ln -s ~/.config/nvim/coc ~/.config/coc
RUN cd ~/.config/coc/extensions && npm install

# Install .tmux
RUN git clone https://github.com/gpakosz/.tmux.git ~/.tmux
RUN ln -s -f .tmux/.tmux.conf ~/.tmux.conf
RUN cp ~/.tmux/.tmux.conf.local ~/

# Install Claude Code
RUN npm install -g @anthropic-ai/claude-code && \
    ln -sf "$(asdf which node)" /work/.local/bin/node && \
    ln -sf "$(asdf which npm)" /work/.local/bin/npm && \
    ln -sf "$(asdf which claude)" /work/.local/bin/claude
RUN mkdir -p ~/.claude
COPY templates/CLAUDE.md /work/.claude/CLAUDE.md

# Prepare work area
USER $UID
WORKDIR /work

CMD ["tmux"]

