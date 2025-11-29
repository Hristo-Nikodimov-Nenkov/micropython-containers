FROM ubuntu:24.04

RUN apt-get update && \
    apt-get install -y \
        bash \
        jq \
        docker.io \
        curl \
        git \
    && rm -rf /var/lib/apt/lists/*

# Git identity (can be overridden with ARG during build)
ARG GIT_USER_NAME="Build Containers Bot"
ARG GIT_USER_EMAIL="buildbot@example.com"

RUN git config --global user.name "$GIT_USER_NAME" && \
    git config --global user.email "$GIT_USER_EMAIL"

WORKDIR /var/containers

COPY build_containers.sh /usr/lib/build_containers.sh
RUN chmod +x /usr/lib/build_containers.sh

ENTRYPOINT ["/build_containers.sh"]
