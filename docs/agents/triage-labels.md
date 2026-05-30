# Triage Labels

## 标签映射

| 角色 | 标签名称 | 说明 |
|------|----------|------|
| needs-triage | needs-triage | 需要评估 |
| needs-info | needs-info | 等待报告者提供信息 |
| ready-for-agent | ready-for-agent | 可由代理处理 |
| ready-for-human | ready-for-human | 需要人工处理 |
| wontfix | wontfix | 不会处理 |

### 创建标签

```bash
# 创建所有标签
gh label create needs-triage --description "需要评估" --color "FBCA04"
gh label create needs-info --description "等待信息" --color "D93F0B"
gh label create ready-for-agent --description "可由代理处理" --color "0E8A16"
gh label create ready-for-human --description "需要人工处理" --color "1D76DB"
gh label create wontfix --description "不会处理" --color "FFFFFF"
```
