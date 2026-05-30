# test_boss.R - 测试 BOSS直聘爬取

library(rvest)

url <- "https://www.zhipin.com/web/geek/job?query=数据分析实习&city=101010100"
cat("测试 URL:", url, "\n")

UA <- "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

tryCatch({
  # 直接用 read_html
  session <- read_html(url, encoding = "UTF-8")
  cat("页面读取成功\n")

  # 提取所有文本
  text <- html_text2(session)
  cat("文本长度:", nchar(text), "\n")

  # 打印前2000字符
  cat("文本前2000字符:\n", substr(text, 1, 2000), "\n")
}, error = function(e) {
  cat("错误:", conditionMessage(e), "\n")
})