FROM archlinux:base-devel
LABEL maintainer="nemanjan00 nemanjan00@gmail.com"

ARG UID=1000
ARG GID=1000

USER 0

# Install all system packages
RUN pacman -Syu --noconfirm \
    git base-devel curl wget \
    zsh \
    clang cmake \
    htop ripgrep the_silver_searcher eza fzf jq jc \
    zip unzip 7zip unrar zstd \
    ctags strace tree xxd file \
    diffutils patch \
    man-db man-pages \
    python-pynvim neovim \
    tmux \
    docker \
    miller socat

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
RUN asdf plugin add python && asdf install python 3.14.4 && asdf set --home python 3.14.4

# Python libraries available to scripts via asdf Python
RUN pip install --no-cache-dir curl_cffi && \
    asdf reshim python && \
    ln -sf "$(asdf which curl-cffi)" /work/.local/bin/curl-cffi

# Disable cache
#ADD "https://www.random.org/cgi-bin/randbyte?nbytes=10&format=h" /tmp/skipcache

# Setup zsh and plugins
RUN git clone https://github.com/zplug/zplug.git ~/.zplug

COPY ./zplug /tmp/zplug
RUN patch ~/.zplug/base/core/add.zsh /tmp/zplug/patch/pipe_fix.diff

RUN git clone https://github.com/nemanjan00/zsh.git ~/.zsh
RUN echo "source ~/.zsh/index.zsh" > ~/.zshrc

RUN timeout 30 zsh -ic "TERM=xterm-256color ZPLUG_PIPE_FIX=true zplug install"

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

# Install Claude Code, muxmcp (stdio MCP multiplexer), and shell-session-mcp
# (PTY-backed interactive sessions; node-pty needs base-devel + python — both present)
RUN npm install -g @anthropic-ai/claude-code muxmcp shell-session-mcp && \
    ln -sf "$(asdf which node)" /work/.local/bin/node && \
    ln -sf "$(asdf which claude)" /work/.local/bin/claude && \
    ln -sf "$(asdf which muxmcp)" /work/.local/bin/muxmcp && \
    ln -sf "$(asdf which shell-session-mcp)" /work/.local/bin/shell-session-mcp
RUN mkdir -p ~/.claude ~/.config/claude/mcp.d
COPY --chown=$UID:$GID templates/CLAUDE.md /work/CLAUDE.md
COPY --chown=$UID:$GID templates/mcp.d/ /work/.config/claude/mcp.d/

# Prepare work area
USER $UID
WORKDIR /work

CMD ["tmux"]

