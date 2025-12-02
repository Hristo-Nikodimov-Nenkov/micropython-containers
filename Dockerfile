FROM ubuntu:24.04

RUN apt-get update
RUN apt-get install -y --no-install-recommends \
    git unzip wget curl rsync ca-certificates pkg-config \
    build-essential \
    make \
    cmake \
    ninja-build \
    python3 \
    python3-pip \
    python3-setuptools \
    python3-venv \
    flex \
    bison \
    libffi-dev \
    libssl-dev \
    libbz2-dev \
    libreadline-dev \
    libsqlite3-dev \
    gdb-multiarch \
    libc6-dev \
    libusb-1.0-0-dev \
    gcc-arm-none-eabi \
    binutils-arm-none-eabi \
    libnewlib-arm-none-eabi \
    libstdc++-arm-none-eabi-newlib \
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