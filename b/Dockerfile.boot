FROM defn/home:sshd

ARG HOMEDIR
ARG DOTFILES
ARG HOMEBOOT

USER root

ENV HOME=/root
ENV DEBIAN_FRONTEND=noninteractive
ENV container docker

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
        docker.io \
    && rm -f /usr/bin/gs


RUN install -d -o $HOMEBOOT -d $HOMEBOOT /home/linuxbrew

USER $HOMEBOOT
WORKDIR /home/$HOMEBOOT
ENV HOME=/home/$HOMEBOOT

ENV PATH=/home/linuxbrew/.linuxbrew/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

COPY .linuxbrew /tmp/.linuxbrew

RUN git clone --depth 1 https://github.com/Homebrew/brew /home/linuxbrew/.linuxbrew \
    && git clone --depth 100 https://github.com/Homebrew/linuxbrew-core /home/linuxbrew/.linuxbrew/Library/Taps/homebrew/homebrew-core

RUN env HOMEBREW_NO_AUTO_UPDATE=1 brew list

RUN env HOMEBREW_NO_AUTO_UPDATE=1 brew tap linuxbrew/xorg

RUN env HOMEBREW_NO_AUTO_UPDATE=1 brew bundle --help

RUN sudo ln -nfs locale.h /usr/include/xlocale.h && env HOMEBREW_NO_AUTO_UPDATE=1 brew install perl

ENV PATH=/home/$HOMEBOOT/.asdf/bin:/home/$HOMEBOOT/.asdf/shims:/home/linuxbrew/.linuxbrew/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

RUN git clone $HOMEDIR homedir \
    && mv homedir/.git . \
    && rm -rf homedir \
    && git reset --hard

RUN echo "$DOTFILES" > .dotfiles-repo

RUN env HOMEBREW_NO_AUTO_UPDATE=1 brew upgrade

RUN echo 1 && make update && make upgrade

RUN sudo apt-get update && sudo apt-get install -y libudev-dev

RUN make install || true

RUN $HOME/env make install

RUN go get github.com/klauspost/asmfmt/cmd/asmfmt@master
RUN go get github.com/go-delve/delve/cmd/dlv@master
RUN go get github.com/kisielk/errcheck@master
RUN go get github.com/davidrjenni/reftools/cmd/fillstruct@master
RUN go get github.com/rogpeppe/godef@master
RUN go get golang.org/x/tools/cmd/goimports@master
RUN go get golang.org/x/lint/golint@master
RUN go get github.com/golangci/golangci-lint/cmd/golangci-lint@master
RUN go get github.com/fatih/gomodifytags@master
RUN go get golang.org/x/tools/cmd/gorename@master
RUN go get github.com/jstemmer/gotags@master
RUN go get golang.org/x/tools/cmd/guru@master
RUN go get github.com/josharian/impl@master
RUN go get honnef.co/go/tools/cmd/keyify@master
RUN go get github.com/fatih/motion@master
RUN go get github.com/koron/iferr@master
RUN go get golang.org/x/tools/gopls@latest || true

COPY .bump /tmp/.bump
RUN make update && make upgrade && make install && brew upgrade
RUN sudo apt-get update && sudo apt-get upgrade -y

RUN curl -O -sSL "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o "session-manager-plugin.deb" \
    && sudo dpkg -i session-manager-plugin.deb \
    && rm -f session-manager-plugin.deb

RUN curl -O -sSL "https://bin.equinox.io/c/VdrWdbjqyF/cloudflared-stable-linux-amd64.deb" \
    && sudo dpkg -i cloudflared-stable-linux-amd64.deb \
    && rm -f cloudflared-stable-linux-amd64.deb

