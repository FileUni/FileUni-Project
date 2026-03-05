# FileUni 两仓库 CI 逻辑（Community 侧）

- `FileUni-Community` 是公开构建与发布仓库。
- 它接收来自 `FileUni-WorkSpace` 的 dispatch 触发。
- 收到触发后，Community CI 拉取 WorkSpace 指定代码并执行构建。
- 构建完成后，在 Community 仓库发布 GitHub Release 和下载产物。

## 发布顺序

1. 接收 `FileUni-WorkSpace` 触发请求。
2. 拉取 `FileUni-WorkSpace` 指定版本源码并构建。
3. 上传 artifacts 并在 `FileUni-Community` 发布 Release。
