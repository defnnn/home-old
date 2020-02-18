FROM letfn/container

USER root
ENV HOME=/root
WORKDIR /root

RUN echo @testing http://nl.alpinelinux.org/alpine/edge/testing >> /etc/apk/repositories
RUN apk add curl sudo tmux expect vim bash make jq
RUN apk add pass@testing libusb
RUN apk add openssh docker docker-compose

RUN ssh-keygen -A
RUN chown -R app:app /etc/ssh /run

RUN cd /usr/local/bin && curl -sSL -O https://github.com/drone/drone-cli/releases/download/v1.2.1/drone_linux_amd64.tar.gz \
    && tar xvfz drone_linux_amd64.tar.gz \
    && rm -f drone_linux_amd64.tar.gz \
    && chmod 755 drone

RUN cd /usr/local/bin && curl -sSL -O https://github.com/justjanne/powerline-go/releases/download/v1.15.0/powerline-go-linux-amd64 \
    && mv powerline-go-linux-amd64 powerline-go \
    && chmod 755 powerline-go

RUN cd /usr/local/bin && curl -sSL -O https://github.com/segmentio/aws-okta/releases/download/v0.27.0/aws-okta-v0.27.0-linux-amd64 \
    && mv aws-okta-v0.27.0-linux-amd64 aws-okta \
    && chmod 755 aws-okta

RUN cd /usr/local/bin && curl -sSL -O https://github.com/segmentio/chamber/releases/download/v2.7.5/chamber-v2.7.5-linux-amd64 \
    && mv chamber-v2.7.5-linux-amd64 chamber \
    && chmod 755 chamber

RUN echo "app ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
RUN echo "Defaults !requiretty" >> /etc/sudoers

COPY --chown=app:app home /app/src

USER app
ENV HOME=/app/src
WORKDIR /app/src

RUN chmod 700 /app/src/.ssh
RUN chmod 600 /app/src/.ssh/authorized_keys
RUN chmod 700 /app/src/.gnupg

RUN mkdir -p /app/src/.aws && ln -nfs /efs/config/aws/config /app/src/.aws/
RUN ln -nfs /efs/config/pass /app/src/.password-store

COPY --chown=app:app .dotfiles /app/src/.dotfiles
RUN make -f .dotfiles/Makefile dotfiles

COPY service /service

ENTRYPOINT [ "/tini", "--", "/service" ]
