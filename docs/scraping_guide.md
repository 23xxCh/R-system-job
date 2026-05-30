# 实习岗位数据爬取指南

## 当前状态

- **现有数据**: 597 条岗位，其中 62 条是实习岗位
- **待爬取**: 216 个实习岗位 URL（9个城市 × 12个关键词 × 2页）
- **爬取工具**: kimi-webbridge Chrome 扩展

## 问题说明

所有主要招聘网站（智联招聘、BOSS直聘、拉勾网）都有反爬虫保护：
- 需要 JavaScript 渲染页面
- 检测自动化访问
- 需要有效的会话令牌

因此，直接用 R 的 `rvest` 包无法爬取这些网站，需要使用浏览器自动化工具。

## 解决方案

### 方法 1: 使用 kimi-webbridge（推荐）

1. **启用 Chrome 扩展**
   - 打开 Chrome 浏览器
   - 确保 kimi-webbridge 扩展已安装并启用
   - 点击扩展图标，启用 WebSocket 服务器

2. **运行爬取脚本**
   ```bash
   # 生成任务列表
   Rscript scripts/scrape_intern_kimi.R

   # 使用 kimi-webbridge 逐个爬取
   npx kimi-webbridge navigate --url "https://sou.zhaopin.com/?jl=530&kw=数据分析实习&p=1"
   npx kimi-webbridge evaluate --script "extract_jobs.js"
   ```

3. **合并数据**
   ```bash
   Rscript scripts/parse_batch.R
   ```

### 方法 2: 手动爬取

1. 打开浏览器，访问智联招聘
2. 搜索"数据分析实习"等关键词
3. 使用浏览器开发者工具提取数据
4. 保存为 JSON 格式到 `data/raw/` 目录

### 方法 3: 使用其他数据源

- **实习僧**: https://www.shixiseng.com/
- **刺猬实习**: https://www.ciweishijian.com/
- **牛客网**: https://www.nowcoder.com/

这些网站可能有不同的反爬虫策略，可以尝试用 rvest 直接爬取。

## 数据文件说明

- `data/intern_scrape_tasks.json`: 216 个爬取任务
- `data/intern_urls.json`: 288 个 URL 列表
- `data/raw/`: 原始 JSON 数据文件
- `data/processed/jobs_clean.csv`: 合并后的清洗数据

## 爬取脚本

- `scripts/scrape_intern_kimi.R`: 生成 kimi-webbridge 任务
- `scripts/gen_intern_urls.R`: 生成 URL 列表
- `scripts/parse_batch.R`: 合并 JSON 数据
