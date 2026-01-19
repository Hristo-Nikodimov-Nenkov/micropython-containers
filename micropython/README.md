# MicroPython Build Container
This Docker container allows you to **build MicroPython firmware** for **various ports**. \
If you are using **ESP32** based board you should use [micropython_esp-idf](https://hub.docker.com/r/rav3nh01m/micropython_esp-idf). 

## Table of Contents

- [Supported MicroPython Versions](#supported-micropython-versions)
- [Environment Variables](#environment-variables)
- [Project layout](#project-layout)
- [Example Usage](#example-usage)

---

## Supported MicroPython versions
You can check which versions are available [here](https://hub.docker.com/r/rav3nh01m/micropython/tags). \
The **tag** is the **version** of MicroPyhon the container will build. \
**All packages are pre-installed.**

## Environment Variables
The container uses the following environment variables as input:

### Firmware configuration

- **PORT**
The MicroPython port to build.
Must be lowercase.

- **BOARD**
The target board for which the firmware is built.
**Must be uppercase** and must **exactly match** a directory name in: **micropython/ports/<PORT>/boards**

- **BOARD_VARIANT**
Some boards support variants (for example rp2 → WEACTSTUDIO).
If you **want to use** this variable, check the **available variants** for the selected board.

---

### Freezing files into firmware

- **FREEZE_MAIN** - **String** value: **"true"** or **"false"**. \
When **enabled**, main.py (if present) is **frozen** into the firmware. \
Useful for **flash-and-forget** deployments.

- **FREEZE_BOOT** - **String** value: **"true"** or **"false"**. \
When **enabled**, boot.py (if present) is **frozen** into the firmware. \
Useful for setting a **safe default state** for **board pins** in **flash-and-forget** deployments.

When **/modules** directory exists it's **content** is **frozen** relative to it. \
If you have module like /modules/test_module you should use **"import test_module"** or **"from text_module import ..."**

**When module with the same name exists in firmware and flash you'll receive an error.**

---

### Project directory

- **PROJECT_DIR** - Path to the **project directory**.
When running in CI/CD, the baked-in build_firmware.sh script will usually auto-detected and set to the CI workspace. \
If you use a custom build_firmware.sh, you must handle this yourself.

If used with "GitHub Actions":
```yaml
      - name: Run MicroPython build container
        run: |
          docker run --rm \
            -e PROJECT_DIR=/project \
            -v "$PWD:/project" \
            rav3nh01m/micropython:latest
```
**PROJECT_DIR value must be the same as the mount path in the container, in this case "/project".**

---

### File ownership (DinD / CI support)
- **HOST_UID** - Host User ID.
- **HOST_GID** - Host Group ID.

The container runs as **root**, so **all** files **created** inside the container are **owned by root:root** by default. \
When using Docker-in-Docker (DinD), this can result in mixed ownership: \
Files created by the host (for example in GitHub Actions) are owned by the host runner. \
Files generated inside the container are owned by root:root \
When HOST_UID and/or HOST_GID are set, the baked-in firmware.sh script will recursively change ownership of the project directory \
and all its contents to: **HOST_UID:HOST_GID** \
If you are using "GitHub Actions" you can pass both UID and GID like this:

```yaml
      - name: Get runner UID and GID
        id: runner_ids
        run: |
          echo "uid=$(id -u)" >> "$GITHUB_OUTPUT"
          echo "gid=$(id -g)" >> "$GITHUB_OUTPUT"

      - name: Run MicroPython build container
        run: |
          docker run --rm \
            -e HOST_UID=${{ steps.runner_ids.outputs.uid }} \
            -e HOST_GID=${{ steps.runner_ids.outputs.gid }} \
        ...
```
This ensures generated files are writable and manageable by the workflow after the container exits.

## Project layout.
Your **project** should have this **layout**, if you **use** the **baked-in build script**.
- **/modules** – Modules that have to be frozen in the firmware. \
There is **no need** to create **manifest.py**; it is **generated** before each build **when the directory exists**.

- **/lib** – Modules that are **not frozen** and will be **uploaded** to the microcontroller.

- **/main.py** – The entry point of the project.
To **freeze it in the firmware**, use **FREEZE_MAIN="true"**.

- **/boot.py** - (Optional) It is **executed before** main.py and is **used** to **set the board** to **safe state**.
To **freeze it in the firmware**, use **FREEZE_BOOT="true"**.

- **/dist** – The output directory.
After a **successful** build the **firmware (.bin, .hex, or .uf2)** will appear here.

- **/build_firmware.sh** – If this **file exists** in your project, it will **override** the **integrated script** inside the container.

- **/manifest.py** – If this **file exists** in your project, it will be **used** as **manifest** when building the firmware. 

### Project root not in the repo root
If your **code** is **not** in the **root directory** of the repo:
- **mount** the directory **containing** the **main.py** file and/or **modules** directories.
For example, if they are in **/src** use **-v ./src:/var/project**

## Example usage
You can use this container both for [manual](#manual-build) builds or inside a [CI/CD](#cicd-build) pipeline. \
Check the way that CI/CD can use containers, "GitHub Actions" use DinD ( Docker-in-Docker ), \
while Woodpecker CI uses separate container for each step.

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

      - name: Get runner UID and GID
        id: runner_ids
        run: |
          echo "uid=$(id -u)" >> "$GITHUB_OUTPUT"
          echo "gid=$(id -g)" >> "$GITHUB_OUTPUT"

      - name: Run MicroPython build container
        run: |
          docker run --rm \
            -e HOST_UID=${{ steps.runner_ids.outputs.uid }} \
            -e HOST_GID=${{ steps.runner_ids.outputs.gid }} \
            -e PORT=${{ vars.PORT }} \
            -e BOARD=${{ vars.BOARD }} \
            -e PROJECT_DIR="/project" \
            -v 
      
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

### VS Code setup
At the moment "MicroPico" extension for "VS Code" supports both rp2 and esp32 boards (with some kinks).

You can use this in .vscode/settings.json
```json
{
  "python.analysis.extraPaths": [
    "./lib",
    "./modules",
    "micropython-stdlib-stubs-1.26.0.post3"
  ],
  "python.analysis.typeshedPaths": [
    "micropython-stdlib-stubs-1.26.0.post3"
  ],
  "python.analysis.diagnosticSeverityOverrides": {
    "reportMissingModuleSource": "none"
  },
  "micropico.syncFolder": "",
  "micropico.additionalSyncFolders": [],
  "micropico.pyIgnore": [
    "**/.git",
    "**/.github",
    "**/.vscode",
    "**/env",
    "**/venv",
    "**/__pycache__",
    "**/modules"
  ],
  "micropico.syncFileTypes": [
    "py",
    "mpy",
    "json"
  ],
  "micropico.syncAllFileTypes": false
}
```
The micropython-stdlib-stubs-1.26.0.post3 should match the version of micropython you intent to use. 

---
---
If you find this useful, consider buying me a beer 🍺 https://buymeacoffee.com/reaper.maxpayne