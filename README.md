# MicroPython containers
Docker containers based on Ubuntu 26.04 for building custom MicroPython firmwares.

## Structure
Each directory is linked to the DockerHub repo with the same name. \
For the moment there are 3 sets of containers:
- micropython - For most boards ( tested on RPI based boards like PICO, PICO_W, PICO2_W)
- micropython_esp-idf - For ESP32 based boards ( tested on ESP32_C3 and ESP32_WROOM_32U)
- micropython_esp-idf_no-bt - Same as micropython_esp-idf, but with Bluetooth (NimBLE) compiled out of MicroPython itself to reclaim RAM on memory-constrained boards like the ESP32-C3

### Dockerfile
Each directory has the Dockerfile used to create the container.

---

### build.sh
The script is used to run "docker build ..." and "docker push ... " for the specific directory.

---

### build_firmware.sh
The ENTRYPOINT of the container. Every container has one baked-in. \
If a file with the same name is present in the root directory of the project it is used instead.

---

### versions.json
Used as input for versions and tags.

--- 

### README.md
Documentation for the specific container set.

---

### Build artefacts
- service_hash - The SHA256 digest of Dockerfile, build.sh and build_firmware.sh \
If the hash changes, all images of that set are rebuilt.

- readme_hash - The SHA256 digest of README.md \
If the hash changes, the documentation in DockerHub will be updated with the new version.

---

## Examples
The [examples](examples) directory contains:
- [GitHub Actions workflows](examples/workflows/GitHub%20Actions) - build and upload an artifact, or build and create a release.
- [Woodpecker CI pipeline](examples/workflows/Woodpecker%20CI/build/.woodpecker.yml) - build using the container as the step image.
- [VS Code on Windows](examples/VS%20Code/Windows/README.md) - IDE setup with MicroPico and stubs.

---
---
If this project helped you, consider buying me a beer 🍺 https://buymeacoffee.com/reaper.maxpayne