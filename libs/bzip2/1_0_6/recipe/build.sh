#!/usr/bin/env bash
set -euo pipefail

# Fallback build script for bzip2 HarmonyOS arm64-v8a.
# Can be run from anywhere if SOURCE_DIR and OUTPUT_ROOT are provided.
#
# Usage:
#   SOURCE_DIR=/path/to/bzip2-src OUTPUT_ROOT=/path/to/output bash recipe/build.sh
#
# Environment:
#   OHOS_SDK: Path to HarmonyOS SDK (required)
#   SOURCE_DIR: Path to extracted bzip2 source containing Makefile-libbz2_so
#   OUTPUT_ROOT: Directory to receive built artifacts

SOURCE_DIR="${SOURCE_DIR:-.}"
OUTPUT_ROOT="${OUTPUT_ROOT:-./output}"
OHOS_SDK="${OHOS_SDK:-}"

if [[ -z "$OHOS_SDK" ]]; then
  echo "Error: OHOS_SDK must be set" >&2
  exit 1
fi

if [[ ! -f "$SOURCE_DIR/Makefile-libbz2_so" ]]; then
  echo "Error: Makefile-libbz2_so not found in $SOURCE_DIR" >&2
  exit 1
fi

export CC="${OHOS_SDK}/native/llvm/bin/aarch64-linux-ohos-clang"
export AR="${OHOS_SDK}/native/llvm/bin/llvm-ar"
export RANLIB="${OHOS_SDK}/native/llvm/bin/llvm-ranlib"
export CFLAGS="-fPIC -fPIE -D_FILE_OFFSET_BITS=64 -Wall -Winline -O2"

mkdir -p "$OUTPUT_ROOT/lib" "$OUTPUT_ROOT/bin"

cd "$SOURCE_DIR"

make clean >/dev/null 2>&1 || true
make -f Makefile-libbz2_so clean >/dev/null 2>&1 || true
make -f Makefile-libbz2_so CC="$CC" CFLAGS="$CFLAGS"

cp -f libbz2.so.1.0.8 "$OUTPUT_ROOT/lib/"
if [[ -L libbz2.so.1.0 ]]; then
  cp -f libbz2.so.1.0 "$OUTPUT_ROOT/lib/" || cp -L libbz2.so.1.0 "$OUTPUT_ROOT/lib/"
else
  cp -f libbz2.so.1.0 "$OUTPUT_ROOT/lib/"
fi
cp -f bzip2-shared "$OUTPUT_ROOT/bin/"

echo "Fallback build finished."
echo "Library artifacts: $OUTPUT_ROOT/lib"
echo "Binary artifacts: $OUTPUT_ROOT/bin"
