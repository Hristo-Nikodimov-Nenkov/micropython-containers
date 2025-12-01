FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive

ARG MICROPYTHON_VERSION

RUN : "${MICROPYTHON_VERSION:?MICROPYTHON_VERSION build-arg is required!}"
RUN echo "Installing MICROPYTHON ${MICROPYTHON_VERSION}..."

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
        git unzip wget curl rsync ca-certificates build-essential pkg-config \
        python3 python3-pip python3-setuptools python3-venv \
        cmake ninja-build libffi-dev libssl-dev libbz2-dev libreadline-dev libsqlite3-dev gcc-arm-none-eabi \
 && rm -rf /var/lib/apt/lists/*
 
WORKDIR /opt 
RUN git clone -b ${MICROPYTHON_VERSION} \
        --recursive \ 
        https://github.com/micropython/micropython.git

WORKDIR /opt/micropython
RUN git submodule update --init --recursive
RUN make -C mpy-cross -j"$(nproc)"

WORKDIR /project
COPY build_firmware.sh /usr/local/bin/build_firmware.sh
RUN chmod +x /usr/local/bin/build_firmware.sh

ENTRYPOINT ["/usr/local/bin/build_firmware.sh"]