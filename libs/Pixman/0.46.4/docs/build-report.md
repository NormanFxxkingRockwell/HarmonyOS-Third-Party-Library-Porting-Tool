# Pixman 构建报告

## 1. 构建系统识别结果

- 按 `docs/10-build-system-detect.md` 的固定识别顺序：
  - 未命中 `CMakeLists.txt`
  - 未命中 `configure` / `configure.ac` / `configure.in`
  - 未命中顶层 `Makefile`
  - 未命中 `BUILD.gn` / `.gn`
  - 因此文档内归类结果为：`unknown`
- 补充说明：
  - 上游实际主构建入口为 `meson.build`
  - Phase 3 已明确当前上游主构建系统是 `Meson`
- 本轮 `lycium` 起点：
  - `tpc_c_cplusplus/thirdparty/pixman/HPKBUILD`

## 2. lycium 路径决策

- 是否发现现成 `HPKBUILD`：是
  - `tpc_c_cplusplus/thirdparty/pixman/HPKBUILD`
- 本轮是否优先尝试 `lycium`：是
- 是否进入 fallback：否

依据：
- 已存在同库 recipe，必须先按 `lycium-first` 路线执行。
- 现成 recipe 的版本、下载包、`SHA512SUM`、`builddir`、构建系统、架构范围和 binary 收集逻辑漂移，均属于“先预修正再执行 lycium”的范围。
- 本轮遇到的失败先后属于 `A. 环境缺失` 和 `B. HPKBUILD / recipe 问题`，都不是“lycium 无法表达该构建逻辑”的构建系统类失败，因此不触发 fallback。

## 3. lycium 预检查与预修正

### 3.1 预检查发现的问题

- 现成 recipe 版本落后：
  - 原 `pkgver=0.42.2`
  - 目标版本为 `0.46.4`
- 下载源、`packagename`、`builddir` 与当前目标不一致：
  - 原 `source` 指向 gitee zip
  - 原 `packagename=Pixman-pixman-0.42.2.zip`
  - 当前目标下载包实际为 `pixman-pixman-0.46.4.tar.gz`
  - 当前目标解包根目录为 `pixman-pixman-0.46.4`
- 原 recipe 构建系统路线已漂移：
  - 原 `buildtools="configure"`
  - 原 `build()` 调用 `../autogen.sh`
  - 当前上游 `0.46.4` 顶层实际为 `Meson`
- 原 recipe 默认 `archs=("armeabi-v7a" "arm64-v8a")`，与仓库默认目标 `arm64-v8a` 不一致。
- 上游存在可独立运行测试入口：
  - `pixel-test`
  - `region-test`
  - `matrix-test`
  - `scaling-test`
  - `thread-test`
  - `prng-test`
  - `tolerance-test`
- 原 recipe 没有把这些上游测试 binary 安装或收集到 lycium install 目录。
- 原 recipe 目录没有 Meson 交叉文件模板。

### 3.2 已执行的预修正

- 升级 `pkgver` 到 `0.46.4`
- 将 `source` 修正为官方 GitLab tag archive：
  - `https://gitlab.freedesktop.org/pixman/pixman/-/archive/pixman-$pkgver/pixman-pixman-$pkgver.tar.gz`
- 将 `packagename` 修正为：
  - `pixman-pixman-0.46.4.tar.gz`
- 将 `builddir` 修正为：
  - `pixman-pixman-0.46.4`
- 修正 `SHA512SUM`
- 将 `buildtools` 从 `configure` 路线切换到 `meson`
- 将目标架构收敛到仓库默认目标：
  - `archs=("arm64-v8a")`
- 新增 Meson 交叉文件模板：
  - `tpc_c_cplusplus/thirdparty/pixman/arm64-v8a-cross-file.txt`
  - `tpc_c_cplusplus/thirdparty/pixman/armeabi-v7a-cross-file.txt`
- 在 `prepare()` 中补齐依赖的 `pkgconfig` 路径
- 在 `build()` 中显式固定关键选项：
  - `-Ddefault_library=shared`
  - `-Dtests=enabled`
  - `-Ddemos=disabled`
  - `-Dgtk=disabled`
  - `-Dopenmp=disabled`
  - `-Dlibpng=enabled`
- 在 `package()` 中补齐 binary 收集逻辑，把以下上游测试入口拷贝到 install 目录：
  - `matrix-test`
  - `pixel-test`
  - `prng-test`
  - `region-test`
  - `scaling-test`
  - `thread-test`
  - `tolerance-test`

## 4. lycium 执行结果

### 4.1 执行命令

```bash
LIB_NAME=Pixman PKGNAME=pixman HPK_DIR=tpc_c_cplusplus/thirdparty/pixman ARCH=arm64-v8a bash scripts/run-lycium-build.sh
```

### 4.2 第一轮失败分类

- 失败分类：`A. 环境缺失`
- 失败现象：
  - lycium 日志提示：`请先安装 meson 命令, 才可以编译 pixman`
- 处理：
  - 在仓库 `tmp/pixman-meson-venv/` 下创建局部 Python venv
  - 安装 `meson`
  - 将 `meson` 链接到已在 WSL PATH 中的 `~/.local/bin/meson`
- 处理后不进入 fallback，继续重试 lycium

### 4.3 第二轮失败分类

- 失败分类：`B. HPKBUILD / recipe 问题`
- 失败现象：
  - lycium 先尝试 `armeabi-v7a`
  - `armeabi-v7a-build/build.log` 中报错：
    - `libpng support requested but libpng library not found`
- 根因：
  - recipe 仍声明了 `armeabi-v7a`，而当前批次目标和依赖闭包都以 `arm64-v8a` 为准
- 处理：
  - 将 `archs` 收敛为 `("arm64-v8a")`
- 处理后不进入 fallback，继续重试 lycium

### 4.4 第三轮结果

- 第三轮 `lycium` 成功
- 关键日志信号：
  - `Compileing OpenHarmony arm64-v8a pixman 0.46.4 libs...`
  - `Build pixman 0.46.4 end!`
  - `ALL JOBS DONE!!!`
- 未发现新的 `.rej` 文件
- 未进入 fallback

## 5. 编译驱动型修改

- 修改文件：
  - `tpc_c_cplusplus/thirdparty/pixman/HPKBUILD`
  - `tpc_c_cplusplus/thirdparty/pixman/SHA512SUM`
  - `tpc_c_cplusplus/thirdparty/pixman/arm64-v8a-cross-file.txt`
  - `tpc_c_cplusplus/thirdparty/pixman/armeabi-v7a-cross-file.txt`
- 修改目的：
  - 让同库现成 recipe 与当前上游版本和构建系统对齐
  - 保留共享库与上游自带测试 binary
  - 将构建范围收敛到仓库默认目标 `arm64-v8a`
- 是否修改 `libs/Pixman/` 源码：否

## 6. 产物概览

- `build-pass`：是
- `binary-pass`：是
- `device-pass`：是

### 6.1 `.so` 产物

- `outputs/Pixman/lib/libpixman-1.so -> libpixman-1.so.0 -> libpixman-1.so.0.46.4`

### 6.2 架构确认

- `outputs/Pixman/lib/libpixman-1.so.0.46.4`
  - `ELF 64-bit LSB shared object, ARM aarch64`
- `outputs/Pixman/bin/pixel-test`
  - `ELF 64-bit LSB pie executable, ARM aarch64`
- `outputs/Pixman/bin/thread-test`
  - `ELF 64-bit LSB pie executable, ARM aarch64`
- `outputs/Pixman/bin/prng-test`
  - `ELF 64-bit LSB pie executable, ARM aarch64`

## 7. binary 收集结果

- binary 来源类型：上游自带、可独立运行的测试入口
- binary 收集来源：
  - install 目录：
    - `tpc_c_cplusplus/lycium/usr/pixman/arm64-v8a/bin/`
- install 目录回收结果：
  - `matrix-test`
  - `pixel-test`
  - `prng-test`
  - `region-test`
  - `scaling-test`
  - `thread-test`
  - `tolerance-test`
- 构建目录中也已生成更多上游测试入口，但本轮设备测试不需要再从构建目录补回收，因为 install 目录已经具备合适 binary。

## 8. 设备测试结果

### 8.1 设备测试通道

- `harmonyos-dev-mcp`：当前会话不可用
  - `list_mcp_resources` 返回空列表
  - `list_mcp_resource_templates` 返回空列表
- 实际执行通道：`hdc fallback`

### 8.2 首次设备执行情况

- 首轮设备执行失败，但不是 `Pixman` 自身构建失败。
- 失败原因：
  - 初次推送时未成功发送 `libpixman-1.so.0.46.4`
  - 运行时依赖 `libpng16.so.16` 和 `libz.so.1` 也未补齐
- 关键输出：
  - `Error loading shared library libpixman-1.so.0`
  - `Error loading shared library libpng16.so.16`
  - `EXIT:127`
- 处理：
  - 改用实际文件路径重新发送 `libpixman-1.so.0.46.4`
  - 补推 `libpng16.so.16.56.0` 和 `libz.so.1.3.2`
  - 在设备侧补建对应 SONAME 软链
- 该问题属于设备侧运行时依赖补齐，不触发 fallback。

### 8.3 二次设备执行命令

```powershell
$hdc = 'C:\Users\aoqiduan\Desktop\env\OH_SDK\ohos-sdk\toolchains\hdc.exe'

& $hdc shell 'rm -rf /data/local/tmp/Pixman && mkdir -p /data/local/tmp/Pixman'
Get-ChildItem outputs/Pixman/bin -File | ForEach-Object { & $hdc file send $_.FullName '/data/local/tmp/Pixman/' }
& $hdc file send '<outputs/Pixman/lib/libpixman-1.so.0.46.4>' '/data/local/tmp/Pixman/'
& $hdc file send '<tpc_c_cplusplus/lycium/usr/libpng/arm64-v8a/lib/libpng16.so.16.56.0>' '/data/local/tmp/Pixman/'
& $hdc file send '<tpc_c_cplusplus/lycium/usr/zlib/arm64-v8a/lib/libz.so.1.3.2>' '/data/local/tmp/Pixman/'
& $hdc shell 'cd /data/local/tmp/Pixman && ln -sf libpixman-1.so.0.46.4 libpixman-1.so.0 && ln -sf libpixman-1.so.0 libpixman-1.so && ln -sf libpng16.so.16.56.0 libpng16.so.16 && ln -sf libpng16.so.16 libpng16.so && ln -sf libz.so.1.3.2 libz.so.1 && ln -sf libz.so.1 libz.so && chmod +x ./*'
& $hdc shell 'cd /data/local/tmp/Pixman && LD_LIBRARY_PATH=/data/local/tmp/Pixman ./pixel-test; echo EXIT:$?'
& $hdc shell 'cd /data/local/tmp/Pixman && LD_LIBRARY_PATH=/data/local/tmp/Pixman ./thread-test; echo EXIT:$?'
& $hdc shell 'cd /data/local/tmp/Pixman && LD_LIBRARY_PATH=/data/local/tmp/Pixman ./prng-test -bench; echo EXIT:$?'
```

### 8.4 二次设备执行结果

- `pixel-test`
  - 返回：`EXIT:0`
  - 关键输出：无额外 stdout，返回码为 `0`
- `thread-test`
  - 返回：`EXIT:0`
  - 关键输出：无额外 stdout，返回码为 `0`
- `prng-test -bench`
  - 返回：`EXIT:0`
  - 关键输出：
    - `aligned randmemset                    : 4036.21 MB/s`
    - `unaligned randmemset                  : 6583.43 MB/s`
    - `aligned randmemset (more 00 and FF)   : 2975.21 MB/s`
    - `unaligned randmemset (more 00 and FF) : 2977.45 MB/s`

## 9. 最终结论

- `build-pass`：是
- `binary-pass`：是
- `device-pass`：是
- 本轮采用路径：
  - `lycium-first`
  - 第 1 轮修复环境缺失（`meson`）
  - 第 2 轮修复 recipe 架构声明
  - 第 3 轮 `lycium` 成功
  - binary 来自 install 目录中的上游自带、可独立运行测试入口
  - `harmonyos-dev-mcp` 当前不可用，因此设备测试使用 `hdc fallback`
  - 无需 fallback
