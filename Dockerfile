FROM archlinux/base
MAINTAINER nemanjan00 nemanjan00@gmail.com

USER 0

# Install dependencies for building stuff
RUN pacman -Syu --noconfirm git base-devel curl

# Install shell
RUN pacman -Syu --noconfirm zsh

# Create user
RUN groupadd -g 1000 user
RUN useradd -r -u 1000 -g 1000 -s /usr/bin/zsh user
RUN usermod -d /work -m user

# Cmake
RUN pacman -Syu --noconfirm clang cmake

# Prepare home for user
RUN mkdir /work
RUN chown 1000:1000 /work
WORKDIR /work

USER 1000

# Cquery
RUN git clone https://aur.archlinux.org/cquery.git /tmp/cquery
WORKDIR /tmp/cquery
RUN makepkg
USER 0

RUN pacman -U --noconfirm ./*.pkg.*

# Install node
USER 0
RUN pacman -Syu --noconfirm nodejs yarn

# Add some common stuff
RUN pacman -Syu --noconfirm htop the_silver_searcher fzf jq

# Ctags
RUN pacman -Syu --noconfirm ctags

# Install neovim stuff
RUN pacman -Syu --noconfirm python-pynvim neovim

# Install tmux stuff
RUN pacman -Syu --noconfirm tmux

# Install language version manager
USER 1000
RUN git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.7.6
RUN echo -e '\n. $HOME/.asdf/asdf.sh' >> ~/.zshrc
RUN echo -e '\n. $HOME/.asdf/completions/asdf.bash' >> ~/.zshrc

# Disable cache
ADD "https://www.random.org/cgi-bin/randbyte?nbytes=10&format=h" /tmp/skipcache

# Setup zsh and plugins
RUN git clone https://github.com/zplug/zplug.git ~/.zplug
RUN git clone https://github.com/nemanjan00/zsh.git ~/.zsh
RUN echo "source ~/.zsh/index.zsh" > ~/.zshrc

COPY ./zplug /tmp/zplug
RUN patch ~/.zplug/base/core/add.zsh /tmp/zplug/patch/pipe_fix.diff

RUN zsh -ic "TERM=xterm-256color ZPLUG_PIPE_FIX=true zplug install"

# Download my dotfiles
USER 1000
RUN git clone https://github.com/nemanjan00/vim.git ~/.config/nvim

# Install plug manager for vim
RUN curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

# Install plugins inside of vim
RUN nvim +PlugInstall +q +q

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

