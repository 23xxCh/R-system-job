# ============================================================
# scrape_with_kimi.R —— 用 kimi-webbridge 批量爬取实习岗位
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

# --- 提取岗位数据的 JavaScript 代码 ---
EXTRACT_JS <- '(() => {
  const items = document.querySelectorAll(".joblist-box__item");
  const jobs = [];
  items.forEach(item => {
    const nameEl = item.querySelector(".jobinfo__name");
    const salaryEl = item.querySelector(".jobinfo__salary");
    const companyEl = item.querySelector(".companyinfo__name");
    const infoItems = item.querySelectorAll(".jobinfo__other-info-item");
    const tags = item.querySelectorAll(".joblist-box__item-tag");
    const job = {
      t: nameEl ? nameEl.textContent.trim() : "",
      s: salaryEl ? salaryEl.textContent.trim() : "",
      cp: companyEl ? companyEl.textContent.trim() : "",
      ci: infoItems[0] ? infoItems[0].textContent.trim() : "",
      e: infoItems[1] ? infoItems[1].textContent.trim() : "",
      ed: infoItems[2] ? infoItems[2].textContent.trim() : "",
      sz: tags[0] ? tags[0].textContent.trim() : "",
      in: tags[1] ? tags[1].textContent.trim() : "",
      src: "智联招聘",
      kw: ""
    };
    jobs.push(job);
  });
  return JSON.stringify(jobs);
})()'

# --- 爬取函数 ---
scrape_page <- function(url, keyword, session_name) {
  cat("爬取:", keyword, "@", url, "\n")

  # 导航到页面
  nav_cmd <- sprintf(
    'curl -s -X POST http://127.0.0.1:10086/command -H "Content-Type: application/json" -d \'{"action":"navigate","args":{"url":"%s","newTab":true},"session":"%s"}\'',
    url, session_name
  )
  system(nav_cmd, intern = TRUE)

  # 等待页面加载
  Sys.sleep(3)

  # 提取数据
  extract_cmd <- sprintf(
    'curl -s -X POST http://127.0.0.1:10086/command -H "Content-Type: application/json" -d \'{"action":"evaluate","args":{"code":"%s"},"session":"%s"}\'',
    gsub('"', '\\"', EXTRACT_JS),
    session_name
  )
  result <- system(extract_cmd, intern = TRUE)

  # 解析结果
  tryCatch({
    resp <- fromJSON(result)
    if (resp$ok && !is.null(resp$data$value)) {
      jobs <- fromJSON(resp$data$value)
      if (nrow(jobs) > 0) {
        jobs$kw <- keyword
        cat("  成功:", nrow(jobs), "条岗位\n")
        return(jobs)
      }
    }
    cat("  未找到岗位数据\n")
    return(NULL)
  }, error = function(e) {
    cat("  解析失败:", conditionMessage(e), "\n")
    return(NULL)
  })
}

# --- 主流程 ---
all_results <- list()
task_count <- 0

for (city_name in names(CITY_CODES)) {
  city_code <- CITY_CODES[city_name]

  for (kw in INTERN_KEYWORDS) {
    for (page in 1:2) {
      task_count <- task_count + 1
      session_name <- paste0("intern-", task_count)

      url <- sprintf("https://sou.zhaopin.com/?jl=%s&kw=%s&p=%d",
                     city_code, URLencode(kw), page)

      jobs <- scrape_page(url, kw, session_name)

      if (!is.null(jobs) && nrow(jobs) > 0) {
        all_results[[length(all_results) + 1]] <- jobs
      }

      # 随机延时
      Sys.sleep(runif(1, 2, 4))
    }
  }
}

# --- 合并保存 ---
if (length(all_results) > 0) {
  combined <- bind_rows(all_results)

  # 保存为 JSON
  output_file <- "data/raw/page_intern_all.json"
  write_json(combined, output_file, pretty = TRUE, auto_unbox = TRUE)

  cat("\n爬取完成！\n")
  cat("共爬取:", nrow(combined), "条实习岗位数据\n")
  cat("已保存到:", output_file, "\n")
} else {
  cat("\n未爬取到任何数据\n")
}
