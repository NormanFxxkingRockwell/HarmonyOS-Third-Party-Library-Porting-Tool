# cJSON 构建报告

## 1. 构建结论

- `build-pass`: pass
- `binary-pass`: pass
- `device-pass`: pass

## 2. 构建路径

- 构建主路径：`lycium`
- 使用 recipe：`tpc_c_cplusplus/thirdparty/cJSON/HPKBUILD`
- 目标架构：`arm64-v8a`
- 构建系统识别结果：`cmake`
- recipe 预检查结论：
  - 现成 `HPKBUILD` 已覆盖目标版本 `v1.7.19`
  - `packagename=v1.7.19.tar.gz`
  - `builddir=cJSON-1.7.19`
  - 上游默认 `BUILD_SHARED_LIBS=ON`
  - 上游默认 `ENABLE_CJSON_TEST=ON`
- recipe 预修正结论：
  - 本轮未修改 `HPKBUILD`、`SHA512SUM`、`packagename` 或 `builddir`
  - 未触发 fallback

## 3. 产物情况

- 共享库：
  - `outputs/cJSON/lib/libcjson.so.1.7.19`
  - `outputs/cJSON/lib/libcjson.so.1`
  - `outputs/cJSON/lib/libcjson.so`
- 测试/验证入口：
  - `outputs/cJSON/bin/cJSON_test`
  - `outputs/cJSON/bin/parse_examples`
  - `outputs/cJSON/bin/readme_examples`
- 架构确认：
  - `libcjson.so.1.7.19` 已确认为 `ELF 64-bit LSB shared object, ARM aarch64`
  - `cJSON_test`、`readme_examples` 已确认为 `ELF 64-bit LSB pie executable, ARM aarch64`

## 4. binary 来源

- binary 来源类型：`上游自带、可独立运行的测试入口`
- binary 回收来源：
  - `.so` 来自 `lycium install` 产物
  - `cJSON_test`、`parse_examples`、`readme_examples` 来自 `arm64-v8a-build/` 构建目录
- 实际设备测试入口：
  - 主验证入口：`cJSON_test`
  - 补充验证入口：`readme_examples`
- 未将 `parse_examples` 作为最终设备侧主验证入口的原因：
  - 它依赖 `tests/inputs/` 下的外部测试数据文件
  - 当前设备侧只推送二进制与运行时库时会缺少这些输入资源
  - 实际执行结果也验证了这一点：程序可启动，但多个用例因 “Failed to read expected output / Failed to read test6 data” 失败
  - 因此它不是本轮最适合直接设备侧验证的独立入口

## 5. 关键命令

### 5.1 lycium 构建

```bash
LIB_NAME=cJSON PKGNAME=cJSON RECIPE_SCOPE=thirdparty bash scripts/run-lycium-build.sh
```

### 5.2 产物回收

```bash
mkdir -p outputs/cJSON/lib outputs/cJSON/bin
cp -a tpc_c_cplusplus/lycium/usr/cJSON/arm64-v8a/lib/libcjson.so* outputs/cJSON/lib/
cp -a tpc_c_cplusplus/thirdparty/cJSON/cJSON-1.7.19/arm64-v8a-build/cJSON_test outputs/cJSON/bin/
cp -a tpc_c_cplusplus/thirdparty/cJSON/cJSON-1.7.19/arm64-v8a-build/tests/parse_examples outputs/cJSON/bin/
cp -a tpc_c_cplusplus/thirdparty/cJSON/cJSON-1.7.19/arm64-v8a-build/tests/readme_examples outputs/cJSON/bin/
```

### 5.3 设备测试

设备测试通道：`hdc fallback`

```bash
hdc shell rm -rf /data/local/tmp/cJSON
hdc shell mkdir -p /data/local/tmp/cJSON
hdc file send outputs/cJSON/lib/libcjson.so.1.7.19 /data/local/tmp/cJSON/
hdc file send outputs/cJSON/bin/cJSON_test /data/local/tmp/cJSON/
hdc file send outputs/cJSON/bin/parse_examples /data/local/tmp/cJSON/
hdc file send outputs/cJSON/bin/readme_examples /data/local/tmp/cJSON/
hdc shell "cd /data/local/tmp/cJSON && \
  ln -sf libcjson.so.1.7.19 libcjson.so.1 && \
  ln -sf libcjson.so.1 libcjson.so && \
  chmod 755 cJSON_test parse_examples readme_examples && \
  export LD_LIBRARY_PATH=/data/local/tmp/cJSON:\$LD_LIBRARY_PATH && \
  ./cJSON_test"
hdc shell "cd /data/local/tmp/cJSON && \
  export LD_LIBRARY_PATH=/data/local/tmp/cJSON:\$LD_LIBRARY_PATH && \
  chmod 755 readme_examples && \
  ./readme_examples"
```

## 6. 设备侧执行结果

- 通道：`hdc fallback`
- `cJSON_test` 真实功能路径：
  - 创建 JSON 对象
  - 打印 JSON
  - 预分配缓冲打印
  - 解析/处理示例数据
- `cJSON_test` 关键输出包含：
  - `Version: 1.7.19`
  - 多段实际 JSON 文本输出
  - 最后输出对象 `{"number": null}`
- `readme_examples` 真实功能路径：
  - 创建 monitor JSON
  - 辅助 API 构造对象
  - 校验 full-hd 判断逻辑
- `readme_examples` 关键输出：
  - `3 Tests 0 Failures 0 Ignored`
  - `OK`
- `parse_examples` 执行结果：
  - 程序可启动，但因缺少外部测试数据文件而失败
  - 该结果已用于说明为什么它不适合作为本轮主设备侧入口

## 7. 备注

- 当前会话未发现可直接调用的 `harmonyos-dev-mcp` 工具入口，因此设备测试按仓库规则记录为 `hdc fallback`。
- 本轮未进入 fallback native build，也未生成 `libs/cJSON/build.sh`。
- 本轮未发现新的 `.rej` 文件；最终成功结论以 lycium recipe 路径为准。
