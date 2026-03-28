FROM archlinux:base-devel
LABEL maintainer="nemanjan00 nemanjan00@gmail.com"

USER 0

# Install all system packages
RUN pacman -Syu --noconfirm \
    git base-devel curl \
    zsh \
    clang cmake \
    htop ripgrep fzf jq \
    ctags \
    python-pynvim neovim \
    tmux

# Create user with home at /work
RUN groupadd -g 1000 user && \
    useradd -u 1000 -g 1000 -s /usr/bin/zsh -d /work user && \
    mkdir /work && \
    chown 1000:1000 /work
WORKDIR /work

# Install asdf version manager
USER 1000
ENV ASDF_DATA_DIR=/work/.asdf
RUN curl -fsSL https://github.com/asdf-vm/asdf/releases/download/v0.18.1/asdf-v0.18.1-linux-amd64.tar.gz | tar xz -C /tmp && \
    mkdir -p ~/.local/bin && \
    mv /tmp/asdf ~/.local/bin/asdf
ENV PATH="/work/.local/bin:/work/.asdf/shims:${PATH}"

# Install Node.js via asdf
RUN asdf plugin add nodejs && asdf install nodejs latest && asdf set --home nodejs latest

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
USER 1000
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
RUN npm install -g @anthropic-ai/claude-code
RUN mkdir -p ~/.claude
COPY templates/CLAUDE.md /work/.claude/CLAUDE.md

# Prepare work area
USER 1000
WORKDIR /work

CMD ["tmux"]

