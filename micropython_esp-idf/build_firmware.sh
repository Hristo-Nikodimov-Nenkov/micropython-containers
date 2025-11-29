#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------
# Config
# -----------------------------------------------------------------------
MICROPYTHON_DIR="/opt/micropython"
IDF_PATH="/opt/esp-idf"
EXPORT_SH="$IDF_PATH/export.sh"

BOARD="${BOARD:?ERROR: BOARD environment variable not set}"
BUILD_DIR="/project"
PORT_DIR="$MICROPYTHON_DIR/ports/esp32"
BOARD_DIR="$PORT_DIR/boards/$BOARD"

# -----------------------------------------------------------------------
# Checks
# -----------------------------------------------------------------------
[[ -d "$MICROPYTHON_DIR" ]] || { echo "ERROR: MicroPython not found"; exit 1; }
[[ -d "$IDF_PATH" ]] || { echo "ERROR: ESP-IDF not found"; exit 1; }
[[ -d "$BOARD_DIR" ]] || { echo "ERROR: Board not found: $BOARD_DIR"; exit 1; }
[[ -d "$BUILD_DIR" ]] || { echo "ERROR: /project not mounted"; exit 1; }

echo "==========================================="
echo " MicroPython ESP32 Firmware Builder"
echo " BOARD       = $BOARD"
echo " MicroPython = $MICROPYTHON_DIR"
echo " ESP-IDF     = $IDF_PATH"
echo " Project     = $BUILD_DIR"
echo "==========================================="

# -----------------------------------------------------------------------
# Optional custom override
# -----------------------------------------------------------------------
if [[ -f "$BUILD_DIR/build_firmware.sh" ]]; then
    echo "Executing custom project build script..."
    exec "$BUILD_DIR/build_firmware.sh"
fi

# -----------------------------------------------------------------------
# Source ESP-IDF environment
# -----------------------------------------------------------------------
echo "Sourcing ESP-IDF environment..."
source "$EXPORT_SH"

echo "ESP-IDF version: $(idf.py --version)"

# -----------------------------------------------------------------------
# Prepare mpy-cross
# -----------------------------------------------------------------------
MPY_CROSS=""
for c in "$MICROPYTHON_DIR/mpy-cross" "$MICROPYTHON_DIR/lib/mpy-cross"; do
    [[ -x "$c" ]] && MPY_CROSS="$c" && break
done
[[ -n "$MPY_CROSS" ]] || { echo "ERROR: mpy-cross not found"; exit 1; }
export MPY_CROSS
echo "mpy-cross: $MPY_CROSS"

# -----------------------------------------------------------------------
# Prepare build
# -----------------------------------------------------------------------
pushd "$PORT_DIR" >/dev/null

# Remove previous build safely
BUILD_PATH="build-$BOARD"
[[ -d "$BUILD_PATH" ]] && rm -rf "$BUILD_PATH"

# Initialize submodules
echo "Updating submodules..."
make submodules || { echo "ERROR: make submodules failed"; exit 2; }

# -----------------------------------------------------------------------
# Generate dynamic manifest.py if modules exist
# -----------------------------------------------------------------------
if [[ -d "$BUILD_DIR/modules" ]]; then
    echo "Creating dynamic manifest.py..."
    {
        echo 'include("$(PORT_DIR)/boards/manifest.py")'
        echo ''
        echo 'freeze("modules", opt=3)'
        echo 'freeze(".", script="main.py", opt=3)'

    } > "$BUILD_DIR/manifest.py"

    MANIFEST_ARG="FROZEN_MANIFEST=$BUILD_DIR/manifest.py"
else
    MANIFEST_ARG=""
fi

# -----------------------------------------------------------------------
# Build firmware
# -----------------------------------------------------------------------
echo "Building firmware for board $BOARD..."
make BOARD="$BOARD" $MANIFEST_ARG -j"$(nproc)" || { echo "ERROR: Build failed"; exit 3; }

popd >/dev/null

# -----------------------------------------------------------------------
# Collect firmware outputs
# -----------------------------------------------------------------------
OUTPUT_DIR="$BUILD_DIR/dist"
mkdir -p "$OUTPUT_DIR"

FIRMWARE_FILES=($(find "$PORT_DIR/$BUILD_PATH" -type f -name "*.bin"))

[[ ${#FIRMWARE_FILES[@]} -gt 0 ]] || { echo "ERROR: No firmware output"; exit 4; }

cp "${FIRMWARE_FILES[@]}" "$OUTPUT_DIR/"

echo "==========================================="
echo " Firmware Build Complete"
for f in "${FIRMWARE_FILES[@]}"; do
    echo " Output → $OUTPUT_DIR/$(basename "$f")"
done
echo "==========================================="