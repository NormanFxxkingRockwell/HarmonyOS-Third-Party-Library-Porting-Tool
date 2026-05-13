# Expat 业务适配报告

## 1. 输入方案

- 输入方案文件：`reports/Expat/adaptation-plan.md`
- 目标版本：`Expat 2.7.5`
- 当前阶段依据 `docs/08-adaptation-implement.md` 执行，遵循“优先做最小修改”的规则。

## 2. 已实施修改

- 本阶段未对 `libs/Expat/` 业务源码做修改。
- 结论是当前主库无需 HarmonyOS 业务适配补丁，直接把工作重心交给 Phase 5 的 recipe 预修正、构建和测试入口回收。

## 3. 与方案的差异

- 无。

## 4. 遗留业务适配问题

- 当前未发现主库层面的遗留业务适配问题。
- 若后续编译失败，优先检查：
  - `libexpat` recipe 是否已升级到 `R_2_7_5`
  - CMake 选项是否保留 shared lib、examples 和 `xmlwf`
  - 测试 binary 的构建/安装/回收路径是否完整

## 5. 测试入口与使用建议

- 优先测试入口路径：
  - `libs/Expat/expat/examples/elements.c`
  - `libs/Expat/expat/examples/outline.c`
  - `libs/Expat/expat/examples/element_declarations.c`
- 候选 CLI 能力校验入口：
  - `libs/Expat/expat/xmlwf/xmlwf.c`
- 不作为首选设备侧入口的上游测试：
  - `libs/Expat/expat/tests/runtests.c`
  - `libs/Expat/expat/tests/runtests_cxx.cpp`
  - `libs/Expat/expat/tests/xmltest.sh`
- 原因：
  - `runtests*` 依赖完整测试支撑构建
  - `xmltest.sh` 依赖额外 XML 测试数据集
  - `examples/elements.c` 更适合最小真实功能验证
- 推荐能力校验命令：
  - `echo '<root><a>1</a></root>' | ./elements`
  - `./xmlwf sample.xml`

## 6. 交接给 Phase 5 的说明

- 主库业务源码当前无须改动。
- 构建主线应优先使用 `lycium`，起点为 `tpc_c_cplusplus/thirdparty/libexpat/HPKBUILD`。
- 进入 `lycium` 前必须先完成：
  - recipe 版本升级
  - `SHA512SUM` 更新
  - `packagename`、下载包名、`builddir` 对齐
  - tests/examples/tools 开关确认
- 若 examples 能够成功构建并可独立运行，优先回收 `elements` 作为设备侧测试 binary；若 examples 不适用，再用 `xmlwf` 做 CLI 真实能力校验。
