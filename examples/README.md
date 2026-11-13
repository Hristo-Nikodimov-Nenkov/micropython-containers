# Examples
Ready-to-use examples for the MicroPython build containers.

## CI/CD workflows
- [GitHub Actions / build_and_upload_artefact.yml](workflows/GitHub%20Actions/build_and_upload_artefact.yml) \
Builds the firmware on every push to **main** and uploads the zipped firmware and code as a workflow **artifact**.
- [GitHub Actions / build_and_release.yml](workflows/GitHub%20Actions/build_and_release.yml) \
Builds the firmware on every push to **main**, creates a **tag** and a **GitHub release** with the zipped firmware and code.
- [Woodpecker CI / build/.woodpecker.yml](workflows/Woodpecker%20CI/build/.woodpecker.yml) \
Builds the firmware using the container as the step image. The firmware ends up in **dist/** in the CI workspace.

The GitHub Actions examples use **rav3nh01m/micropython_esp-idf** (ESP32 boards). \
For other ports change the image to **rav3nh01m/micropython** and add **-e PORT="${{ vars.PORT }}"** to the **docker run** command.
For non-ESP32 ports there are no split images, so also remove the **Create split firmware zip** step and its file from the upload/release.

### GitHub Actions variables
Create these in **Settings → Secrets and variables → Actions → Variables** before pushing the workflow:

| Variable | Required | Description |
|---|---|---|
| IMAGE_TAG | yes | Image tag to use, e.g. **v1.29_v5.5**. Falls back to **latest** if not found. |
| BOARD | yes | Board name, e.g. **ESP32_GENERIC_C3**. |
| VERSION, MAJOR, MINOR | yes | Used to build the version **VERSION.MAJOR.MINOR.run_number**. |
| FREEZE_MAIN, FREEZE_BOOT | no | Set to **"true"** to freeze main.py / boot.py into the firmware. |
| IS_PRERELEASE | release only | **true** / **false** - marks the GitHub release as a pre-release. |

The release workflow also needs **Settings → Actions → General → Workflow permissions** set to **Read and write permissions**.

## IDE
- [VS Code on Windows](VS%20Code/Windows/README.md) - MicroPico, Pylance and stubs setup.
