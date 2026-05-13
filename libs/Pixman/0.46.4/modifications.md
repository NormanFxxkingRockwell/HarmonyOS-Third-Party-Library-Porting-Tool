# Pixman 0.46.4 鸿蒙化改动记录

## 结论

- 构建路径：lycium。
- 构建结果：`build-pass`、`binary-pass`、`device-pass` 均通过。
- 本轮未修改 `libs/Pixman/` 上游业务源码。
- 关键复用点集中在 recipe 从旧 configure 路线切换到 Meson、补 Meson cross-file、收集上游测试 binary，以及设备侧补齐运行时依赖。

## 关键改动

### recipe 版本和构建系统修正

- 使用 recipe：`tpc_c_cplusplus/thirdparty/pixman/HPKBUILD`。
- 将 `pkgver` 从 `0.42.2` 升级到 `0.46.4`。
- 将下载源修正为官方 GitLab tag archive：

```text
https://gitlab.freedesktop.org/pixman/pixman/-/archive/pixman-$pkgver/pixman-pixman-$pkgver.tar.gz
```

- 将 `packagename` 修正为 `pixman-pixman-0.46.4.tar.gz`。
- 将 `builddir` 修正为 `pixman-pixman-0.46.4`。
- 重新生成 `SHA512SUM`。
- 将构建系统从旧 `configure/autogen.sh` 路线切换为 Meson。
- 将 `archs` 收敛为 `("arm64-v8a")`。

### Meson cross-file

- 新增并归档 `recipe/arm64-v8a-cross-file.txt`。
- `HPKBUILD` 在构建前复制 `$ARCH-cross-file.txt` 并替换其中的 SDK 路径。
- 当前知识包只保留 `arm64-v8a` cross-file，不保留其他架构模板。

### Meson 构建参数

- 共享库：`-Ddefault_library=shared`
- 测试入口：`-Dtests=enabled`
- 禁用无关图形/并行选项：
  - `-Ddemos=disabled`
  - `-Dgtk=disabled`
  - `-Dopenmp=disabled`
- 保留 libpng 支持：`-Dlibpng=enabled`

### 测试 binary 收集

`package()` 阶段将上游自带、可独立运行的测试入口复制到 install 目录：

- `matrix-test`
- `pixel-test`
- `prng-test`
- `region-test`
- `scaling-test`
- `thread-test`
- `tolerance-test`

这些 binary 已归档到：

- `artifacts/arm64-v8a/bin/`

## 构建失败处理记录

构建过程中没有进入 fallback，失败均按 lycium-first 规则在 recipe 或环境层处理：

- 第一轮失败：环境缺少 `meson` 命令。
  - 处理：创建局部 Python venv 安装 Meson，并把 `meson` 暴露到 PATH。
- 第二轮失败：旧 recipe 仍尝试 `armeabi-v7a`，且该架构依赖闭包不完整。
  - 处理：将 recipe 收敛为 `arm64-v8a`。
- 第三轮 lycium 构建通过。

## 产物

### Pixman 产物

- `artifacts/arm64-v8a/lib/libpixman-1.so.0.46.4`
- `artifacts/arm64-v8a/lib/libpixman-1.so.0`
- `artifacts/arm64-v8a/lib/libpixman-1.so`
- `artifacts/arm64-v8a/bin/*-test`

### 运行时依赖

设备侧验证需要补齐 libpng 和 zlib 运行时库。本知识包已将它们归档到 `artifacts/arm64-v8a/lib/`：

- `libpng16.so.16.56.0`
- `libpng16.so.16`
- `libpng16.so`
- `libpng.so`
- `libz.so.1.3.2`
- `libz.so.1`
- `libz.so`

## 验证

设备测试通道：`hdc fallback`。

已验证的真实入口：

- `pixel-test`
- `thread-test`
- `prng-test -bench`

设备侧执行前需要设置运行时库路径：

```bash
export LD_LIBRARY_PATH=/data/local/tmp/Pixman
```

详细推送命令、软链补齐和执行记录见 `docs/build-report.md`。

## 复用到新版本时的检查点

- 重新确认上游是否仍使用 Meson。
- 同步检查 `source`、`packagename`、`builddir`、`SHA512SUM`。
- 保留并复核 `arm64-v8a-cross-file.txt` 的 SDK 路径替换逻辑。
- 确认 `pixel-test/thread-test/prng-test` 等测试入口是否仍存在且被安装。
- 设备测试必须补齐 `libpixman`、`libpng16` 和 `libz` 的 SONAME 软链。

## 详细来源

- `docs/adaptation-plan.md`
- `docs/adaptation-report.md`
- `docs/build-report.md`
- `recipe/HPKBUILD`
- `recipe/SHA512SUM`
- `recipe/arm64-v8a-cross-file.txt`
