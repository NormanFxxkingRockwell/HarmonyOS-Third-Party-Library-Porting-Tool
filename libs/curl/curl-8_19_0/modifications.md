# curl curl-8_19_0 鸿蒙化改动记录

## 状态

构建成功，设备验证通过。lycium 路径完成，未进入 fallback。

## 事实来源

- `docs/build-report.md`：构建过程、失败分类、验证命令和输出
- `docs/adaptation-report.md`：业务适配结论
- `docs/adaptation-plan.md`：原始适配方案
- `recipe/HPKBUILD`：最终 recipe
- `recipe/SHA512SUM`：源码包校验和

## 关键结论

- curl 8.19.0 上游已原生支持 OHOS 系统（`lib/CMakeLists.txt:267`），无需源码 patch
- 原适配方案计划的 `curl_oh_pkg.patch` 对该版本不需要
- 基于 `tpc_c_cplusplus/community/curl_8_9_1/HPKBUILD` 升级创建新 recipe

## recipe 改动

recipe 位于 `tpc_c_cplusplus/community/curl_8_19_0/`，基于 curl_8_9_1 升级：

- `pkgver`：`curl-8_9_1` → `curl-8_19_0`
- `source` URL：更新为 `https://github.com/curl/curl/archive/refs/tags/curl-8_19_0.zip`
- `packagename`：`curl-8_19_0.zip`
- `builddir`：`curl-curl-8_19_0`
- `SHA512SUM`：重新计算
- `archs`：仅保留 `arm64-v8a`（依赖 zstd 只有 arm64-v8a 产物）
- `depends`：`openssl`、`zstd`、`nghttp2`
- CMake 关键参数：
  - `-DCURL_USE_PKGCONFIG=OFF`：避免 pkg-config 问题
  - `-DCURL_USE_LIBPSL=OFF`：可选依赖缺失
  - `-DUSE_LIBIDN2=OFF`：可选依赖缺失
  - `-DENABLE_CURL_MANUAL=OFF`：减少构建开销
  - `-DPICKY_COMPILER=OFF`：避免编译器警告中断
  - `-DENABLE_WEBSOCKETS=ON`：启用 WebSocket 支持
  - `-DUSE_NGHTTP2=ON`：启用 HTTP/2
  - `-DBUILD_TESTING=OFF`：不构建测试
  - `-DCURL_CA_BUNDLE="/etc/ssl/certs/cacert.pem"`：CA 证书路径
  - `-DCURL_CA_PATH="/etc/ssl/certs/"`：CA 证书目录

## 依赖 recipe 修复

nghttp2 recipe 需修改 `ENABLE_EXAMPLES=ON` → `OFF`。
示例程序依赖不满足导致构建失败，详见 `docs/dependencies/nghttp2-ENABLE_EXAMPLES-fix.md`。
此修复影响所有依赖 nghttp2 的库，不仅仅是 curl。

## 源码改动

无。curl 8.19.0 上游已包含 OHOS 支持。

## 产物

- 共享库：`lib/libcurl.so.4.8.0`（ELF 64-bit LSB shared object, ARM aarch64）
- CLI 工具：`bin/curl`（ELF 64-bit LSB pie executable, ARM aarch64）
- 符号链接：`lib/libcurl.so.4`、`lib/libcurl.so`
- 头文件：`include/curl/` 下全部公开头
- CMake 配置：`lib/cmake/CURL/`
- pkg-config：`lib/pkgconfig/libcurl.pc`

产物来自 lycium install 和 outputs/curl/ 合并。

### 运行时依赖闭包

libcurl.so 和 curl 二进制依赖以下共享库（readelf 确认）：

- `libssl.so.3`、`libcrypto.so.3`（openssl）
- `libzstd.so.1`（zstd）
- `libnghttp2.so.14`（nghttp2）
- `libz.so`（zlib）
- `libc.so`（系统库，不归档）

已归档至 `lib/runtime-deps/`，设备验证时需一并推送。
仅使用本知识包产物时，必须同时部署这些运行时依赖，否则设备侧无法加载。

### 配置文件绝对路径警告

`bin/curl-config`、`lib/pkgconfig/libcurl.pc`、`lib/cmake/CURL/CURLConfig.cmake`
含本机绝对路径（lycium install 目录和 SDK 路径）。这些文件是原始 install 产物，
不能直接跨机器复用。如需在其他机器使用，应：

- 重新构建 curl 以生成目标机器的 config 文件，或
- 手动替换其中的路径为实际部署路径

## 验证

- 构建：pass
- 二进制：pass（curl CLI 可执行）
- 设备：pass

设备验证通过 hdc fallback 通道执行：
1. 推送产物到设备 `/data/local/tmp/curl/`（含 curl、libcurl.so、依赖 so）
2. `./curl --version` 输出：`curl 8.19.0-DEV (aarch64-linux-ohos) libcurl/8.19.0-DEV OpenSSL/3.6.1 zlib/1.3.1 zstd/1.5.7 nghttp2/1.68.1`
3. `./curl -I https://www.baidu.com` 返回 `HTTP/1.1 200 OK`

## 套用到新版本时的检查点

- 新版本是否仍原生支持 OHOS（检查 `lib/CMakeLists.txt` 中 OHOS 相关代码）
- source URL 和 SHA512SUM 需更新
- zstd 等依赖是否仍只有 arm64-v8a 产物，决定是否继续限制 archs
- 可选依赖（libpsl、libidn2）是否已构建，若已构建可考虑启用
- nghttp2 的 ENABLE_EXAMPLES 修复是否仍需要
- CA 证书路径配置是否仍适用
- 运行时依赖版本是否变化（openssl 3.x、zstd 1.x、nghttp2 1.x）
