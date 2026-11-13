# Visual Studio Code
Example usage of VS Code as IDE for rp2 and esp32 boards using MicroPython codebase.

## Requirements

### Python
You can install Python in one of the following ways:
- Microsoft Store \
[v3.12](https://apps.microsoft.com/detail/9NCVDN91XZQP?hl=en-us&ocid=pdpshare)  
[v3.13](https://apps.microsoft.com/detail/9PNRBTZXMB4Z?hl=en-us&ocid=pdpshare)
---
- Stand-alone installation [here](https://www.python.org/downloads/windows/)

Python on your PC is only used for IntelliSense (stubs) and tooling - the firmware is built inside the container. Python 3.12 or later is recommended.

### USB JTAG
In some cases your system might not recognize the board as valid USB device. \
In this case you will have to download and execute [Zadig](https://zadig.akeo.ie/). \
In its options select **List All Devices**, pick your board from the device list and choose the driver that should be installed (usually **WinUSB**).

## Extensions
A list of VS Code extensions for MicroPython development.

### MicroPico
It started as an rp2 only extension, but now it also supports esp32 boards.

#### Setup
- Manual: Create **empty** file with name ".micropico" in the root directory of your project.
- Automated: 
    Install the extension \
    Press "Ctrl + Shift + P" to open **"Command Palette"** \
    Start typing **"MicroPico: Initialize MicroPico project"** and **left-click** on it or use "Up"/"Down" arrow keys to select it and press "Enter".

#### Python & Pylance
Language and IntelliSense support for VS Code 

#### Stubs
You will need them to provide IntelliSense for integrated modules like "machine", "asyncio", "os"... \
You can use **pip** to install the **stubs** for the specific board using: \
 **pip install -U micropython-\<port\>[-\<board\>]-stubs==\<micropython_version\> --target typings --no-user**

The stubs version should match the MicroPython version of your firmware. If stubs for your exact version are not published yet, use the closest older version.

```cmd
pip install -U micropython-rp2-stubs==1.29.* --target typings --no-user
```
```cmd
pip install -U micropython-rp2-pico_w-stubs==1.29.* --target typings --no-user
```
```cmd
pip install -U micropython-esp32-stubs==1.29.* --target typings --no-user
```
```cmd
pip install -U micropython-esp32-esp32_generic_c3-stubs==1.29.* --target typings --no-user
```

#### .vscode/settings.json

```json
{
    "python.analysis.extraPaths": [
        "./lib",
        "./modules",
        "./typings",
        "~/.micropico-stubs/included"
    ],
    "python.analysis.typeshedPaths": [
        "./typings",
        "~/.micropico-stubs/included"
    ],
    "python.analysis.diagnosticSeverityOverrides": {
        "reportMissingModuleSource": "none"
    },
    "micropico.syncFolder": "",
    "micropico.additionalSyncFolders": [],
    "micropico.pyIgnore": [
        "/.git",
        "/.github",
        "/.vscode",
        "/env",
        "/venv",
        "/__pycache__",
        "/modules",
        "/typings"
    ],
    "micropico.syncFileTypes": [
        "py",
        "mpy",
        "json"
    ],
    "micropico.syncAllFileTypes": false,
    "python.languageServer": "Pylance",
    "python.analysis.typeCheckingMode": "basic",
    "python.terminal.activateEnvironment": false,
    "micropico.openOnStart": true
}
```

In this example you have both: \
pip installed stubs - "./typings" (installed with **--target typings**) \
and manually installed stubs - "~/.micropico-stubs/included"

You can remove the one you don't use.

---

The "/modules" directory is in "micropico.pyIgnore" to prevent having the same module in both firmware and flash memory. \
"/typings" is ignored because the stubs are only needed by the IDE, not by the board.