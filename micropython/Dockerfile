FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive

# Arguments
ARG MICROPYTHON_VERSION=

RUN : "${MICROPYTHON_VERSION:?MICROPYTHON_VERSION build-arg is required!}"
RUN echo "Installing MICROPYTHON ${MICROPYTHON_VERSION}..."

RUN apt update \
&& apt install -y --no-install-recommends \
        git unzip wget curl rsync ca-certificates pkg-config \
        build-essential make cmake ninja-build  \
        python3 python3-pip python3-setuptools python3-venv \
        flex bison libffi-dev libssl-dev libbz2-dev libreadline-dev libsqlite3-dev \
        gcc-arm-none-eabi gdb-multiarch libc6-dev libnewlib-arm-none-eabi libstdc++-arm-none-eabi-newlib libusb-1.0-0-dev \
&& rm -rf /var/lib/apt/lists/*

WORKDIR /opt
RUN git clone -b ${MICROPYTHON_VERSION} --recursive https://github.com/micropython/micropython.git

WORKDIR /opt/micropython

ENV PICO_SDK_PATH=/opt/micropython/lib/pico-sdk
ENV PATH="$PICO_SDK_PATH/tools:$PATH"
ENV CC=gcc
ENV CXX=g++

RUN make -C mpy-cross -j"$(nproc)"

WORKDIR /project
COPY build_firmware.sh /usr/local/bin/build_firmware.sh
RUN chmod +x /usr/local/bin/build_firmware.sh

ENTRYPOINT ["/usr/local/bin/build_firmware.sh"]