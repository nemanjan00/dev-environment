FROM archlinux/base
MAINTAINER nemanjan00 nemanjan00@gmail.com

# Install dependencies for building stuff
RUN pacman -Syu --noconfirm git base-devel curl

# Install shell
RUN pacman -Syu --noconfirm zsh
RUN chsh -s /usr/bin/zsh root
RUN git clone https://github.com/nemanjan00/zsh.git ~/.zsh
RUN echo "source ~/.zsh/index.zsh" > ~/.zshrc

# Install node
RUN pacman -Syu --noconfirm nodejs yarn

# Install neovim stuff
RUN pacman -Syu --noconfirm python-pynvim neovim

# Download my dotfiles
RUN git clone https://github.com/nemanjan00/vim.git ~/.config/nvim

# Install plug
RUN curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

# Install plugins
RUN nvim +PlugInstall +q +q

# Install tmux stuff
RUN pacman -Syu --noconfirm tmux

# Prepare work area
RUN mkdir /work

WORKDIR /work

