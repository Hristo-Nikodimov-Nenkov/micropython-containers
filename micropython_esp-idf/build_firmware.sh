#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# Required environment variables
# ---------------------------------------------------------------------------
: "${BOARD:?ERROR: BOARD must be set (example: RPI_PICO, RPI_PICO2_W)}"

PROJECT_DIR="/project"
MICROPYTHON_DIR="/opt/micropython"
IDF_PATH="/opt/esp-idf"
EXPORT_SH="$IDF_PATH/export.sh"
PORT_DIR="${MICROPYTHON_DIR}/ports/esp32"
BOARD_DIR="${PORT_DIR}/boards/${BOARD}"

echo "==========================================="
echo " Building MicroPython firmware for:"
echo " BOARD = ${BOARD}"
echo "==========================================="

if [[ ! -d "$PORT_DIR" ]]; then
    echo "ERROR: MicroPython port not found: $PORT_DIR"
    exit 2
fi

if [[ ! -d "$BOARD_DIR" ]]; then
    echo "ERROR: Board not found: $BOARD_DIR"
    exit 3
fi

# -----------------------------------------------------------------------
# Source ESP-IDF environment
# -----------------------------------------------------------------------
echo "Sourcing ESP-IDF environment..."
source "$EXPORT_SH"

echo "ESP-IDF version: $(idf.py --version)"

MPY_CROSS="${MICROPYTHON_DIR}/mpy-cross"
if [[ ! -x "$MPY_CROSS" ]]; then
    echo "ERROR: mpy-cross not found at ${MPY_CROSS}"
    exit 4
fi
export MPY_CROSS

# ---------------------------------------------------------------------------
# Handle manifest
# ---------------------------------------------------------------------------
MANIFEST="$PROJECT_DIR/manifest.py"
MODULES_DIR="$PROJECT_DIR/modules"

if [[ -f "$MANIFEST" ]]; then
    echo "Using existing manifest.py"
else
    echo "No manifest.py found — checking if generation is needed..."

    modules_nonempty=false
    if [ -d "$MODULES_DIR" ] && find "$MODULES_DIR" -mindepth 1 | read; then
        modules_nonempty=true
    fi

    freeze_main="${FREEZE_MAIN:-false}"
    freeze_main="${freeze_main,,}"
    generate_manifest=false

    if [[ "$modules_nonempty" == true || "$freeze_main" == "true" ]]; then
        generate_manifest=true
    fi

    if [[ "$generate_manifest" == true ]]; then
        echo "Generating manifest.py..."
        {
            echo 'include("$(PORT_DIR)/boards/manifest.py")'
            echo
            if [[ "$modules_nonempty" == true ]]; then
                echo 'freeze("modules", opt=3)'
            fi
            if [[ "$freeze_main" == "true" ]]; then
                echo 'freeze(".", script="main.py", opt=3)'
            fi
        } > "$MANIFEST"
    else
        echo "No modules to freeze and FREEZE_MAIN not set — continuing without manifest."
    fi
fi

# ---------------------------------------------------------------------------
# Build firmware
# ---------------------------------------------------------------------------
echo "==========================================="
echo " Building firmware..."
echo "==========================================="

cd "$PORT_DIR"

make clean
make BOARD="$BOARD" submodules

if [[ -f "$MANIFEST" ]]; then
    echo "Using frozen manifest: $MANIFEST"
    make BOARD="$BOARD" FROZEN_MANIFEST="$MANIFEST" -j"$(nproc)"
else
    make BOARD="$BOARD" -j"$(nproc)"
fi

OUTPUT_DIR="$PROJECT_DIR/dist"
mkdir -p "$OUTPUT_DIR"

BUILD_DIR="$PORT_DIR/build-$BOARD"

if [[ -d "$BUILD_DIR" ]]; then
    cp "$BUILD_DIR"/*.bin "$OUTPUT_DIR/" 2>/dev/null || true
else
    echo "ERROR: Build directory not found: $BUILD_DIR"
    exit 5
fi