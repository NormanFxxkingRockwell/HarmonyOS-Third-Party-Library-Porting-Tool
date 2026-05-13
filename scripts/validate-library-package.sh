#!/bin/bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 libs/<library>/<version>" >&2
    exit 2
fi

pkg_dir="${1%/}"
failures=0

fail() {
    echo "FAIL: $*"
    failures=$((failures + 1))
}

warn() {
    echo "WARN: $*"
}

pass() {
    echo "PASS: $*"
}

require_file() {
    local path="$1"
    if [[ -f "$path" ]]; then
        pass "found $path"
    else
        fail "missing $path"
    fi
}

require_dir() {
    local path="$1"
    if [[ -d "$path" ]]; then
        pass "found $path"
    else
        fail "missing $path"
    fi
}

extract_meta_archs() {
    awk '
        /^archs:[[:space:]]*$/ { in_archs=1; next }
        /^[^[:space:]]/ { in_archs=0 }
        in_archs && /^[[:space:]]*-[[:space:]]*/ {
            gsub(/^[[:space:]]*-[[:space:]]*/, "", $0)
            gsub(/[[:space:]]+$/, "", $0)
            print
        }
    ' "$pkg_dir/meta.yaml" 2>/dev/null
}

extract_recipe_archs() {
    local hpkbuild="$pkg_dir/recipe/HPKBUILD"
    grep -E '^archs=\(' "$hpkbuild" 2>/dev/null \
        | head -1 \
        | sed -E 's/^archs=\((.*)\)$/\1/' \
        | tr -d '"' \
        | tr ' ' '\n' \
        | sed '/^$/d'
}

extract_recipe_refs() {
    local hpkbuild="$pkg_dir/recipe/HPKBUILD"
    grep -Eo '[A-Za-z0-9_./{}$`-]+\.(patch|txt)' "$hpkbuild" 2>/dev/null \
        | sed -E 's/`//g; s#^.*/##' \
        | sort -u
}

require_dir "$pkg_dir"
require_file "$pkg_dir/meta.yaml"
require_file "$pkg_dir/modifications.md"
require_file "$pkg_dir/docs/build-report.md"

method="lycium"
if [[ -f "$pkg_dir/meta.yaml" ]] && grep -q 'method:[[:space:]]*fallback' "$pkg_dir/meta.yaml"; then
    method="fallback"
fi

if [[ "$method" == "lycium" ]]; then
    require_file "$pkg_dir/recipe/HPKBUILD"
    require_file "$pkg_dir/recipe/SHA512SUM"
else
    pass "fallback package does not require HPKBUILD/SHA512SUM"
fi

if [[ -f "$pkg_dir/modifications.md" ]]; then
    if grep -q 'recipe 改动：HPKBUILD' "$pkg_dir/modifications.md" \
        && grep -q '源码改动：检查 patches/ 目录' "$pkg_dir/modifications.md"; then
        fail "modifications.md still looks like the old generated template"
    else
        pass "modifications.md is not the old generated template"
    fi
fi

if [[ "$method" == "lycium" && -f "$pkg_dir/recipe/HPKBUILD" ]]; then
    mapfile -t refs < <(extract_recipe_refs)
    for ref in "${refs[@]}"; do
        [[ -n "$ref" ]] || continue
        candidates=("$ref")
        if [[ "$ref" == *'$ARCH'* ]]; then
            candidates+=("${ref//\$ARCH/arm64-v8a}")
        fi
        if [[ "$ref" == *'${ARCH}'* ]]; then
            candidates+=("${ref//\$\{ARCH\}/arm64-v8a}")
        fi

        found_ref=false
        for candidate in "${candidates[@]}"; do
            if [[ -f "$pkg_dir/recipe/$candidate" || -f "$pkg_dir/patches/$candidate" || -f "$pkg_dir/$candidate" ]]; then
                found_ref=true
                break
            fi
        done

        if $found_ref; then
            pass "recipe reference exists: $ref"
        else
            fail "recipe reference is missing: $ref"
        fi
    done
fi

if [[ -f "$pkg_dir/meta.yaml" ]]; then
    mapfile -t meta_archs < <(extract_meta_archs)
    if [[ ${#meta_archs[@]} -eq 0 ]]; then
        fail "meta.yaml has no top-level archs list"
    fi

    for arch in "${meta_archs[@]}"; do
        if [[ "$arch" != "arm64-v8a" ]]; then
            fail "meta.yaml declares unsupported arch for this repository: $arch"
        fi
    done

    if printf '%s\n' "${meta_archs[@]}" | grep -qx "arm64-v8a"; then
        pass "meta.yaml includes required arch: arm64-v8a"
    else
        fail "meta.yaml missing required arch: arm64-v8a"
    fi
fi

if [[ "$method" == "lycium" && -f "$pkg_dir/meta.yaml" && -f "$pkg_dir/recipe/HPKBUILD" ]]; then
    mapfile -t meta_archs < <(extract_meta_archs)
    mapfile -t recipe_archs < <(extract_recipe_archs)

    if [[ ${#recipe_archs[@]} -eq 0 ]]; then
        warn "recipe/HPKBUILD has no archs=(...) line"
    fi

    for arch in "${recipe_archs[@]}"; do
        if [[ "$arch" != "arm64-v8a" ]]; then
            fail "recipe declares unsupported arch for this repository: $arch"
        fi

        if printf '%s\n' "${meta_archs[@]}" | grep -qx "$arch"; then
            pass "meta.yaml includes recipe arch: $arch"
        else
            fail "meta.yaml missing recipe arch: $arch"
        fi

        if [[ -d "$pkg_dir/artifacts/$arch" ]]; then
            pass "artifact directory exists for recipe arch: $arch"
        else
            fail "artifact directory missing for recipe arch: $arch"
        fi
    done

    for arch in "${meta_archs[@]}"; do
        if [[ ${#recipe_archs[@]} -gt 0 ]] && ! printf '%s\n' "${recipe_archs[@]}" | grep -qx "$arch"; then
            fail "meta.yaml declares arch not present in recipe: $arch"
        fi
    done
fi

if [[ ! -d "$pkg_dir/artifacts" ]]; then
    fail "missing artifacts directory"
elif find "$pkg_dir/artifacts" -type f -o -type l | grep -q .; then
    pass "artifacts contain files or links"
else
    fail "artifacts directory is empty"
fi

if [[ -d "$pkg_dir/artifacts" ]]; then
    for path in "$pkg_dir"/artifacts/*; do
        [[ -e "$path" ]] || continue
        name="$(basename "$path")"
        case "$name" in
            arm64-v8a)
                pass "artifact arch directory is allowed: $name"
                ;;
            *)
                fail "artifacts may only contain arm64-v8a at the top level, found: $name"
                ;;
        esac
    done
fi

if [[ -f "$pkg_dir/docs/build-report.md" ]] && grep -q 'ziptool' "$pkg_dir/docs/build-report.md"; then
    if find "$pkg_dir/artifacts" \( -type f -o -type l \) -path '*/bin/ziptool' | grep -q .; then
        pass "ziptool validation entry is present in artifacts"
    else
        fail "build-report mentions ziptool but artifacts do not contain bin/ziptool"
    fi
fi

if [[ $failures -eq 0 ]]; then
    echo "OK: $pkg_dir"
else
    echo "FAILED: $pkg_dir ($failures issue(s))"
fi

exit "$failures"
