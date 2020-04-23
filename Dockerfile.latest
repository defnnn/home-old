FROM registry.eldri.ch/defn/home:update1

RUN sudo apt-get update && sudo apt-get upgrade -y

RUN make update

RUN make upgrade

RUN make install

COPY service /service
