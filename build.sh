#!/usr/bin/env bash
set -euo pipefail

# Local ZMK build script using Docker.
# Parses build.yaml and builds all (or selected) firmware targets.
#
# Usage:
#   ./build.sh              # build all targets
#   ./build.sh left         # build only targets whose shield contains "left"
#   ./build.sh right        # ... "right"
#   ./build.sh reset        # ... "settings_reset"
#   ./build.sh --clean      # wipe cached west workspace and rebuild all
#
# First build fetches ZMK + Zephyr into a Docker volume (slow).
# Subsequent builds reuse the cache (fast).

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="${SCRIPT_DIR}/config"
BUILD_YAML="${SCRIPT_DIR}/build.yaml"
OUTPUT_DIR="${SCRIPT_DIR}/firmware"
DOCKER_IMAGE="zmkfirmware/zmk-build-arm:3.5"
DOCKER_VOLUME="zmk-build-workspace"

FILTER=""
CLEAN=0
for arg in "$@"; do
    if [[ "$arg" == "--clean" ]]; then
        CLEAN=1
    else
        FILTER="$arg"
    fi
done

if ! command -v docker &>/dev/null; then
    echo "ERROR: docker not found"
    exit 1
fi

if [[ $CLEAN -eq 1 ]]; then
    echo "Removing cached workspace..."
    docker volume rm "$DOCKER_VOLUME" 2>/dev/null || true
fi

mkdir -p "$OUTPUT_DIR"

build_count=0
fail_count=0

build_entry() {
    local board="$1" shield="$2" snippet="$3" cmake_args="$4" artifact="$5"

    if [[ -n "$FILTER" ]] && [[ "$shield $artifact" != *"$FILTER"* ]]; then
        return
    fi

    local build_name
    if [[ -n "$artifact" ]]; then
        build_name="$artifact"
    elif [[ -n "$shield" ]]; then
        build_name="${shield// /_}"
    else
        build_name="$board"
    fi

    echo "━━━ Building: $build_name (board=$board shield=$shield) ━━━"

    local build_dir="/workspace/build/$build_name"
    local west_args="-p -s zmk/app -b $board -d $build_dir"
    local cmake_extra=""
    if [[ -n "$shield" ]]; then
        cmake_extra+=" -DSHIELD=\"$shield\""
    fi
    if [[ -n "$snippet" ]]; then
        west_args+=" -S $snippet"
    fi
    if [[ -n "$cmake_args" ]]; then
        cmake_extra+=" $cmake_args"
    fi
    cmake_extra+=" -DZMK_CONFIG=/workspace/config"

    if [[ -n "$cmake_extra" ]]; then
        west_args+=" -- $cmake_extra"
    fi

    if docker run --rm \
        -v "$DOCKER_VOLUME":/workspace \
        -v "$CONFIG_DIR":/workspace/config:ro \
        -v "$OUTPUT_DIR":/workspace/output \
        -e ZEPHYR_BASE=/workspace/zephyr \
        -w /workspace \
        "$DOCKER_IMAGE" \
        sh -c "
            if [ ! -f /workspace/.west/config ]; then
                west init -l config
            fi
            west update
            west zephyr-export
            west build $west_args \
            && cp $build_dir/zephyr/zmk.uf2 /workspace/output/${build_name}.uf2
        "; then
        echo "✓ $build_name → firmware/${build_name}.uf2"
        build_count=$((build_count + 1))
    else
        echo "✗ $build_name FAILED"
        fail_count=$((fail_count + 1))
    fi
    echo
}

parse_and_build() {
    local board="" shield="" snippet="" cmake_args="" artifact=""
    local in_include=0

    while IFS= read -r line; do
        line="${line#"${line%%[![:space:]]*}"}"
        line="${line%"${line##*[![:space:]]}"}"

        [[ -z "$line" || "$line" == \#* ]] && continue

        if [[ "$line" == "include:" ]]; then
            in_include=1
            continue
        fi
        [[ $in_include -eq 0 ]] && continue

        if [[ "$line" == "- board:"* ]]; then
            if [[ -n "$board" ]]; then
                build_entry "$board" "$shield" "$snippet" "$cmake_args" "$artifact"
            fi
            board="${line#*: }" shield="" snippet="" cmake_args="" artifact=""
        elif [[ "$line" == "shield:"* ]]; then
            shield="${line#*: }"
        elif [[ "$line" == "snippet:"* ]]; then
            snippet="${line#*: }"
        elif [[ "$line" == "cmake-args:"* ]]; then
            cmake_args="${line#*: }"
        elif [[ "$line" == "artifact-name:"* ]]; then
            artifact="${line#*: }"
        fi
    done < "$BUILD_YAML"

    if [[ -n "$board" ]]; then
        build_entry "$board" "$shield" "$snippet" "$cmake_args" "$artifact"
    fi
}

parse_and_build

echo "━━━ Done: $build_count succeeded, $fail_count failed ━━━"
[[ $fail_count -eq 0 ]]
