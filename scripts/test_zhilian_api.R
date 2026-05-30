# test_zhilian_api.R - 测试智联招聘 API

library(httr)
library(jsonlite)

# 智联招聘 API 端点
api_url <- "https://fe-api.zhaopin.com/c/i/sou"

# 请求体
body <- list(
  kw = "数据分析实习",
  cityId = "530",
  workExperience = "-1",
  education = "-1",
  companyType = "-1",
  employmentType = "-1",
  jobWelfareTag = "-1",
  kt = "3",
  start = "0",
  pageSize = "90",
  rt = "5e4ee27b0f0942758f083e02c2557989",
  at = "a33a3f5b406a46e2b2f5e3a5e3b5e3a5"
)

cat("测试 API URL:", api_url, "\n")
cat("请求体:", toJSON(body, auto_unbox = TRUE), "\n\n")

tryCatch({
  resp <- POST(
    api_url,
    body = toJSON(body, auto_unbox = TRUE),
    encode = "raw",
    content_type_json(),
    user_agent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")
  )

  cat("状态码:", status_code(resp), "\n")
  cat("内容类型:", content_type(resp), "\n")

  # 解析响应
  resp_text <- content(resp, as = "text", encoding = "UTF-8")
  cat("响应长度:", nchar(resp_text), "\n")

  # 尝试解析 JSON
  tryCatch({
    data <- fromJSON(resp_text)
    cat("响应结构:", paste(names(data), collapse=", "), "\n")

    if (!is.null(data$result$data)) {
      cat("找到", length(data$result$data), "条岗位\n")
      # 打印前3条岗位
      for (i in 1:min(3, length(data$result$data))) {
        job <- data$result$data[[i]]
        cat(sprintf("  %d. %s - %s (%s)\n", i, job$jobName, job$salary, job$company$companyName))
      }
    }
  }, error = function(e) {
    cat("JSON 解析错误:", conditionMessage(e), "\n")
    cat("响应前500字符:", substr(resp_text, 1, 500), "\n")
  })
}, error = function(e) {
  cat("请求错误:", conditionMessage(e), "\n")
})
