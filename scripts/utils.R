# ============================================================
# utils.R —— 通用工具函数
# ============================================================
# 日志、重试、文件操作等不特定于某个模块的工具

library(glue)       # 字符串插值：glue("hello {name}", name="world")
library(jsonlite)   # JSON 读写
library(readr)      # 快速 CSV 读写

# --- 日志 ---
# 不用 print()，统一用 log_* 系列，方便以后改成写文件
log_info <- function(...) {
  msg <- glue(...)
  message(format(Sys.time(), "[%H:%M:%S] "), msg)
}

log_warn <- function(...) {
  msg <- glue(...)
  message(format(Sys.time(), "[%H:%M:%S] WARN: "), msg)
}

log_error <- function(...) {
  msg <- glue(...)
  message(format(Sys.time(), "[%H:%M:%S] ERROR: "), msg)
}

# --- 重试包装器 ---
# expr: 要执行的表达式
# max_retry: 最多重试几次
# delay: 每次重试前等多久（秒）
retry <- function(expr, max_retry = 3, delay = 2) {
  for (i in 1:max_retry) {
    result <- tryCatch(expr, error = function(e) e)
    if (!inherits(result, "error")) return(result)
    log_warn("第 {i} 次失败: {conditionMessage(result)}，{delay}秒后重试...")
    Sys.sleep(delay)
  }
  stop(glue("重试 {max_retry} 次后仍然失败"))
}

# --- CSV 读写 ---
# 保存数据框到 CSV，自动创建目录
save_csv <- function(df, path) {
  dir.create(dirname(path), showWarnings = FALSE, recursive = TRUE)
  readr::write_csv(df, path)
  log_info("已保存 {nrow(df)} 行到 {path}")
}

# 读取 CSV，自动判断文件是否存在
load_csv <- function(path) {
  if (!file.exists(path)) {
    log_warn("文件不存在: {path}")
    return(NULL)
  }
  readr::read_csv(path, show_col_types = FALSE)
}

# --- 清理文件名中的非法字符 ---
sanitize_filename <- function(x) {
  gsub("[/\\\\:*?\"<>|]", "_", x)
}
