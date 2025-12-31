ARG MICROPYTHON_VERSION
FROM $DOCKERHUB_USERNAME/micropython:$MICROPYTHON_VERSION AS base

ARG ESP_IDF_VERSION

RUN test -n "$ESP_IDF_VERSION" || (echo "ERROR: ESP_IDF_VERSION build-arg is required" && exit 1) 

RUN echo "Installing ESP-IDF ${ESP_IDF_VERSION}..."

WORKDIR /opt
RUN git clone -b $ESP_IDF_VERSION \
    --recursive \ 
    https://github.com/espressif/esp-idf.git

WORKDIR /opt/esp-idf
RUN git submodule update --init --recursive
RUN chmod +x install.sh export.sh

RUN ./install.sh all
RUN echo ". /opt/esp-idf/export.sh" >> /etc/bash.bashrc

WORKDIR /project
COPY build_firmware.sh /usr/local/bin/build_firmware.sh
RUN chmod +x /usr/local/bin/build_firmware.sh

ENTRYPOINT ["/usr/local/bin/build_firmware.sh"]