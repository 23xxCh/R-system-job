# Issue Tracker

## GitHub Issues

仓库地址: https://github.com/23xxCh/R-system-job

### 工具

使用 `gh` CLI 管理 GitHub Issues。

### 常用命令

```bash
# 创建 Issue
gh issue create --title "标题" --body "描述"

# 列出 Issues
gh issue list

# 查看 Issue
gh issue view 123

# 添加标签
gh issue edit 123 --add-label "needs-triage"

# 关闭 Issue
gh issue close 123
```

### 标签映射

参见 `docs/agents/triage-labels.md`。
