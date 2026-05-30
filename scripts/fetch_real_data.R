# ============================================================
# fetch_real_data.R —— 用 kimi-webbridge 抓取真实数据的流程控制
# ============================================================
# 工作流：
#   1. 本脚本生成所有搜索 URL
#   2. 将 URL 列表写入 data/url_list.json
#   3. 我（Claude Code）用 kimi-webbridge 逐个抓取页面
#   4. 每页数据保存为 data/raw/page_XXX.json
#   5. 本脚本读取所有 JSON，合并为 data/raw/jobs_raw.csv
#   6. 调用 clean.R 清洗数据
#
# 你只需要运行这个脚本，URL 列表会自动准备好

source("config.R")
source("scripts/utils.R")

# --- 智联招聘城市代码映射 ---
# 智联用数字代码表示城市，需要映射
CITY_CODES <- c(
  "北京" = "530",  "上海" = "538",  "广州" = "763",  "深圳" = "765",
  "杭州" = "653",  "成都" = "801",  "武汉" = "736",  "南京" = "635",
  "重庆" = "551",  "西安" = "854",  "苏州" = "639",  "天津" = "531",
  "长沙" = "749",  "郑州" = "719",  "东莞" = "769",  "青岛" = "573"
)

# --- 生成 URL 列表 ---
generate_url_list <- function(keywords = KEYWORDS[1:3],   # 先用前3个关键词测试
                              cities   = CITIES[1:4]) {  # 先用4个城市测试
  urls <- list()

  for (kw in keywords) {
    for (city in cities) {
      code <- CITY_CODES[city]
      if (is.na(code)) next

      url <- paste0(
        "https://sou.zhaopin.com/?kw=",
        URLencode(kw, reserved = TRUE),
        "&jl=", code
      )

      urls <- c(urls, list(list(
        keyword  = kw,
        city     = city,
        city_code = code,
        url      = url,
        pages    = 3  # 每个关键词爬3页
      )))
    }
  }

  urls
}

# --- 保存 URL 列表 ---
url_list <- generate_url_list()
dir.create("data/raw", showWarnings = FALSE, recursive = TRUE)
jsonlite::write_json(url_list, "data/url_list.json", auto_unbox = TRUE, pretty = TRUE)
log_info("已生成 {length(url_list)} 个搜索任务，保存到 data/url_list.json")

# --- 打印任务概览 ---
cat("\n=== 爬取任务概览 ===\n")
cat("关键词:", paste(unique(sapply(url_list, "[[", "keyword")), collapse = ", "), "\n")
cat("城市:", paste(unique(sapply(url_list, "[[", "city")), collapse = ", "), "\n")
cat("总任务数:", length(url_list), "\n")
cat("每任务爬取页数:", url_list[[1]]$pages, "\n")
cat("预计总页面数:", length(url_list) * url_list[[1]]$pages, "\n")
cat("\n下一步：让 Claude Code 用 kimi-webbridge 逐个抓取这些页面\n")
