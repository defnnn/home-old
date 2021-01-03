FROM defn/python:latest

ARG HOMEBOOT
ENV HOMEBOOT=$HOMEBOOT

USER root

ARG DEBIAN_FRONTEND=noninteractive

ENV HOME=/root
ENV container docker

RUN dpkg-divert --local --rename --add /sbin/udevadm && ln -s /bin/true /sbin/udevadm

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
        wget apt-transport-https software-properties-common \
        openssh-server tzdata locales iputils-ping iproute2 net-tools dnsutils curl wget unzip jq xz-utils \
        sudo git vim less \
        build-essential m4 make \
        libssl-dev zlib1g-dev libbz2-dev libsqlite3-dev libncurses5-dev libncursesw5-dev libffi-dev liblzma-dev libreadline-dev \
        tmux gnupg libusb-1.0-0 \
    && rm -f /usr/bin/gs

RUN curl -fsSL https://adoptopenjdk.jfrog.io/adoptopenjdk/api/gpg/key/public | apt-key add -
RUN add-apt-repository --yes https://adoptopenjdk.jfrog.io/adoptopenjdk/deb/
RUN apt-get update && apt-get install -y adoptopenjdk-11-hotspot

RUN echo GatewayPorts clientspecified >> /etc/ssh/sshd_config

RUN ln -sf /usr/share/zoneinfo/UTC /etc/localtime \
    && dpkg-reconfigure -f noninteractive tzdata \
    && locale-gen en_US.UTF-8 \
    && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8

RUN install -d -o $HOMEBOOT -g $HOMEBOOT /home/$HOMEBOOT
RUN ls -ld /home/$HOMEBOOT

USER $HOMEBOOT
WORKDIR /home/$HOMEBOOT
ENV HOME=/home/$HOMEBOOT

ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
