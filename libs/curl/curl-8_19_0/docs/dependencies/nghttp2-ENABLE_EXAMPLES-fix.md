# nghttp2 依赖修复记录

## 问题

构建 curl 时，nghttp2 recipe 默认 `ENABLE_EXAMPLES=ON` 导致构建失败。
示例程序依赖不满足，编译中断。

## 修复

修改 `tpc_c_cplusplus/community/nghttp2/HPKBUILD`：

```diff
-    -DENABLE_EXAMPLES=ON \
+    -DENABLE_EXAMPLES=OFF \
```

## 位置

- 原始文件：`tpc_c_cplusplus/community/nghttp2/HPKBUILD`
- 关键行：build() 函数内 cmake 参数

## 套用到新版本时的检查点

- 新版本 nghttp2 recipe 是否仍默认 ENABLE_EXAMPLES=ON
- 如果示例程序依赖已满足，可考虑恢复 ON
- 此修复影响所有依赖 nghttp2 的库，不仅仅是 curl
