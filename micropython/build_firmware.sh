#!/usr/bin/bash
set -euo pipefail

# ==============================================================================
# Set PROJECT_DIR variable
# ==============================================================================
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

# ==============================================================================
# Check for custom build_firmware.sh
# ==============================================================================
PROJECT_SCRIPT="$PROJECT_DIR/build_firmware.sh"

if [[ -f "$PROJECT_SCRIPT" ]]; then
    echo "================================================================================"
    echo " Using build_firmware.sh from project."
    echo "================================================================================"
    chmod +x "$PROJECT_SCRIPT"
    exec "$PROJECT_SCRIPT"
else
    echo "================================================================================"
    echo " Using baked-in build_firmware.sh"
    echo "================================================================================"
fi

# ==============================================================================
# Ownership of generated files: HOST_UID / HOST_GID, or fall back to the
# current owner of the project directory (so a manual run never leaves the
# project owned by root).
# ==============================================================================
TARGET_UID="${HOST_UID:-$(stat -c %u "$PROJECT_DIR")}"
TARGET_GID="${HOST_GID:-$(stat -c %g "$PROJECT_DIR")}"

MANIFEST="$PROJECT_DIR/manifest.py"
generate_manifest=false

# Runs on success AND failure: remove the generated manifest.py (so it is never
# mistaken for a project manifest on the next run) and fix ownership.
cleanup() {
    local rc=$?
    if [[ "$generate_manifest" == true ]]; then
        echo " Removing generated manifest.py..."
        rm -f "$MANIFEST"
    fi
    chown -R "$TARGET_UID:$TARGET_GID" "$PROJECT_DIR" || true
    exit "$rc"
}
trap cleanup EXIT

# ==============================================================================
# Required environment variables
# ==============================================================================
: "${PORT:?ERROR: PORT must be set (example: rp2, stm32, nrf)}"
: "${BOARD:?ERROR: BOARD must be set (example: RPI_PICO, RPI_PICO2_W)}"

MICROPYTHON_DIR="/opt/micropython"
PORT_DIR="${MICROPYTHON_DIR}/ports/${PORT}"
BOARD_DIR="${PORT_DIR}/boards/${BOARD}"

echo "================================================================================"
echo " Building MicroPython firmware for"
echo "--------------------------------------------------------------------------------"
echo " PORT: ${PORT}, BOARD: ${BOARD}, BOARD_VARIANT: ${BOARD_VARIANT:-<none>}"
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

MPY_CROSS="${MICROPYTHON_DIR}/mpy-cross"
if [[ ! -x "$MPY_CROSS" ]]; then
    echo "ERROR: mpy-cross not found at ${MPY_CROSS}"
    echo "================================================================================"
    exit 4
fi

export MPY_CROSS

MODULES_DIR="$PROJECT_DIR/modules"
FROZEN_MANIFEST=""

cd "$PROJECT_DIR"

if [[ -f "$MANIFEST" ]]; then
    echo " Using project manifest.py"
    echo "--------------------------------------------------------------------------------"
    # Relative paths inside a manifest resolve against the manifest's own
    # directory, so the project manifest is used in place.
    FROZEN_MANIFEST="$MANIFEST"
else
    echo " No manifest.py found — checking if generation is needed..."
    echo "--------------------------------------------------------------------------------"

    modules_nonempty=false
    if [[ -d "$MODULES_DIR" && -n "$(ls -A "$MODULES_DIR")" ]]; then
        modules_nonempty=true
    fi

    # Only freeze main.py / boot.py when requested AND the file exists.
    freeze_main="${FREEZE_MAIN:-false}"
    freeze_main="${freeze_main,,}"
    if [[ "$freeze_main" == true && ! -f "main.py" ]]; then
        echo " FREEZE_MAIN=true but main.py not found — skipping."
        freeze_main=false
    fi

    freeze_boot="${FREEZE_BOOT:-false}"
    freeze_boot="${freeze_boot,,}"
    if [[ "$freeze_boot" == true && ! -f "boot.py" ]]; then
        echo " FREEZE_BOOT=true but boot.py not found — skipping."
        freeze_boot=false
    fi

    if [[ "$modules_nonempty" == true || "$freeze_main" == true || "$freeze_boot" == true ]]; then
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

        echo " Using generated manifest.py"
        echo "--------------------------------------------------------------------------------"
        cat "$MANIFEST"
        echo "========================================================================================="

        echo "========================================================================================="
        echo " Copying files to freeze..."
        echo "-----------------------------------------------------------------------------------------"
        cp -v "$MANIFEST" "$BOARD_DIR/manifest.py"
        FROZEN_MANIFEST="$BOARD_DIR/manifest.py"

        if [[ "$modules_nonempty" == true ]]; then
            cp -rv "$MODULES_DIR" "$BOARD_DIR"
        fi
        if [[ "$freeze_main" == true ]]; then
            cp -v "$PROJECT_DIR/main.py" "$BOARD_DIR"
        fi
        if [[ "$freeze_boot" == true ]]; then
            cp -v "$PROJECT_DIR/boot.py" "$BOARD_DIR"
        fi

        # ----------------------------------------------------------------------
        # Append build info to the frozen copy of modules/firmware.py (the
        # project's own file, if any, is left untouched).
        # ----------------------------------------------------------------------
        if [[ "$modules_nonempty" == true ]]; then
            frozen_boot_py=False
            [[ "$freeze_boot" == true ]] && frozen_boot_py=True

            frozen_main_py=False
            [[ "$freeze_main" == true ]] && frozen_main_py=True

            FIRMWARE_INFO="$BOARD_DIR/modules/firmware.py"

            if [[ -s "$FIRMWARE_INFO" && -n "$(tail -c1 "$FIRMWARE_INFO")" ]]; then
                echo >> "$FIRMWARE_INFO"
            fi

            {
                echo "MICROPYTHON_VERSION = \"${MICROPYTHON_VERSION:-unknown}\""
                echo "PORT = \"$PORT\""
                echo "BOARD = \"$BOARD\""
                echo "FROZEN_BOOT_PY = $frozen_boot_py"
                echo "FROZEN_MAIN_PY = $frozen_main_py"
            } >> "$FIRMWARE_INFO"

            echo " Build info appended to $FIRMWARE_INFO:"
            cat "$FIRMWARE_INFO"
        fi
        echo "========================================================================================="
    else
        echo " No modules to freeze, FREEZE_MAIN and FREEZE_BOOT not set to 'true'"
        echo " continuing without manifest."
        echo "--------------------------------------------------------------------------------"
    fi
fi

echo "========================================================================================="
echo " Building firmware..."
echo "========================================================================================="

cd "$PORT_DIR"

# Use an explicit build directory so it is known regardless of BOARD_VARIANT.
BUILD_NAME="build-$BOARD"
COMMON_ARGS=("BOARD=$BOARD")

if [[ -n "${BOARD_VARIANT:-}" ]]; then
    BUILD_NAME="build-$BOARD-$BOARD_VARIANT"
    COMMON_ARGS+=("BOARD_VARIANT=$BOARD_VARIANT")
fi

COMMON_ARGS+=("BUILD=$BUILD_NAME")
MAKE_ARGS=("${COMMON_ARGS[@]}")

if [[ -n "$FROZEN_MANIFEST" ]]; then
    MAKE_ARGS+=("FROZEN_MANIFEST=$FROZEN_MANIFEST")
fi

echo "-----------------------------------------------------------------------------------------"
echo " Make submodule args: ${COMMON_ARGS[*]}"
echo " Make args: ${MAKE_ARGS[*]}"
echo "-----------------------------------------------------------------------------------------"

make "${COMMON_ARGS[@]}" clean
make "${COMMON_ARGS[@]}" submodules -j2
echo "-----------------------------------------------------------------------------------------"
make "${MAKE_ARGS[@]}" -j2
echo "-----------------------------------------------------------------------------------------"

# ==============================================================================
# Create "dist" directory.
# ==============================================================================
OUTPUT_DIR="$PROJECT_DIR/dist"
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

echo " OUTPUT_DIR: $OUTPUT_DIR"
echo "-----------------------------------------------------------------------------------------"

BUILD_DIR="$PORT_DIR/$BUILD_NAME"

if [[ -d "$BUILD_DIR" ]]; then
    cp "$BUILD_DIR"/*.bin "$BUILD_DIR"/*.hex "$BUILD_DIR"/*.uf2 "$OUTPUT_DIR/" 2>/dev/null || true
else
    echo "ERROR: Build directory not found: $BUILD_DIR"
    echo "========================================================================================="
    exit 5
fi

# ==============================================================================
# List project and dist directories content.
# ==============================================================================
echo "========================================================================================="
echo " Project directory content:"
echo "-----------------------------------------------------------------------------------------"
ls -al "$PROJECT_DIR"
echo "========================================================================================="
echo " Output directory content:"
echo "-----------------------------------------------------------------------------------------"
ls -al "$OUTPUT_DIR"
echo "========================================================================================="
