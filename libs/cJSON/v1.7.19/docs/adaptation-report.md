# cJSON 业务适配报告

## 1. 输入方案

- 输入方案见 `reports/cJSON/adaptation-plan.md`。
- Phase 3 结论是：`cJSON` 主库为通用 ANSI C 实现，当前未识别出必须替换为 HarmonyOS 专有业务接口的代码路径。

## 2. 已实施修改

- 本阶段未对 `libs/cJSON/` 下业务源码做修改。
- 未新增 HarmonyOS 条件分支。
- 未修改 `cJSON.c`、`cJSON.h`、`cJSON_Utils.c`、`cJSON_Utils.h` 等主库文件。

## 3. 与方案的差异

- 无差异。
- Phase 4 按方案执行了“最小修改”原则；由于未发现必要业务适配点，因此保持上游源码不变。

## 4. 遗留业务适配问题

- 当前未发现阻塞 HarmonyOS 业务适配的源码级问题。
- 后续风险主要位于 Phase 5 的构建接入与测试产物组织，而不是业务代码本身。
- 若后续在交叉编译或设备侧运行中暴露 locale 相关兼容问题，应优先在构建配置层处理 `ENABLE_LOCALES`，而不是直接改动主库逻辑。

## 5. 测试入口与使用建议

- 优先测试入口：
  - `libs/cJSON/test.c`
  - `libs/cJSON/tests/parse_examples.c`
  - `libs/cJSON/tests/readme_examples.c`
  - `libs/cJSON/tests/misc_tests.c`
- 推荐优先生成并复用上游自带、可独立运行的测试程序，而不是自行编造最小驱动。
- 推荐设备侧真实功能验证路径：
  - 运行 `test.c` 对应可执行文件，验证 JSON 创建、打印、预分配打印和解析。
  - 若启用 `ENABLE_CJSON_TEST`，运行 `parse_examples` 或 `readme_examples`，验证解析/打印回归路径。
- 当前库存在可独立运行的上游测试入口，因此不能记录为“无测试用例”。

## 6. 交接给 Phase 5 的说明

- 构建系统类型：`cmake`
- 现成 recipe：存在
  - `tpc_c_cplusplus/thirdparty/cJSON/HPKBUILD`
  - `tpc_c_cplusplus/community/cJSON/HPKBUILD`
- Phase 5 必须按仓库规则坚持 lycium-first：
  - 先做 recipe 预检查
  - 再做必要预修正
  - 再执行 lycium
- 当前不支持仅因为测试目标较多、默认选项未裁剪或 locale 配置未确认，就直接进入 fallback。
- Phase 5 需重点确认：
  - 是否保留默认主库共享库产物 `libcjson.so`
  - 是否启用并导出至少一个上游自带、可独立运行的测试程序用于设备侧验证
  - 现成 recipe 的 `check()` 仅占位，需补足实际设备测试路线
