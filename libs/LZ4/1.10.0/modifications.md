# LZ4 1.10.0 鸿蒙化改动记录

## 状态

- 构建：pass
- 二进制检查：pass
- 设备验证：pass
- 构建方式：fallback（无 lycium HPKBUILD）

## 事实来源

- `docs/build-report.md`
- `docs/adaptation-report.md`
- `docs/adaptation-plan.md`
- `recipe/build.sh`

## 关键结论

- **源码改动：无**。上游 LZ4 1.10.0 源码无需任何修改即可在 HarmonyOS 上编译运行。核心压缩实现（lz4.c、lz4frame.c、lz4hc.c、xxhash.c）为纯 C，平台无关。
- **无 lycium recipe**：tpc_c_cplusplus 中无现成 HPKBUILD，上游提供 `build/cmake/` CMake 入口，直接走 fallback 构建更合适。
- **无 patch**：不需要任何源码补丁。
- **无运行时第三方依赖**：liblz4.so 仅依赖系统库（libc、libm 等），无需归档额外 .so。
- **无配置文件**：产物不含 .pc、CMake config、*-config 等消费侧配置文件，不存在跨机器路径问题。

## recipe 改动

无 lycium recipe。使用 fallback 脚本 `recipe/build.sh`，关键参数：

- CMake 入口：`build/cmake/`（非顶层 CMakeLists.txt）
- `-DBUILD_SHARED_LIBS=ON` - 构建共享库
- `-DBUILD_STATIC_LIBS=OFF` - 不构建静态库
- `-DLZ4_BUILD_CLI=ON` - 构建 lz4 CLI 工具
- `-DCMAKE_TOOLCHAIN_FILE=$OHOS_SDK/native/build/cmake/ohos.toolchain.cmake`
- `-DOHOS_ARCH=arm64-v8a`

## 源码改动

无。上游源码保持不变。

CLI 程序（`programs/`）包含 POSIX 能力探测和 pthread 支持逻辑（platform.h、util.h、threadpool.c），但 HarmonyOS toolchain 可正常处理，无需宏分支修改。

## 产物

```
artifacts/arm64-v8a/
├── bin/
│   └── lz4              # CLI 工具，可独立运行
└── lib/
    ├── liblz4.so        # symlink → liblz4.so.1
    ├── liblz4.so.1      # symlink → liblz4.so.1.10.0
    └── liblz4.so.1.10.0 # 实际共享库
```

- 头文件来自上游 `lib/` 目录：lz4.h、lz4frame.h、lz4hc.h、lz4file.h
- lz4 CLI 不依赖 liblz4.so 即可启动（静态链接了压缩逻辑），设备验证路径直接

## 验证

设备验证通过 hdc 执行：

```bash
hdc file send artifacts/arm64-v8a/bin/lz4 /data/local/tmp/LZ4/
hdc shell chmod 755 /data/local/tmp/LZ4/lz4
hdc shell /data/local/tmp/LZ4/lz4 -V
```

关键输出：
```
*** lz4 v1.10.0 64-bit single-thread, by Yann Collet ***
```

构建过程中有 clang 关于 `--gcc-toolchain` 的未使用参数告警，不影响产物。

## fallback 脚本复用

`recipe/build.sh` 已改造为可复用脚本，接受以下环境变量：

- `SOURCE_DIR`：LZ4 源码根目录（必须包含 `build/cmake/CMakeLists.txt`）
- `OUTPUT_ROOT`：产物输出目录
- `OHOS_SDK`：HarmonyOS SDK 路径（默认从 COMMAND_LINE_TOOLS_ROOT 推导）

使用方式：
```bash
SOURCE_DIR=/path/to/lz4-src OUTPUT_ROOT=/path/to/output bash recipe/build.sh
```

脚本内部使用 CMake 交叉编译，产物自动复制到 OUTPUT_ROOT/lib/ 和 OUTPUT_ROOT/bin/。

## 套用到新版本时的检查点

1. **源码是否仍需零修改**：LZ4 新版本若引入新的平台相关代码（如新的 mmap 用法、Linux 特定系统调用），可能需要评估。
2. **CMake 入口是否变化**：确认 `build/cmake/` 目录结构和 CMakeLists.txt 参数是否兼容。
3. **CLI 是否仍独立可运行**：验证 lz4 CLI 是否仍不依赖 liblz4.so 即可启动。
4. **版本号更新**：fallback 脚本不硬编码版本号，但 meta.yaml 中的 version 和 source.archive URL 需同步更新。
5. **lycium recipe 是否出现**：若 tpc_c_cplusplus 后续添加了 LZ4 的 HPKBUILD，应优先尝试 lycium 构建。
