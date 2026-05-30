# ============================================================
# scrape_intern_kimi.R —— 用 kimi-webbridge 爬取实习岗位
# ============================================================

library(jsonlite)
library(dplyr)
library(stringr)

setwd("E:/Show work/R-system")

# --- 智联招聘城市代码 ---
CITY_CODES <- c(
  "北京" = "530", "上海" = "538", "广州" = "763", "深圳" = "765",
  "杭州" = "653", "东莞" = "779", "惠州" = "773", "佛山" = "768", "中山" = "780"
)

# --- 实习相关关键词 ---
INTERN_KEYWORDS <- c(
  "数据分析实习", "Python实习", "前端开发实习", "后端开发实习",
  "AI应用实习", "智能制造实习", "自动化实习", "机器人实习",
  "机械实习", "软件开发实习", "算法实习", "测试实习"
)

# --- 生成 URL 列表 ---
urls <- list()

for (city_name in names(CITY_CODES)) {
  city_code <- CITY_CODES[city_name]

  for (kw in INTERN_KEYWORDS) {
    for (page in 1:2) {
      url <- sprintf("https://sou.zhaopin.com/?jl=%s&kw=%s&p=%d", city_code, URLencode(kw), page)

      urls[[length(urls) + 1]] <- list(
        keyword = kw,
        city = city_name,
        city_code = city_code,
        page = page,
        url = url,
        source = "智联招聘",
        output_file = sprintf("data/raw/page_%s_%s_p%d.json", kw, city_code, page)
      )
    }
  }
}

# 保存 URL 列表
write_json(urls, "data/intern_scrape_tasks.json", pretty = TRUE, auto_unbox = TRUE)

cat("共生成", length(urls), "个实习岗位爬取任务\n")
cat("已保存到: data/intern_scrape_tasks.json\n\n")

# 打印使用说明
cat("使用方法:\n")
cat("1. 确保 kimi-webbridge Chrome 扩展已启用\n")
cat("2. 运行此脚本生成任务列表\n")
cat("3. 使用 kimi-webbridge 逐个爬取 URL\n")
cat("4. 将结果保存到 data/raw/ 目录\n")
cat("5. 运行 parse_batch.R 合并数据\n\n")

# 打印前5个任务示例
cat("任务示例 (前5个):\n")
for (i in 1:min(5, length(urls))) {
  u <- urls[[i]]
  cat(sprintf("%d. [%s] %s @ %s (第%d页)\n", i, u$source, u$keyword, u$city, u$page))
  cat("   URL:", u$url, "\n")
  cat("   输出:", u$output_file, "\n\n")
}
