ARG FROM_VERSION=latest
FROM letfn/python-cli:$FROM_VERSION
ARG FROM_VERSION

USER root

ENV HOME=/root
ENV DEBIAN_FRONTEND=noninteractive
ENV container docker

RUN dpkg-divert --local --rename --add /sbin/udevadm && ln -s /bin/true /sbin/udevadm

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
        openssh-server tzdata locales iputils-ping iproute2 net-tools \
        docker.io libusb-1.0-0 git curl \
        sudo \
        build-essential \
    && rm -f /usr/bin/gs \
    && mkdir -p /run/sshd /var/run/sshd /run && chown -R app:app /var/run/sshd /run /etc/ssh

RUN echo "app ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

RUN ln -sf /usr/share/zoneinfo/UTC /etc/localtime \
    && dpkg-reconfigure -f noninteractive tzdata \
    && locale-gen en_US.UTF-8 \
    && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8

COPY git-linuxbrew /home/linuxbrew/.linuxbrew
COPY git-linuxbrew-core /home/linuxbrew/.linuxbrew/Library/Taps/homebrew/homebrew-core

RUN /home/linuxbrew/.linuxbrew/bin/brew install hello \
    && (brew bundle || true) \
    && chown -R app:app /home/linuxbrew

# TODO what causes .cache root:root ownership
RUN chown -R app:app /app/src/.cache

USER app

ENV HOME=/app/src
ENV PATH=/home/linuxbrew/.linuxbrew/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

RUN git clone https://github.com/destructuring/homedir \
    && mv homedir/.git . \
    && git reset --hard \
    && rm -rf homedir

RUN git clone https://github.com/destructuring/dotfiles /app/src/.dotfiles \
    && make -f .dotfiles/Makefile dotfiles

COPY service /service

ENTRYPOINT [ "/tini", "--", "/service" ]
