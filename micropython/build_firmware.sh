#!/usr/bin/bash
set -euo pipefail

# ---------------------------------------------------------------------------
# Required environment variables
# ---------------------------------------------------------------------------
: "${PORT:?ERROR: PORT must be set (example: rp2, stm32, nrf)}"
: "${BOARD:?ERROR: BOARD must be set (example: RPI_PICO, RPI_PICO2_W)}"

PROJECT_DIR="/var/project"
MICROPY_DIR="/opt/micropython"
PORT_DIR="${MICROPY_DIR}/ports/${PORT}"
BOARD_DIR="${PORT_DIR}/boards/${BOARD}"

echo "================================================================================"
echo " Building MicroPython firmware for"
echo "--------------------------------------------------------------------------------"
echo " PORT: ${PORT}"
echo " BOARD: ${BOARD}"
echo "================================================================================"

if [[ ! -d "$PORT_DIR" ]]; then
    echo "ERROR: MicroPython port not found: $PORT_DIR"
    echo "--------------------------------------------------------------------------------"
    exit 2
fi

if [[ ! -d "$BOARD_DIR" ]]; then
    echo "ERROR: Board not found: $BOARD_DIR"
    echo "--------------------------------------------------------------------------------"
    exit 3
fi

MPY_CROSS="${MICROPY_DIR}/mpy-cross"
if [[ ! -x "$MPY_CROSS" ]]; then
    echo "ERROR: mpy-cross not found at ${MPY_CROSS}"
    exit 4
fi

export MPY_CROSS

MANIFEST="$PROJECT_DIR/manifest.py"
MODULES_DIR="$PROJECT_DIR/modules"

ls -al "$PROJECT_DIR"

if [[ -f "$MANIFEST" ]]; then
    echo " Using existing manifest.py"
    echo "--------------------------------------------------------------------------------"
else
    echo " No manifest.py found — checking if generation is needed..."
    echo "--------------------------------------------------------------------------------"

    modules_nonempty=false
    if [[ -d "$MODULES_DIR" && -n "$(ls -A "$MODULES_DIR")" ]]; then
        modules_nonempty=true
    fi

    freeze_main="${FREEZE_MAIN:-false}"
    freeze_main="${freeze_main,,}"
    generate_manifest=false

    if [[ "$modules_nonempty" == true || "$freeze_main" == "true" ]]; then
        generate_manifest=true
    fi

    if [[ "$generate_manifest" == true ]]; then
        echo " Generating manifest.py..."
        echo "--------------------------------------------------------------------------------"
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
        echo " No modules to freeze and FREEZE_MAIN not set — continuing without manifest."
        echo "--------------------------------------------------------------------------------"
    fi
fi

echo "========================================================================================="
echo " Building firmware..."
echo "========================================================================================="

cd "$PORT_DIR"

make clean
make BOARD="$BOARD" submodules
echo "-----------------------------------------------------------------------------------------"

if [[ -f "$MANIFEST" ]]; then
    echo "Using frozen manifest: $MANIFEST"
    echo "-----------------------------------------------------------------------------------------"
    make BOARD="$BOARD" FROZEN_MANIFEST="$MANIFEST" -j2
else
    make BOARD="$BOARD" -j2
fi

OUTPUT_DIR="$PROJECT_DIR/dist"
mkdir -p "$OUTPUT_DIR"
echo " OUTPUT_DIR: $OUTPUT_DIR"
echo "-----------------------------------------------------------------------------------------"

BUILD_DIR="$PORT_DIR/build-$BOARD"

if [[ -d "$BUILD_DIR" ]]; then
    cp "$BUILD_DIR"/*.bin "$BUILD_DIR"/*.hex "$BUILD_DIR"/*.uf2 "$OUTPUT_DIR/" 2>/dev/null || true
else
    echo "ERROR: Build directory not found: $BUILD_DIR"
    echo "-----------------------------------------------------------------------------------------"
    exit 5
fi

echo "========================================================================================="
echo " Project directory content:"
echo "-----------------------------------------------------------------------------------------"
ls -al $PROJECT_DIR
echo "========================================================================================="
echo " Output directory content:"
echo "-----------------------------------------------------------------------------------------"
ls -al $OUTPUT_DIR
echo "========================================================================================="