# zlib 1.3.2 鸿蒙化改动记录

## 状态

- 构建方式：lycium
- 构建结果：build-pass / binary-pass / device-pass
- 目标架构：`arm64-v8a`
- 源码业务改动：无

## 事实来源

- `docs/adaptation-plan.md`
- `docs/adaptation-report.md`
- `docs/build-report.md`
- `recipe/HPKBUILD`
- `recipe/SHA512SUM`

## 关键改动

zlib 主库平台相关性较低，本轮没有修改上游源码，也没有额外 patch。可复用要点主要集中在 recipe 与验证产物：

- 使用 `tpc_c_cplusplus/thirdparty/zlib/HPKBUILD`，该 recipe 已对齐 `1.3.2`。
- 构建系统走 CMake，不进入 fallback。
- 本知识包将 recipe 架构声明收敛为 `archs=("arm64-v8a")`。
- `check()` 只保留 arm64 设备验证所需的 `libc++_shared.so` 拷贝逻辑。
- 设备测试入口使用上游示例程序 `zlib_example`，不是仅运行版本或帮助输出。

## 产物

`artifacts/arm64-v8a/` 合并归档了 lycium install 产物、设备验证运行时库和测试 binary，包含：

- `include/zconf.h`
- `include/zlib.h`
- `lib/libz.so.1.3.2`
- `lib/libz.so.1`
- `lib/libz.so`
- `lib/libz.a`
- `lib/libc++_shared.so`
- `lib/pkgconfig/zlib.pc`
- `bin/zlib_example`
- `bin/minigzip`

当前知识包只保留 `arm64-v8a`。不要在 `meta.yaml`、`recipe/HPKBUILD` 或产物目录中声明其他架构。

## 验证

设备侧验证记录见 `docs/build-report.md`。核心执行路径是：

```bash
hdc shell env LD_LIBRARY_PATH=/data/local/tmp/zlib/lib/zlib/lib /data/local/tmp/zlib/bin/zlib/bin/zlib_example
```

关键输出包括：

```text
zlib version 1.3.2 = 0x1320, compile flags = 0xa9
gzopen error
uncompress(): hello, hello!
```

`hdc file send` 在当时环境下会把源路径层级带到目标目录，因此报告中记录的设备侧路径包含额外的 `zlib/` 层级；复用时应按实际发送结果确认最终路径。

## 套用到新版本时的检查点

- 同步更新 `pkgver`、`source`、`builddir`、`packagename` 和 `SHA512SUM`。
- 优先检查 `thirdparty/zlib` recipe 是否已经覆盖目标版本；不要误用仍停留在旧版本的 community recipe。
- 若测试 binary 目录发生变化，应重新回收 `zlib_example` 或选择 `minigzip` 验证压缩/解压路径。
