# MicroPython Build Container for ESP32 boards
This Docker container allows you to **build MicroPython firmware** for **ESP32** port. \

All supported **MicroPython versions** and **ESP-IDF versions** are pre-installed, and `mpy-cross` is pre-built for each MicroPython version.  

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
- **BOARD** - Target board name like: **ESP32_GENERIC**, it should be **exactly** the same as in **micropython/ports/esp32/boards**.
- **IDF_VERSION** - ESP-IDF version to use.

> **Note:** All environment variables must be set and valid. The build script will exit with an error if a value is missing or invalid.
---

## Build Process


### Available ports

## Example Usage

### Build ESP32 Firmware

```bash
docker run --rm \
    -e PORT=esp32 \
    -e BOARD=ESP32_S3_DEV \
    -e IDF_VERSION=5.5 \
    -v $(pwd):/project \
    micropython-v1.26.1

