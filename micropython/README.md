# MicroPython Firmware Builder
The tag is the release version of MicroPython that the container will build.

## Setup
To build custom firmware your project should have this layout:

- **/modules** – Modules that have to be frozen in the firmware.
There is **no need** to create **manifest.py**; it is generated before each build.

- **/lib** – Modules that are **not frozen** and will be **uploaded** to the microcontroller.

- **/main.py** – The entry point of the project.
To **freeze it in the firmware**, set the environment variable **FREEZE_MAIN=true**.

- **/dist** – The output directory.
After a successful build the **firmware (.bin, .hex, or .uf2)** will appear here.

- **/build_firmware.sh** – If this file exists in your project, it will **override** the integrated script inside the container.

- **/manifest.py** – If included, this file will be used instead of an auto-generated manifest.

### Environment Variables
---
The container uses environment variables as input:

- **PORT** – The MicroPython port.

- **BOARD** – The board the firmware is built for.
Must **match exactly** a board name in **micropython/ports/$PORT/boards**.

- **FREEZE_MAIN** – Set to **true** to freeze main.py inside the firmware.

### Workflow
---
#### Manual build
---
All examples use latest.

To **use a specific** version, replace **latest** with something like:
**v1.xx.x or v1.xx**

Available versions can be found here:
https://hub.docker.com/r/rav3nh01m/micropython/tags

Pull the image:
```sh
docker pull rav3nh01m/micropython:latest
```
After that, run:
```sh
docker run --rm \
-e PORT=rp2 \
-e BOARD=RPI_PICO_W \
-v ./:/project \
rav3nh01m/micropython:latest
```
Or if you want to freeze main.py:

```sh
docker run --rm \
-e PORT=rp2 \
-e BOARD=RPI_PICO_W \
-e FREEZE_MAIN=true \
-v ./:/project \
rav3nh01m/micropython:latest
```

You can use **any version** of MicroPython **available in the set** by changing **latest** to the **version you want**.

After the **build completes**, the firmware will be in **/dist** relative to the directory you mounted with -v:”

**-v <host_path>:<container_path>**

The container path **must be**: **/project** unless you use custom build_firmware.sh, in which case you can use any path you want.

#### CI/CD Build
---
You can use GitHub Actions or any other CI/CD system to set up automatic builds.

For GitHub Actions, you can use either **Environment variables** or **Actions variables**, both found under:
**Settings → Secrets and variables → Actions**

Use them like this:
- Environment variables: **${{ env.PORT }}**
- Actions variables: **${{ vars.PORT }}**

Where **PORT** is the **NAME** of the variable.

If your **code is not in the root directory** of the repo, **mount** the directory **containing the main.py** file and the **lib** and/or **modules** directories.
For example, if they are in **/src**:

**-v ./src:/project**

---
---
If you find this useful, please consider buying me a beer → https://buymeacoffee.com/reaper.maxpayne