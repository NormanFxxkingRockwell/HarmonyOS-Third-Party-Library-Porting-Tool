# cJSON HAP 高可信设备验证报告

## 1. 结论

- `hap-device-pass`: pass
- 模板来源：`templates/soTest-template.zip`
- 临时工程路径：`tmp/hap-test/cJSON/soTest`
- 清理结果：已执行 `bash scripts/collect-hap-test-artifacts.sh --lib-name cJSON ...`，临时工程已清理

本轮按 [docs/12-hap-device-test.md](/home/aoqiduan/projects/harmonyOS-mcp/harmonyOS-tool/ho-thirdparty-porting/docs/12-hap-device-test.md) 的标准路径完成了：

```text
准备临时 HAP 工程
-> 拷贝目标 .so 到 entry/libs/arm64-v8a/
-> 修改 NAPI bridge
-> ArkTS 页面展示 native 调用结果
-> 构建 unsigned / signed HAP
-> 通过 signTools 做外部签名
-> 安装到设备
-> 启动 Ability
-> 收集日志
-> 归档 patch 与 artifacts
```

## 2. 输入与接入产物

- 接入 `.so` 路径：
  - `outputs/cJSON/lib/libcjson.so.1.7.19`
  - `outputs/cJSON/lib/libcjson.so.1`
  - `outputs/cJSON/lib/libcjson.so`
- 归档后的 unsigned HAP：
  - `reports/cJSON/hap-device/artifacts/entry-default-unsigned.hap`
- 归档后的 signed HAP：
  - `reports/cJSON/hap-device/artifacts/signApp.hap`
- 归档后的签名 profile：
  - `reports/cJSON/hap-device/artifacts/ohos_provision_debug.p7b`
- patch 路径：
  - `reports/cJSON/hap-device/hap-test.patch`

## 3. 修改的 HAP 工程文件

- `entry/src/main/cpp/CMakeLists.txt`
- `entry/src/main/cpp/napi_init.cpp`
- `entry/src/main/cpp/types/libentry/Index.d.ts`
- `entry/src/main/ets/pages/Index.ets`
- `entry/libs/arm64-v8a/libcjson.so`
- `entry/libs/arm64-v8a/libcjson.so.1`
- `entry/libs/arm64-v8a/libcjson.so.1.7.19`

## 4. NAPI 调用链说明

- ArkTS 页面 `Index.ets` 在 `aboutToAppear()` 中调用 `runCjsonSmoke()`，并支持按钮重复触发。
- `runCjsonSmoke()` 通过 `libentry.so` 暴露的 NAPI 方法进入 native。
- native 侧真实调用了 cJSON API：
  - `cJSON_Parse`
  - `cJSON_GetObjectItemCaseSensitive`
  - `cJSON_GetStringValue`
  - `cJSON_PrintUnformatted`
  - `cJSON_Version`
- 返回值不是模板默认 `add(2, 3)`，而是实际三方库执行结果：
  - `pass=true;version=1.7.19;library=cJSON;rendered={"library":"cJSON","status":"ok","items":[1,2,3]}`

## 5. ArkTS UI 展示说明

- 页面默认文案为 `Preparing cJSON smoke test...`
- 启动后自动执行一次 smoke test，并将返回字符串直接展示在页面
- 同时通过 `hilog` 打印 tag `cJSONTest`
- 这满足“UI 或日志中出现可审计结果，且结果来自目标三方库调用”的要求

## 6. 环境与前置检查

- Phase 1 复核结果：
  - `BASE_ENV_READY=true`
  - `LYCIUM_ENV_READY=true`
  - `DEVICE_CONNECTED=true`
  - `HAP_ENV_READY=true`
  - `HAP_SIGNING_MODE=external-signTools`
  - `HAP_OHPM_READY=true`
  - `HAP_HVIGOR_READY=true`
  - `HAP_JAVA_READY=true`
  - `HAP_SIGNTOOLS_READY=true`
- 当前会话没有可用的 `harmonyos-dev-mcp` 调用入口，因此安装与启动按文档记录为 `hdc fallback`
- 设备序列号：`3QC0124A24000185`

## 7. 构建命令与结果

### 7.1 准备临时工程

```bash
bash scripts/prepare-hap-test-project.sh --lib-name cJSON
```

结果：
- 成功从模板解压临时工程
- 成功将 `libcjson.so*` 拷贝到 `entry/libs/arm64-v8a/`

### 7.2 HAP 构建

```bash
cd tmp/hap-test/cJSON/soTest
<command-line-tools>/bin/ohpm install
<command-line-tools>/bin/hvigorw assembleHap --mode module -p product=default -p module=entry
```

结果：
- `ohpm install` 成功
- `hvigorw assembleHap` 成功
- 成功生成 unsigned HAP
- 构建日志已归档：
  - `reports/cJSON/hap-device/artifacts/build.log`
  - `reports/cJSON/hap-device/artifacts/build-retry.log`

## 8. 签名模式与签名结果

- 签名模式：`external-signTools`
- 使用目录：`signTools/hapsigner.zip` 解压到临时 `sign-run/hapsigner/`
- 实际签名命令：

```bash
java -jar hap-sign-tool.jar sign-profile ...
java -jar hap-sign-tool.jar sign-app ...
```

结果：
- 成功生成 `ohos_provision_debug.p7b`
- 成功生成 `signApp.hap`
- 重签日志已归档：
  - `reports/cJSON/hap-device/artifacts/sign-app-rerun.log`

## 9. 安装命令、启动命令与结果

安装命令：

```bash
hdc install -r <signApp.hap>
```

启动命令：

```bash
hdc shell aa start -a EntryAbility -b com.example.sotest
```

结果：
- 安装成功
- Ability 启动成功
- 关键日志已归档：
  - `reports/cJSON/hap-device/artifacts/install-rerun.log`
  - `reports/cJSON/hap-device/artifacts/start-rerun.log`

## 10. 关键日志输出

二进制设备测试复核日志：
- `reports/cJSON/hap-device/artifacts/hdc-device-test-fixed.log`
- 其中 `cJSON_test` 输出包含 `Version: 1.7.19`
- 其中 `readme_examples` 输出包含 `3 Tests 0 Failures 0 Ignored` 与 `OK`

HAP 实机日志：
- `reports/cJSON/hap-device/artifacts/hilog-rerun.log`
- 关键通过证据：

```text
cJSON smoke result: pass=true;version=1.7.19;library=cJSON;rendered={"library":"cJSON","status":"ok","items":[1,2,3]}
```

## 11. 本轮暴露出的流程问题

### 11.1 Windows `hdc.exe` + WSL 相对路径不适合作为当前默认发送方式

- 按现有 `hdc file send outputs/... /data/local/tmp/cJSON/` 形式重跑 binary 设备测试时，Windows `hdc.exe` 会把相对路径层级一起带到设备端
- 实际结果变成 `/data/local/tmp/cJSON/outputs/cJSON/...`
- 后续 `chmod cJSON_test`、直接执行 binary 会失败
- 本轮改为：

```bash
hdc file send <Windows/UNC 绝对路径> /data/local/tmp/cJSON/<目标文件名>
```

- 改完后二进制设备测试恢复正常

### 11.2 仅拷贝 `libcjson.so` 不足以覆盖 SONAME 运行时依赖

- 首次 HAP 安装与启动虽然成功，但日志显示：
  - `load libcjson.so.1 failed`
- 原因是 `libentry.so` 的 `NEEDED` 依赖是 `libcjson.so.1`
- 仅放入 `libcjson.so` 时，HAP 包内缺少 `libcjson.so.1`
- 本轮补充拷贝：
  - `libcjson.so`
  - `libcjson.so.1`
  - `libcjson.so.1.7.19`
- 重建后 HAP 包内包含这三个文件，应用侧运行通过

这说明当前 workflow 已可行，但文档/脚本仍应补充“版本化 SONAME `.so` 需要一并带入 HAP”的规则。

## 12. 清理与归档结果

- 已执行：

```bash
bash scripts/collect-hap-test-artifacts.sh \
  --lib-name cJSON \
  --extra-artifact tmp/hap-test/cJSON/sign-run \
  --extra-artifact tmp/workflow-smoke/cjson-hap \
  --extra-artifact tmp/workflow-smoke/cjson-device
```

- 收集结果：
  - `reports/cJSON/hap-device/hap-test.patch`
  - `reports/cJSON/hap-device/artifacts/`
  - `reports/cJSON/hap-device/project-files.txt`
- `WORKDIR_CLEANED=true`

## 13. 最终判定

- `build-pass`: 已存在并复核通过
- `binary-pass`: 已存在并复核通过
- `device-pass`: 已复核通过
- `hap-device-pass`: pass

当前 `cJSON` 已证明：
- 现有 Phase 1 环境检查链路可支撑 HAP 验证
- `prepare-hap-test-project.sh -> HAP 改造 -> hvigorw -> external signTools -> hdc install/start -> artifact collect` 这条 workflow 可以打通
- 需要后续补的不是“这条路能不能走”，而是把上面两处流程缺口固化进文档和脚本
