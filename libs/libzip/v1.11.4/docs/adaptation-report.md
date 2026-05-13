# libzip 业务适配报告

## 1. 输入方案

- 输入方案文件：`reports/libzip/adaptation-plan.md`
- Phase 3 结论是：当前未发现必须新增 HarmonyOS 专有业务接口替换或新增 HarmonyOS 专有平台宏分支的证据。
- 本轮优先目标是保持上游源码不变，先把 Phase 5 的 recipe 预检查、预修正、lycium 构建与测试入口打通。

## 2. 已实施修改

- 本轮未对 `libs/libzip/` 上游源码做业务适配修改。
- 未新增 HarmonyOS 条件分支。
- 未修改主库实现、公开头文件或上游 CLI 源码。

## 3. 与方案的差异

- 无。
- 当前执行与 `adaptation-plan.md` 一致：业务代码层面先不改，若编译阶段暴露源码级兼容问题，再按最小修改原则处理。

## 4. 遗留业务适配问题

- 当前没有已确认、必须在 Phase 4 先处理的业务适配问题。
- 已知风险主要仍在构建配置和 recipe 漂移，而不是业务逻辑：
  - recipe 从 `1.9.2` 升级到 `1.11.4`
  - patch 适配性
  - 依赖探测与 feature 开关
  - CLI 回收和设备侧运行时依赖

## 5. 测试入口与使用建议

- 优先测试入口：上游 CLI `ziptool`
- 选择依据：
  - 它是上游自带、可独立运行的程序
  - 能覆盖真实的 zip 创建、写入和读取路径
  - 相比 `regress/` 回归套件，更适合设备侧直接验证
- 候选补充入口：
  - `zipcmp`
  - `zipmerge`
- 不优先直接使用的入口：
  - `regress/`
  - 原因是该目录依赖 `nihtest`、脚本和大量测试数据，不是设备侧最直接的独立入口
- 推荐设备侧真实功能验证命令思路：
  - 用 `ziptool` 创建或更新一个 zip 文件
  - 用 `ziptool` 读取其中指定条目
  - 对原始文件内容与读出内容做比对
- 不允许只用 `--help` 或版本输出作为最终测试。

## 6. 交接给 Phase 5 的说明

- 构建系统识别：`cmake`
- 已发现现成 recipe：
  - `tpc_c_cplusplus/thirdparty/libzip/HPKBUILD`
- 依据 `docs/README.md` 和 `docs/10-build-system-detect.md`，Phase 5 必须先走：
  - recipe 预检查
  - recipe 预修正
  - lycium 实际构建
  - 失败分类
  - 只有证明 lycium 不可行后才允许 fallback
- Phase 5 的重点不是直接编译，而是先把旧 recipe 升级到目标版本 `v1.11.4`，并确认旧 patch 是否仍适用。
- 设备侧优先复用的上游入口已经明确：`ziptool` CLI 真实功能验证。
