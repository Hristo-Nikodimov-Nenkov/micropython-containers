#!/usr/bin/bash
set -euo pipefail

# ---------------------------------------------------------------------------
# Set PROJECT_DIR variable
# ---------------------------------------------------------------------------
if [[ -n "${PROJECT_DIR:-}" ]]; then
    PROJECT_DIR="$(realpath "$PROJECT_DIR")"
elif [[ -n "${CI_WORKSPACE:-}" ]]; then
    PROJECT_DIR="$(realpath "$CI_WORKSPACE")"
elif [[ -n "${GITHUB_WORKSPACE:-}" ]]; then
    PROJECT_DIR="$(realpath "$GITHUB_WORKSPACE")"
elif [[ -n "${CI_PROJECT_DIR:-}" ]]; then
    PROJECT_DIR="$(realpath "$CI_PROJECT_DIR")"
elif [[ -n "${CIRCLE_WORKING_DIRECTORY:-}" ]]; then
    PROJECT_DIR="$(realpath "$CIRCLE_WORKING_DIRECTORY")"
elif [[ -n "${BUILD_SOURCESDIRECTORY:-}" ]]; then
    PROJECT_DIR="$(realpath "$BUILD_SOURCESDIRECTORY")"
elif [[ -n "${BITBUCKET_CLONE_DIR:-}" ]]; then
    PROJECT_DIR="$(realpath "$BITBUCKET_CLONE_DIR")"
elif [[ -n "${WORKSPACE:-}" ]]; then
    PROJECT_DIR="$(realpath "$WORKSPACE")"
else
    echo "================================================================================"
    echo "ERROR: PROJECT_DIR not set and no known CI workspace variable found"
    echo "================================================================================"
    exit 1
fi

# ---------------------------------------------------------------------------
# Check if HOST_UID and/or HOST_GID is set or fallback to 0 (root)
# ---------------------------------------------------------------------------
TARGET_UID="${HOST_UID:-0}"
TARGET_GID="${HOST_GID:-0}"

# ---------------------------------------------------------------------------
# Check for custom build_firmware.sh
# ---------------------------------------------------------------------------
PROJECT_SCRIPT="$PROJECT_DIR/build_firmware.sh"
IMAGE_SCRIPT="/usr/local/bin/build_firmware.sh"

if [[ -f "$PROJECT_SCRIPT" ]]; then
    echo "================================================================================"
    echo " Using build_firmware.sh from project."
    echo "================================================================================"
    chmod +x "$PROJECT_DIR/build_firmware.sh"
    exec "$PROJECT_SCRIPT"
else
    echo "================================================================================"
    echo " Using baked-in build_firmware.sh"
    echo "================================================================================"
fi

# ---------------------------------------------------------------------------
# Required environment variables
# ---------------------------------------------------------------------------
: "${PORT:?ERROR: PORT must be set (example: rp2, stm32, nrf)}"
: "${BOARD:?ERROR: BOARD must be set (example: RPI_PICO, RPI_PICO2_W)}"

MICROPY_DIR="/opt/micropython"
PORT_DIR="${MICROPY_DIR}/ports/${PORT}"
BOARD_DIR="${PORT_DIR}/boards/${BOARD}"

echo "================================================================================"
echo " Building MicroPython firmware for"
echo "--------------------------------------------------------------------------------"
echo " PORT: ${PORT}, BOARD: ${BOARD}"
echo "--------------------------------------------------------------------------------"

if [[ ! -d "$PORT_DIR" ]]; then
    echo "ERROR: MicroPython port not found: $PORT_DIR"
    echo "================================================================================"
    exit 2
fi

if [[ ! -d "$BOARD_DIR" ]]; then
    echo "ERROR: Board not found: $BOARD_DIR"
    echo "================================================================================"
    exit 3
fi

MPY_CROSS="${MICROPY_DIR}/mpy-cross"
if [[ ! -x "$MPY_CROSS" ]]; then
    echo "ERROR: mpy-cross not found at ${MPY_CROSS}"
    echo "================================================================================"
    exit 4
fi

export MPY_CROSS

MANIFEST="$PROJECT_DIR/manifest.py"
MODULES_DIR="$PROJECT_DIR/modules"

cd "$PROJECT_DIR"

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

    generate_manifest=false

    if [[ "$modules_nonempty" == true ]]; then
        generate_manifest=true
    fi

    freeze_main="${FREEZE_MAIN:-false}"
    freeze_main="${freeze_main,,}"
    if [[ -f "main.py" ]] && [[ "$freeze_main" == true ]]; then
        generate_manifest=true
    fi

    freeze_boot="${FREEZE_BOOT:-false}"
    freeze_boot="${freeze_boot,,}"
    if [[ -f "boot.py" ]] && [[ "$freeze_boot" == true ]]; then
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
            if [[ "$freeze_main" == true ]]; then
                echo 'freeze(".", script="main.py", opt=3)'
            fi
            if [[ "$freeze_boot" == true ]]; then
                echo 'freeze(".", script="boot.py", opt=3)'
            fi
        } > "$MANIFEST"
        
        echo "--------------------------------------------------------------------------------"
        echo " Using generated manifest.py"
        echo "--------------------------------------------------------------------------------"
        cat "$MANIFEST"
        echo "--------------------------------------------------------------------------------"
        
        # Copy modules directory if needed
        if [[ "$modules_nonempty" == true ]]; then
            echo "Copying modules/ to $BOARD_DIR"
            cp -r "$MODULES_DIR" "$BOARD_DIR/"
        fi

        # Copy main.py if needed
        if [[ "$freeze_main" == true ]]; then
            echo "Copying main.py to $BOARD_DIR"
            cp "$PROJECT_DIR/main.py" "$BOARD_DIR/"
        fi

        # Copy boot.py if needed
        if [[ "$freeze_boot" == true && -f "boot.py" ]]; then
            echo "Copying boot.py to $BOARD_DIR"
            cp "$PROJECT_DIR/boot.py" "$BOARD_DIR/"
        fi

        echo "Copying manifest.py to $BOARD_DIR"
        cp "$MANIFEST" "$BOARD_DIR/"

    else
        echo " No modules to freeze, FREEZE_MAIN and FREEZE_BOOT not set to 'true'"
        echo " continuing without manifest."
        echo "--------------------------------------------------------------------------------"
    fi
fi

chown -R root:root "$PROJECT_DIR"

echo "========================================================================================="
echo " Building firmware..."
echo "========================================================================================="

cd "$PORT_DIR"

SUBMODULE_ARGS=("BOARD=$BOARD")

if [[ -n "${BOARD_VARIANT:-}" ]]; then
    SUBMODULE_ARGS+=("BOARD_VARIANT=$BOARD_VARIANT")
fi

MAKE_ARGS=("BOARD=$BOARD")

if [[ -f "$MANIFEST" ]]; then
    MAKE_ARGS+=("FROZEN_MANIFEST=$MANIFEST")
fi

echo " Make submodule args: ${SUBMODULE_ARGS[@]}"
echo " Make args: ${MAKE_ARGS[@]}"
echo "-----------------------------------------------------------------------------------------"

make clean
make "${SUBMODULE_ARGS[@]}" submodules all -j2
echo "-----------------------------------------------------------------------------------------"
make "${MAKE_ARGS[@]}" -j2
echo "-----------------------------------------------------------------------------------------"


OUTPUT_DIR="$PROJECT_DIR/dist"
mkdir -p "$OUTPUT_DIR"
echo " OUTPUT_DIR: $OUTPUT_DIR"
echo "-----------------------------------------------------------------------------------------"

BUILD_DIR="$PORT_DIR/build-$BOARD"

if [[ -d "$BUILD_DIR" ]]; then
    cp "$BUILD_DIR"/*.bin "$BUILD_DIR"/*.hex "$BUILD_DIR"/*.uf2 "$OUTPUT_DIR/" 2>/dev/null || true
else
    echo "ERROR: Build directory not found: $BUILD_DIR"
    echo "========================================================================================="
    exit 5
fi

echo "========================================================================================="
echo " Project directory content:"
echo "-----------------------------------------------------------------------------------------"
ls -al "$PROJECT_DIR"
echo "========================================================================================="
echo " Output directory content:"
echo "-----------------------------------------------------------------------------------------"
ls -al "$OUTPUT_DIR"
echo "========================================================================================="

if [[ "$generate_manifest" == true ]]; then
    echo " Removing generated manifest.py..."
    rm "$PROJECT_DIR/manifest.py"
    echo "========================================================================================="
fi

chown -R "$TARGET_UID:$TARGET_GID" "$PROJECT_DIR"