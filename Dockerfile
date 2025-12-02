FROM ubuntu:24.04

RUN apt-get update
RUN apt-get install -y --no-install-recommends git unzip wget curl rsync ca-certificates pkg-config 
RUN rm -rf /var/lib/apt/lists/*

# Git identity (can be overridden with ARG during build)
ARG GIT_USER_NAME="Build Containers Bot"
ARG GIT_USER_EMAIL="buildbot@example.com"

RUN git config --global user.name "$GIT_USER_NAME" && \
    git config --global user.email "$GIT_USER_EMAIL"

WORKDIR /var/containers

COPY build_containers.sh /usr/lib/build_containers.sh
RUN chmod +x /usr/lib/build_containers.sh

ENTRYPOINT ["/usr/lib/build_containers.sh"]