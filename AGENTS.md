# AI 执行说明

## 前置条件

用户需先准备 lycium 构建环境：

```
git clone https://gitee.com/openharmony/tpc_c_cplusplus.git
```

确保以下路径存在：
- `tpc_c_cplusplus/lycium/`
- `tpc_c_cplusplus/thirdparty/`

确保 HarmonyOS SDK 已配置：
- `OHOS_SDK` 环境变量指向 SDK 目录
- 或 `COMMAND_LINE_TOOLS_ROOT` 指向 command-line-tools

## 核心任务

读取本仓库中某个库的配置，套用到同库不同版本。

当前仓库只保留 `arm64-v8a` 产物和配置；不要迁移或声明 `armeabi-v7a`、`x86_64` 等其他架构。

## 执行流程

### 1. 查找目标库

用户指定库名和版本，如 `zlib 1.3.2`。

检查本仓库：
```
libs/<库名>/<版本>/meta.yaml
libs/<库名>/<版本>/recipe/HPKBUILD
```

### 2. 读取配置

优先读取：
- `meta.yaml`：构建方式（lycium/fallback）、架构（当前应为 `arm64-v8a`）
- `recipe/HPKBUILD`：lycium recipe
- `recipe/SHA512SUM`：校验和
- `modifications.md`：改动指导

如有：
- `patches/*.patch`：源码改动
- `docs/build-report.md`：构建报告

### 3. 套用配置到新版本

假设用户要适配 `zlib 1.4.0`（基于已适配的 `1.3.2`）：

#### 3.1 更新 recipe

基于 `libs/zlib/1.3.2/recipe/HPKBUILD`：
- 更新 `pkgver`：`1.3.2` → `1.4.0`
- 更新 `source` URL（版本号变化）
- 更新 `builddir`（如版本号影响目录名）
- 重新计算 `SHA512SUM`

#### 3.2 处理 patches

检查 `libs/zlib/1.3.2/patches/`：
- 如有 patch，评估是否仍适用于新版本
- patch 行号可能因源码变化失效，需重新生成或调整

#### 3.3 检查 modifications.md

阅读改动指导：
- recipe 中的 sed 命令是否仍适用
- 源码改动是否在新版本已修复
- 新版本是否有需要额外处理的改动

#### 3.4 写入目标位置

将新配置写入用户的 lycium 目录：
```
tpc_c_cplusplus/thirdparty/zlib/HPKBUILD
tpc_c_cplusplus/thirdparty/zlib/SHA512SUM
```

### 4. 环境问题处理

当环境缺失时：
- `OHOS_SDK` 未设置：提示用户配置
- lycium 路径不存在：提示用户克隆 tpc_c_cplusplus
- SDK 未安装：提示用户下载 command-line-tools
- cmake/clang 缺失：提示用户检查 SDK 目录

## 迁移脚本

从 `ho-thirdparty-porting` 生成知识包时，必须一次处理一个库：

```bash
LIB_NAME=libzip scripts/migrate-library.sh ../ho-thirdparty-porting .
scripts/validate-library-package.sh libs/libzip/v1.11.4
```

脚本会复制真实报告、产物、recipe 和 recipe 同级 patch/cross-file。生成的 `modifications.md` 只是结构化草稿，仍需人工从 `docs/build-report.md` 等报告中提炼真实改动。

后续 AI 接手继续整理库知识包时，先阅读 [AI_CONTINUATION_WORKFLOW.md](./AI_CONTINUATION_WORKFLOW.md)，按其中的一库一提交流程执行。

## 输出规范

完成套用后，输出：

```
库名: zlib
原版本: 1.3.2
目标版本: 1.4.0

改动点:
- pkgver: 1.3.2 → 1.4.0
- source: https://zlib.net/fossils/zlib-1.3.2.tar.gz → https://zlib.net/fossils/zlib-1.4.0.tar.gz
- SHA512SUM: 已更新

写入位置: tpc_c_cplusplus/thirdparty/zlib/

需确认:
- 新版本 SHA512SUM 需下载源码后计算
- patches/001-xxx.patch 可能需调整行号
```

## 注意事项

1. 不要并行处理多个库
2. 套用前先确认原版本配置完整
3. 版本跨度大时（如 1.0 → 2.0），改动可能不适用，需重新分析
4. fallback 构建方式的库，需额外检查 build.sh

## 库命名规范

本仓库库名使用大写开头，与 ho-thirdparty-porting/outputs 保持一致：
- `zlib`, `bzip2` 等小写库保持小写
- `OpenCV`, `OpenSSL`, `Skia`, `Abseil` 等使用大写开头
- 特殊命名：`GNU_libiconv`, `GNU_libunistring`, `Mbed_TLS`, `Protocol_Buffers`
