# bzip2 1_0_6 鸿蒙化改动记录

## 状态

构建通过、binary 通过、设备验证通过。产物为 `libbz2.so.1.0.8` 共享库和 `bzip2-shared` CLI。

## 事实来源

- `docs/build-report.md`
- `docs/adaptation-report.md`
- `docs/adaptation-plan.md`
- `recipe/HPKBUILD`

## 关键结论

- **无上游源码改动**。bzip2 核心算法是纯 C，平台相关性低，不需要 HarmonyOS 业务适配补丁。
- **lycium recipe 无法直接使用**。现成 recipe 的 `packagename` 为 `bzip2-bzip2-1_0_6.zip`，但实际下载包名为 `bzip2-1_0_6.zip`，导致 recipe 预检阶段即失败。
- **进入 fallback 构建**。fallback 脚本复用上游 `Makefile-libbz2_so`，低成本产出 `.so` 和共享库链路 CLI。
- 实际构建的源码版本为 `1.0.8`，但 recipe 的 `pkgver` 标记为 `1_0_6`，存在版本漂移。

## recipe 改动

现有 `tpc_c_cplusplus/thirdparty/bzip2/HPKBUILD` 存在以下问题，导致 lycium 构建失败：

- `packagename`：`$pkgname-$pkgname-${pkgver}.zip` → 展开为 `bzip2-bzip2-1_0_6.zip`，实际应为 `bzip2-1_0_6.zip`
- `builddir`：`$pkgname-$pkgname-${pkgver}` → 展开为 `bzip2-bzip2-1_0_6`，与实际解压目录不匹配
- `build()`：只构建 `libbz2.a bzip2 bzip2recover`，不产出 `.so`
- `package()`：不安装 `.so` 产物

因此本库不走 lycium 路径，改用 fallback。

## 源码改动

无。未对 `libs/bzip2/` 业务源码做任何修改。

## 产物

来自 fallback 构建目录回收：

- 共享库：`libbz2.so.1.0.8`、`libbz2.so.1.0`（软链）
- 测试 binary：`bzip2-shared`（由 `Makefile-libbz2_so` 生成）
- 头文件：`bzlib.h`

## 验证

设备测试通道：`hdc fallback`

验证入口：
1. `bzip2-shared --help` → 输出版本 `1.0.8, 13-Jul-2019` 和参数说明
2. `bzip2-shared -dc sample1.bz2` → 成功解压样例数据流

关键输出：
```
bzip2, a block-sorting file compressor.  Version 1.0.8, 13-Jul-2019.
```

## 套用到新版本时的检查点

- 现成 lycium recipe 的 `packagename` 和 `builddir` 是否已修复；若已修复可尝试走 lycium 路径
- 新版本是否仍需要 `.so` 产物（默认 Makefile 只产出 `.a`）
- 上游 `Makefile-libbz2_so` 是否仍存在于新版本源码中
- 版本漂移问题：recipe `pkgver` 与实际源码版本是否一致
- 设备验证仍需覆盖真实压缩/解压功能路径，不能仅靠 `--help`
