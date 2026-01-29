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

Since the containers use Ubuntu 24.04 the recomended version of Python is 3.12 or later.

### USB JTAG
In some cases your system might not recognize the board as valid USB device. \
In this caces you will have to download and execute [Zadig](https://zadig.akeo.ie/). \
In it's options you should select the COM port and the driver that should be installed.

## Extensions
A list of VS Code extensions for MicroPython development.

### MicroPico
It started as rp2 only extension, but now it also support esp32 boards.

#### Setup
- Manual: Create **empty** file with name ".micropico" in the root directory of your project.
- Automated: 
    Install the extension \
    Press "Ctrl + Shift + P" to open **"Command Palette"** \
    Start typing **"MicroPico: Initialize MicroPico project"** and **left-click** on it or use "Up"/"Down" arrow keys to select it and press "Enter".

#### Python & Pylance
Language and IntelliSense support for VS Code 

#### Stubs
You will need them to provide IntelliSense for integrated modules like "machine", "uasyncio", "uos"... \
You can use **pip** to install the **stubs** for the specific board using: \
 **pip install -U micropython-\<port\>[-\<board\>]-stubs==\<micropython_version\> --no-user**

```cmd
pip install -U micropython-rp2-stubs==1.27.0.* --target typings --no-user
```
```cmd
pip install -U micropython-rp2-pico_w-stubs==1.27.0.* --target typings --no-user
```
```cmd
pip install -U micropython-esp32-stubs==1.27.0.* --target typings --no-user
```
```cmd
pip install -U micropython-esp32-esp32_generic_c3-stubs==1.27.0.* --target typings --no-user
```

#### .vscode/settings.json

```json
{
    "python.analysis.extraPaths": [
        "./lib",
        "./modules",
        "micropython-esp32-esp32_generic_c3-stubs-1.27.0.post1",
        "~/.micropico-stubs/included"
    ],
    "python.analysis.typeshedPaths": [
        "micropython-esp32-esp32_generic_c3-stubs-1.27.0.post1",
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
        "/modules"
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
pip installed stubs - "micropython-esp32-esp32_generic_c3-stubs-1.27.0.post1" \
and manually installed stubs - "~/.micropico-stubs/included"

You can remove the one you don't use.

---

The "/modules" directory is "micropico.pyIgnore" to prevent the case of having same module in both firmware and flash memory.