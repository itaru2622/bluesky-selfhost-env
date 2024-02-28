ARG base=golang:1.21-bookworm
FROM ${base}
ARG base

RUN apt update; apt install -y git ca-certificates   net-tools curl bash-completion

ARG branch=main
RUN git clone https://github.com/gorilla/websocket.git -b ${branch} /opt/gorilla-websocket
COPY ./start.sh /start.sh

WORKDIR /opt/gorilla-websocket/examples/chat
ENV PATH ./:${PATH}:/
ENV ENABLE_WSS false
ENV SCRIPT '*.go'

CMD start.sh
EXPOSE 8080
