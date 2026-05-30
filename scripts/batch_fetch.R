# ============================================================
# batch_fetch.R —— 批量爬取任务列表
# ============================================================
# 定义要爬取的关键词×城市×页数组合
# 输出 URL 列表，供 kimi-webbridge 逐个抓取

KEYWORD_CITY_TASKS <- list(
  # keyword = c(城市名, 城市代码)
  list(kw = "数据分析师",   cities = list(c("北京","530"), c("上海","538"), c("深圳","765"))),
  list(kw = "Python开发",   cities = list(c("北京","530"), c("上海","538"), c("杭州","653"))),
  list(kw = "前端开发",     cities = list(c("北京","530"), c("上海","538"), c("深圳","765"))),
  list(kw = "后端开发",     cities = list(c("北京","530"), c("上海","538"), c("杭州","653"))),
  list(kw = "AI应用工程师", cities = list(c("北京","530"), c("深圳","765"), c("杭州","653"))),
  list(kw = "机械工程师",   cities = list(c("北京","530"), c("上海","538"), c("深圳","765")))
)

PAGES_PER_SEARCH <- 2

# 生成所有 URL
all_tasks <- list()
task_id <- 0

for (task in KEYWORD_CITY_TASKS) {
  kw <- task$kw
  for (city_pair in task$cities) {
    city_name <- city_pair[1]
    city_code <- city_pair[2]
    for (page in 1:PAGES_PER_SEARCH) {
      task_id <- task_id + 1
      url <- paste0(
        "https://sou.zhaopin.com/?kw=",
        URLencode(kw, reserved = TRUE),
        "&jl=", city_code,
        "&p=", page
      )
      all_tasks[[task_id]] <- list(
        id    = task_id,
        kw    = kw,
        city  = city_name,
        page  = page,
        url   = url,
        file  = sprintf("data/raw/page_%s_%s_p%d.json",
                        gsub("[^a-zA-Z]", "", kw), city_code, page)
      )
    }
  }
}

cat("=== 批量爬取任务 ===\n")
cat("总任务数:", length(all_tasks), "页\n")
cat("\n按关键词统计:\n")
kw_counts <- table(sapply(all_tasks, "[[", "kw"))
for (kw in names(kw_counts)) cat(sprintf("  %-15s %d 页\n", kw, kw_counts[kw]))
cat("\n按城市统计:\n")
city_counts <- table(sapply(all_tasks, "[[", "city"))
for (c in names(city_counts)) cat(sprintf("  %-6s %d 页\n", c, city_counts[c]))
