# Multi-Port MicroPython Build Container

This Docker container allows you to **build MicroPython firmware for multiple boards and ports** in a fully offline-ready environment.  
It supports **ESP32**, **RP2040/Pico**, **STM32**, **nRF**, **Unix**, and other MicroPython ports.

All supported **MicroPython versions** and **ESP-IDF versions** are pre-installed, and `mpy-cross` is pre-built for each MicroPython version.  
Pico SDK and ARM GCC toolchains are included.

---

## Table of Contents

- [Supported MicroPython Versions](#supported-micropython-versions)  
- [Supported ESP-IDF Versions](#supported-esp-idf-versions)  
- [Environment Variables](#environment-variables)  
- [Build Process](#build-process)  
- [Example Usage](#example-usage)  
- [Freeze Modules](#freeze-modules)  
- [Notes](#notes)  

---

## Supported MicroPython Versions

- 1.26.1 with ESP-IDF - 5.5 & 5.4  
- 1.25.0 with ESP-IDF - 5.4 & 5.3 
- 1.24.1 with ESP-IDF - 5.3 & 5.2 

> Only required for ESP32-family boards.

---

## Environment Variables

The container requires the following **environment variables** at runtime:

| Variable               | Description                                                                 | Example           |
|------------------------|-----------------------------------------------------------------------------|-----------------|
| `BOARD`                | Target board name                                                           | `ESP32_S3_DEV` or `RPI_PICO_W` |
| `PORT`                 | MicroPython port type                                                       | `esp32`, `rp2`, `stm32`, `nrf`, `unix` |
| `IDF_VERSION`          | ESP-IDF version to use (required **only for ESP32 ports**)                  | `5.5`           |

> **Note:** All environment variables must be set and valid. The build script will exit with an error if a value is missing or invalid.

---

## Build Process

1. The build script copies your project files into `/app`.  
2. If a `.freeze` directory and `manifest.py` exist, freeze modules into the firmware.  
3. The script selects the port (`PORT`) and sets up the correct toolchain.  
4. For ESP32 ports, it sources the selected ESP-IDF version (`IDF_VERSION`).  
5. Builds the firmware for the specified board.  
6. Outputs the firmware to `/project/build`.

### Available ports
- alif (ALIF_ENSEMBLE, OPENMV_AE3)
- bare-arm
- cc3200 (LAUNCHXL, WIPY)
- embed
- esp32 (ARDUINO_NANO_ESP32, ESP32_GENERIC, ESP32_GENERIC_C2, ESP32_GENERIC_C3, ESP32_GENERIC_C5, ESP32_GENERIC_C6, ESP32_GENERIC_S2, ESP32_GENERIC_S3, GARATRONIC_PYBSTICK26_ESP32C3, LILYGO_TTGO_LORA32, LOLIN_C3_MINI, LOLIN_S2_MINI, LOLIN_S2_PICO, M5STACK_ATOM, M5STACK_ATOMS3_LITE, M5STACK_NANOC6, OLIMEX_ESP32_EVB, OLIMEX_ESP32_POE, SIL_MANT1S, SIL_WESP32, SPARKFUN_IOT_REDBOARD_ESP32, UM_FEATHERS2, UM_FEATHERS2NEO, UM_FEATHERS3, UM_FEATHERS3NEO, UM_NANOS3, UM_OMGS3, UM_PROS3, UM_RGBTOUCH_MINI, UM_TINYC6, UM_TINYPICO, UM_TINYS2, UM_TINYS3, UM_TINYWATCHS3)
- esp8266
- mimxrt
- minimal
- nrf
- pic16bit
- powerpc
- qemu
- renesas-ra
- rp2
- samd
- stm32
- unix
- webassembly
- windows
- zephyr

---

## Example Usage

### Build ESP32 Firmware

```bash
docker run --rm \
    -e PORT=esp32 \
    -e BOARD=ESP32_S3_DEV \
    -e IDF_VERSION=5.5 \
    -v $(pwd):/project \
    micropython-v1.26.1

