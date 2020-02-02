FROM archlinux/base
MAINTAINER nemanjan00 nemanjan00@gmail.com

# Install dependencies for building stuff
RUN pacman -Syu --noconfirm git base-devel curl

# Install shell
RUN pacman -Syu --noconfirm zsh
RUN chsh -s /usr/bin/zsh root

RUN git clone https://github.com/zplug/zplug.git ~/.zplug
RUN git clone https://github.com/nemanjan00/zsh.git ~/.zsh
RUN echo "source ~/.zsh/index.zsh" > ~/.zshrc

RUN zsh -c "source ~/.zshrc ; TERM=xterm-256color zplug install"

# Install langage version manager
RUN git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.7.6
RUN echo -e '\n. $HOME/.asdf/asdf.sh' >> ~/.zshrc
RUN echo -e '\n. $HOME/.asdf/completions/asdf.bash' >> ~/.zshrc

# Install node
RUN pacman -Syu --noconfirm nodejs yarn

# Install neovim stuff
RUN pacman -Syu --noconfirm python-pynvim neovim

# Download my dotfiles
RUN git clone https://github.com/nemanjan00/vim.git ~/.config/nvim

# Install plug manager for vim
RUN curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

# Install plugins inside of vim
RUN nvim +PlugInstall +q +q

# Coc
RUN ln -s ~/.config/nvim/coc ~/.config/coc
RUN zsh -c "cd ~/.config/coc/extensions ; yarn"

# Install tmux stuff
RUN pacman -Syu --noconfirm tmux

# Prepare work area
RUN mkdir /work

WORKDIR /work

CMD ["tmux"]

