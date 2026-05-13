# libzip v1.11.4 鸿蒙化改动记录

## 结论

- 构建路径：lycium。
- 构建结果：`build-pass`、`binary-pass`、`device-pass` 均通过。
- 本轮未修改 `libs/libzip/` 上游业务源码、公开头文件或 CLI 源码。
- 有价值的复用点集中在 lycium recipe、旧 patch 适配、依赖开关、产物回收和设备侧真实功能验证。

## 关键改动

### recipe 升级与元数据修正

- 使用 recipe：`tpc_c_cplusplus/thirdparty/libzip/HPKBUILD`。
- 将 recipe 从旧目标 `v1.9.2` 升级到 `v1.11.4`。
- 修正 `pkgdesc`、`url` 和 `depends`，明确依赖 `xz`、`zstd`、`openssl`、`bzip2`、`zlib`。
- 修正 `packagename=v1.11.4.tar.gz`，并同步 `SHA512SUM`，避免包名与校验文件名不一致。
- 设置 `builddir=libzip-1.11.4`，与 upstream archive 解包目录一致。

### patch 保留与适配

- 保留并复用 `libzip_oh_pkg.patch`。
- `HPKBUILD` 在 `prepare()` 中执行：

```bash
patch -p1 < `pwd`/../libzip_oh_pkg.patch
```

- 该 patch 已在 `v1.11.4` 上确认可应用。
- 本知识包已将 patch 放入 `recipe/libzip_oh_pkg.patch`，复用时需与 `HPKBUILD` 同目录放置。

### CMake 构建开关

- 打开共享库和工具：
  - `BUILD_SHARED_LIBS=ON`
  - `BUILD_TOOLS=ON`
- 关闭不适合作为本轮设备侧主验证入口的部分：
  - `BUILD_REGRESS=OFF`
  - `BUILD_OSSFUZZ=OFF`
  - `BUILD_EXAMPLES=OFF`
  - `BUILD_DOC=OFF`
- 依赖策略：
  - `ENABLE_OPENSSL=ON`
  - `ENABLE_BZIP2=ON`
  - `ENABLE_LZMA=ON`
  - `ENABLE_ZSTD=ON`
  - `ENABLE_GNUTLS=OFF`
  - `ENABLE_MBEDTLS=OFF`
- 安装路径显式设置为 `${LYCIUM_ROOT}/usr/libzip/${ARCH}`。

### 构建失败处理记录

构建过程中遇到的问题都属于 recipe 元数据问题，因此按 lycium-first 规则修 recipe 后重试，没有进入 fallback：

- 首轮失败：`SHA512SUM` 最后一行文件名落在 patch 文件上，导致与 `packagename` 不一致。
- 次轮失败：下载包名 `v1.11.4.tar.gz` 与 `packagename` 不一致。
- 三轮失败：`SHA512SUM` 中文件名仍为旧的 `libzip-1.11.4.tar.gz`。

这些问题对新版本复用很重要：更新 libzip 版本时必须同时检查 `source`、`packagename`、`SHA512SUM` 文件名和 `builddir`。

## 产物

### 设备验证包

`artifacts/output/` 来自 `../ho-thirdparty-porting/outputs/libzip/`，对应已完成设备验证的 arm64 包：

- `artifacts/output/lib/libzip.so.5.5`
- `artifacts/output/lib/libzip.so.5`
- `artifacts/output/lib/libzip.so`
- `artifacts/output/lib/libzstd.so.1`
- `artifacts/output/lib/libz.so.1`
- `artifacts/output/lib/liblzma.so.5`
- `artifacts/output/bin/ziptool`
- `artifacts/output/bin/zipcmp`
- `artifacts/output/bin/zipmerge`

### lycium install 产物

`artifacts/arm64-v8a/` 来自 `tpc_c_cplusplus/lycium/usr/libzip/arm64-v8a/`，包含：

- `bin/ziptool`
- `bin/zipcmp`
- `bin/zipmerge`
- `include/zip.h`
- `include/zipconf.h`
- `lib/libzip.so.5.5`
- `lib/libzip.so.5`
- `lib/libzip.so`
- `lib/pkgconfig/libzip.pc`

当前知识包只保留 `arm64-v8a`。不要在 `meta.yaml` 或产物目录中声明其他架构。

## 验证

设备侧首选验证入口是 upstream CLI `ziptool`，不是仅执行 `--help` 或版本输出。

已通过的真实功能路径：

```text
创建 zip -> 写入文件条目 -> 读取条目 -> 文件内容比对
```

关键设备命令记录见 `docs/build-report.md`。核心命令摘要：

```bash
export LD_LIBRARY_PATH=/data/local/tmp/libzip-run/lib
./ziptool -n sample.zip add_file input.txt input.txt 0 0
./ziptool sample.zip cat 0 > output.txt
cmp input.txt output.txt
```

通过标志：

```text
DEVICE_TEST_OK
```

## 复用到新版本时的检查点

- 先更新 `pkgver`，再同步检查 `source`、`packagename`、`builddir`、`SHA512SUM`。
- 重新验证 `libzip_oh_pkg.patch` 是否仍能应用；如果失败，应基于新版本源码重做最小 patch。
- 保持 `BUILD_TOOLS=ON`，否则会丢失 `ziptool`、`zipcmp`、`zipmerge` 这类设备侧真实验证入口。
- 如果依赖开关变化，必须重新确认运行时依赖库是否需要一起打包。
- 设备验证仍应使用 `ziptool` 做读写回环和内容比对，不接受只跑帮助信息。

## 详细来源

- `docs/adaptation-plan.md`
- `docs/adaptation-report.md`
- `docs/build-report.md`
- `recipe/HPKBUILD`
- `recipe/SHA512SUM`
- `recipe/libzip_oh_pkg.patch`
