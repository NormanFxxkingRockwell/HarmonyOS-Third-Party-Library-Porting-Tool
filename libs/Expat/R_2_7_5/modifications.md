# Expat R_2_7_5 鸿蒙化改动记录

## 状态

- 构建方式：lycium
- 构建结果：build-pass / binary-pass / device-pass
- 目标架构：`arm64-v8a`
- 源码业务改动：无
- fallback：未进入

## 事实来源

- `docs/adaptation-plan.md`
- `docs/adaptation-report.md`
- `docs/build-report.md`
- `recipe/HPKBUILD`
- `recipe/SHA512SUM`
- `recipe/HPKCHECK`

## 关键结论

Expat 主库不需要 HarmonyOS 专用源码 patch。本轮鸿蒙化的可复用价值主要在 lycium recipe 升级、构建开关确认、示例 binary 回收和设备侧 XML 解析验证。

## recipe 改动

原 `tpc_c_cplusplus/thirdparty/libexpat/HPKBUILD` 版本落后于目标版本。本轮修正点：

- `pkgver` 从旧的 `R_2_5_0` 升级到 `R_2_7_5`。
- `source` 从旧镜像 zip 包切换到上游 GitHub tag tarball：`https://github.com/libexpat/libexpat/archive/refs/tags/$pkgver.tar.gz`。
- `packagename` 对齐为 `R_2_7_5.tar.gz`。
- `builddir` 对齐为 `libexpat-R_2_7_5`。
- `SHA512SUM` 更新为 `R_2_7_5.tar.gz` 的校验值。
- 构建系统继续使用 CMake。
- 本知识包将 recipe 架构声明收敛为 `archs=("arm64-v8a")`。

关键 CMake 开关：

- `EXPAT_SHARED_LIBS=ON`：产出共享库。
- `EXPAT_BUILD_TOOLS=ON`：构建并安装 `xmlwf`。
- `EXPAT_BUILD_EXAMPLES=ON`：构建 `elements`、`outline`、`element_declarations`。
- `EXPAT_BUILD_TESTS=ON`：保留测试目标，`HPKCHECK` 通过 `ctest` 执行。
- `EXPAT_BUILD_DOCS=OFF`：不构建文档。
- `EXPAT_WARNINGS_AS_ERRORS=OFF`：避免交叉构建环境中的 warning 升级为失败。

## 源码改动

未修改 `libs/Expat/` 上游业务源码，也没有归档源码 patch。

适配方案中识别到 `xmlwf` 的 Unix 文件映射实现会使用 `mmap`、`fcntl`、`unistd.h`、`sys/stat.h` 等 POSIX 接口，但本轮构建和设备验证未证明这些接口需要 HarmonyOS 专用替换。因此不要为了平台名主动加 `OHOS` 宏分支。

## 产物

`artifacts/arm64-v8a/` 合并归档了 lycium install 产物、示例 binary 和设备验证输入，包含：

- `lib/libexpat.so.1.11.3`
- `lib/libexpat.so.1`
- `lib/libexpat.so`
- `lib/pkgconfig/expat.pc`
- `lib/cmake/expat-2.7.5/*.cmake`
- `include/expat.h`
- `include/expat_external.h`
- `include/expat_config.h`
- `bin/xmlwf`
- `bin/elements`
- `bin/outline`
- `bin/element_declarations`
- `bin/sample.xml`

当前知识包只保留 `arm64-v8a`。不要在 `meta.yaml`、`recipe/HPKBUILD` 或产物目录中声明其他架构。

## 验证

设备侧验证入口优先使用 `elements`，因为它能读取 XML 并输出元素树，依赖比完整测试套件更少，比只运行 `xmlwf --version` 更能覆盖真实解析路径。

报告中的实际设备验证命令：

```bash
hdc shell mkdir -p /data/local/tmp/Expat
hdc file send outputs/Expat/lib/libexpat.so.1 /data/local/tmp/Expat/libexpat.so.1
hdc file send outputs/Expat/bin/elements /data/local/tmp/Expat/elements
hdc file send outputs/Expat/bin/sample.xml /data/local/tmp/Expat/sample.xml
hdc shell chmod 755 /data/local/tmp/Expat/elements
hdc shell "export LD_LIBRARY_PATH=/data/local/tmp/Expat; /data/local/tmp/Expat/elements < /data/local/tmp/Expat/sample.xml"
```

关键输出：

```text
root
	a
```

`xmlwf` 也已归档，可作为 CLI 能力复验入口，但复验时必须读取 XML 文件或标准输入 XML，不接受只运行版本或帮助信息作为最终验证。

## 套用到新版本时的检查点

- 同步更新 `pkgver`、`source`、`packagename`、`builddir` 和 `SHA512SUM`。
- 确认上游 tag 目录结构仍是 `libexpat-<tag>/expat`，否则 `-S./expat` 需要调整。
- 确认 `EXPAT_BUILD_TOOLS`、`EXPAT_BUILD_EXAMPLES`、`EXPAT_BUILD_TESTS` 的默认行为没有变化。
- 重新确认 `elements`、`outline`、`element_declarations` 的构建输出路径；若 examples 路径变化，需要更新产物回收命令。
- 若使用 `xmlwf` 做设备验证，必须覆盖实际 XML 解析路径。
