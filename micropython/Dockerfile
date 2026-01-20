FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update
RUN apt-get install -y --no-install-recommends git unzip wget curl rsync ca-certificates pkg-config 
RUN apt-get install -y --no-install-recommends python3 python3-pip python3-setuptools python3-venv python3-dev
RUN apt-get install -y --no-install-recommends build-essential make cmake ninja-build
RUN apt-get install -y --no-install-recommends flex bison gdb-multiarch
RUN apt-get install -y --no-install-recommends libffi-dev libssl-dev libbz2-dev libreadline-dev libsqlite3-dev libc6-dev libusb-1.0-0-dev
RUN apt-get install -y --no-install-recommends gcc-arm-none-eabi binutils-arm-none-eabi libnewlib-arm-none-eabi libstdc++-arm-none-eabi-newlib

RUN rm -rf /var/lib/apt/lists/*
    
ARG MICROPYTHON_VERSION=
RUN test -n "$MICROPYTHON_VERSION" || (echo "ERROR: MICROPYTHON_VERSION build-arg is required" && exit 1)

WORKDIR /opt
RUN git clone -b ${MICROPYTHON_VERSION} --recursive https://github.com/micropython/micropython.git

WORKDIR /opt/micropython
RUN git submodule update --init --recursive
RUN make -C mpy-cross -j2

COPY build_firmware.sh /usr/local/bin/build_firmware.sh
RUN chmod +x /usr/local/bin/build_firmware.sh

ENTRYPOINT ["/usr/local/bin/build_firmware.sh"]