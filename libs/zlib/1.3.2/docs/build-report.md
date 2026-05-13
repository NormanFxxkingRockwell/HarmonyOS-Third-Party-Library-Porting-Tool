# zlib 构建报告

## 1. 构建结论

- `build-pass`: pass
- `binary-pass`: pass
- `device-pass`: pass

## 2. 构建路径

- 构建主路径：`lycium`
- 使用 recipe：`tpc_c_cplusplus/thirdparty/zlib/HPKBUILD`
- 目标架构：`arm64-v8a`
- 说明：现成 `thirdparty/zlib` recipe 已对齐 `1.3.2`，未进入 fallback 原生构建

## 3. 产物情况

- 共享库：
  - `outputs/zlib/lib/libz.so.1.3.2`
  - `outputs/zlib/lib/libz.so.1`
- 运行时库：
  - `outputs/zlib/lib/libc++_shared.so`
- 测试 binary：
  - `outputs/zlib/bin/zlib_example`
  - `outputs/zlib/bin/minigzip`

## 4. binary 来源

- binary 来源类型：`test program`
- binary 回收来源：`build` 目录
- 实际使用的设备测试 binary：`zlib_example`

## 5. 关键命令

### 5.1 lycium 构建

```bash
LIB_NAME=zlib PKGNAME=zlib RECIPE_SCOPE=thirdparty ARCH=arm64-v8a bash scripts/run-lycium-build.sh
```

### 5.2 产物回收

```bash
mkdir -p outputs/zlib/lib outputs/zlib/bin
cp -f tpc_c_cplusplus/lycium/usr/zlib/arm64-v8a/lib/libz.so.1.3.2 outputs/zlib/lib/
cp -f tpc_c_cplusplus/lycium/usr/zlib/arm64-v8a/lib/libc++_shared.so outputs/zlib/lib/
cp -f tpc_c_cplusplus/thirdparty/zlib/zlib-1.3.2/arm64-v8a-build/test/zlib_example outputs/zlib/bin/
cp -f tpc_c_cplusplus/thirdparty/zlib/zlib-1.3.2/arm64-v8a-build/test/minigzip outputs/zlib/bin/
cp -f outputs/zlib/lib/libz.so.1.3.2 outputs/zlib/lib/libz.so.1
```

### 5.3 设备测试

设备测试通道：`hdc fallback`

```bash
hdc shell mkdir /data/local/tmp/zlib
hdc shell mkdir /data/local/tmp/zlib/lib
hdc shell mkdir /data/local/tmp/zlib/bin
hdc file send outputs/zlib/lib/libz.so.1 /data/local/tmp/zlib/lib/
hdc file send outputs/zlib/bin/zlib_example /data/local/tmp/zlib/bin/
hdc shell chmod 755 /data/local/tmp/zlib/bin/zlib/bin/zlib_example
hdc shell env LD_LIBRARY_PATH=/data/local/tmp/zlib/lib/zlib/lib /data/local/tmp/zlib/bin/zlib/bin/zlib_example
```

## 6. 设备侧执行结果

- 返回结果：命令成功执行
- 关键输出：

```text
zlib version 1.3.2 = 0x1320, compile flags = 0xa9
gzopen error
uncompress(): hello, hello!
```

## 7. 备注

- `hdc file send` 在当前环境下会把源路径层级一并带到目标目录，因此设备侧实际路径为：
  - `/data/local/tmp/zlib/lib/zlib/lib/libz.so.1`
  - `/data/local/tmp/zlib/bin/zlib/bin/zlib_example`
- 当前未发现新的 `.rej` 文件，也未在关键构建日志中发现未处理失败信号。
