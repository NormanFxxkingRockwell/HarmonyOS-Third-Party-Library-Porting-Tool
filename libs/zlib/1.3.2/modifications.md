# zlib 1.3.2 改动指导

## 改动来源

- recipe 改动：HPKBUILD
- 源码改动：无

## HPKBUILD 改动要点

原生 recipe 来自 tpc_c_cplusplus/thirdparty/zlib/HPKBUILD，主要改动：

| 改动点 | 说明 |
|--------|------|
| pkgver | 版本号 |
| source | 源码下载地址 |
| builddir | 构建目录名（与版本号关联） |
| buildtools | cmake |

## 源码改动

无需改动上游源码，lycium 直接构建即可。

## 构建命令

```bash
LIB_NAME=zlib PKGNAME=zlib RECIPE_SCOPE=thirdparty ARCH=arm64-v8a bash scripts/run-lycium-build.sh
```

## 注意事项

1. check() 函数会拷贝 libc++_shared.so，用于设备测试
2. 构建产物在 `lycium/usr/zlib/<架构>/lib/`