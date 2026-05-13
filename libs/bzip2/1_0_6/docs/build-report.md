# bzip2 构建报告

## 1. 构建结论

- `build-pass`: pass
- `binary-pass`: pass
- `device-pass`: pass

## 2. 构建路径

- 首次尝试：`lycium`
- `lycium` 失败分类：`HPKBUILD / recipe 问题`
- 失败原因：
  - `thirdparty/bzip2/HPKBUILD` 的 `packagename` 为 `bzip2-bzip2-1_0_6.zip`
  - 下载包名实际为 `bzip2-1_0_6.zip`
  - recipe 预检阶段即失败
- 进入路径：fallback 原生构建
- fallback 脚本：`libs/bzip2/build.sh`

## 3. 产物情况

- 共享库：
  - `outputs/bzip2/lib/libbz2.so.1.0.8`
  - `outputs/bzip2/lib/libbz2.so.1.0`
- 测试 binary：
  - `outputs/bzip2/bin/bzip2-shared`

## 4. binary 来源

- binary 来源类型：`test program`
- binary 回收来源：fallback 构建目录
- 实际设备测试 binary：`bzip2-shared`

## 5. 关键命令

### 5.1 lycium 验证

```bash
LIB_NAME=bzip2 PKGNAME=bzip2 RECIPE_SCOPE=thirdparty ARCH=arm64-v8a bash scripts/run-lycium-build.sh
```

### 5.2 fallback 构建

```bash
bash libs/bzip2/build.sh
```

### 5.3 设备测试

设备测试通道：`hdc fallback`

```bash
hdc file send outputs/bzip2/lib/libbz2.so.1.0 /data/local/tmp/bzip2/
hdc file send outputs/bzip2/bin/bzip2-shared /data/local/tmp/bzip2/
hdc shell chmod 755 /data/local/tmp/bzip2/outputs/bzip2/bin/bzip2-shared
hdc shell env LD_LIBRARY_PATH=/data/local/tmp/bzip2/bzip2/lib /data/local/tmp/bzip2/outputs/bzip2/bin/bzip2-shared --help
hdc file send libs/bzip2/sample1.bz2 /data/local/tmp/bzip2/
hdc shell env LD_LIBRARY_PATH=/data/local/tmp/bzip2/bzip2/lib /data/local/tmp/bzip2/outputs/bzip2/bin/bzip2-shared -dc /data/local/tmp/bzip2/libs/bzip2/sample1.bz2
```

## 6. 设备侧执行结果

- 帮助命令成功输出 `bzip2-shared` 版本与参数说明。
- 解压命令成功执行并输出样例数据流。
- 关键输出：

```text
bzip2, a block-sorting file compressor.  Version 1.0.8, 13-Jul-2019.
```

## 7. 备注

- 本库的关键问题不是源码适配，而是现成 recipe 无法满足版本与包名校验要求。
- fallback 直接复用了上游 `Makefile-libbz2_so`，较低成本产出 `.so` 和共享库链路 CLI。
