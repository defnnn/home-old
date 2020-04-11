ARG FROM_IMAGE=letfn/python-cli:latest

FROM $FROM_IMAGE

ARG FROM_VERSION

USER root

ENV HOME=/root
ENV DEBIAN_FRONTEND=noninteractive
ENV container docker

RUN dpkg-divert --local --rename --add /sbin/udevadm && ln -s /bin/true /sbin/udevadm

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
        openssh-server tzdata locales iputils-ping iproute2 net-tools git curl xz-utils unzip jq make vim \
        docker.io docker-compose sshfs libusb-1.0-0 \
        sudo \
        build-essential \
        libssl-dev zlib1g-dev libbz2-dev libsqlite3-dev libncurses5-dev libncursesw5-dev libffi-dev liblzma-dev libreadline-dev \
    && rm -f /usr/bin/gs \
    && mkdir -p /run/sshd /var/run/sshd /run && chown -R app:app /var/run/sshd /run /etc/ssh

RUN echo "app ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

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

COPY service /service

ENTRYPOINT [ "/service" ]
