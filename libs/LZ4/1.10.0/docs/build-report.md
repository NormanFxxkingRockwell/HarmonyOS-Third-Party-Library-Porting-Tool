# LZ4 构建报告

## 1. 构建结论

- `build-pass`: pass
- `binary-pass`: pass
- `device-pass`: pass

## 2. 构建路径

- 构建路径：fallback 原生构建
- 原因：
  - 未发现现成 `HPKBUILD`
  - 上游已提供稳定的 `build/cmake` 入口
- fallback 脚本：`libs/LZ4/build.sh`

## 3. 产物情况

- 共享库：
  - `outputs/LZ4/lib/liblz4.so.1.10.0`
  - `outputs/LZ4/lib/liblz4.so.1`
  - `outputs/LZ4/lib/liblz4.so`
- 测试 binary：
  - `outputs/LZ4/bin/lz4`

## 4. binary 来源

- binary 来源类型：`test program`
- binary 回收来源：install 目录
- 实际设备测试 binary：`lz4`

## 5. 关键命令

### 5.1 fallback 构建

```bash
bash libs/LZ4/build.sh
```

### 5.2 设备测试

设备测试通道：`hdc fallback`

```bash
hdc file send outputs/LZ4/bin/lz4 /data/local/tmp/LZ4/
hdc shell chmod 755 /data/local/tmp/LZ4/outputs/LZ4/bin/lz4
hdc shell /data/local/tmp/LZ4/outputs/LZ4/bin/lz4 -V
```

## 6. 设备侧执行结果

- 命令成功执行
- 关键输出：

```text
*** lz4 v1.10.0 64-bit single-thread, by Yann Collet ***
```

## 7. 备注

- 构建过程中存在 `clang` 关于 `--gcc-toolchain` 的未使用参数告警，但不影响最终产物。
- `lz4` CLI 本身不依赖 `liblz4.so` 才能启动，因此设备侧验证路径非常直接。
