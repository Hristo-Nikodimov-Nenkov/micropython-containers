# MicroPython Build Container for ESP32 based boards
This Docker container allows you to **build MicroPython firmware** for **esp32 port**. \
If you are using other board from other port you should use [micropython](https://hub.docker.com/r/rav3nh01m/micropython). 

## Table of Contents

- [Supported MicroPython Versions](#supported-micropython-versions)
- [Environment Variables](#environment-variables)
- [Project layout](#project-layout)
- [Example Usage](#example-usage)

---

## Supported MicroPython versions
You can check which versions are available [here](https://hub.docker.com/r/rav3nh01m/micropython_esp-idf/tags). \
The **tag** is the **version** of MicroPyhon container will build and the **version** of ESP-IDF used in the build procces.

**All packages are pre-installed.**

## Environment Variables
The container uses the following environment variables as input:

### Firmware configuration

- **BOARD**
The target board for which the firmware is built.
**Must be uppercase** and must **exactly match** a directory name in: **micropython/ports/esp32/boards**

- **BOARD_VARIANT**
Some boards support variants.
If you **want to use** this variable, check the **available variants** for that specific board.

---

### Freezing files into firmware

- **FREEZE_MAIN** - **String** value: **"true"** or **"false"**. \
When **enabled**, main.py (if present) is **frozen** into the firmware. \
Useful for **flash-and-forget** deployments.

- **FREEZE_BOOT** - **String** value: **"true"** or **"false"**. \
When **enabled**, boot.py (if present) is **frozen** into the firmware. \
Useful for setting a **safe default state** of **board pins** in **flash-and-forget** deployments.

When **/modules** directory exists it's **content** is **frozen** relative to it. \
If you have module like /modules/test_module you should use **"import test_module"** or **"from text_module import ..."**

**When module with the same name exists in firmware and flash you'll receive an error.**

---

### Build information (automatically set)

- **MICROPYTHON_VERSION** and **ESP_IDF_VERSION** \
Already **baked into the image** as environment variables (set from the same build-args used to **build** it), so they always reflect the **exact** MicroPython and ESP-IDF versions that image contains - even when you pulled it by a shorthand tag (e.g. **v1.29_v5.5**) or **latest**. \
You **don't need to set them yourself**; only pass **-e MICROPYTHON_VERSION=...** / **-e ESP_IDF_VERSION=...** if you deliberately want to **override** the value written below (this makes the reported version **less accurate**, not more).

When **/modules** is frozen (see above), the container **appends build info** to the frozen copy of **modules/firmware.py** - the project's own file (if any) is **left untouched**, only the copy that gets built into the firmware gains these lines:
```python
MICROPYTHON_VERSION = "v1.29.0"
PORT = "esp32"
BOARD = "ESP32_GENERIC_C3"
ESP_IDF_VERSION = "v5.5.2"
FROZEN_BOOT_PY = False
FROZEN_MAIN_PY = True
```
This lets your firmware code read its own build info (e.g. to expose it over an API) **without hardcoding it** anywhere in your project.

---

### Project directory

- **PROJECT_DIR** - Path to the **project directory**.

When running in CI/CD and the container is used as image the baked-in build_firmware.sh script will usually auto-detected and use the CI workspace. \
In "Woodpecker CI"
```yaml
- name: Build firmware
  image: rav3nh01m/micropython_esp-idf:latest
  environment:
    BOARD: ESP32_GENERIC_C3
```

This will execute the baked-in build script and generated .bin files will be in /dist directory relative to CI workspace.
If you receive un error add PROJECT_DIR environment variable and mount the CI workspace using:
```yaml
- name: Build firmware
  image: rav3nh01m/micropython_esp-idf:latest
  environment:
    BOARD: ESP32_GENERIC_C3
    PROJECT_DIR: /project
  volumes:
    ${CI_WORKSPACE}:/project
```

When the workflow uses DinD ( Docker in Docker) you should set the environment variable.
In "GitHub Actions:"
```yaml
- name: Run MicroPython build container
  run: |
    docker run --rm \
      -e PROJECT_DIR=/project \
      -v "$PWD:/project" \
      rav3nh01m/micropython:latest
```
**PROJECT_DIR value must be the same as the mount path in the container, in this case "/project".**

**If you use a custom build_firmware.sh, you must handle this yourself**.

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
- name: Run MicroPython build container
  run: |
    UID=$(id -u)
    GID=$(id -g)

    docker run --rm \
      -e HOST_UID=$UID \
      -e HOST_GID=$GID \
  ...
```
or:
```yaml
- name: Run MicroPython build container
  run: |
    docker run --rm \
      -e HOST_UID=$(id -u) \
      -e HOST_GID=$(id -g) \
  ...
```

This ensures generated files are writable and manageable by the workflow after the container exits.

## Project layout.
Your **project** should have this **layout**, if you **use** the **baked-in build script**.
- **/modules** – Modules that have to be frozen in the firmware. \
There is **no need** to create **manifest.py**; it is **generated** before each build **when the directory exists and is not empty**.

- **/lib** – Modules that are **not frozen** and has to be **uploaded** to the microcontroller. 

- **/main.py** – The entry point of the project.
To **freeze it in the firmware**, use **FREEZE_MAIN="true"**.

- **/boot.py** - (Optional) It is **executed before** main.py and is **used** to **set board pins** to **safe state**.
To **freeze it in the firmware**, use **FREEZE_BOOT="true"**.

- **/dist** – The output directory.
After a **successful** build the **firmware (.bin files - bootloader, partition-table and the app image)** will appear here.

- **/build_firmware.sh** – If this **file exists** in your project, it will **override** the **integrated script** inside the container.

- **/manifest.py** – If this **file exists** in your project, it will be **used** as **manifest** when building the firmware. 

- **/sdkconfig.board** – If this **file exists** in your project, it is **copied** into the **board directory** and **appended** to **SDKCONFIG_DEFAULTS** in **mpconfigboard.cmake**, **after** the board's own defaults. \
Boards list every sdkconfig fragment they use **explicitly** in their own **mpconfigboard.cmake** (there is **no** upstream **auto-discovery** of a conventionally-named file), so this lets a **project override** any **pure sdkconfig** default - **later entries win** for the **same key** - **without** patching or **forking MicroPython**.

Useful for things like:
```
CONFIG_ESP_DEFAULT_CPU_FREQ_MHZ=160
CONFIG_ESP_MAIN_TASK_STACK_SIZE=4096
CONFIG_MBEDTLS_SSL_MAX_CONTENT_LEN=4096
CONFIG_ESP_WIFI_STATIC_RX_BUFFER_NUM=6
CONFIG_LOG_DEFAULT_LEVEL_WARN=y
CONFIG_ESP_TASK_WDT_TIMEOUT_S=10
```

**This does NOT work to disable Bluetooth.** Every stock ESP32-C3 board pulls in **boards/sdkconfig.ble** unconditionally, reserving RAM for the NimBLE stack whether or not the firmware ever uses Bluetooth - but setting `CONFIG_BT_ENABLED=n` (and friends) here only removes the **ESP-IDF** component. MicroPython's ESP32 port hardcodes `MICROPY_PY_BLUETOOTH` to `(1)` for every board **independent of sdkconfig**, so it still compiles its NimBLE bindings - which then fail to find the NimBLE headers ESP-IDF no longer built, breaking the build. \
Use [rav3nh01m/micropython_esp-idf_no-bt](https://hub.docker.com/r/rav3nh01m/micropython_esp-idf_no-bt) instead if you want to disable Bluetooth and reclaim that RAM - it compiles MicroPython itself without NimBLE support, and this same `sdkconfig.board` override (with `CONFIG_BT_ENABLED=n`) works there to also drop the ESP-IDF side.

**If HTTPS requests fail** (e.g. TLS/mbedtls allocation errors during the handshake) and your project **doesn't need Bluetooth**, the RAM NimBLE reserves is a common culprit on memory-constrained boards like the ESP32-C3 - there's simply not enough heap left for the TLS buffers. Switching to [rav3nh01m/micropython_esp-idf_no-bt](https://hub.docker.com/r/rav3nh01m/micropython_esp-idf_no-bt) frees that RAM and is usually the better option in that case.

**Note:** changing this file changes the **sdkconfig**, which **invalidates** the **existing build cache** for that board - expect a **full rebuild**, not an incremental one, the **next** time it changes.

### Project root not in the repo root
If your **code** is **not** in the **root directory** of the repo then you should **mount** the directory \
**containing** the **main.py** file and/or **modules** directories. For example, if they are in **/src** use:
- **-v ./src:/project**
- **PROJECT_DIR=/project**

## Example usage
You can use this container both for [manual](#manual-build) builds or inside a [CI/CD](#cicd-build) pipeline. \
Check the way that CI/CD can use containers, "GitHub Actions" use DinD ( Docker-in-Docker ), \
while Woodpecker CI uses separate container for each step.

### Manual build
---

Pull the image:
```bash
docker pull rav3nh01m/micropython_esp-idf:latest
```

After that, run:
```bash
docker run --rm \
-e PROJECT_DIR="/project" \
-e BOARD=ESP32_GENERIC_C3 \
-v ./:/project \
rav3nh01m/micropython_esp-idf:latest
```
The **path** you **mount** the project ( -v ./:**/project** ) must be the same as **PROJECT_DIR** ( -e PROJECT_DIR="**/project**").

---

Or if you want to freeze main.py:

```bash
docker run --rm \
-e PROJECT_DIR="/project" \
-e BOARD=ESP32_GENERIC_C3 \
-e FREEZE_MAIN=true \
-v ./:/project \
rav3nh01m/micropython_esp-idf:latest
```
---
Or if you want to freeze boot.py:

```bash
docker run --rm \
-e PROJECT_DIR="/project" \
-e BOARD=ESP32_GENERIC_C3 \
-e FREEZE_BOOT=true \
-v ./:/project \
rav3nh01m/micropython_esp-idf:latest
```
---

You can use **any version** of MicroPython **available** in the **set** by changing **latest** to the **version** you want. \
It should be like: **v1.27.0_v5.5.1**, **v1.27_v5.5.1**, **v1.27.0_v5.5** or **v1.27_v5.5**. 
You can see all available versions [here](https://hub.docker.com/r/rav3nh01m/micropython_esp-idf/tags).

---

After the **build completes**, the **firmware** will be in **/dist** relative to **PROJECT_DIR**. \
**-e PROJECT_DIR=<container_path>** \
**-v <host_path>:<container_path>**

The container path **must** be the **same** as **PROJECT_DIR**, unless you use **custom build_firmware.sh**.

### CI/CD build
You can use GitHub Actions, Woodpecker, GitLab CI or any other CI/CD system to set up automatic builds.

---

**Before pushing this workflow to GitHub you must create IMAGE_TAG and BOARD actions variables (not Environment).** \
If you want to **use environment variables** you should change **\${{ vars. }}** to **\${{ env. }}**
```yaml
name: Build firmware (upload artifact)

on:
  push:
    branches: [main]
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest    
    steps:
      # Checkout project code
      - name: Checkout
        uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2

      # The IMAGE_TAG actions variable must be set before workflow push to main brach.
      # If you preffer using environment variables change "vars." to "env."
      # You can set them both in workflow "env:" section or in Settings > Secrets and variables > Actions
      - name: Determine Docker image
        id: docker_image
        run: |
          IMAGE_BASE="rav3nh01m/micropython_esp-idf"
          IMAGE="$IMAGE_BASE:${{ vars.IMAGE_TAG }}"

          echo "Checking for image: $IMAGE"

          if docker pull "$IMAGE"; then
            echo "Using image: $IMAGE"
          else
            echo "Image not found. Falling back to latest."
            IMAGE="$IMAGE_BASE:latest"
            docker pull "$IMAGE"
          fi

          echo "image=$IMAGE" >> "$GITHUB_OUTPUT"

      - name: Run MicroPython build container
        run: |
          docker run --rm \
            -e HOST_UID=$(id -u) \
            -e HOST_GID=$(id -g) \
            -e PROJECT_DIR=/project \
            -e BOARD="${{ vars.BOARD }}" \
#            -e FREEZE_BOOT="${{ vars.FREEZE_BOOT }}" \
#            -e FREEZE_MAIN="${{ vars.FREEZE_MAIN }}" \
            -v "$PWD:/project" \
            "${{ steps.docker_image.outputs.image }}"

      # Upload firmware artifacts
      - name: Upload firmware artifacts
        uses: actions/upload-artifact@v3
        with:
          name: firmware
          path: dist/**
```
If you want to freeze main.py:
- Add FREEZE_MAIN with value "true" to workflow variables.
- Uncomment **#   -e FREEZE_MAIN="${{ vars.FREEZE_MAIN }}"** i.e remove "#". \
- Push the workflow to GitHub.

If you want to freeze main.py:
- Add FREEZE_BOOT with value "true" to workflow variables.
- Uncomment **#   -e FREEZE_BOOT="${{ vars.FREEZE_BOOT }}"** i.e remove "#". \
- Push the workflow to GitHub.

If you want to **use environment variables** instead change **\${{ vars. }}** to **\${{ env. }}**

---
You can **create automatic releases** of the firmware by using this workflow. 

You must also set:
- VERSION, MAJOR and MINOR actions variables to generate releases like v0.1.4.x\
where VERSION is 0, MAJOR is 1, MINOR is 4 and x is the workflow run number.
- IS_PRERELEASE - if you want to be able to have an easy way to change the prerelease flag of the release.

```yaml
name: Build and release

env:
  # The VERSION, MAJOR & MINOR actions variables must be set before workflow push to main brach.
  # You can set them in Settings > Secrets and variables > Actions | Variables |
  BUILD_VERSION: ${{ vars.VERSION }}.${{ vars.MAJOR }}.${{ vars.MINOR }}.${{ github.run_number }}

on:
  push:
    branches:
      - main

jobs:
  build-and-release:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2

      - name: Determine Docker image
        id: docker_image
        run: |
          IMAGE_BASE="rav3nh01m/micropython_esp-idf"
          IMAGE="$IMAGE_BASE:${{ vars.IMAGE_TAG }}"

          echo "Checking for image: $IMAGE"

          if docker pull "$IMAGE"; then
            echo "Using image: $IMAGE"
          else
            echo "Image not found. Falling back to latest."
            IMAGE="$IMAGE_BASE:latest"
            docker pull "$IMAGE"
          fi

          echo "image=$IMAGE" >> "$GITHUB_OUTPUT"
      
      - name: Run MicroPython build container
        run: |
          docker run --rm \
            -e HOST_UID=$(id -u) \
            -e HOST_GID=$(id -g) \
            -e PROJECT_DIR=/project \
            -e BOARD="${{ vars.BOARD }}" \
#            -e FREEZE_BOOT="${{ vars.FREEZE_BOOT }}" \
#            -e FREEZE_MAIN="${{ vars.FREEZE_MAIN }}" \
            -v "$PWD:/project" \
            "${{ steps.docker_image.outputs.image }}"

      - name: Copy firmware with version in file name
        run: |
          mkdir -p release
          for f in dist/*.bin; do
            base=$(basename "$f" .bin)
            cp "$f" "release/${base}-v${{ env.BUILD_VERSION }}.bin"
          done

      - name: Create firmware zip
        working-directory: ./release
        run: zip -j firmware-v${{env.BUILD_VERSION}}.zip micropython-v${{env.BUILD_VERSION}}.bin

      - name: Create split firmware zip
        working-directory: ./release
        run: |
          zip splitted_firmware-v${{ env.BUILD_VERSION }}.zip \
            micropython*.bin \
            bootloader*.bin \
            partition-table*.bin

      - name: Create code.zip
        run: |
          mkdir -p ./release/code
      
          if [ -d ".vscode" ]; then
            cp -R .vscode ./release/code/
            echo "Copied .vscode"
          else
            echo ".vscode directory not found — skipping"
          fi

          if [ -d "lib" ]; then
            cp -R lib ./release/code/
            echo "Copied lib"
          else
            echo "lib directory not found — skipping"
          fi
      # If you want you can add more directories or file to be ziped. 

      # Conditional step that handles where main.py is stored - firmware or code
      - name: Copy main.py (if not frozen)
        if: ${{ vars.FREEZE_MAIN != 'true' }}
        run: |
          if [ -f "main.py" ]; then
            cp main.py ./release/code/
            echo "Copied main.py"
          else
            echo "main.py not found — skipping"
          fi

      # Conditional step that handles where boot.py is stored - firmware or code
      - name: Copy boot.py (if not frozen)
        if: ${{ vars.FREEZE_BOOT != 'true' }}
        run: |
          if [ -f "boot.py" ]; then
            cp boot.py ./release/code/
            echo "Copied main.py"
          else
            echo "boot.py not found — skipping"
          fi

      - name: Create code zip
        working-directory: ./release/code
        run: zip -r ../code-v${{env.BUILD_VERSION}}.zip .

      # Make sure that you've set Settings > Actions > General - Workflow permissions to "Read and write permissions".
      # Also don't forget to press the "Save" button.
      - name: Authenticate Git
        run: git remote set-url origin https://x-access-token:${{secrets.GITHUB_TOKEN}}@github.com/${{github.repository}}

      - name: Create tag
        run: |
          git config user.name "github-actions"
          git config user.email "github-actions@github.com"
          git tag v${{ env.BUILD_VERSION }}
          git push origin v${{ env.BUILD_VERSION }}

      # Uploads files to release
      - name: Create Release
        uses: softprops/action-gh-release@v1
        with:
          tag_name: v${{ env.BUILD_VERSION }}
          name: Release v${{ env.BUILD_VERSION }}
          prerelease: ${{ vars.IS_PRERELEASE }}
          files: |
            ./release/firmware-v${{ env.BUILD_VERSION }}.zip
            ./release/splitted_firmware-v${{ env.BUILD_VERSION }}.zip
            ./release/code-v${{env.BUILD_VERSION}}.zip
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```
**You must set Settings → Actions → General → Workflow permissions to Read/Write!** \
**This workflow creates a separate release for every push to main branch.**

To reset the workflow run number you can change the yaml file name. \
Use this workflow:
- Create the variables needed (IMAGE_TAG, BOARD, VERSION, MAJOR, MINOR, IS_PRERELEASE) and set their values.
- Create build-v{VERSION}.{MAJOR}.{MINOR}.x.yml as your workflow.
- Set workflow permissions to Read/Write.
- Press the "Save" button.
- Push the workflow to main branch.

You can reset the **run_number** for every version bump by:
- Change the values of the VERSION, MAJOR and MINOR variables.
- Rename the .yml to match the values of the variables.
- Push to main branch

With the value of **IS_PRERELEASE** you select if the build is full release or pre-release. \
The value **MUST** be set **BEFORE** the push to the **main branch!**

### VS Code setup
You can use this in .vscode/settings.json

```json
{
    "python.languageServer": "Pylance",
    "python.analysis.typeCheckingMode": "basic",
    "python.analysis.diagnosticSeverityOverrides": {
        "reportMissingModuleSource": "none"
    },
    "python.analysis.extraPaths": [
        "~/.micropico-stubs/included",
        "./modules",
        "./lib"
    ],
    "python.analysis.typeshedPaths": [
        "~/.micropico-stubs/included"
    ],
    "micropico.syncFolder": "",
    "micropico.openOnStart": true,
    "micropico.syncAllFileTypes": true,
    "micropico.pyIgnore":[
        "/modules",
        "/.micropico",
        "/.github",
        "/.git",
        "/.gitignore",
        "/.vscode",
        "/.idea",
        "/.DS_Store",
        "/.stash"
    ]
}
```
If you want you can change
```json
    "micropico.syncAllFileTypes": true,
```
to
```json
  "micropico.syncAllFileTypes": false,
  "micropico.syncFileTypes": [
    "py",
    "mpy",
    "json"
  ]
```
and list the file types that should be uploaded.

The micropython-stdlib-stubs version should match the version of micropython you intent to use. \
And in this case is installed using pip
```cmd
pip install micropython-esp32-esp32_generic_c3-stubs==1.27.0.post1
```

---
---
If you find this useful, consider buying me a beer 🍺 https://buymeacoffee.com/reaper.maxpayne