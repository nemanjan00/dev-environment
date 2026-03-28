FROM archlinux:base-devel
LABEL maintainer="nemanjan00 nemanjan00@gmail.com"

USER 0

# Install all system packages
RUN pacman -Syu --noconfirm \
    git base-devel curl \
    zsh \
    clang cmake \
    nodejs yarn \
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

# Install language version manager
USER 1000
RUN git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.7.6
RUN echo -e '\n. $HOME/.asdf/asdf.sh' >> ~/.zshrc
RUN echo -e '\n. $HOME/.asdf/completions/asdf.bash' >> ~/.zshrc

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
RUN zsh -c "cd ~/.config/coc/extensions ; yarn"

# Install .tmux
RUN git clone https://github.com/gpakosz/.tmux.git ~/.tmux
RUN ln -s -f .tmux/.tmux.conf ~/.tmux.conf
RUN cp ~/.tmux/.tmux.conf.local ~/

# Prepare work area
USER 1000
WORKDIR /work

CMD ["tmux"]

