# libzip 构建报告

## 1. 构建结论

- `build-pass`: pass
- `binary-pass`: pass
- `device-pass`: pass

## 2. 构建路径

- 构建主路径：`lycium`
- 使用 recipe：`tpc_c_cplusplus/thirdparty/libzip/HPKBUILD`
- 目标架构：`arm64-v8a`
- recipe 预修正：
  - 将 recipe 从 `v1.9.2` 升级到任务目标版本 `v1.11.4`
  - 修正 `pkgdesc`、`url`、`zlib` 依赖声明
  - 修正 `packagename`、`SHA512SUM` 与上游下载包名的一致性
  - 保留旧 `libzip_oh_pkg.patch`，并确认其对 `v1.11.4` 仍可应用
  - 显式打开 `BUILD_SHARED_LIBS=ON`、`BUILD_TOOLS=ON`
  - 显式关闭 `BUILD_REGRESS=OFF`、`BUILD_OSSFUZZ=OFF`、`BUILD_EXAMPLES=OFF`、`BUILD_DOC=OFF`
  - 显式设置 `ENABLE_GNUTLS=OFF`、`ENABLE_MBEDTLS=OFF`，保留 `OpenSSL`/`bzip2`/`lzma`/`zstd`
  - 显式设置 `CMAKE_INSTALL_PREFIX=tpc_c_cplusplus/lycium/usr/libzip/<arch>/`
- recipe 失败分类与处理：
  - 首轮失败：`SHA512SUM` 最后一行文件名落在 patch 文件上，导致与 `packagename` 不一致
  - 次轮失败：下载包名 `v1.11.4.tar.gz` 与 `packagename` 不一致
  - 三轮失败：`SHA512SUM` 中文件名仍为旧的 `libzip-1.11.4.tar.gz`
  - 以上都属于文档定义的 recipe 元数据问题，因此均按“先修 recipe，再重试 lycium”处理，没有进入 fallback
- 最终结论：
  - 修正完成后 lycium 构建成功，未进入 fallback

## 3. 产物情况

- 共享库：
  - `outputs/libzip/lib/libzip.so.5.5`
  - `outputs/libzip/lib/libzip.so.5`
  - `outputs/libzip/lib/libzip.so`
- 测试/验证入口：
  - `outputs/libzip/bin/ziptool`
  - `outputs/libzip/bin/zipcmp`
  - `outputs/libzip/bin/zipmerge`
- 为满足设备侧运行时依赖，额外收集了：
  - `outputs/libzip/lib/libzstd.so.1`
  - `outputs/libzip/lib/libz.so.1`
  - `outputs/libzip/lib/liblzma.so.5`

## 4. binary 来源

- binary 来源类型：`CLI`
- binary 回收来源：`lycium install` 产物
- 实际设备测试入口：
  - 上游 CLI：`ziptool`
- 为什么最终使用 CLI 而不是上游回归测试目录：
  - `regress/` 主要依赖 `nihtest`、大量 `.test` 脚本、zip 样本和宿主测试环境
  - 它不是当前库最适合设备侧直接执行的独立入口
  - `ziptool` 是上游自带、可独立运行的程序，且能覆盖“创建 zip -> 写入条目 -> 读取条目 -> 内容比对”的真实功能路径，更符合仓库测试规则

## 5. 关键命令

### 5.1 lycium 构建

```bash
LIB_NAME=libzip PKGNAME=libzip RECIPE_SCOPE=thirdparty bash scripts/run-lycium-build.sh
```

### 5.2 产物回收

```bash
rm -rf outputs/libzip
mkdir -p outputs/libzip/lib outputs/libzip/bin
cp -a tpc_c_cplusplus/lycium/usr/libzip/arm64-v8a/lib/libzip.so* outputs/libzip/lib/
cp -a tpc_c_cplusplus/lycium/usr/libzip/arm64-v8a/bin/ziptool outputs/libzip/bin/
cp -a tpc_c_cplusplus/lycium/usr/libzip/arm64-v8a/bin/zipcmp outputs/libzip/bin/
cp -a tpc_c_cplusplus/lycium/usr/libzip/arm64-v8a/bin/zipmerge outputs/libzip/bin/
cp -Lf tpc_c_cplusplus/lycium/usr/zstd/arm64-v8a/lib/libzstd.so.1 outputs/libzip/lib/
cp -Lf tpc_c_cplusplus/lycium/usr/zlib/arm64-v8a/lib/libz.so.1 outputs/libzip/lib/
cp -Lf tpc_c_cplusplus/lycium/usr/xz/arm64-v8a/lib/liblzma.so.5 outputs/libzip/lib/
```

### 5.3 设备测试

设备测试通道：`hdc fallback`

```bash
hdc shell "rm -rf /data/local/tmp/libzip-run && mkdir -p /data/local/tmp/libzip-run"
hdc file send outputs/libzip /data/local/tmp/libzip-run
hdc file send outputs/libzip/bin/ziptool /data/local/tmp/libzip-run/ziptool
hdc shell "cd /data/local/tmp/libzip-run && \
  ln -sf libzip.so.5.5 lib/libzip.so.5 && \
  ln -sf libzip.so.5 lib/libzip.so && \
  ln -sf libzstd.so.1 lib/libzstd.so && \
  ln -sf libz.so.1 lib/libz.so && \
  ln -sf liblzma.so.5 lib/liblzma.so && \
  chmod +x ziptool && \
  export LD_LIBRARY_PATH=/data/local/tmp/libzip-run/lib && \
  rm -f sample.zip output.txt input.txt && \
  printf 'HarmonyOS libzip roundtrip\nsecond-line-123\n' > input.txt && \
  ./ziptool -n sample.zip add_file input.txt input.txt 0 0 && \
  ./ziptool sample.zip cat 0 > output.txt && \
  cmp input.txt output.txt && \
  echo DEVICE_TEST_OK"
```

## 6. 设备侧执行结果

- 返回结果：命令成功执行
- 真实功能路径：`创建 zip -> 写入文件条目 -> 读取条目 -> 文件内容比对`
- 关键输出：

```text
DEVICE_TEST_OK
```

## 7. 备注

- `libzip.so.5.5` 已确认为 `ELF 64-bit LSB shared object, ARM aarch64`。
- 当前会话未发现可直接调用的 `harmonyos-dev-mcp` 入口，因此设备测试按仓库规则记录为 `hdc fallback`。
- `hdc file send` 从当前工作路径发送目录时，对目录层级和符号链接的保留不完全稳定，因此设备侧额外补发了 `ziptool`，并补齐了运行时库的符号链接后，真实功能验证通过。
- 当前未发现新的 `.rej` 文件；最终成功构建以 lycium recipe 路径为准。
