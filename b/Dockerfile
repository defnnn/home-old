FROM letfn/python:latest

ARG HOMEDIR
ARG DOTFILES
ARG HOMEUSER

USER root

ENV HOME=/root
ENV DEBIAN_FRONTEND=noninteractive
ENV container docker

COPY .reset /tmp/.reset

RUN dpkg-divert --local --rename --add /sbin/udevadm && ln -s /bin/true /sbin/udevadm

COPY cache /cache

RUN if test -f /cache/.pip/pip.conf; then set -x; apt update; apt install -y ca-certificates; sed 's#http://deb.debian.org/debian#https://nexus.defn.sh/repository/debian#; s#http://security.debian.org/debian-security#https://nexus.defn.sh/repository/debian-security#' -i /etc/apt/sources.list; fi

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
        openssh-server tzdata locales iputils-ping iproute2 net-tools dnsutils curl wget unzip jq xz-utils \
        sudo git vim less \
        build-essential m4 make \
        libssl-dev zlib1g-dev libbz2-dev libsqlite3-dev libncurses5-dev libncursesw5-dev libffi-dev liblzma-dev libreadline-dev \
        docker.io docker-compose sshfs libusb-1.0-0 \
    && rm -f /usr/bin/gs

RUN useradd -m -s /bin/bash $HOMEUSER

RUN echo "$HOMEUSER ALL=(ALL) NOPASSWD: ALL" | tee -a /etc/sudoers

RUN echo TrustedUserCAKeys /efs/ssh/trusted-user-ca-keys.pem | tee -a /etc/ssh/sshd_config
RUN echo GatewayPorts yes >> /etc/ssh/sshd_config

RUN ln -sf /usr/share/zoneinfo/UTC /etc/localtime \
    && dpkg-reconfigure -f noninteractive tzdata \
    && locale-gen en_US.UTF-8 \
    && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8

RUN install -d -o $HOMEUSER -d $HOMEUSER /home/linuxbrew

USER $HOMEUSER
WORKDIR /home/$HOMEUSER

ENV HOME=/home/$HOMEUSER
ENV PATH=/home/linuxbrew/.linuxbrew/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

COPY .linuxbrew /tmp/.linuxbrew

RUN git clone --depth 1 https://github.com/Homebrew/brew /home/linuxbrew/.linuxbrew \
    && git clone --depth 100 https://github.com/Homebrew/linuxbrew-core /home/linuxbrew/.linuxbrew/Library/Taps/homebrew/homebrew-core \
    && cd /home/linuxbrew/.linuxbrew/Library/Taps/homebrew/homebrew-core \
    && git reset --hard ff972618ce70bc7b0906913d3ad62b3615172e80

RUN env HOMEBREW_NO_AUTO_UPDATE=1 brew list

RUN env HOMEBREW_NO_AUTO_UPDATE=1 brew tap linuxbrew/xorg

RUN env HOMEBREW_NO_AUTO_UPDATE=1 brew bundle --help

RUN env HOMEBREW_NO_AUTO_UPDATE=1 brew install perl

ENV PATH=/home/$HOMEUSER/.asdf/bin:/home/$HOMEUSER/.asdf/shims:/home/linuxbrew/.linuxbrew/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

RUN git clone $HOMEDIR homedir \
    && mv homedir/.git . \
    && rm -rf homedir \
    && git reset --hard

RUN echo "$DOTFILES" > .dotfiles-repo

RUN env HOMEBREW_NO_AUTO_UPDATE=1 brew upgrade

RUN make update && make upgrade

RUN sudo apt-get install -y libudev-dev

RUN make install || true

RUN $HOME/env make install

RUN go mod init github.com/defn/home
RUN go get github.com/klauspost/asmfmt/cmd/asmfmt@master
RUN go get github.com/go-delve/delve/cmd/dlv@master
RUN go get github.com/kisielk/errcheck@master
RUN go get github.com/davidrjenni/reftools/cmd/fillstruct@master
RUN go get github.com/rogpeppe/godef@master
RUN go get golang.org/x/tools/cmd/goimports@master
RUN go get golang.org/x/lint/golint@master
RUN go get golang.org/x/tools/gopls@latest
RUN go get github.com/golangci/golangci-lint/cmd/golangci-lint@master
RUN go get github.com/fatih/gomodifytags@master
RUN go get golang.org/x/tools/cmd/gorename@master
RUN go get github.com/jstemmer/gotags@master
RUN go get golang.org/x/tools/cmd/guru@master
RUN go get github.com/josharian/impl@master
RUN go get honnef.co/go/tools/cmd/keyify@master
RUN go get github.com/fatih/motion@master
RUN go get github.com/koron/iferr@master

COPY .bump /tmp/.bump

RUN make update && make upgrade && make install && brew upgrade

RUN rm -f /home/linuxbrew/.linuxbrew/bin/gs

COPY service /service
RUN sudo chmod 755 /service

RUN sudo apt-get update && sudo apt-get upgrade -y

RUN sudo mkdir -p /run/sshd /run && sudo chown -R $HOMEUSER:$HOMEUSER /run /etc/ssh
