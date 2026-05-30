# ============================================================
# scrape_intern_batch.R —— 批量爬取实习岗位（kimi-webbridge 版）
# ============================================================

library(jsonlite)
library(dplyr)
library(stringr)

setwd("E:/Show work/R-system")

# --- 读取任务列表 ---
tasks_file <- "data/intern_scrape_tasks.json"
if (!file.exists(tasks_file)) {
  cat("任务文件不存在，请先运行 scrape_intern_kimi.R 生成任务列表\n")
  stop("任务文件不存在")
}

tasks <- fromJSON(tasks_file, flatten = TRUE)
cat("共", nrow(tasks), "个爬取任务\n\n")

# --- 爬取函数（需要 kimi-webbridge） ---
scrape_one_task <- function(task) {
  cat("爬取:", task$keyword, "@", task$city, "第", task$page, "页\n")

  tryCatch {
    # 导航到页面
    system2("npx", args = c("kimi-webbridge", "navigate", "--url", shQuote(task$url)))

    # 等待页面加载
    Sys.sleep(3)

    # 提取数据
    js_code <- '
    const jobs = [];
    document.querySelectorAll(".joblist-box__item").forEach(item => {
      const job = {
        t: item.querySelector(".jobinfo__name")?.textContent?.trim() || "",
        s: item.querySelector(".jobinfo__salary")?.textContent?.trim() || "",
        cp: item.querySelector(".companyinfo__name")?.textContent?.trim() || "",
        ci: item.querySelector(".jobinfo__other-info-item")?.textContent?.trim() || "",
        e: item.querySelector(".jobinfo__other-info-item:nth-child(2)")?.textContent?.trim() || "",
        ed: item.querySelector(".jobinfo__other-info-item:nth-child(3)")?.textContent?.trim() || "",
        sz: item.querySelector(".companyinfo__tag")?.textContent?.trim() || "",
        in: item.querySelector(".companyinfo__industry")?.textContent?.trim() || "",
        src: "智联招聘",
        kw: "' + task$keyword + '"
      };
      jobs.push(job);
    });
    return JSON.stringify(jobs);
    '

    result <- system2("npx", args = c("kimi-webbridge", "evaluate", "--script", js_code),
                      stdout = TRUE, stderr = FALSE)

    if (!is.null(result) && nchar(result) > 0) {
      jobs <- fromJSON(result)
      if (nrow(jobs) > 0) {
        # 保存为 JSON
        write_json(jobs, task$output_file, pretty = TRUE, auto_unbox = TRUE)
        cat("  成功:", nrow(jobs), "条岗位\n")
        return(TRUE)
      }
    }

    cat("  未找到岗位数据\n")
    return(FALSE)
  }, error = function(e) {
    cat("  爬取失败:", conditionMessage(e), "\n")
    return(FALSE)
  })
}

# --- 批量爬取 ---
success_count <- 0
for (i in 1:nrow(tasks)) {
  task <- tasks[i, ]

  # 检查是否已爬取
  if (file.exists(task$output_file)) {
    cat("跳过（已存在）:", task$keyword, "@", task$city, "\n")
    success_count <- success_count + 1
    next
  }

  # 爬取
  result <- scrape_one_task(task)
  if (result) success_count <- success_count + 1

  # 随机延时
  Sys.sleep(runif(1, 2, 4))
}

cat("\n爬取完成！成功:", success_count, "/", nrow(tasks), "\n")
