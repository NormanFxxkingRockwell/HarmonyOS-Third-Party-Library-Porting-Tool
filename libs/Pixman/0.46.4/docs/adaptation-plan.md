# Pixman 业务代码适配方案

## 1. 项目结构概览

- 仓库根目录的主构建入口是 `meson.build` 和 `meson.options`，当前上游主构建系统为 `Meson`。
- 核心库源码位于 `pixman/`，其中包含像素合成、区域计算、渐变、架构优化实现和 CPU 特性检测逻辑。
- 公开头文件主要位于 `pixman/`，包括 `pixman.h`；`pixman-version.h` 与 `pixman-config.h` 由 Meson 配置阶段生成并安装到 `include/pixman-1/`。
- 自带测试入口位于 `test/`，公共测试辅助代码位于 `test/utils/`；这些测试以独立二进制方式由 Meson 注册，适合后续设备侧验证。
- 演示程序位于 `demos/`，但依赖 `gtk+-3.0`、`glib-2.0` 和部分图片输入，不是设备侧首选验证入口。
- 顶层的 `a64-neon-test.S`、`neon-test.S`、`arm-simd-test.S` 等文件用于构建阶段探测 SIMD 汇编能力。

## 2. 平台相关代码识别

- `meson.build` 按 CPU 架构和编译器能力探测 `mmx`、`sse2`、`ssse3`、`arm-simd`、`neon`、`a64-neon`、`rvv`、`openmp`、`libpng`、`threads` 等特性，并决定生成哪些优化实现和测试目标。
- `pixman/pixman-arm.c` 包含 Windows、iOS、Android、Linux ELF、3DS、PSP2、Switch 等多平台分支；其中 Linux ARM 分支会读取 `/proc/self/auxv`，而 `arm64-v8a` 对应的 `USE_ARM_A64_NEON` 路径直接把 A64 NEON 视为 AArch64 内建能力。
- `pixman/pixman-riscv.c` 在 `__linux__` 下通过 `sys_riscv_hwprobe()` 做 RVV 运行时检测，说明部分优化实现仍带有 Linux 特定假设。
- `pixman/pixman-implementation.c` 读取环境变量 `PIXMAN_DISABLE` 控制优化后端开关，这对后续设备侧问题定位有用。
- `test/utils/utils.c` 和 `test/utils/utils.h` 依赖 `signal.h`、`sys/time.h`、`unistd.h`、`sys/mman.h`、`mmap`、`mprotect`、`gettimeofday`、`libpng` 等能力；`thread-test.c` 依赖 `pthread.h` 或 Windows threads。
- `demos/meson.build` 仅在 `gtk+-3.0` 和 `glib-2.0` 可用时构建 demo，可见 demo 路线比主库和测试更依赖桌面环境。

## 3. HarmonyOS 业务适配点

- 当前优先目标应是让上游 Meson 构建在 HarmonyOS 工具链下稳定产出 `.so` 和可运行测试 binary，而不是预先改写像素算法实现。
- 对 HarmonyOS Native 侧，优先保留上游 Unix-like 路径，不新增 `OHOS` 专属像素处理实现；只有在实际编译或运行证明平台宏不兼容时，才做最小源码补丁。
- 目标架构固定为 `arm64-v8a`。因此应优先围绕 `a64-neon` 路径验证，而不是直接沿用旧 recipe 中“统一关闭 ARM SIMD/NEON”的历史配置；只有在 Meson 实际编译失败时，才把 `-Da64-neon=disabled` 或相关降级作为修正项。
- 测试相关代码对 `pthread`、`mmap/mprotect`、`libpng` 有要求。若这些能力在设备侧或工具链探测中出现不一致，优先通过构建选项或配置探测修正让流程走通，而不是先改 `pixman/` 主逻辑。
- 当前没有发现现成的 `OHOS` 宏或 HarmonyOS 专用实现文件，说明 Phase 4 应先遵循“最小源码改动”原则。
- 已发现同库现成 `HPKBUILD`，因此 Phase 5 必须坚持 lycium-first，先复制、升级、修正 recipe，再判断是否需要 fallback。

## 4. 建议修改清单

- Phase 4 首先做“无源码改动”实施，除非实际编译报错证明需要补平台宏或小范围兼容补丁。
- Phase 5 的 recipe 预检查必须先确认现有 `HPKBUILD` 与上游构建系统是否一致；当前上游 `0.46.4` 为 Meson 主线，而现有 recipe 仍走 `autogen.sh/configure`，这一点必须先修正。
- recipe 预修正应优先覆盖 `pkgver`、`source`、`SHA512SUM`、`builddir`、`packagename`、`buildtools` 和构建命令，不能因为版本或构建系统漂移就直接 fallback。
- 若需要设备侧测试 binary，优先保留 `-Dtests=enabled`；`demos` 因 GTK 依赖较重，除非构建顺利且有必要，否则不应作为首轮目标。
- 若测试仅被 `libpng` 或 `openmp` 阻塞，优先最小化地关闭相应可选项或收缩测试集，不应先裁剪主库共享库产出。

## 5. 风险与假设

- 已知最大风险是现成 recipe 漂移：`tpc_c_cplusplus/thirdparty/pixman/HPKBUILD` 当前版本是 `0.42.2`，且使用 `configure`/`autogen.sh` 路线，而当前任务版本 `0.46.4` 的上游仓库顶层已无对应 autotools 入口。
- `test/utils` 依赖 `mmap`、`mprotect`、`pthread`、`libpng` 等能力；若 HarmonyOS NDK 探测结果与宿主 Linux 不一致，可能影响部分测试二进制的构建或运行。
- `demos/` 依赖 GTK/GLib 和图片输入，更像桌面演示，不适合作为设备侧首选验证入口。
- 目前假设 HarmonyOS Native 侧可提供 `pthread`、常规 `unistd`、`mmap`/`mprotect` 和标准文件 I/O；若 Phase 5 运行结果否定该假设，再回到 Phase 4 做最小代码调整。

## 6. 可复用测试入口与指导

- 上游自带、可独立运行且更适合设备侧首轮验证的入口位于 `test/`。优先推荐不依赖外部样例数据的独立二进制：`pixel-test`、`region-test`、`matrix-test`、`scaling-test`、`thread-test`。
- 这些二进制由 `test/meson.build` 直接注册为独立测试程序，首轮设备侧验证无需额外测试数据，推荐先执行以下命令：

```sh
/data/local/tmp/Pixman/pixel-test
/data/local/tmp/Pixman/region-test
/data/local/tmp/Pixman/matrix-test
/data/local/tmp/Pixman/scaling-test
/data/local/tmp/Pixman/thread-test
```

- `thread-test` 依赖 `pthread`；若线程支持不可用，它会输出跳过信息，因此它适合作为线程能力补充验证，而不是唯一主验证入口。
- `test/` 下还有 `prng-test`、`tolerance-test`、`stress-test`、`lowlevel-blt-bench` 等程序，可作为第二轮补充验证。其中 `prng-test` 支持 `-bench`，`tolerance-test` 支持传入循环次数。

```sh
/data/local/tmp/Pixman/prng-test -bench
/data/local/tmp/Pixman/tolerance-test 1000
```

- `demos/` 虽然也是上游自带入口，但它们依赖 GTK/GLib 和图像输入文件，不适合作为当前设备侧首轮验证入口。
- 当前没有比这些独立测试二进制更合适的上游 CLI 主入口，因此后续应优先复用 `test/` 产物，而不是发明新的验证程序。
- 无测试用例：否。

## 7. 给 Phase 5 的最小交接摘要

- 构建系统类型：`Meson`
- 是否发现现成 `HPKBUILD`：是，路径为 `tpc_c_cplusplus/thirdparty/pixman/HPKBUILD`
- 现成 `HPKBUILD` 版本情况：已存在同库 recipe，但当前版本为 `0.42.2`，且使用 `configure`/`autogen.sh` 路线；需要升级到任务表指定的 `0.46.4`，并修正为与当前上游一致的 Meson 构建路径
- 是否更适合优先尝试 `lycium`：是。已存在同库 recipe，Phase 5 必须先做 recipe 预检查和预修正后再执行 lycium
- 是否预计需要 fallback：暂不预计必须 fallback；只有在同库 recipe 经预检查、预修正并实际执行 lycium 后仍证明不可行，才允许进入 fallback
- 已知高风险依赖或构建障碍：同库 recipe 的构建系统和版本均已漂移；测试二进制依赖 `libpng`、`pthread`、`mmap/mprotect`；`demos` 依赖 `gtk+-3.0`/`glib-2.0`，不应作为首轮目标
