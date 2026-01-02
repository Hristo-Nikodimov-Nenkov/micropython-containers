# MicroPython containers
Docker containers based on Ubuntu 24.04 for building custom MicroPython firmwares.

## Structure
Each directory is linked to DockerHub repo with the same name. \
For the moment there are 2 sets of containers:
- micropython - For most boards ( tested on RPI based boards like PICO, PICO_W, PICO2_W)
- micropython_esp-idf - For ESP32 based boards ( tested on ESP32_C3 and ESP32_WROOM_32U)

### Dockerfile
Each directory has the Dockerfile used to create the container.

---

### build.sh
The script is used to run "docker build ..." and "docker push ... " for  the specific directory.

---

### build_firmware.sh
The ENTRYPOINT of the container. Every container has one baked-in. \
If file with same name is present in the root directory of the project it is used insted.

---

### versions.json
Used as input for versions and tags.

--- 

### README.md
Documentation for specific container set.

---

### Build artefacts
- service_hash - The SHA256 digest of Dockerfile, build.sh and build_firmware.sh \
If hash changes all containers are rebuild.

- readme_hash - The SHA256 digest of README.md \
If hash changes the documentation in DockerHub will be updated with the new version.

---
---
If this project helped you, consider buying me a beer 🍺 https://buymeacoffee.com/reaper.maxpayne