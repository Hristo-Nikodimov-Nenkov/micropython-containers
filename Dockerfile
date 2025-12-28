FROM ubuntu:24.04

RUN apt-get update && apt-get upgrade -y
RUN apt-get install bash zip gh docker.io jq

RUN rm -rf /var/lib/apt/lists/*

COPY ./build_containers.sh /usr/local/lib
COPY ./scripts /usr/local/lib

RUN chmod +x /usr/local/lib/build_containers.sh
RUN chmod +x /usr/local/lib/scripts/*.sh

ENTRYPOINT [ ./build_containers.sh ]