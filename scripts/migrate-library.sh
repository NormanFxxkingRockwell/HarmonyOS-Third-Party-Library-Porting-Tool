#!/bin/bash
set -euo pipefail

PORTING_ROOT="${1:-../ho-thirdparty-porting}"
TARGET_ROOT="${2:-.}"
LIB_NAME="${LIB_NAME:-${3:-}}"
ARCH="arm64-v8a"

if [[ -z "$LIB_NAME" ]]; then
    cat >&2 <<'USAGE'
Usage:
  LIB_NAME=libzip scripts/migrate-library.sh [PORTING_ROOT] [TARGET_ROOT]
  scripts/migrate-library.sh [PORTING_ROOT] [TARGET_ROOT] libzip

This tool intentionally migrates one library at a time.
USAGE
    exit 2
fi

if [[ ! -d "$PORTING_ROOT" ]]; then
    echo "Error: porting root not found: $PORTING_ROOT" >&2
    exit 1
fi

if [[ ! -d "$PORTING_ROOT/outputs/$LIB_NAME" ]]; then
    echo "Error: output bundle not found: $PORTING_ROOT/outputs/$LIB_NAME" >&2
    exit 1
fi

if [[ ! -d "$PORTING_ROOT/reports/$LIB_NAME" ]]; then
    echo "Error: reports not found: $PORTING_ROOT/reports/$LIB_NAME" >&2
    exit 1
fi

declare -A RECIPE_HINTS=(
    [Abseil]="community/abseil-cpp"
    [Expat]="thirdparty/libexpat"
    [FreeType]="thirdparty/freetype2"
    [GNU_libiconv]="community/libiconv"
    [GNU_libunistring]="community/libunistring"
    [LZMA_SDK]="community/xz"
    [Mbed_TLS]="community/mbedtls_4_0_0"
    [Protocol_Buffers]="thirdparty/protobuf_v34.1"
    [Zstandard]="thirdparty/zstd"
    [SQLite]="community/sqlite_3_52_0"
    [curl]="community/curl_8_19_0"
)

declare -A INSTALL_HINTS=(
    [Abseil]="abseil-cpp"
    [Expat]="libexpat"
    [FreeType]="freetype2"
    [GNU_libiconv]="libiconv"
    [GNU_libunistring]="libunistring"
    [LZMA_SDK]="xz"
    [Mbed_TLS]="mbedtls_4_0_0"
    [Protocol_Buffers]="protobuf"
    [Zstandard]="zstd"
    [SQLite]="sqlite_3_52_0"
    [curl]="curl_8_19_0"
)

die() {
    echo "Error: $*" >&2
    exit 1
}

relpath() {
    local path="$1"
    printf '%s\n' "${path#"$PORTING_ROOT/"}"
}

parse_assignment() {
    local file="$1"
    local key="$2"
    grep -E "^${key}=" "$file" | head -1 | cut -d= -f2- | tr -d '"'
}

parse_recipe_archs() {
    local file="$1"
    grep -E '^archs=\(' "$file" 2>/dev/null \
        | head -1 \
        | sed -E 's/^archs=\((.*)\)$/\1/' \
        | tr -d '"' \
        | tr ' ' '\n' \
        | sed '/^$/d'
}

find_recipe_dir() {
    local lib="$1"
    local hint="${RECIPE_HINTS[$lib]:-}"
    local candidate

    if [[ -n "$hint" && -f "$PORTING_ROOT/tpc_c_cplusplus/$hint/HPKBUILD" ]]; then
        echo "$PORTING_ROOT/tpc_c_cplusplus/$hint"
        return 0
    fi

    local names=(
        "$lib"
        "$(echo "$lib" | tr '[:upper:]' '[:lower:]')"
        "$(echo "$lib" | tr '[:lower:]' '[:upper:]')"
    )

    for name in "${names[@]}"; do
        for scope in thirdparty community; do
            candidate="$PORTING_ROOT/tpc_c_cplusplus/$scope/$name"
            if [[ -f "$candidate/HPKBUILD" ]]; then
                echo "$candidate"
                return 0
            fi
        done
    done

    return 1
}

guess_install_name() {
    local lib="$1"
    local recipe_dir="${2:-}"
    local pkgname=""

    if [[ -f "$recipe_dir/HPKBUILD" ]]; then
        pkgname="$(parse_assignment "$recipe_dir/HPKBUILD" pkgname || true)"
    fi

    local names=(
        "${INSTALL_HINTS[$lib]:-}"
        "$pkgname"
        "$lib"
        "$(echo "$lib" | tr '[:upper:]' '[:lower:]')"
    )

    local name
    for name in "${names[@]}"; do
        [[ -n "$name" ]] || continue
        if [[ -d "$PORTING_ROOT/tpc_c_cplusplus/lycium/usr/$name/$ARCH" ]]; then
            echo "$name"
            return 0
        fi
    done

    return 1
}

detect_build_system() {
    local hpkbuild="$1"
    if grep -q 'meson setup' "$hpkbuild"; then
        echo "meson"
    elif grep -q 'cmake' "$hpkbuild"; then
        echo "cmake"
    elif grep -q 'configure' "$hpkbuild"; then
        echo "autotools"
    elif grep -q '\bmake\b' "$hpkbuild"; then
        echo "makefile"
    else
        echo "unknown"
    fi
}

detect_fallback_version() {
    local report="$PORTING_ROOT/reports/$LIB_NAME/build-report.md"
    local version=""

    version="$(find "$PORTING_ROOT/outputs/$LIB_NAME/lib" -maxdepth 1 -type f -name '*.so.*' -printf '%f\n' 2>/dev/null \
        | sed -E 's/^.*\.so\.//' \
        | grep -E '^[0-9]+([._-][0-9]+)*$' \
        | sort -Vr \
        | head -1 || true)"

    if [[ -n "$version" ]]; then
        echo "$version" | tr '/ ' '__'
        return
    fi

    version="$(grep -E '源码版本|source version|version' "$report" 2>/dev/null \
        | head -1 \
        | sed -E 's/.*[:：|][[:space:]]*//; s/[[:space:]]*$//' \
        | awk '{print $1}' \
        | tr -d '`' || true)"

    if [[ -z "$version" || "$version" == "值" ]]; then
        version="unknown"
    fi

    echo "$version" | tr '/ ' '__'
}

recipe_dir=""
method="fallback"
version=""
build_system="unknown"
install_name=""

if recipe_dir="$(find_recipe_dir "$LIB_NAME")"; then
    method="lycium"
    hpkbuild="$recipe_dir/HPKBUILD"
    version="$(parse_assignment "$hpkbuild" pkgver || true)"
    build_system="$(detect_build_system "$hpkbuild")"

    if [[ -z "$version" ]]; then
        die "cannot parse pkgver from $hpkbuild"
    fi

    if ! parse_recipe_archs "$hpkbuild" | grep -qx "$ARCH"; then
        die "recipe does not declare required arch $ARCH: $(relpath "$hpkbuild")"
    fi

    install_name="$(guess_install_name "$LIB_NAME" "$recipe_dir" || true)"
else
    method="fallback"
    version="$(detect_fallback_version)"
    install_name="$(guess_install_name "$LIB_NAME" "" || true)"
fi

target_dir="$TARGET_ROOT/libs/$LIB_NAME/$version"

if [[ -e "$target_dir" && "${FORCE:-0}" != "1" ]]; then
    die "target already exists: $target_dir (set FORCE=1 to replace)"
fi

if [[ -e "$target_dir" ]]; then
    rm -rf "$target_dir"
fi

mkdir -p "$target_dir/docs" "$target_dir/artifacts/output" "$target_dir/artifacts/$ARCH" "$target_dir/recipe" "$target_dir/patches"

cp -a "$PORTING_ROOT/reports/$LIB_NAME/." "$target_dir/docs/"
cp -a "$PORTING_ROOT/outputs/$LIB_NAME/." "$target_dir/artifacts/output/"

if [[ -n "$install_name" && -d "$PORTING_ROOT/tpc_c_cplusplus/lycium/usr/$install_name/$ARCH" ]]; then
    cp -a "$PORTING_ROOT/tpc_c_cplusplus/lycium/usr/$install_name/$ARCH/." "$target_dir/artifacts/$ARCH/"
fi

recipe_source_path=""
package_name=""
builddir=""
patches=()
depends=()

if [[ "$method" == "lycium" ]]; then
    recipe_source_path="$(relpath "$recipe_dir")"
    cp -a "$recipe_dir/HPKBUILD" "$target_dir/recipe/"
    sed -i 's/^archs=.*/archs=("arm64-v8a")/' "$target_dir/recipe/HPKBUILD"
    [[ -f "$recipe_dir/SHA512SUM" ]] && cp -a "$recipe_dir/SHA512SUM" "$target_dir/recipe/"
    [[ -f "$recipe_dir/HPKCHECK" ]] && cp -a "$recipe_dir/HPKCHECK" "$target_dir/recipe/"

    while IFS= read -r file; do
        cp -a "$file" "$target_dir/recipe/"
    done < <(find "$recipe_dir" -maxdepth 1 -type f \( -name '*.patch' -o -name '*cross-file*' \) | sort)

    package_name="$(parse_assignment "$recipe_dir/HPKBUILD" packagename || true)"
    builddir="$(parse_assignment "$recipe_dir/HPKBUILD" builddir || true)"

    while IFS= read -r patch; do
        patches+=("$(basename "$patch")")
    done < <(find "$target_dir/recipe" -maxdepth 1 -type f -name '*.patch' | sort)

    deps_line="$(grep -E '^depends=\(' "$recipe_dir/HPKBUILD" 2>/dev/null | head -1 || true)"
    if [[ -n "$deps_line" ]]; then
        while IFS= read -r dep; do
            [[ -n "$dep" ]] && depends+=("$dep")
        done < <(printf '%s\n' "$deps_line" | sed -E 's/^depends=\((.*)\)$/\1/' | tr -d '"' | tr ' ' '\n' | sed '/^$/d')
    fi
else
    fallback_lib_dir="$PORTING_ROOT/libs/$LIB_NAME"
    if [[ -f "$fallback_lib_dir/build.sh" ]]; then
        cp -a "$fallback_lib_dir/build.sh" "$target_dir/recipe/"
    fi
fi

{
    echo "name: $LIB_NAME"
    echo "version: $version"
    echo
    echo "source:"
    echo "  porting_repo: ../ho-thirdparty-porting"
    echo "  output_bundle: outputs/$LIB_NAME"
    echo
    echo "recipe:"
    echo "  method: $method"
    if [[ "$method" == "lycium" ]]; then
        echo "  source_path: $recipe_source_path"
        echo "  build_system: $build_system"
        [[ -n "$package_name" ]] && echo "  package_name: $package_name"
        [[ -n "$builddir" ]] && echo "  builddir: $builddir"
        if [[ ${#patches[@]} -gt 0 ]]; then
            echo "  patches:"
            for patch in "${patches[@]}"; do
                echo "    - $patch"
            done
        fi
    else
        echo "  build_system: fallback"
        [[ -f "$target_dir/recipe/build.sh" ]] && echo "  build_script: recipe/build.sh"
    fi
    echo
    echo "archs:"
    echo "  - $ARCH"
    if [[ ${#depends[@]} -gt 0 ]]; then
        echo
        echo "dependencies:"
        echo "  build:"
        for dep in "${depends[@]}"; do
            echo "    - $dep"
        done
    fi
    echo
    echo "artifacts:"
    echo "  verified_bundle: artifacts/output"
    if [[ -d "$target_dir/artifacts/$ARCH" && -n "$(find "$target_dir/artifacts/$ARCH" -mindepth 1 -print -quit)" ]]; then
        echo "  per_arch_install:"
        echo "    $ARCH: artifacts/$ARCH"
    fi
    echo
    echo "docs:"
    [[ -f "$target_dir/docs/adaptation-plan.md" ]] && echo "  adaptation_plan: docs/adaptation-plan.md"
    [[ -f "$target_dir/docs/adaptation-report.md" ]] && echo "  adaptation_report: docs/adaptation-report.md"
    [[ -f "$target_dir/docs/build-report.md" ]] && echo "  build_report: docs/build-report.md"
} > "$target_dir/meta.yaml"

cat > "$target_dir/modifications.md" <<EOF
# $LIB_NAME $version 鸿蒙化改动记录

## 状态

该文件由迁移脚本生成，是待人工复核的结构化草稿。不要把本文件视为最终适配总结。

## 事实来源

- \`docs/adaptation-plan.md\`
- \`docs/adaptation-report.md\`
- \`docs/build-report.md\`
EOF

if [[ "$method" == "lycium" ]]; then
    cat >> "$target_dir/modifications.md" <<EOF
- \`recipe/HPKBUILD\`
- \`recipe/SHA512SUM\`

## 构建配置

- 构建路径：lycium。
- recipe 来源：\`$recipe_source_path\`
- 目标架构：\`$ARCH\`
- 构建系统：\`$build_system\`

EOF
    if [[ ${#patches[@]} -gt 0 ]]; then
        echo "## 已归档 patch" >> "$target_dir/modifications.md"
        echo >> "$target_dir/modifications.md"
        for patch in "${patches[@]}"; do
            echo "- \`recipe/$patch\`" >> "$target_dir/modifications.md"
        done
        echo >> "$target_dir/modifications.md"
    fi
else
    cat >> "$target_dir/modifications.md" <<EOF

## 构建配置

- 构建路径：fallback。
- 目标架构：\`$ARCH\`
- 构建脚本：请优先查看 \`docs/build-report.md\`；如已复制则见 \`recipe/build.sh\`。

EOF
fi

cat >> "$target_dir/modifications.md" <<'EOF'
## 人工复核清单

- 从 `docs/build-report.md` 提炼真实改动点、失败分类和验证命令。
- 确认 `meta.yaml` 中的产物、依赖和验证状态是否完整。
- 如果要套用到同库新版本，重新检查 source、packagename、builddir、SHA512SUM 和 patch 适配性。
- 设备验证必须保留真实功能路径，不接受只运行帮助信息作为最终结论。
EOF

echo "Migrated $LIB_NAME $version -> $target_dir"
