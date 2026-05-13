# Expat 构建报告

## 1. 构建结论

- `build-pass`: pass
- `binary-pass`: pass
- `device-pass`: pass

## 2. 构建路径

- 构建主路径：`lycium`
- 使用 recipe：`tpc_c_cplusplus/thirdparty/libexpat/HPKBUILD`
- 目标架构：`arm64-v8a`
- 构建系统：`cmake`
- 说明：现成 `libexpat` recipe 已先升级到 `R_2_7_5`，完成 `SHA512SUM`、下载包名、`builddir` 和构建开关预修正后，直接通过 `lycium` 构建成功，未进入 fallback。

## 3. lycium 预检查与预修正

- 预检查发现：
  - 现成 recipe 版本为 `R_2_5_0`
  - `source` 指向旧镜像 zip 包
  - `packagename` 为 `libexpat-R_2_5_0.zip`
  - `SHA512SUM` 与目标版本不匹配
- 预修正内容：
  - `pkgver` 升级到 `R_2_7_5`
  - `source` 切换为上游 `tar.gz`
  - `packagename` 对齐为 `R_2_7_5.tar.gz`
  - `SHA512SUM` 更新为目标源码包校验值
  - 显式保留 `EXPAT_SHARED_LIBS=ON`
  - 显式保留 `EXPAT_BUILD_TOOLS=ON`
  - 显式保留 `EXPAT_BUILD_EXAMPLES=ON`
  - 显式保留 `EXPAT_BUILD_TESTS=ON`
  - 关闭 `EXPAT_BUILD_DOCS`

## 4. 失败分类与决策

- 未触发失败分类。
- 依据文档，本轮没有因为 recipe 版本不一致直接 fallback，而是先完成 recipe 升级与预修正，再执行 `lycium`。

## 5. fallback 执行记录

- 未进入 fallback。

## 6. 编译驱动型代码与脚本修改

- 修改 `tpc_c_cplusplus/thirdparty/libexpat/HPKBUILD`
- 修改 `tpc_c_cplusplus/thirdparty/libexpat/SHA512SUM`
- 未修改 `libs/Expat/` 业务源码

## 7. 产物概况

- 共享库：
  - `outputs/Expat/lib/libexpat.so.1.11.3`
  - `outputs/Expat/lib/libexpat.so.1`
  - `outputs/Expat/lib/libexpat.so`
- 测试 binary：
  - `outputs/Expat/bin/elements`
  - `outputs/Expat/bin/outline`
  - `outputs/Expat/bin/element_declarations`
  - `outputs/Expat/bin/xmlwf`
- 测试输入：
  - `outputs/Expat/bin/sample.xml`

## 8. binary 来源

- binary 来源类型：`test program`
- 优先用于设备测试的 binary：`elements`
- binary 回收来源：
  - `xmlwf` 来自 install 产物：`tpc_c_cplusplus/lycium/usr/libexpat/arm64-v8a/bin/xmlwf`
  - `elements`、`outline`、`element_declarations` 来自 build 目录：
    - `tpc_c_cplusplus/thirdparty/libexpat/libexpat-R_2_7_5/arm64-v8a-build/examples/`
- 说明：虽然 install 产物中已有 `xmlwf`，但依据 Phase 3/4 报告，`elements` 更适合做设备侧最小真实功能验证，因此优先选用 `elements`。

## 9. 关键命令

### 9.1 lycium 构建

```bash
LIB_NAME=Expat PKGNAME=libexpat RECIPE_SCOPE=thirdparty ARCH=arm64-v8a bash scripts/run-lycium-build.sh
```

### 9.2 产物回收

```bash
mkdir -p outputs/Expat/lib outputs/Expat/bin
cp -f tpc_c_cplusplus/lycium/usr/libexpat/arm64-v8a/lib/libexpat.so.1.11.3 outputs/Expat/lib/
cp -f tpc_c_cplusplus/lycium/usr/libexpat/arm64-v8a/bin/xmlwf outputs/Expat/bin/
cp -f tpc_c_cplusplus/thirdparty/libexpat/libexpat-R_2_7_5/arm64-v8a-build/examples/elements outputs/Expat/bin/
cp -f tpc_c_cplusplus/thirdparty/libexpat/libexpat-R_2_7_5/arm64-v8a-build/examples/outline outputs/Expat/bin/
cp -f tpc_c_cplusplus/thirdparty/libexpat/libexpat-R_2_7_5/arm64-v8a-build/examples/element_declarations outputs/Expat/bin/
cp -f outputs/Expat/lib/libexpat.so.1.11.3 outputs/Expat/lib/libexpat.so.1
cp -f outputs/Expat/lib/libexpat.so.1.11.3 outputs/Expat/lib/libexpat.so
printf '<root><a>1</a></root>\n' > outputs/Expat/bin/sample.xml
```

### 9.3 设备测试

设备测试通道：`hdc fallback`

```bash
hdc shell mkdir -p /data/local/tmp/Expat
hdc file send outputs/Expat/lib/libexpat.so.1 /data/local/tmp/Expat/libexpat.so.1
hdc file send outputs/Expat/bin/elements /data/local/tmp/Expat/elements
hdc file send outputs/Expat/bin/sample.xml /data/local/tmp/Expat/sample.xml
hdc shell chmod 755 /data/local/tmp/Expat/elements
hdc shell "export LD_LIBRARY_PATH=/data/local/tmp/Expat; /data/local/tmp/Expat/elements < /data/local/tmp/Expat/sample.xml"
```

## 10. 设备侧执行结果

- 设备测试主通道：`harmonyos-dev-mcp` 未在当前执行环境中发现可直接调用入口
- 实际使用：`hdc fallback`
- 返回结果：命令成功执行
- 关键输出：

```text
root
	a
```

## 11. 产物校验结果

- `outputs/Expat/lib/libexpat.so.1.11.3` 已确认是 `ELF 64-bit LSB shared object, ARM aarch64`
- `outputs/Expat/bin/elements` 已确认是 `ELF 64-bit LSB pie executable, ARM aarch64`
- `outputs/Expat/bin/xmlwf` 已确认是 `ELF 64-bit LSB pie executable, ARM aarch64`
- 当前未发现新的 `.rej` 文件
- 本轮未进入 fallback，关键日志中未见未处理失败信号

## 12. 最终产物路径

- 共享库目录：`outputs/Expat/lib/`
- 测试 binary 目录：`outputs/Expat/bin/`
