# ============================================================
# save_intern_data.R —— 保存实习岗位数据
# ============================================================

library(jsonlite)
library(dplyr)

setwd("E:/Show work/R-system")

# 读取所有实习批次数据
batch_files <- list.files("data/raw", pattern = "page_intern_batch_.*\\.json$", full.names = TRUE)
cat("找到", length(batch_files), "个实习批次文件\n")

all_data <- list()
for (f in batch_files) {
  raw <- fromJSON(f)
  if (nrow(raw) > 0) {
    all_data[[basename(f)]] <- raw
  }
}

# 合并数据
if (length(all_data) > 0) {
  combined <- bind_rows(all_data)
  cat("合并完成，共", nrow(combined), "条实习岗位数据\n")

  # 保存为新的 JSON 文件
  output_file <- "data/raw/page_intern_all.json"
  write_json(combined, output_file, pretty = TRUE, auto_unbox = TRUE)
  cat("已保存到:", output_file, "\n")

  # 显示数据概览
  cat("\n数据概览:\n")
  cat("总岗位数:", nrow(combined), "\n")
  cat("城市分布:\n")
  print(table(combined$ci))
  cat("\n关键词分布:\n")
  print(table(combined$kw))
} else {
  cat("未找到实习数据\n")
}
