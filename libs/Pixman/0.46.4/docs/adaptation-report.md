# Pixman 业务适配报告

## 1. 输入方案

- 输入方案文件：`reports/Pixman/adaptation-plan.md`
- 执行依据：`docs/08-adaptation-implement.md` 与 `docs/09-adaptation-report.md`
- 本库审批属性：`是否需要用户审批方案=否`，因此 Phase 3 结束后直接进入 Phase 4
- 方案结论：优先保持上游源码不改动，只有在已证实的 HarmonyOS 编译或运行兼容问题出现时，才补最小源码修正

## 2. 已实施修改

- 本阶段未对 `libs/Pixman/` 源码做业务适配修改。
- 决策依据是方案中“先不预改源码、优先保留上游 Unix-like 路径”和 [docs/08-adaptation-implement.md](/home/aoqiduan/projects/harmonyOS-mcp/harmonyOS-tool/ho-thirdparty-porting/docs/08-adaptation-implement.md) 的“优先做最小修改”原则。
- 基础自检结果：`libs/Pixman/` 工作树保持干净，没有新增 HarmonyOS 条件分支，也没有引入额外头文件或语法变更。

## 3. 与方案的差异

- 无差异。
- Phase 3 方案要求本阶段先保持源码不动，当前实施结果与方案一致。

## 4. 遗留业务适配问题

- 尚未发现必须在 Phase 4 先行处理的 HarmonyOS 业务代码改动点。
- 若 Phase 5 实际构建证明 `a64-neon`、`pthread`、`mmap/mprotect`、`libpng` 或平台探测宏与 HarmonyOS 工具链不兼容，再按最小范围补充源码修正。
- 现成同库 recipe 与当前上游构建系统已漂移，这属于 Phase 5 的 recipe/构建驱动问题，不在本报告中作为业务源码修改处理。

## 5. 测试入口与使用建议

- 优先测试入口路径：上游 `test/` 目录构建出的独立二进制，首轮推荐 `pixel-test`、`region-test`、`matrix-test`、`scaling-test`、`thread-test`
- 入口选择依据：这些程序由上游 `test/meson.build` 直接注册为独立可执行文件，不依赖宿主测试框架包装脚本，也不需要外部样例数据
- 推荐命令：

```sh
/data/local/tmp/Pixman/pixel-test
/data/local/tmp/Pixman/region-test
/data/local/tmp/Pixman/matrix-test
/data/local/tmp/Pixman/scaling-test
/data/local/tmp/Pixman/thread-test
```

- 候选补充测试入口：`prng-test`、`tolerance-test`
- 推荐命令：

```sh
/data/local/tmp/Pixman/prng-test -bench
/data/local/tmp/Pixman/tolerance-test 1000
```

- 关键 API / 参数 / 样例输入：
  - `thread-test`：验证 `pthread` 路径；若线程不可用会输出跳过信息
  - `prng-test`：支持 `-bench`
  - `tolerance-test`：支持传入迭代次数，例如 `1000`
  - 首轮推荐入口无需额外样例输入文件
- `demos/` 中的程序依赖 GTK/GLib 和图像输入文件，不适合作为当前设备侧首轮验证入口
- “无测试用例”结论：否

## 6. 交接给 Phase 5 的说明

- 业务代码层面当前没有必须先改的内容，Phase 5 应直接接手现有源码，不要把“本阶段无源码改动”误判为缺少适配方案。
- 构建必须坚持 lycium-first。已存在同库 recipe：`tpc_c_cplusplus/thirdparty/pixman/HPKBUILD`。
- Phase 5 首先应按流程做 recipe 预检查与预修正，重点核对：
  - `pkgver`、`source`、`SHA512SUM`、`builddir`、`packagename`
  - 现有 recipe 的 `configure/autogen.sh` 路线与当前上游 `Meson` 主线不一致
  - 是否保留 `-Dtests=enabled` 以产出设备侧验证二进制
- Phase 5 不应重新猜测试入口，应直接复用本报告中的 `test/` 独立二进制优先级和推荐命令。
