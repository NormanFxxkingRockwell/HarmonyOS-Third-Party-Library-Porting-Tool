# curl 构建报告

## 1. 构建系统识别结果

- 构建系统：CMake
- 主 CMakeLists.txt：`libs/curl/CMakeLists.txt`
- 构建类型：共享库 + CLI 工具

## 2. lycium 尝试记录

- 使用现有 recipe：`tpc_c_cplusplus/community/curl_8_9_1/HPKBUILD` 作为基础
- 升级版本：curl-8_9_1 -> curl-8_19_0
- 创建新 recipe：`tpc_c_cplusplus/community/curl_8_19_0/HPKBUILD`
- 预修正项：
  - 更新 source URL 和 packagename
  - 更新 SHA512SUM
  - 修改 archs 只包含 arm64-v8a（依赖库 zstd 只有 arm64-v8a）
  - 修改依赖为 openssl, zstd, nghttp2（已构建成功的版本）
  - 添加 CMake 参数禁用可选依赖：CURL_USE_LIBPSL=OFF, USE_LIBIDN2=OFF
  - 禁用 CURL_USE_PKGCONFIG 避免 pkg-config 问题
  - 禁用 ENABLE_CURL_MANUAL 和 PICKY_COMPILER
- lycium 执行结果：成功
- 依赖构建：
  - nghttp2: 需要修复（原 recipe ENABLE_EXAMPLES=ON 导致失败，改为 OFF）
  - openssl: 已构建
  - zstd: 已构建

## 3. 失败分类与决策

- 第一轮失败：nghttp2 构建失败（ENABLE_EXAMPLES=ON 但依赖不满足）
  - 分类：HPKBUILD 配置问题
  - 处理：修改 nghttp2 recipe 禁用 ENABLE_EXAMPLES
- 第二轮失败：curl armeabi-v7a 构建失败（zstd 没有 armeabi-v7a 产物）
  - 分类：依赖产物缺失
  - 处理：修改 curl recipe 只构建 arm64-v8a
- 第三轮失败：CMake 找不到 libpsl 和 libidn2
  - 分类：可选依赖缺失
  - 处理：添加 CMake 参数禁用这些可选依赖

## 4. fallback 执行记录

- 未进入 fallback，lycium 路径成功

## 5. 编译驱动型代码与脚本修改

- 修改 `tpc_c_cplusplus/community/nghttp2/HPKBUILD`：ENABLE_EXAMPLES=ON -> OFF
- 创建 `tpc_c_cplusplus/community/curl_8_19_0/HPKBUILD`
- 创建 `tpc_c_cplusplus/community/curl_8_19_0/SHA512SUM`
- 复制其他必要文件：HPKCHECK, README.OpenSource, README_zh.md, docs/

## 6. 产物概览

- build-pass：✅ 成功
- binary-pass：✅ 成功（curl CLI）
- device-pass：✅ 成功
- `.so` 路径：`outputs/curl/lib/libcurl.so.4.8.0`
- binary 路径：`outputs/curl/bin/curl`

## 7. binary 验证方式

- binary 来源类型：CLI
- 运行命令：
  - `./curl --version`
  - `./curl -I https://www.baidu.com`
- 设备侧执行结果：成功
- 关键输出：
  ```
  curl 8.19.0-DEV (aarch64-linux-ohos) libcurl/8.19.0-DEV OpenSSL/3.6.1 zlib/1.3.1 zstd/1.5.7 nghttp2/1.68.1
  Protocols: dict file ftp ftps gopher gophers http https imap imaps ipfs ipns mqtt mqtts pop3 pop3s rtsp smb smbs smtp smtps telnet tftp ws wss
  Features: alt-svc AsynchDNS HSTS HTTP2 HTTPS-proxy IPv6 Largefile libz NTLM SSL threadsafe TLS-SRP UnixSockets zstd
  ```
  HTTP 测试：`HTTP/1.1 200 OK`

## 8. 设备测试记录

- 设备测试通道：hdc fallback
- hdc 推送目录：`/data/local/tmp/curl/`
- hdc 推送命令：
  ```
  hdc file send curl /data/local/tmp/curl/
  hdc file send libcurl.so.4.8.0 /data/local/tmp/curl/
  hdc file send libzstd.so* /data/local/tmp/curl/
  hdc file send libnghttp2.so* /data/local/tmp/curl/
  hdc file send libssl.so* /data/local/tmp/curl/
  hdc file send libcrypto.so* /data/local/tmp/curl/
  ```
- 设备执行命令：
  ```
  cd /data/local/tmp/curl && chmod +x curl && LD_LIBRARY_PATH=/data/local/tmp/curl ./curl --version
  cd /data/local/tmp/curl && LD_LIBRARY_PATH=/data/local/tmp/curl ./curl -I https://www.baidu.com
  ```
- 设备侧输出：见第 7 节

## 9. 产物校验结果

- libcurl.so: ELF 64-bit LSB shared object, ARM aarch64
- curl: ELF 64-bit LSB pie executable, ARM aarch64, dynamically linked
- 所有产物架构为 arm64-v8a (AArch64)

## 10. 最终产物路径

- `outputs/curl/lib/libcurl.so.4.8.0`
- `outputs/curl/lib/libcurl.so.4` (symlink)
- `outputs/curl/lib/libcurl.so` (symlink)
- `outputs/curl/bin/curl`