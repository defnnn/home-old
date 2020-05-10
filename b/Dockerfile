FROM letfn/python:latest

ARG HOMEDIR
ARG DOTFILES

USER root

ENV HOME=/root
ENV DEBIAN_FRONTEND=noninteractive
ENV container docker

COPY .reset /.reset

RUN dpkg-divert --local --rename --add /sbin/udevadm && ln -s /bin/true /sbin/udevadm

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
        openssh-server tzdata locales iputils-ping iproute2 net-tools git curl xz-utils unzip jq make vim less wget \
        docker.io docker-compose sshfs libusb-1.0-0 \
        sudo \
        build-essential \
        libssl-dev zlib1g-dev libbz2-dev libsqlite3-dev libncurses5-dev libncursesw5-dev libffi-dev liblzma-dev libreadline-dev \
    && rm -f /usr/bin/gs \
    && mkdir -p /run/sshd /var/run/sshd /run && chown -R app:app /var/run/sshd /run /etc/ssh

RUN echo "app ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

RUN echo GatewayPorts yes >> /etc/ssh/sshd_config

RUN ln -sf /usr/share/zoneinfo/UTC /etc/localtime \
    && dpkg-reconfigure -f noninteractive tzdata \
    && locale-gen en_US.UTF-8 \
    && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8

RUN git clone --depth 1 https://github.com/Homebrew/brew /home/linuxbrew/.linuxbrew \
    && git clone --depth 1 https://github.com/Homebrew/linuxbrew-core /home/linuxbrew/.linuxbrew/Library/Taps/homebrew/homebrew-core \
    && chown -R app:app /home/linuxbrew

RUN rm -rf main.py requirements.txt tests .cache __pycache__

USER app

ENV HOME=/app/src
ENV PATH=/home/linuxbrew/.linuxbrew/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

RUN brew list

RUN brew bundle --help

RUN brew install perl

ENV PATH=/app/src/.asdf/bin:/app/src/.asdf/shims:/home/linuxbrew/.linuxbrew/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

COPY .homedir /.homedir

RUN git clone $HOMEDIR homedir \
    && mv homedir/.git . \
    && rm -rf homedir \
    && git reset --hard

RUN echo "$DOTFILES" > .dotfiles-repo

RUN make update

RUN make upgrade

RUN make install && brew upgrade

RUN nvim --headless +PlugInstall +qa \
    && curl -sSL -o jet.zip \
        https://github.com/borkdude/jet/releases/download/v0.0.12/jet-0.0.12-linux-amd64.zip \
    && unzip jet.zip && rm -f jet.zip && mv jet .config/nvim/plugged/vim-iced/bin/jet

RUN sudo apt-get update && sudo apt-get upgrade -y

COPY service /service
RUN sudo chmod 755 /service

COPY --chown=app:app a/ .ansible/
RUN cd .ansible && ../env ansible-playbook docker.yml -c local

COPY .counter /.counter

RUN make update && make upgrade && make install && brew upgrade \
    && sudo apt-get update && sudo apt-get upgrade -y
