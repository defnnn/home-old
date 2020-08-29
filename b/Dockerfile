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
    && git clone --depth 1 https://github.com/Homebrew/linuxbrew-core /home/linuxbrew/.linuxbrew/Library/Taps/homebrew/homebrew-core

RUN brew list && sudo chown -vhR $HOMEUSER:$HOMEUSER /home/linuxbrew | grep -v retained

RUN brew tap linuxbrew/xorg && sudo chown -vhR $HOMEUSER:$HOMEUSER /home/linuxbrew | grep -v retained

RUN brew bundle --help && sudo chown -vhR $HOMEUSER:$HOMEUSER /home/linuxbrew | grep -v retained

RUN brew install perl -s && sudo chown -vhR $HOMEUSER:$HOMEUSER /home/linuxbrew | grep -v retained

ENV PATH=/home/$HOMEUSER/.asdf/bin:/home/$HOMEUSER/.asdf/shims:/home/linuxbrew/.linuxbrew/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

COPY .homedir /tmp/.homedir

RUN git clone $HOMEDIR homedir \
    && mv homedir/.git . \
    && rm -rf homedir \
    && git reset --hard

RUN echo "$DOTFILES" > .dotfiles-repo

RUN sudo chown -vhR $HOMEUSER:$HOMEUSER /home/linuxbrew | grep -v retained

RUN brew upgrade

RUN make update && make upgrade

RUN $HOME/env make install

RUN sudo apt-get update && sudo apt-get upgrade -y

COPY service /service
RUN sudo chmod 755 /service

COPY .bump /tmp/.bump

RUN sudo apt-get update && sudo apt-get upgrade -y && brew upgrade

RUN sudo mkdir -p /run/sshd /run && sudo chown -R $HOMEUSER:$HOMEUSER /run /etc/ssh

RUN make update && make upgrade && make install
