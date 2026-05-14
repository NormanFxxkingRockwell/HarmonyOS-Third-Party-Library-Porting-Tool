#!/usr/bin/env bash
# LZ4 HarmonyOS fallback build script
# Usage: SOURCE_DIR=<lz4-src> OUTPUT_ROOT=<out> [OHOS_SDK=<sdk>] bash recipe/build.sh
set -euo pipefail

if [ -z "${SOURCE_DIR:-}" ]; then
  echo "ERROR: SOURCE_DIR not set. Point to LZ4 source root (must contain build/cmake/CMakeLists.txt)." >&2
  exit 1
fi

if [ -z "${OUTPUT_ROOT:-}" ]; then
  echo "ERROR: OUTPUT_ROOT not set. Point to output directory for artifacts." >&2
  exit 1
fi

if [ ! -f "$SOURCE_DIR/build/cmake/CMakeLists.txt" ]; then
  echo "ERROR: $SOURCE_DIR/build/cmake/CMakeLists.txt not found. SOURCE_DIR must be LZ4 source root." >&2
  exit 1
fi

OHOS_SDK="${OHOS_SDK:-}"
if [ -z "$OHOS_SDK" ]; then
  ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
  COMMAND_LINE_TOOLS_ROOT="${COMMAND_LINE_TOOLS_ROOT:-$ROOT_DIR/../command-line-tools}"
  OHOS_SDK="$COMMAND_LINE_TOOLS_ROOT/sdk/default/openharmony"
fi

if [ ! -d "$OHOS_SDK" ]; then
  echo "ERROR: OHOS_SDK directory not found: $OHOS_SDK" >&2
  echo "Set OHOS_SDK to your HarmonyOS SDK path." >&2
  exit 1
fi

TOOLCHAIN_FILE="${TOOLCHAIN_FILE:-$OHOS_SDK/native/build/cmake/ohos.toolchain.cmake}"
BUILD_DIR="$SOURCE_DIR/build-ohos"
INSTALL_DIR="$SOURCE_DIR/install-ohos"
LIB_OUTPUT_DIR="$OUTPUT_ROOT/lib"
BIN_OUTPUT_DIR="$OUTPUT_ROOT/bin"
INCLUDE_OUTPUT_DIR="$OUTPUT_ROOT/include"

mkdir -p "$LIB_OUTPUT_DIR" "$BIN_OUTPUT_DIR" "$INCLUDE_OUTPUT_DIR"
rm -rf "$BUILD_DIR" "$INSTALL_DIR"

"$OHOS_SDK/native/build-tools/cmake/bin/cmake" \
  -S "$SOURCE_DIR/build/cmake" \
  -B "$BUILD_DIR" \
  -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_SHARED_LIBS=ON \
  -DBUILD_STATIC_LIBS=OFF \
  -DLZ4_BUILD_CLI=ON \
  -DCMAKE_TOOLCHAIN_FILE="$TOOLCHAIN_FILE" \
  -DOHOS_ARCH=arm64-v8a \
  -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR"

"$OHOS_SDK/native/build-tools/cmake/bin/cmake" --build "$BUILD_DIR" --parallel "$(nproc)"
"$OHOS_SDK/native/build-tools/cmake/bin/cmake" --install "$BUILD_DIR"

find "$INSTALL_DIR" -name 'liblz4.so*' -exec cp -a {} "$LIB_OUTPUT_DIR"/ \;
find "$INSTALL_DIR/bin" -maxdepth 1 -type f -perm -111 -exec cp -a {} "$BIN_OUTPUT_DIR"/ \;
cp -a "$INSTALL_DIR/include/." "$INCLUDE_OUTPUT_DIR"/

rm -rf "$BUILD_DIR" "$INSTALL_DIR"

echo "Fallback build finished."
echo "Library artifacts: $LIB_OUTPUT_DIR"
echo "Binary artifacts: $BIN_OUTPUT_DIR"
