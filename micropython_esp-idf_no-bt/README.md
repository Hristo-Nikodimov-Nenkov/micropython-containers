# MicroPython Build Container for ESP32 based boards (Bluetooth disabled)

This is a variant of [micropython_esp-idf](https://hub.docker.com/r/rav3nh01m/micropython_esp-idf) with
**Bluetooth (NimBLE) compiled out of MicroPython itself**, not just disabled in `sdkconfig`.

Everything else - environment variables, project layout, `sdkconfig.board` support, CI/CD usage - is
**identical** to [micropython_esp-idf](https://hub.docker.com/r/rav3nh01m/micropython_esp-idf). \
See that image's [README](https://hub.docker.com/r/rav3nh01m/micropython_esp-idf) for the full documentation.
This README only covers what's different.

## Why this image exists

Every stock ESP32-C3 MicroPython board pulls in `boards/sdkconfig.ble` unconditionally, reserving a fixed
chunk of the chip's very limited internal RAM for the NimBLE controller/host stack whether or not the
firmware ever uses Bluetooth. The regular `micropython_esp-idf` image lets a project override that via
`sdkconfig.board` (`CONFIG_BT_ENABLED=n`, etc.) - but that only removes the *ESP-IDF component*. MicroPython
itself still unconditionally compiles its NimBLE bindings
(`extmod/nimble/modbluetooth_nimble.c`, `ports/esp32/mpnimbleport.c`) because
`ports/esp32/mpconfigport.h` defaults `MICROPY_PY_BLUETOOTH` to `(1)` for every board, and the ESP32 port's
`Makefile` has no hook to override that from a project directory. The result is a build that fails with
`fatal error: host/ble_hs.h: No such file or directory` as soon as `CONFIG_BT_ENABLED=n` removes the
NimBLE headers those files still `#include`.

This image patches `ports/esp32/mpconfigport.h` at build time so `MICROPY_PY_BLUETOOTH` defaults to `(0)`
instead, so MicroPython never compiles against NimBLE in the first place.

## Using it

Same as `micropython_esp-idf`, just with a different image name:

```bash
docker run --rm \
-e PROJECT_DIR="/project" \
-e BOARD=ESP32_GENERIC_C3 \
-v ./:/project \
rav3nh01m/micropython_esp-idf_no-bt:latest
```

**To actually reclaim the RAM** `boards/sdkconfig.ble` reserves for the NimBLE stack, you still need your
own `sdkconfig.board` in the project with:
```
CONFIG_BT_ENABLED=n
CONFIG_BT_NIMBLE_ENABLED=n
CONFIG_BT_CONTROLLER_ENABLED=n
```
This image only stops MicroPython from *requiring* those headers to exist - it doesn't change `sdkconfig`
on its own.

## Supported versions

Only versions known to need this (and verified to build) are published here - check
[tags](https://hub.docker.com/r/rav3nh01m/micropython_esp-idf_no-bt/tags) for what's currently available.

---
---
If you find this useful, consider buying me a beer 🍺 https://buymeacoffee.com/reaper.maxpayne
