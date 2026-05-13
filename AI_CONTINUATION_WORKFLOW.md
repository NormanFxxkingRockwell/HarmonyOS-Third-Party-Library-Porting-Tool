# AI 后续接手操作指导

本文用于指导后续 AI 继续维护本仓库的三方库鸿蒙化知识包。目标不是批量搬运文件，而是把 `../ho-thirdparty-porting` 中已经完成的鸿蒙化结果整理成可复用、可验证、可让其他使用者快速参考的知识包。

## 当前目标

本仓库存放每个库的鸿蒙化复用信息：

- 鸿蒙化过程中真实改了什么。
- 为什么这样改，哪些点套用到新版本时必须重新检查。
- 可直接使用的 `arm64-v8a` 产物。
- 可复用的 lycium recipe、校验和、patch 或 cross-file。
- 已完成验证的报告和真实验证入口。

后续工作可以按流水线推进，但不能变成机械复制。`scripts/migrate-library.sh` 只负责生成草稿包，`modifications.md` 必须由 AI 阅读报告和 recipe 后人工改写。

## 硬性规则

1. 一次只处理一个库。
2. 当前仓库只保留 `arm64-v8a`，不要迁移或声明 `armeabi-v7a`、`x86`、`x86_64`。
3. `artifacts/` 顶层只能有 `arm64-v8a/`，不要再生成 `artifacts/output/`。
4. 不要恢复或参考旧的机械迁移提交 `902ba6a`。
5. 不要把脚本生成的 `modifications.md` 模板直接提交。
6. 不要声称做了新的设备验证，除非本轮确实重新执行了设备验证；通常这里只归档 `../ho-thirdparty-porting/reports/<库>/build-report.md` 中已有的验证事实。
7. 每个库完成后独立校验、独立提交、独立推送。
8. `meta.yaml`、`modifications.md` 或报告中作为复用入口引用的本地文件，必须在知识包内真实存在。
9. fallback 知识包必须归档实际 fallback 构建脚本；如果验证命令依赖输入文件，也必须归档验证输入。
10. 从源仓库复制来的脚本如果移动了目录，必须重新检查相对路径语义，不能假设原脚本在新位置仍可执行。
11. 设备验证时推送过的非系统运行时 `.so`，必须归档到知识包或明确说明由系统/外部环境提供；不要只归档主库 `.so`。
12. `curl-config`、`.pc`、CMake config 等配置文件如果含构建机绝对路径，必须修成可迁移版本，或在 `meta.yaml` / `modifications.md` 明确标记不可直接跨机器复用。
13. 如果当前库构建依赖另一个 recipe 的修复，必须把依赖 recipe 修复记录归档到 `docs/dependencies/`，不能只在正文里一句话带过。

## 推荐工作流

### 1. 开始前检查仓库

```bash
git status --short --branch
git pull --ff-only
```

如果工作区不干净，先判断改动是否属于当前任务。不要覆盖用户或其他 AI 的未提交改动。

### 2. 选择下一个库

优先选择 recipe 映射清楚、改动面较小的库。不要一次迁移多个库。

已经按新规范整理过的代表性库：

- `zlib/1.3.2`
- `libzip/v1.11.4`
- `Pixman/0.46.4`
- `Expat/R_2_7_5`

选择新库前先确认数据源存在：

```bash
LIB_NAME=Expat
test -d ../ho-thirdparty-porting/outputs/$LIB_NAME
test -d ../ho-thirdparty-porting/reports/$LIB_NAME
```

### 3. 用脚本生成草稿包

```bash
LIB_NAME=Expat scripts/migrate-library.sh ../ho-thirdparty-porting .
```

脚本会生成：

- `libs/<库>/<版本>/meta.yaml`
- `libs/<库>/<版本>/modifications.md`
- `libs/<库>/<版本>/docs/`
- `libs/<库>/<版本>/recipe/`
- `libs/<库>/<版本>/artifacts/arm64-v8a/`

如果目标目录已存在，不要直接覆盖。先确认已有内容是否是当前新规范产物，必要时让用户决定是否重做。

### 4. 阅读事实来源

至少阅读这些文件：

```bash
sed -n '1,260p' libs/<库>/<版本>/docs/build-report.md
sed -n '1,220p' libs/<库>/<版本>/docs/adaptation-report.md
sed -n '1,220p' libs/<库>/<版本>/docs/adaptation-plan.md
sed -n '1,220p' libs/<库>/<版本>/recipe/HPKBUILD
```

同时检查产物：

```bash
find libs/<库>/<版本>/artifacts/arm64-v8a -maxdepth 6 -type f -o -type l | sort
file libs/<库>/<版本>/artifacts/arm64-v8a/lib/*.so* 2>/dev/null || true
readelf -d libs/<库>/<版本>/artifacts/arm64-v8a/bin/* 2>/dev/null | rg 'NEEDED|RUNPATH|RPATH' || true
readelf -d libs/<库>/<版本>/artifacts/arm64-v8a/lib/*.so* 2>/dev/null | rg 'NEEDED|RUNPATH|RPATH' || true
```

需要从这些事实中提炼：

- 是否修改了上游业务源码。
- 是否有 patch、cross-file、HPKCHECK。
- recipe 原本哪里不匹配，修了哪些字段。
- 构建系统是什么，关键构建开关是什么。
- 产物来自 lycium install、outputs，还是 build 目录回收。
- 二进制和 `.so` 的 `NEEDED` 运行时依赖有哪些，哪些需要随包归档。
- `curl-config`、`.pc`、CMake config、shell 脚本等文本产物是否含构建机绝对路径。
- 当前库是否依赖其他 recipe 的修复，例如依赖库 recipe 参数调整。
- 设备侧验证入口是什么，是否覆盖真实功能路径。
- 套用到新版本时必须重新检查哪些点。

### 5. 改写 `meta.yaml`

`meta.yaml` 要写成结构化事实，不要只保留脚本默认字段。常见字段示例：

```yaml
name: Expat
version: R_2_7_5

source:
  upstream: https://github.com/libexpat/libexpat
  archive: https://github.com/libexpat/libexpat/archive/refs/tags/R_2_7_5.tar.gz
  porting_repo: ../ho-thirdparty-porting
  output_bundle: outputs/Expat

recipe:
  method: lycium
  scope: thirdparty
  source_path: tpc_c_cplusplus/thirdparty/libexpat
  build_system: cmake
  package_name: R_2_7_5.tar.gz
  builddir: libexpat-R_2_7_5

archs:
  - arm64-v8a

artifacts:
  verified_bundle: artifacts/arm64-v8a
  per_arch_install:
    arm64-v8a: artifacts/arm64-v8a
  bundled_runtime:
    dir: lib/runtime-deps/
    files:
      - libssl.so.3
      - libcrypto.so.3
  notes:
    config_files_have_host_paths: "bin/foo-config and lib/pkgconfig/foo.pc contain build-machine absolute paths"

validation:
  build_pass: pass
  binary_pass: pass
  device_pass: pass
  device_channel: hdc fallback
  device_entry: elements
```

如果有运行时依赖、CLI、测试 binary、headers、cmake/pkgconfig 文件，应在 `artifacts` 或 `dependencies` 中明确写出。

如果 `readelf -d` 显示依赖了非系统库，例如 `libssl.so.3`、`libcrypto.so.3`、`libzstd.so.1`、`libnghttp2.so.14`，必须二选一：

- 归档到 `artifacts/arm64-v8a/lib/runtime-deps/`，并在 `meta.yaml` 写入 `artifacts.bundled_runtime` 和 `dependencies.runtime`。
- 明确写入 `modifications.md`：这些库不随包提供，需要使用者从哪个库知识包或设备环境获取。

### 6. 改写 `modifications.md`

必须写成该库的真实鸿蒙化记录，推荐结构：

```markdown
# <库> <版本> 鸿蒙化改动记录

## 状态

## 事实来源

## 关键结论

## recipe 改动

## 源码改动

## 产物

## 验证

## 套用到新版本时的检查点
```

写作要求：

- 明确说清楚是否有上游源码改动；没有就写“无”，不要含糊。
- recipe 改动要具体到 `pkgver`、`source`、`packagename`、`builddir`、`SHA512SUM`、关键 build flags。
- 验证不能只写“通过”，要写真实入口和关键输出。
- 如果 build-report 里记录了失败分类，要写清楚失败怎么处理，是否进入 fallback。
- 如果设备验证依赖额外 `.so`，要写清楚运行时依赖闭包、归档位置和部署方式。
- 如果 install 产物里的 `curl-config`、`.pc`、CMake config 等含构建机绝对路径，要单独写“配置文件绝对路径警告”。
- 如果修过依赖库 recipe，要写清楚依赖库名、修复点、归档文档路径和新版本复用检查点。
- 不要照抄大段报告，提炼为后续复用要点。

### 6.1 fallback 知识包额外要求

如果 `meta.yaml` 中 `recipe.method` 是 `fallback`，必须额外完成以下检查。

必须归档：

- 实际执行过的 fallback 构建脚本，优先放在 `recipe/build.sh`。
- 如果脚本只是原始脚本备份而不能在知识包位置直接执行，应命名为 `recipe/original-build.sh`，并在 `modifications.md` 中说明需要放回哪个源码目录执行。
- 设备验证命令用到的输入文件，例如 `.xml`、`.bz2`、测试数据集片段，优先放在 `docs/validation/`。
- 如果 fallback 仍参考失败的 lycium recipe，可以保留 `recipe/HPKBUILD` / `recipe/SHA512SUM` 作为失败事实来源，但 `meta.yaml` 必须明确真正复用入口是 fallback 脚本。

`meta.yaml` 至少补充：

```yaml
recipe:
  method: fallback
  build_system: makefile
  fallback_script: recipe/build.sh
  fallback_script_usage: "SOURCE_DIR=<src> OUTPUT_ROOT=<out> bash recipe/build.sh"

validation:
  validation_inputs:
    - docs/validation/sample1.bz2
```

`modifications.md` 必须写清：

- 为什么没有继续修 lycium，或者为什么本轮实际进入 fallback。
- fallback 脚本依赖哪些源码目录、SDK 环境变量和输出目录。
- fallback 脚本是否已经改造成可复用脚本；如果没有，必须说清楚原始执行位置。
- 验证输入文件归档在哪里，如何配合设备侧命令复验。

### 6.2 本地引用闭环检查

提交前必须检查所有本地引用是否闭环。重点看这些字段和文本：

- `fallback_script`
- `build_script`
- `patches`
- `cross_files`
- `validation_inputs`
- `docs/validation/...`
- `recipe/*.sh`

可用命令：

```bash
pkg=libs/<库>/<版本>
rg -n "fallback_script|build_script|validation_inputs|docs/validation|recipe/.*\\.sh|patches:|cross_files:" "$pkg"
find "$pkg" -maxdepth 4 -type f | sort
```

如果 `meta.yaml` 写了 `fallback_script: recipe/build.sh`，必须能通过：

```bash
test -f "$pkg/recipe/build.sh"
bash -n "$pkg/recipe/build.sh"
```

如果验证命令提到 `sample1.bz2`、`sample.xml` 等输入文件，必须能在包内找到对应文件：

```bash
find "$pkg/docs/validation" "$pkg/artifacts/arm64-v8a" -type f 2>/dev/null | sort
```

### 6.3 运行时依赖闭包检查

对包含 CLI 或共享库的知识包，必须检查 `readelf` 动态依赖闭包。不要只看设备报告里的命令，也不要只看 `meta.yaml` 中的 build 依赖。

```bash
pkg=libs/<库>/<版本>
readelf -d "$pkg"/artifacts/arm64-v8a/bin/* 2>/dev/null | rg 'NEEDED|RUNPATH|RPATH' || true
readelf -d "$pkg"/artifacts/arm64-v8a/lib/*.so* 2>/dev/null | rg 'NEEDED|RUNPATH|RPATH' || true
```

处理规则：

- `libc.so`、系统动态加载器等系统库通常不归档，但要确认它们确实属于设备系统环境。
- 主库自身的 symlink，例如 `libcurl.so.4`，应在本库 `artifacts/arm64-v8a/lib/` 内存在。
- 第三方依赖库，例如 OpenSSL、zstd、nghttp2、zlib、libpng、lzma，应归档到 `artifacts/arm64-v8a/lib/runtime-deps/`，或明确说明由哪个知识包/外部环境提供。
- 如果设备验证报告中有 `hdc file send libxxx.so*`，这些 `libxxx` 基本都应进入 `runtime-deps/` 或在文档里说明不归档原因。

归档后复查：

```bash
needed=$(readelf -d "$pkg"/artifacts/arm64-v8a/bin/* "$pkg"/artifacts/arm64-v8a/lib/*.so* 2>/dev/null \
  | sed -n 's/.*Shared library: \[\(.*\)\]/\1/p' | sort -u)
for lib in $needed; do
  case "$lib" in libc.so|ld-musl-*.so*) continue ;; esac
  find "$pkg/artifacts/arm64-v8a/lib" "$pkg/artifacts/arm64-v8a/lib/runtime-deps" \
    -maxdepth 1 \( -type f -o -type l \) -name "$lib" | grep -q . \
    && echo "OK $lib" || echo "MISSING $lib"
done
```

### 6.4 配置文件可迁移性检查

很多 install 产物会带 `*-config`、`.pc`、CMake config。这些文件经常含构建机绝对路径，弱模型很容易漏掉。

必须检查：

```bash
pkg=libs/<库>/<版本>
rg -n "/home/|/mnt/|/Users/|ho-thirdparty-porting|tpc_c_cplusplus|command-line-tools|OHOS_SDK|lycium/usr" \
  "$pkg/artifacts/arm64-v8a" "$pkg/recipe" "$pkg/meta.yaml" "$pkg/modifications.md" || true
```

处理规则：

- 如果能安全改成相对路径或 `${prefix}`，优先修成可迁移版本。
- 如果不确定怎么改，保留原始文件，但必须在 `meta.yaml` 的 `artifacts.notes` 和 `modifications.md` 中明确标记“含构建机绝对路径，不可直接跨机器复用”。
- 不要把含本机路径的配置文件描述成可直接复用。

### 6.5 依赖 recipe 修复归档

如果当前库构建成功依赖另一个库 recipe 的修复，例如 `nghttp2` 需要把 `ENABLE_EXAMPLES=ON` 改成 `OFF`，必须归档依赖修复说明。

推荐位置：

```text
libs/<库>/<版本>/docs/dependencies/<依赖名>-<修复点>.md
```

文档至少包含：

- 依赖库名和 recipe 路径。
- 失败现象。
- 最小 diff。
- 影响范围：只影响当前库，还是所有依赖该库的后续库。
- 套用到依赖库新版本时的检查点。

`meta.yaml` 中也要引用：

```yaml
docs:
  dependency_fixes:
    nghttp2: docs/dependencies/nghttp2-ENABLE_EXAMPLES-fix.md
```

### 7. 清理产物边界

确认只存在 `artifacts/arm64-v8a/`：

```bash
find libs/<库>/<版本>/artifacts -maxdepth 2 -type d | sort
```

如果出现这些目录，说明不符合规范：

- `artifacts/output`
- `artifacts/armeabi-v7a`
- `artifacts/x86`
- `artifacts/x86_64`

一般不需要保留安装副产物里的 `share/` 文档目录。脚本已经默认删除，但如果手工复制引入了，应清理。

### 8. 校验

必须运行：

```bash
scripts/validate-library-package.sh libs/<库>/<版本>
git diff --check
```

如果本库是 fallback，额外运行：

```bash
pkg=libs/<库>/<版本>
bash -n "$pkg/recipe/build.sh"
```

如果 fallback 脚本被声明为可复用脚本，还必须做最小路径语义测试。以 bzip2 这类 Makefile fallback 为例，至少验证：

- 缺少 `OHOS_SDK` 时明确失败。
- `SOURCE_DIR` 不存在时明确失败。
- `SOURCE_DIR` 下缺少关键构建文件时明确失败。
- `SOURCE_DIR` 和 `OUTPUT_ROOT` 使用相对路径或绝对路径时，不会因为脚本内部 `cd` 改变含义。

可使用 fake source 做不依赖真实 SDK 的路径测试：

```bash
tmp=$(mktemp -d)
script="$PWD/libs/bzip2/1_0_6/recipe/build.sh"
mkdir -p "$tmp/src" "$tmp/fake-sdk/native/llvm/bin"
cat > "$tmp/src/Makefile-libbz2_so" <<'EOF'
all:
	@printf lib > libbz2.so.1.0.8
	@printf lib > libbz2.so.1.0
	@printf bin > bzip2-shared
clean:
	@rm -f libbz2.so.1.0.8 libbz2.so.1.0 bzip2-shared
EOF
(
  cd "$tmp"
  SOURCE_DIR="$tmp/src" OUTPUT_ROOT=relative-out OHOS_SDK="$tmp/fake-sdk" \
    bash "$script"
)
find "$tmp/relative-out" -type f | sort
rm -rf "$tmp"
```

上面的 fake 测试不是每个库都能照抄。若库不是 Makefile fallback，应写一个同等粒度的最小测试，目标是验证脚本的输入参数、输出目录和路径语义，而不是重新完成真实交叉编译。

对所有包含 CLI 或共享库的库，额外运行运行时依赖闭包检查和配置路径检查，命令见 6.3 和 6.4。检查结果必须在最终回复中说明。

建议额外运行：

```bash
find libs -maxdepth 4 -type d -path '*/artifacts/*' | sort
rg -n "artifacts/output|armeabi-v7a|x86_64|待人工复核|recipe 改动：HPKBUILD|源码改动：检查" libs/<库>/<版本> || true
```

如果校验脚本失败，先修知识包，不要绕过校验。

### 9. 提交和推送

提交前自审：

```bash
git diff --stat
git diff -- libs/<库>/<版本>/meta.yaml libs/<库>/<版本>/modifications.md libs/<库>/<版本>/recipe/HPKBUILD
```

提交：

```bash
git add libs/<库>/<版本>
git commit -m "Add <库> arm64 knowledge package"
git push origin main
```

推送后确认：

```bash
git status --short --branch
```

应显示本地与 `origin/main` 同步，且没有未提交改动。

## 判断是否适合弱模型继续

适合弱模型流水线化的部分：

- 按脚本生成草稿包。
- 读取固定报告和 recipe。
- 按固定模板补 `meta.yaml`。
- 按固定章节改写 `modifications.md`。
- 跑固定校验命令。
- 单库提交和推送。

不应完全自动化的部分：

- 判断报告里的失败是否属于 recipe、环境、源码 patch 或 fallback。
- 判断设备验证是否覆盖真实功能路径。
- 判断运行时依赖是否必须随产物归档。
- 判断脚本生成版本号或 `builddir` 是否正确。
- 判断是否应覆盖已有库目录。
- 判断从源仓库复制来的 fallback 脚本是否仍能在知识包路径下复用。
- 判断验证命令引用的输入文件是否已经归档并能复现。
- 判断 `readelf NEEDED` 里的第三方运行时依赖是否都已归档或说明来源。
- 判断 install 配置文件里的构建机绝对路径是否会影响跨机器复用。
- 判断依赖库 recipe 修复是否需要独立归档。

如果弱模型不确定，应停下来汇报具体不确定点，而不是猜。

## 常见问题

### 版本目录为什么有时不是普通语义版本？

版本来自 recipe 的 `pkgver`。例如 Expat 使用 `R_2_7_5`。不要擅自改成 `2.7.5`，除非同时有明确的仓库命名规则变更。

### 为什么不能提交脚本模板？

模板只说明“需要人工复核”，不能告诉使用者真实改了什么。这个仓库的价值在可复用改动知识，不是文件搬运。

### 为什么只保留 arm64？

用户已明确当前只需要 `arm64-v8a`。其他架构会增加仓库体积，也会干扰后续使用者判断当前包的验证状态。

### 什么时候可以进入 fallback？

本仓库当前是在整理已完成结果，不是重新移植库。若报告显示原始移植没有进入 fallback，就不要在知识包里改写成 fallback。若数据源库本身没有 lycium recipe，则按脚本生成 fallback 知识包，但仍需人工说明事实来源和验证路径。
