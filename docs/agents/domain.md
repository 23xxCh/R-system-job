# Domain Docs

## 单上下文布局

本项目使用单上下文布局。

### 文件结构

```
/
├── CONTEXT.md          # 项目领域知识
├── docs/
│   └── adr/            # 架构决策记录
```

### CONTEXT.md

包含项目的核心领域知识：
- 项目目标和范围
- 技术栈说明
- 数据结构定义
- 业务规则

### docs/adr/

包含架构决策记录（Architecture Decision Records）：
- ADR-001: 选择 Shiny 作为仪表板框架
- ADR-002: 使用 kimi-webbridge 进行浏览器自动化
- ADR-003: 数据清洗流程设计

### 消费规则

代理技能读取这些文件以了解项目上下文：
- `improve-codebase-architecture`: 读取 CONTEXT.md 和 ADR
- `diagnose`: 读取 CONTEXT.md 了解项目结构
- `tdd`: 读取 CONTEXT.md 了解测试策略
