FROM defn/home:sshd

ARG HOMEBOOT

ENV HOMEBOOT=$HOMEBOOT

USER root

ENV HOME=/root
ENV DEBIAN_FRONTEND=noninteractive
ENV container docker

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
        docker.io libudev-dev

RUN curl -O -sSL "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o "session-manager-plugin.deb" \
    && dpkg -i session-manager-plugin.deb \
    && rm -f session-manager-plugin.deb

RUN curl -O -sSL "https://bin.equinox.io/c/VdrWdbjqyF/cloudflared-stable-linux-amd64.deb" \
    && dpkg -i cloudflared-stable-linux-amd64.deb \
    && rm -f cloudflared-stable-linux-amd64.deb

RUN install -d -o $HOMEBOOT -g $HOMEBOOT -d /home/linuxbrew
RUN install -d -o $HOMEBOOT -g $HOMEBOOT -d /home/$HOMEBOOT
RUN usermod -d /home/$HOMEBOOT $HOMEBOOT

USER $HOMEBOOT
WORKDIR /home/$HOMEBOOT
ENV HOME=/home/$HOMEBOOT

ENV PATH=/home/linuxbrew/.linuxbrew/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

RUN git clone --depth 1 https://github.com/Homebrew/brew /home/linuxbrew/.linuxbrew \
    && git clone --depth 100 https://github.com/Homebrew/linuxbrew-core /home/linuxbrew/.linuxbrew/Library/Taps/homebrew/homebrew-core

RUN env HOMEBREW_NO_AUTO_UPDATE=1 brew list

RUN env HOMEBREW_NO_AUTO_UPDATE=1 brew tap linuxbrew/xorg

RUN env HOMEBREW_NO_AUTO_UPDATE=1 brew bundle --help

RUN sudo ln -nfs locale.h /usr/include/xlocale.h && env HOMEBREW_NO_AUTO_UPDATE=1 brew install perl

ENV PATH=/home/$HOMEBOOT/.asdf/bin:/home/$HOMEBOOT/.asdf/shims:/home/linuxbrew/.linuxbrew/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
