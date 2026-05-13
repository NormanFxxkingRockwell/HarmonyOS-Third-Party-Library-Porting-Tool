# cJSON v1.7.19 鸿蒙化改动记录

## 状态

- 构建：pass（lycium recipe 直接成功，未进入 fallback）
- 二进制：pass（产物确认为 ARM aarch64 ELF）
- 设备验证：pass（hdc fallback 通道）

## 事实来源

- `docs/build-report.md`
- `docs/adaptation-report.md`
- `docs/adaptation-plan.md`
- `recipe/HPKBUILD`

## 关键结论

- **无源码改动**：cJSON 是纯 ANSI C 实现的 JSON 解析库，未发现需要替换为 HarmonyOS 专有接口的代码路径。
- **lycium recipe 裁剪架构**：`tpc_c_cplusplus/thirdparty/cJSON/HPKBUILD` 已从源仓库的 `armeabi-v7a + arm64-v8a` 裁剪为仅保留 `arm64-v8a`，符合本仓库规则。SHA512SUM、packagename、builddir 未修改。
- **无第三方运行时依赖**：`readelf -d` 显示仅依赖 `libc.so`（系统库），无需归档 runtime-deps。
- **配置文件已修复为可迁移路径**：`.pc` 和 CMake config 文件原含构建机绝对路径，已修复为基于文件位置的相对路径计算（见下方详细说明）。

## recipe 改动

- **架构裁剪**：`archs=("arm64-v8a")`，源仓库为 `archs=("armeabi-v7a" "arm64-v8a")`，按本仓库规则裁剪为仅 `arm64-v8a`。
- 其余字段未修改：
  - `pkgname=cJSON`
  - `pkgver=v1.7.19`
  - `builddir=$pkgname-${pkgver:1}` → `cJSON-1.7.19`
  - `packagename=${pkgver}.tar.gz` → `v1.7.19.tar.gz`
  - `buildtools="cmake"`
  - `check()` 仅占位："The test must be on an OpenHarmony device!"
- 构建命令：`cmake -DOHOS_ARCH=$ARCH -B$ARCH-build -S./`，然后 `make -C $ARCH-build install`

## 源码改动

- **无**。cJSON.c、cJSON.h、cJSON_Utils.c、cJSON_Utils.h 均未修改。
- 适配计划中提到的 `ENABLE_LOCALES` / `localeconv()` 兼容点本轮未触发问题，保持默认开启。

## 产物

### 共享库
- `artifacts/arm64-v8a/lib/libcjson.so.1.7.19`（47536 bytes）
- `artifacts/arm64-v8a/lib/libcjson.so.1` → `libcjson.so.1.7.19`
- `artifacts/arm64-v8a/lib/libcjson.so` → `libcjson.so.1`
- SONAME: `libcjson.so.1`

### 测试二进制（上游自带，可独立运行）
- `artifacts/arm64-v8a/bin/cJSON_test` — 主验证入口，验证 JSON 创建、打印、预分配打印和解析
- `artifacts/arm64-v8a/bin/readme_examples` — 补充验证入口，3 Tests 0 Failures
- `artifacts/arm64-v8a/bin/parse_examples` — 可启动但因缺少 `tests/inputs/` 数据文件而失败，不作为主验证入口

### 配置文件
- `artifacts/arm64-v8a/include/cjson/cJSON.h`
- `artifacts/arm64-v8a/lib/pkgconfig/libcjson.pc`
- `artifacts/arm64-v8a/lib/cmake/cJSON/cJSONConfig.cmake`
- `artifacts/arm64-v8a/lib/cmake/cJSON/cJSONConfigVersion.cmake`
- `artifacts/arm64-v8a/lib/cmake/cJSON/cjson.cmake`
- `artifacts/arm64-v8a/lib/cmake/cJSON/cjson-release.cmake`

### 配置文件可迁移性修复

原始构建产物中 `.pc` 和 CMake config 文件含构建机绝对路径（`/home/aoqiduan/projects/.../lycium/usr/cJSON/arm64-v8a/`），已修复为基于文件位置的相对路径计算：

- `lib/pkgconfig/libcjson.pc`：使用 `prefix=${pcfiledir}/../..`，`libdir` 和 `includedir` 基于 `prefix` 计算
- `lib/cmake/cJSON/cJSONConfig.cmake`：使用 `get_filename_component(_prefix "${CMAKE_CURRENT_LIST_DIR}/../../.." ABSOLUTE)` 计算前缀
- `lib/cmake/cJSON/cjson.cmake`：使用 `get_filename_component(_IMPORT_PREFIX "${CMAKE_CURRENT_LIST_DIR}/../../.." ABSOLUTE)`
- `lib/cmake/cJSON/cjson-release.cmake`：使用 `${_IMPORT_PREFIX}/lib/libcjson.so.1.7.19`

修复后可跨机器复用，已通过以下 smoke test 验证：
- `pkg-config --libs --cflags libcjson` 输出正确的 `-L.../lib -lcjson -I.../include`
- `cmake find_package(cJSON CONFIG)` 可正确解析到 `.so` 和 include 路径

## 验证

### 构建验证
```bash
LIB_NAME=cJSON PKGNAME=cJSON RECIPE_SCOPE=thirdparty bash scripts/run-lycium-build.sh
```
lycium 构建成功，未进入 fallback。

### 设备验证（hdc fallback 通道）
```bash
hdc file send outputs/cJSON/lib/libcjson.so.1.7.19 /data/local/tmp/cJSON/
hdc file send outputs/cJSON/bin/cJSON_test /data/local/tmp/cJSON/
hdc file send outputs/cJSON/bin/readme_examples /data/local/tmp/cJSON/
hdc shell "cd /data/local/tmp/cJSON && \
  ln -sf libcjson.so.1.7.19 libcjson.so.1 && \
  ln -sf libcjson.so.1 libcjson.so && \
  chmod 755 cJSON_test readme_examples && \
  export LD_LIBRARY_PATH=/data/local/tmp/cJSON:\$LD_LIBRARY_PATH && \
  ./cJSON_test"
```

**cJSON_test 关键输出**：
- `Version: 1.7.19`
- 多段实际 JSON 文本输出
- 最后输出对象 `{"number": null}`

**readme_examples 关键输出**：
- `3 Tests 0 Failures 0 Ignored`
- `OK`

## 套用到新版本时的检查点

1. **版本匹配**：检查 `pkgver`、`source` URL、`builddir`（`$pkgname-${pkgver:1}` 依赖版本号格式，如 `v1.7.19` → `cJSON-1.7.19`）。
2. **SHA512SUM**：下载新源码包后重新计算。
3. **源码改动**：新版本仍需检查是否有 HarmonyOS 不兼容代码（重点关注 `ENABLE_LOCALES` / `localeconv()` 路径）。
4. **recipe 兼容性**：HPKBUILD 的 `check()` 仅为占位，新版本如需要可补充实际测试。
5. **配置文件可迁移性**：新版本构建后同样会产生含构建机路径的 `.pc` 和 CMake config，需按本版本方式修复为相对路径，并重新跑 pkg-config / cmake smoke test。
6. **运行时依赖**：cJSON 是纯 C 库，通常无第三方运行时依赖，但需用 `readelf -d` 重新确认。
