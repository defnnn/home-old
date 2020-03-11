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
        openssh-server curl tzdata locales iputils-ping iproute2 net-tools pass \
        gnupg pinentry-curses tmux docker.io libusb-1.0-0 vim make rsync git jq \
        unzip sudo \
    && rm -f /usr/bin/gs \
    && mkdir -p /run/sshd /var/run/sshd /run && chown -R app:app /var/run/sshd /run /etc/ssh

RUN echo "app ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

RUN ln -sf /usr/share/zoneinfo/UTC /etc/localtime \
    && dpkg-reconfigure -f noninteractive tzdata \
    && locale-gen en_US.UTF-8 \
    && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8

RUN cd /usr/local/bin && curl -sSL -O https://github.com/drone/drone-cli/releases/download/v1.2.1/drone_linux_amd64.tar.gz \
    && tar xvfz drone_linux_amd64.tar.gz \
    && rm -f drone_linux_amd64.tar.gz \
    && chmod 755 /usr/local/bin/drone

RUN cd /usr/local/bin && curl -sSL -O https://github.com/justjanne/powerline-go/releases/download/v1.15.0/powerline-go-linux-amd64 \
    && mv powerline-go-linux-amd64 powerline-go \
    && chmod 755 /usr/local/bin/powerline-go

RUN cd /usr/local/bin && curl -sSL -O https://github.com/segmentio/aws-okta/releases/download/v1.0.1/aws-okta-v1.0.1-linux-amd64 \
    && mv aws-okta-v1.0.1-linux-amd64 aws-okta \
    && chmod 755 /usr/local/bin/aws-okta

USER app

ENV HOME=/app/src
ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

RUN git clone https://github.com/destructuring/homedir \
    && mv homedir/.git . \
    && git reset --hard

RUN chmod 700 /app/src/.ssh \
    && chmod 600 /app/src/.ssh/authorized_keys \
    && chmod 700 /app/src/.gnupg \
    && mkdir -p /app/src/.aws \
    && ln -nfs /efs/config/aws/config /app/src/.aws/ \
    && ln -nfs /efs/config/pass /app/src/.password-store

RUN git clone https://github.com/destructuring/dotfiles /app/src/.dotfiles \
    && make -f .dotfiles/Makefile dotfiles

COPY --chown=app:app requirements.txt /app/src/requirements.txt

RUN . /app/venv/bin/activate \
    && pip install --no-cache-dir -r /app/src/requirements.txt

COPY service /service

ENTRYPOINT [ "/tini", "--", "/service" ]
