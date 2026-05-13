# HarmonyOS-Third-Party-Library-Porting-Tool

HarmonyOS 三方库鸿蒙化产物存放仓库。

## 定位

本仓库用于存放已鸿蒙化的三方库配置、产物和改动指导，便于：

- 直接获取已编译的 `.so` 产物
- 复用配置到同库不同版本
- 查阅改动要点和适配方法

## 目录结构

```
libs/
├── zlib/
│   └── 1.3.2/
│       ├── meta.yaml          # 基本信息
│       ├── artifacts/         # .so 产物
│       │   ├── arm64-v8a/
│       │   └── output/        # 设备验证包（bin/lib/依赖库）
│       ├── recipe/            # lycium 配置
│       │   ├── HPKBUILD
│       │   └── SHA512SUM
│       ├── patches/           # 源码 patch（如有）
│       ├── modifications.md   # 改动指导
│       └── docs/              # 文档（可选）
```

## 前置条件

使用本仓库的配置需先准备 lycium 环境：

```
git clone https://gitee.com/openharmony/tpc_c_cplusplus.git
```

详见 [AGENTS.md](./AGENTS.md)。

## 已迁移库列表

参见 [libs/](./libs/) 目录。

## 迁移脚本

当前仓库只保留 `arm64-v8a` 产物和配置。迁移必须一次处理一个库：

```bash
LIB_NAME=libzip scripts/migrate-library.sh ../ho-thirdparty-porting .
```

脚本会迁移：

- `reports/<库>/` 到 `docs/`
- `outputs/<库>/` 到 `artifacts/output/`
- `tpc_c_cplusplus/lycium/usr/<pkg>/arm64-v8a/` 到 `artifacts/arm64-v8a/`
- lycium recipe 及其同级 patch/cross-file 到 `recipe/`

如果库没有 lycium recipe，脚本会按 fallback 知识包处理，并在 `meta.yaml` 中记录 `method: fallback`。

迁移后运行：

```bash
scripts/validate-library-package.sh libs/<库名>/<版本>
```

## AI 使用说明

参见 [AGENTS.md](./AGENTS.md)。
