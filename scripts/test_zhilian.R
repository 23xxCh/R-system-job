# test_zhilian.R - 测试智联招聘爬取

library(rvest)

url <- "https://sou.zhaopin.com/?jl=530&kw=数据分析实习&p=1"
cat("测试 URL:", url, "\n")

UA <- "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

tryCatch({
  # 直接用 read_html
  session <- read_html(url, encoding = "UTF-8")
  cat("页面读取成功\n")

  # 提取所有文本
  text <- html_text2(session)
  cat("文本长度:", nchar(text), "\n")

  # 检查是否包含 __INITIAL_STATE__
  if (grepl("__INITIAL_STATE__", text)) {
    cat("找到 __INITIAL_STATE__\n")
  } else {
    cat("未找到 __INITIAL_STATE__\n")
    # 打印前1000字符
    cat("文本前1000字符:\n", substr(text, 1, 1000), "\n")
  }
}, error = function(e) {
  cat("错误:", conditionMessage(e), "\n")
})
