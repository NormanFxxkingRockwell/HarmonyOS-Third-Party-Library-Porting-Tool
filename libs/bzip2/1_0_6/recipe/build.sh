#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMAND_LINE_TOOLS_ROOT="${COMMAND_LINE_TOOLS_ROOT:-$ROOT_DIR/../command-line-tools}"
OHOS_SDK="${OHOS_SDK:-$COMMAND_LINE_TOOLS_ROOT/sdk/default/openharmony}"
OUTPUT_ROOT="$ROOT_DIR/outputs/bzip2"
LIB_OUTPUT_DIR="$OUTPUT_ROOT/lib"
BIN_OUTPUT_DIR="$OUTPUT_ROOT/bin"

export CC="${OHOS_SDK}/native/llvm/bin/aarch64-linux-ohos-clang"
export AR="${OHOS_SDK}/native/llvm/bin/llvm-ar"
export RANLIB="${OHOS_SDK}/native/llvm/bin/llvm-ranlib"
export CFLAGS="-fPIC -fPIE -D_FILE_OFFSET_BITS=64 -Wall -Winline -O2"
export LDFLAGS=""

mkdir -p "$LIB_OUTPUT_DIR" "$BIN_OUTPUT_DIR"

cd "$PROJECT_DIR"

make clean >/dev/null 2>&1 || true
make -f Makefile-libbz2_so clean >/dev/null 2>&1 || true
make -f Makefile-libbz2_so CC="$CC" CFLAGS="$CFLAGS"

cp -f libbz2.so.1.0.8 "$LIB_OUTPUT_DIR"/
cp -f libbz2.so.1.0 "$LIB_OUTPUT_DIR"/
cp -f bzip2-shared "$BIN_OUTPUT_DIR"/

echo "Fallback build finished."
echo "Library artifacts: $LIB_OUTPUT_DIR"
echo "Binary artifacts: $BIN_OUTPUT_DIR"
