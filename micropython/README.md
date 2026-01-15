# MicroPython Build Container
This Docker container allows you to **build MicroPython firmware** for **various ports**. \
If you are using **ESP32** based board you should use [micropython_esp-idf](https://hub.docker.com/r/rav3nh01m/micropython_esp-idf). 

## Table of Contents

- [Supported MicroPython Versions](#supported-micropython-versions)
- [Environment Variables](#environment-variables)
- [Project layout](#project-layout)
- [Example Usage](#example-usage)

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
- **BOARD_VARIANT** - Some boards support variants like rp2 WEACTSTUDIO. \
If you want to **use** this variable chech the **available** options.
- **FREEZE_MAIN** - It should be **string** with value **"true"** or **"false"**. \
It **allows** you to **freeze main.py** inside the firmware, if the file exist, very **handy** if you want to **flash and forget**.
- **FREEZE_BOOT** - It should be **string** with value **"true"** or **"false"**. \
It **allows** you to **freeze boot.py** inside the firmware, if the file exist, very **handy** when you want to **set safe state** of the board pins.
- **PROJECT_DIR** - It's the **path** to the **project directory**. \
If you are **using a CI/CD** then (in most cases) it will **detect** it and use the **CI workspace**, but **only if you use the baked-in build script**. \
If you use **custom build_firmware.sh** you have to **handle this**.

## Project layout.
Your **project** should have this **layout**, if you **use** the **baked-in build script**.
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

Pull the image:
```bash
docker pull rav3nh01m/micropython:latest
```

After that, run:
```bash
docker run --rm \
-e PROJECT_DIR="/var/project" \
-e PORT=rp2 \
-e BOARD=RPI_PICO2 \
-v ./:/var/project \
rav3nh01m/micropython:latest
```
The **path** you **mount** the project ( -v ./:**/var/project** ) must be the same as **PROJECT_DIR** ( -e PROJECT_DIR="**/var/project**").

---

Or if you want to freeze main.py:

```bash
docker run --rm \
-e PROJECT_DIR="/var/project" \
-e PORT=rp2 \
-e BOARD=RPI_PICO_W \
-e FREEZE_MAIN=true \
-v ./:/var/project \
rav3nh01m/micropython:latest
```
---
Or if you want to freeze boot.py:

```bash
docker run --rm \
-e PROJECT_DIR="/var/project" \
-e PORT=rp2 \
-e BOARD=RPI_PICO_W \
-e FREEZE_BOOT=true \
-v ./:/var/project \
rav3nh01m/micropython:latest
```
---

You can use **any version** of MicroPython **available** in the **set** by changing **latest** to the **version** you want. \
It should be like: **v1.xx.x** or **v1.xx**. You can see all available versions [here](https://hub.docker.com/r/rav3nh01m/micropython/tags).

---

After the **build completes**, the **firmware** will be in **/dist** relative to **PROJECT_DIR**. \
**-e PROJECT_DIR=<container_path>** \
**-v <host_path>:<container_path>**

The container path **must** be the **same** as **PROJECT_DIR**, unless you use **custom build_firmware.sh**.

### CI/CD build
You can use GitHub Actions, Woodpecker, GitLab CI or any other CI/CD system to set up automatic builds.

---

**Before pushing this workflow to GitHub you must create MICROPYTHON_VERSION, PORT and BOARD actions variables (not Environment).** \
**Or you can create PORT and BOARD as environment variables and remove the env section from the workflow, but MICROPYTHON_VERSION must be actions variable!**

```yaml
name: Build firmware (upload artifact)

on:
  push:
    branches: [main]
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    container:
      image: rav3nh01m/micropython:${{ vars.MICROPYTHON_VERSION }}
      options: --entrypoint ""

    env:
      PORT: ${{ vars.PORT }}
      BOARD: ${{ vars.BOARD }}
    
    steps:
      # Checkout project code
      - name: Checkout
        uses: actions/checkout@v4

      # Build firmware
      - name: Build firmware
        run: /usr/local/bin/build_firmware.sh

      # Upload firmware artifacts
      - name: Upload firmware artifacts
        uses: actions/upload-artifact@v3
        with:
          name: firmware
          path: dist/**
```
---
Is is also possible to create automatic releases of the firmware by using this workflow. 
As with the previous MICROPYTHON_VERSION must be actions variable.

You must also set:
- VERSION, MAJOR and MINOR actions variables to generate releases like v0.1.4.x\
where VERSION is 0, MAJOR is 1, MINOR is 4 and x is the workflow run number.
- IS_PRERELEASE - if you want to be able to have an easy way to change the prerelease flag of the release.

```yaml
name: Build firmware (release)

on:
  push:
    branches: [main]
  workflow_dispatch:

permissions:
  contents: write

env:
  PORT: ${{ vars.PORT }}
  BOARD: ${{ vars.BOARD }}
  BUILD_VERSION: v${{ vars.VERSION }}.${{ vars.MAJOR }}.${{ vars.MINOR }}.${{ github.run_number }}

jobs:
  build-release:
    runs-on: ubuntu-latest
    container:
      image: rav3nh01m/micropython:${{ vars.MICROPYTHON_VERSION }}
      options: --entrypoint ""

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Build firmware
        run: /usr/local/bin/build_firmware.sh

      - name: Add build version to firmware filenames
        run: |
          for f in dist/*.{bin,uf2,hex}; do
            [ -e "$f" ] || continue
            ext="${f##*.}"
            base="${f%.*}"
            mv "$f" "${base}-${BUILD_VERSION}.${ext}"
          done

      - name: Configure git
        run: |
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"

      - name: Create and push tag
        run: |
          TAG="$BUILD_VERSION"

          if git rev-parse "$TAG" >/dev/null 2>&1; then
            echo "Tag $TAG already exists — skipping"
          else
            git tag "$TAG"
            git push origin "$TAG"
          fi

      - name: Create GitHub release
        uses: actions/create-release@v1
        with:
          tag_name: ${{ env.BUILD_VERSION }}
          release_name: Release ${{ env.BUILD_VERSION }}
          prerelease: ${{ vars.IS_PRERELEASE }}
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      
      - name: Upload release assets
        uses: softprops/action-gh-release@v1
        with:
          tag_name: ${{ env.BUILD_VERSION }}
          files: dist/*
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```
**You must set Settings → Actions → General → Workflow permissions to Read/Write!** \
**This workflow creates a separate release for every push to main branch.**

To reset the workflow run number you can change the yaml file name. \
Use this workflow:
- Create the variables needed (MICROPYTHON_VERSION, PORT, BOARD, VERSION, MAJOR, MINOR, IS_PRERELEASE) and set their values.
- Create build-v{VERSION}.{MAJOR}.{MINOR}.x.yml as your workflow.
- Push the workflow to main branch.

You can reset the **run_number** for every version bump by:
- Change the values of the VERSION, MAJOR and MINOR
- Rename the .yml to match the version
- Push to main branch

With the value of **IS_PRERELEASE** you select if the build is full release or pre-release. \
The value **MUST** be set **BEFORE** the push to the **main branch!**

---
---
If you find this useful, consider buying me a beer 🍺 https://buymeacoffee.com/reaper.maxpayne