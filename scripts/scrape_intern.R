# ============================================================
# scrape_intern.R —— 用 rvest 直接爬取实习岗位数据
# ============================================================

library(rvest)
library(jsonlite)
library(dplyr)
library(stringr)
library(purrr)

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

# --- 通用 User-Agent ---
UA <- "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

# --- 爬取单页 ---
scrape_zhilian_page <- function(keyword, city_code, page = 1) {
  url <- sprintf("https://sou.zhaopin.com/?jl=%s&kw=%s&p=%d", city_code, URLencode(keyword), page)

  cat("爬取:", keyword, "@", city_code, "第", page, "页\n")

  tryCatch({
    session <- read_html(url, encoding = "UTF-8",
                         httr::add_headers(
                           `User-Agent` = UA,
                           `Accept` = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
                           `Accept-Language` = "zh-CN,zh;q=0.9,en;q=0.8"
                         ))

    # 提取页面中的 JSON 数据（智联招聘用 __INITIAL_STATE__ 存放数据）
    script_tags <- session %>% html_elements("script")
    for (script in script_tags) {
      text <- script %>% html_text2()
      if (str_detect(text, "__INITIAL_STATE__")) {
        # 提取 JSON
        json_str <- str_extract(text, "window\\.__INITIAL_STATE__\\s*=\\s*\\{.*\\};")
        if (!is.na(json_str)) {
          json_str <- str_replace(json_str, "window\\.__INITIAL_STATE__\\s*=\\s*", "")
          json_str <- str_replace(json_str, ";$", "")

          # 尝试解析 JSON
          tryCatch({
            data <- fromJSON(json_str, simplifyVector = FALSE)

            # 打印数据结构用于调试
            cat("  数据结构:", paste(names(data), collapse=", "), "\n")

            # 尝试不同的数据路径
            if (!is.null(data$jobList$jobData)) {
              jobs <- data$jobList$jobData
              cat("  找到", length(jobs), "条岗位 (jobData)\n")
              return(jobs)
            } else if (!is.null(data$jobList)) {
              # 尝试直接使用 jobList
              jobs <- data$jobList
              if (is.list(jobs) && length(jobs) > 0) {
                cat("  找到", length(jobs), "条岗位 (jobList)\n")
                return(jobs)
              }
            } else {
              # 打印前500个字符用于调试
              cat("  JSON 前500字符:", substr(json_str, 1, 500), "\n")
            }
          }, error = function(e) {
            cat("  JSON 解析错误:", conditionMessage(e), "\n")
            # 打印 JSON 前500字符用于调试
            cat("  JSON 前500字符:", substr(json_str, 1, 500), "\n")
          })
        }
      }
    }

    cat("  未找到岗位数据\n")
    return(NULL)
  }, error = function(e) {
    cat("  爬取失败:", conditionMessage(e), "\n")
    return(NULL)
  })
}

# --- 解析单个岗位 ---
parse_job <- function(job, keyword, city_name) {
  tryCatch({
    tibble(
      job_title    = job$jobName %||% NA_character_,
      salary       = job$salary %||% NA_character_,
      company      = job$company$companyName %||% NA_character_,
      city         = paste0(city_name, "·", job$city$display %||% ""),
      experience   = job$jobExperience %||% NA_character_,
      education    = job$eduLevel %||% NA_character_,
      company_size = job$company$companySize %||% NA_character_,
      industry     = job$company$companyType %||% NA_character_,
      source       = "智联招聘",
      keyword      = keyword
    )
  }, error = function(e) {
    tibble()
  })
}

# --- 主流程 ---
all_results <- list()

for (city_name in names(CITY_CODES)) {
  city_code <- CITY_CODES[city_name]

  for (kw in INTERN_KEYWORDS) {
    for (page in 1:2) {
      jobs <- scrape_zhilian_page(kw, city_code, page)

      if (!is.null(jobs) && length(jobs) > 0) {
        parsed <- map_dfr(jobs, ~parse_job(.x, kw, city_name))
        if (nrow(parsed) > 0) {
          all_results[[length(all_results) + 1]] <- parsed
        }
      }

      Sys.sleep(runif(1, 2, 4))
    }
  }
}

# --- 合并保存 ---
if (length(all_results) > 0) {
  combined <- bind_rows(all_results)
  cat("\n共爬取", nrow(combined), "条实习岗位数据\n")

  # 保存为 JSON
  output_file <- "data/raw/page_intern_batch.json"
  write_json(combined, output_file, pretty = TRUE)
  cat("已保存到:", output_file, "\n")
} else {
  cat("未爬取到任何数据\n")
}
