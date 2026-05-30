# test_lagou.R - 测试拉勾网爬取

library(rvest)

# 拉勾网实习页面
url <- "https://www.lagou.com/wn/zhaopin?kd=数据分析实习&city=%E5%8C%97%E4%BA%AC"
cat("测试 URL:", url, "\n")

UA <- "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

tryCatch({
  session <- read_html(url, encoding = "UTF-8")
  cat("页面读取成功\n")

  text <- html_text2(session)
  cat("文本长度:", nchar(text), "\n")

  # 打印前2000字符
  cat("文本前2000字符:\n", substr(text, 1, 2000), "\n")
}, error = function(e) {
  cat("错误:", conditionMessage(e), "\n")
})