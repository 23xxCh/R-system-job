# check_intern.R - 检查现有实习数据

library(dplyr)
library(stringr)

setwd("E:/Show work/R-system")

# 读取现有数据
df <- read.csv("data/processed/jobs_clean.csv", stringsAsFactors = FALSE)
cat("现有数据:", nrow(df), "条\n")

# 查找实习相关岗位
intern <- df %>% filter(str_detect(job_title, "实习"))
cat("实习岗位:", nrow(intern), "条\n")

if (nrow(intern) > 0) {
  cat("\n实习岗位示例:\n")
  print(head(intern %>% select(job_title, salary, company, city), 10))
}
