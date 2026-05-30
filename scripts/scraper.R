# ============================================================
# scraper.R —— 多站点爬虫主模块
# ============================================================
# 工作流程：
#   1. 生成爬取任务列表（关键词 × 城市 × 网站）
#   2. 调用浏览器自动化抓取页面 HTML
#   3. 解析 HTML 提取结构化岗位数据
#   4. 合并保存为 CSV
#
# 依赖：config.R, utils.R, rvest

library(rvest)      # HTML 解析核心包
library(dplyr)      # 数据操作
library(purrr)      # 函数式编程工具
library(stringr)    # 字符串处理

source("config.R")
source("scripts/utils.R")

# ============================================================
# 1. 任务生成
# ============================================================
# 把 "关键词 × 城市 × 网站" 展开成一个任务表
generate_tasks <- function(keywords = KEYWORDS,
                           cities   = CITIES,
                           sources  = SOURCES) {
  tasks <- expand.grid(
    keyword = keywords,
    city    = stringsAsFactors = FALSE,
    stringsAsFactors = FALSE
  )
  # 为每个任务分配唯一 ID
  tasks$task_id <- seq_len(nrow(tasks))
  tasks$timestamp <- Sys.time()
  log_info("生成 {nrow(tasks)} 个爬取任务")
  tasks
}

# ============================================================
# 2. 页面抓取（浏览器自动化层）
# ============================================================
# 这一层负责拿到 HTML，具体实现可以替换：
#   - fetch_with_browser(): 调用 kimi-webbridge 浏览器自动化
#   - fetch_with_rvest():   直接 HTTP 请求（简单页面用这个）

# --- 方式 A: 浏览器自动化 ---
# 将任务写入 JSON，由外部浏览器脚本执行
fetch_with_browser <- function(url, output_path) {
  # 写一个任务文件给浏览器脚本
  task <- list(
    url         = url,
    output_file = output_path,
    action      = "scrape",
    wait_for    = ".joblist"  # 等待页面这个元素出现
  )
  task_json <- toJSON(task, auto_unbox = TRUE)
  task_file  <- tempfile(fileext = ".json")
  writeLines(task_json, task_file)

  log_info("浏览器抓取: {url}")
  # 调用浏览器自动化脚本（见 scripts/browser_fetch.sh）
  system2("bash", args = c("scripts/browser_fetch.sh", task_file),
          wait = TRUE, stdout = TRUE, stderr = TRUE)

  if (file.exists(output_path)) {
    return(read_html(output_path, encoding = "UTF-8"))
  }
  log_error("浏览器抓取失败: {url}")
  return(NULL)
}

# --- 方式 B: 直接 HTTP 请求（备用） ---
# 适合没有 JS 渲染的简单页面
fetch_with_http <- function(url, user_agent = NULL) {
  if (is.null(user_agent)) {
    user_agent <- "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
  }
  log_info("HTTP 抓取: {url}")
  tryCatch({
    read_html(url, encoding = "UTF-8",
              httr::add_headers(`User-Agent` = user_agent))
  }, error = function(e) {
    log_error("HTTP 请求失败: {conditionMessage(e)}")
    NULL
  })
}

# ============================================================
# 3. 各网站解析器
# ============================================================
# 每个网站的 HTML 结构不同，需要单独写解析函数
# 返回统一格式的数据框：岗位名、公司、薪资、城市、学历、经验、描述...

# --- 智联招聘解析器 ---
parse_zhilian <- function(html) {
  if (is.null(html)) return(tibble())

  tryCatch({
    # 提取岗位卡片列表
    cards <- html %>% html_elements(".joblist-box__item")

    # 逐个卡片提取字段
    map_dfr(cards, function(card) {
      tibble(
        job_title    = card %>% html_element(".jobinfo__name") %>% html_text2() %>% str_trim(),
        company      = card %>% html_element(".companyinfo__name") %>% html_text2() %>% str_trim(),
        salary       = card %>% html_element(".jobinfo__salary") %>% html_text2() %>% str_trim(),
        city         = card %>% html_element(".jobinfo__other span:nth-child(1)") %>% html_text2(),
        education    = card %>% html_element(".jobinfo__other span:nth-child(2)") %>% html_text2(),
        experience   = card %>% html_element(".jobinfo__other span:nth-child(3)") %>% html_text2(),
        company_size = card %>% html_element(".companyinfo__other span") %>% html_text2(),
        industry     = NA_character_,  # 智联不在列表页显示行业
        description  = NA_character_,
        source       = "智联招聘",
        scraped_at   = Sys.time()
      )
    })
  }, error = function(e) {
    log_error("智联解析失败: {conditionMessage(e)}")
    tibble()
  })
}

# --- BOSS直聘解析器 ---
parse_boss <- function(html) {
  if (is.null(html)) return(tibble())

  tryCatch({
    cards <- html %>% html_elements(".job-card-wrapper")

    map_dfr(cards, function(card) {
      tibble(
        job_title    = card %>% html_element(".job-name") %>% html_text2() %>% str_trim(),
        company      = card %>% html_element(".company-name") %>% html_text2() %>% str_trim(),
        salary       = card %>% html_element(".salary") %>% html_text2() %>% str_trim(),
        city         = card %>% html_element(".job-area") %>% html_text2(),
        education    = card %>% html_element(".tag-list li:nth-child(2)") %>% html_text2(),
        experience   = card %>% html_element(".tag-list li:nth-child(1)") %>% html_text2(),
        company_size = card %>% html_element(".company-tag-list li:nth-child(1)") %>% html_text2(),
        industry     = card %>% html_element(".company-tag-list li:nth-child(2)") %>% html_text2(),
        description  = NA_character_,
        source       = "BOSS直聘",
        scraped_at   = Sys.time()
      )
    })
  }, error = function(e) {
    log_error("BOSS解析失败: {conditionMessage(e)}")
    tibble()
  })
}

# --- 前程无忧解析器 ---
parse_job51 <- function(html) {
  if (is.null(html)) return(tibble())

  tryCatch({
    cards <- html %>% html_elements(".j_joblist .e_box")

    map_dfr(cards, function(card) {
      tibble(
        job_title    = card %>% html_element(".jname a") %>% html_text2() %>% str_trim(),
        company      = card %>% html_element(".cname a") %>% html_text2() %>% str_trim(),
        salary       = card %>% html_element(".sal") %>% html_text2() %>% str_trim(),
        city         = card %>% html_element(".info span:nth-child(1)") %>% html_text2(),
        education    = card %>% html_element(".info span:nth-child(2)") %>% html_text2(),
        experience   = card %>% html_element(".info span:nth-child(3)") %>% html_text2(),
        company_size = NA_character_,
        industry     = card %>% html_element(".dc") %>% html_text2(),
        description  = NA_character_,
        source       = "前程无忧",
        scraped_at   = Sys.time()
      )
    })
  }, error = function(e) {
    log_error("前程无忧解析失败: {conditionMessage(e)}")
    tibble()
  })
}

# --- 解析器路由 ---
# 根据网站名称调用对应的解析函数
parse_page <- function(html, source_name) {
  switch(source_name,
    "智联招聘" = parse_zhilian(html),
    "BOSS直聘" = parse_boss(html),
    "前程无忧" = parse_job51(html),
    {
      log_warn("未知数据源: {source_name}")
      tibble()
    }
  )
}

# ============================================================
# 4. 主爬取流程
# ============================================================
# 单个任务的完整流程：抓取 → 解析 → 返回数据框
scrape_one <- function(keyword, city, source_name, url_template, delay_range) {
  # 构造搜索 URL
  url <- gsub("\\{keyword\\}", URLencode(keyword, reserved = TRUE), url_template)
  url <- gsub("\\{city\\}", URLencode(city, reserved = TRUE), url)

  log_info("开始爬取: [{source_name}] {keyword} @ {city}")

  # 抓取页面（根据 source 选择方式）
  html <- fetch_with_http(url)

  if (is.null(html)) {
    log_warn("跳过: [{source_name}] {keyword} @ {city}")
    return(tibble())
  }

  # 解析
  result <- parse_page(html, source_name)

  # 补充搜索条件字段（方便后续分析）
  result$search_keyword <- keyword
  result$search_city    <- city

  # 随机延时，避免被封
  wait <- runif(1, delay_range[1], delay_range[2])
  log_info("等待 {round(wait, 1)} 秒...")
  Sys.sleep(wait)

  result
}

# 批量爬取所有任务
scrape_all <- function(tasks, sources = SOURCES) {
  all_results <- list()

  for (i in seq_len(nrow(tasks))) {
    task <- tasks[i, ]
    log_info("进度: {i}/{nrow(tasks)}")

    for (src_name in names(sources)) {
      src <- sources[[src_name]]
      if (!src$enabled) next

      result <- tryCatch(
        scrape_one(task$keyword, task$city, src$name, src$url_tpl, src$delay),
        error = function(e) {
          log_error("任务失败: {conditionMessage(e)}")
          tibble()
        }
      )

      if (nrow(result) > 0) {
        all_results[[length(all_results) + 1]] <- result
      }
    }
  }

  # 合并所有结果
  combined <- bind_rows(all_results)
  log_info("爬取完成，共 {nrow(combined)} 条岗位数据")
  combined
}
