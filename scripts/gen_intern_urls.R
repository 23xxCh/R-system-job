# ============================================================
# gen_intern_urls.R —— 生成实习岗位爬取 URL 列表
# ============================================================

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
  "机械实习", "软件开发实习", "算法实习", "测试实习",
  "产品经理实习", "UI设计实习", "运维实习", "数据库实习"
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
        source = "智联招聘"
      )
    }
  }
}

# 保存为 JSON
jsonlite::write_json(urls, "data/intern_urls.json", pretty = TRUE, auto_unbox = TRUE)

cat("共生成", length(urls), "个实习岗位爬取 URL\n")
cat("已保存到: data/intern_urls.json\n\n")

# 打印前10个 URL 示例
cat("URL 示例 (前10个):\n")
for (i in 1:min(10, length(urls))) {
  u <- urls[[i]]
  cat(sprintf("%d. [%s] %s @ %s (第%d页)\n", i, u$source, u$keyword, u$city, u$page))
  cat("   ", u$url, "\n")
}
