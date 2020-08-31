FROM defn/home:boot

ARG HOMEBOOT
ARG HOMEUSER
ARG HOMEHOST

USER root
RUN groupmod -n $HOMEUSER $HOMEBOOT
RUN usermod -d /home/$HOMEUSER $HOMEBOOT
RUN usermod -l $HOMEUSER $HOMEBOOT
RUN ln -nfs $HOMEBOOT /home/$HOMEUSER
RUN echo "$HOMEUSER ALL=(ALL) NOPASSWD: ALL" | tee -a /etc/sudoers
RUN mkdir -p /run/sshd /run && chown -R $HOMEUSER:$HOMEUSER /run /etc/ssh

USER $HOMEUSER
WORKDIR /home/$HOMEUSER
ENV HOME=/home/$HOMEUSER
ENV PATH=/home/$HOMEUSER/.asdf/bin:/home/$HOMEUSER/.asdf/shims:/home/linuxbrew/.linuxbrew/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

RUN make update && make upgrade && make install && brew upgrade
RUN sudo apt-get update && sudo apt-get upgrade -y

RUN rm -f /home/linuxbrew/.linuxbrew/bin/gs

COPY etc/ssh/trusted-user-ca-keys-${HOMEHOST}.pem /etc/ssh/trusted-user-ca-keys.pem
RUN sudo perl -pe 's{TrustedUserCAKeys}{#TrustedUserCAKeys}' -i /etc/ssh/sshd_config
RUN echo TrustedUserCAKeys /etc/ssh/trusted-user-ca-keys.pem | sudo tee -a /etc/ssh/sshd_config

COPY service /service
RUN sudo chmod 755 /service
