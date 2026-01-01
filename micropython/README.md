# MicroPython Build Container
This Docker container allows you to **build MicroPython firmware** for **various ports**. \
If you are using **ESP32** based board you should use [micropython_esp-idf](https://hub.docker.com/r/rav3nh01m/micropython_esp-idf). 

## Table of Contents

- [Supported MicroPython Versions](#supported-micropython-versions)  
- [Environment Variables](#environment-variables)  
- [Project layout](#project-layout)
- [Example Usage](#example-usage)    
- [Notes](#notes)  

---

## Supported MicroPython Versions
You can check which versions are available [here](https://hub.docker.com/r/rav3nh01m/micropython/tags). \
The **tag** is the **version** of MicroPyhon the container will build. \
**All packages are pre-installed.**

## Environment variables
The container uses environment variables as input for:
- **PORT** - The MicroPython port. It should be **lower-case**.
- **BOARD** - The board for which the firmware is intended. \
It should be **upper-case** and **exactly the same** as in **micropython/ports/PORT/boards** directory.
- **FREEZE_MAIN** - It should be **string** with value **"true"** or **"false"**. \
It **allows** you to **freeze main.py** inside the firmware, very **handy** if you want to **flash and forget**.

## Project layout.
Your project should have this layout:
- **/modules** – Modules that have to be frozen in the firmware. \
There is **no need** to create **manifest.py**; it is **generated** before each build **when the directory exists**.

- **/lib** – Modules that are **not frozen** and will be **uploaded** to the microcontroller.

- **/main.py** – The entry point of the project.
To **freeze it in the firmware**, use **FREEZE_MAIN="true"**.

- **/dist** – The output directory.
After a **successful** build the **firmware (.bin, .hex, or .uf2)** will appear here.

- **/build_firmware.sh** – If this **file exists** in your project, it will **override** the **integrated script** inside the container.

- **/manifest.py** – If this **file exists** in your project, it will be **used** as **manifest** when building the firmware. 

### Project root not in the repo root
If your **code** is **not** in the **root directory** of the repo:
- **mount** the directory **containing** the **main.py** file and/or **modules** directories.
For example, if they are in **/src** use **-v ./src:/var/project**

## Example usage
You can use this container both for [manual](#manual-build) builds or inside a [CI/CD](#cicd-build) pipeline.

### Manual build
---
All examples use latest.

To **use a specific** version, replace **latest** with something like:
**v1.xx.x or v1.xx**

Available versions can be found [here](https://hub.docker.com/r/rav3nh01m/micropython/tags).

Pull the image:
```bash
docker pull rav3nh01m/micropython:latest
```

After that, run:
```bash
docker run --rm \
-e PORT=rp2 \
-e BOARD=RPI_PICO2 \
-v ./:/var/project \
rav3nh01m/micropython:latest
```
Or if you want to freeze main.py:

```bash
docker run --rm \
-e PORT=rp2 \
-e BOARD=RPI_PICO_W \
-e FREEZE_MAIN=true \
-v ./:/var/project \
rav3nh01m/micropython:latest
```

You can use **any version** of MicroPython **available** in the **set** by changing **latest** to the **version** you want.

After the **build completes**, the firmware will be in **/dist** relative to the **directory you mounted** with **-v**:”

**-v <host_path>:<container_path>**

The container path **must be /var/project**, unless you use **custom build_firmware.sh**, in which case you can **use any path you want**.

### CI/CD build
You can use GitHub Actions or any other CI/CD system to set up automatic builds.

For GitHub Actions, you can use either **Environment variables** or **Actions variables**, both found under:
**Settings → Secrets and variables → Actions**

Use them like this:
- Environment variables: **${{ env.PORT }}**
- Actions variables: **${{ vars.PORT }}**

Where **PORT** is the **NAME** of the variable.

---
If you find this useful, please consider buying me a beer → https://buymeacoffee.com/reaper.maxpayne