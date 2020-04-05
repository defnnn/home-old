FROM registry.eldri.ch/defn/home:update1

RUN make update

RUN make upgrade

RUN make install

COPY service /service
