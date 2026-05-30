# ============================================================
# parse_fetched_data.R —— 读取 kimi-webbridge 抓取的 JSON 数据
# ============================================================
# kimi-webbridge 每次抓取一页会保存一个 JSON 文件
# 这个脚本读取所有 JSON 文件，合并为统一的 CSV

library(jsonlite)
library(dplyr)
library(readr)
library(stringr)

source("scripts/utils.R")

# --- 解析单个 JSON 文件 ---
parse_one_page <- function(json_path) {
  raw <- fromJSON(json_path, flatten = TRUE)

  if (is.null(raw) || length(raw) == 0) return(tibble())

  # 统一字段名（智联用短字段名）
  df <- tibble(
    job_title    = raw$t %||% raw$title,
    salary       = raw$s %||% raw$salary,
    company      = raw$cp %||% raw$company,
    city         = raw$ci %||% raw$city,
    experience   = raw$e  %||% raw$experience,
    education    = raw$ed %||% raw$education,
    company_size = raw$sz %||% raw$company_size,
    industry     = raw$in %||% raw$industry,
    source       = raw$src %||% raw$source %||% "智联招聘",
    keyword      = raw$kw  %||% raw$keyword %||% NA_character_
  )

  df
}

# --- 合并所有 JSON 文件 ---
combine_all_pages <- function(raw_dir = "data/raw") {
  json_files <- list.files(raw_dir, pattern = "\\.json$", full.names = TRUE)

  if (length(json_files) == 0) {
    log_warn("在 {raw_dir} 中没有找到 JSON 文件")
    return(tibble())
  }

  log_info("找到 {length(json_files)} 个 JSON 文件")

  all_data <- map_dfr(json_files, function(f) {
    tryCatch(parse_one_page(f), error = function(e) {
      log_error("解析 {basename(f)} 失败: {conditionMessage(e)}")
      tibble()
    })
  })

  log_info("合并完成，共 {nrow(all_data)} 条数据")
  all_data
}

# --- 主流程 ---
raw_data <- combine_all_pages()

if (nrow(raw_data) > 0) {
  # 保存原始数据
  readr::write_csv(raw_data, "data/raw/jobs_raw.csv")
  log_info("原始数据已保存到 data/raw/jobs_raw.csv")

  # 调用清洗流程
  source("scripts/clean.R")
  clean_data <- clean_all(raw_data)
  readr::write_csv(clean_data, "data/processed/jobs_clean.csv")
  log_info("清洗数据已保存到 data/processed/jobs_clean.csv")

  # 打印数据概览
  cat("\n=== 数据概览 ===\n")
  cat("总记录数:", nrow(clean_data), "\n")
  cat("字段数:  ", ncol(clean_data), "\n")
  cat("数据来源:", paste(unique(clean_data$source), collapse = ", "), "\n")
  cat("城市数:  ", n_distinct(clean_data$city), "\n")
  cat("关键词:  ", paste(unique(clean_data$keyword), collapse = ", "), "\n")
}
