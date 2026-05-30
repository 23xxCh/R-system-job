# R-system-job

R 语言求职市场数据分析项目，包含 Web 爬虫和 Shiny 交互式仪表板。

## 项目简介

本项目通过爬取智联招聘、BOSS直聘等招聘网站的数据，对求职市场进行分析，帮助用户了解：
- 各城市岗位分布情况
- 薪资水平对比
- 行业热度趋势
- 岗位搜索与筛选

## 功能特性

- **数据爬取**: 支持多城市、多关键词的岗位数据采集
- **数据清洗**: 自动解析薪资、学历、经验等字段
- **交互式仪表板**: 5 个分析标签页
  - 城市分布分析
  - 薪资水平对比
  - 行业热度词云
  - 岗位搜索筛选
  - 实习岗位分析

## 覆盖范围

### 城市
北京、上海、广州、深圳、杭州、东莞、惠州、佛山、中山

### 岗位关键词
- 数据分析、Python、前端开发、后端开发
- AI应用工程师、智能制造、自动化、机器人
- 机械工程师、软件开发、算法、测试

## 快速开始

### 1. 安装依赖

```r
install.packages(c("shiny", "dplyr", "ggplot2", "plotly", 
                    "DT", "wordcloud2", "scales", "stringr",
                    "jsonlite", "rvest", "httr"))
```

### 2. 运行仪表板

```r
shiny::runApp("app.R", port = 3838)
```

然后在浏览器中访问 http://127.0.0.1:3838

## 项目结构

```
R-system-job/
├── app.R                    # Shiny 仪表板主文件
├── config.R                 # 全局配置
├── CLAUDE.md                # Claude Code 配置
├── scripts/
│   ├── clean.R              # 数据清洗
│   ├── parse_batch.R        # 批量解析 JSON
│   ├── scraper.R            # 爬虫模块
│   ├── utils.R              # 工具函数
│   └── ...                  # 其他脚本
├── data/
│   ├── raw/                 # 原始 JSON 数据
│   └── processed/           # 清洗后的 CSV
├── docs/
│   └── agents/              # 代理技能配置
└── output/                  # 输出文件
```

## 数据来源

- **智联招聘**: https://sou.zhaopin.com
- **BOSS直聘**: https://www.zhipin.com

## 使用的工具

- **kimi-webbridge**: 浏览器自动化工具，用于绕过反爬虫保护
- **rvest**: R 语言 HTML 解析包
- **Shiny**: R 语言 Web 应用框架

## 开发说明

### 数据爬取流程

1. 生成搜索 URL 列表
2. 使用 kimi-webbridge 控制浏览器访问页面
3. 提取页面中的岗位数据
4. 保存为 JSON 文件
5. 使用 parse_batch.R 合并和清洗数据

### 添加新关键词

编辑 `config.R` 文件中的 `KEYWORDS` 向量：

```r
KEYWORDS <- c(
  "数据分析师",
  "Python开发",
  "你的新关键词"
)
```

### 添加新城市

编辑 `config.R` 文件中的 `CITIES` 向量，并在 `fetch_real_data.R` 中添加对应的城市代码。

## 许可证

MIT License

## 联系方式

GitHub: https://github.com/23xxCh/R-system-job
