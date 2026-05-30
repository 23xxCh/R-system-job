# ============================================================
# main.R —— 主运行脚本
# ============================================================
# 整个项目的入口，按顺序执行：
#   1. 安装缺失的包
#   2. 生成爬取任务
#   3. 执行爬取
#   4. 清洗数据
#   5. 启动仪表板（可选）
#
# 使用方式：
#   在 RStudio 中打开，逐段执行（推荐初学者）
#   或者：source("scripts/main.R")

# ============================================================
# Step 0: 安装依赖包
# ============================================================
# 只安装缺失的包，已有的跳过
install_if_missing <- function(packages) {
  new_packages <- packages[!(packages %in% installed.packages()[, "Package"])]
  if (length(new_packages) > 0) {
    message("正在安装: ", paste(new_packages, collapse = ", "))
    install.packages(new_packages)
  }
}

# 项目用到的所有包
required_packages <- c(
  # 数据操作
  "dplyr", "tidyr", "purrr", "readr", "stringr",
  # 爬虫
  "rvest", "httr", "xml2",
  # 可视化
  "ggplot2", "plotly", "scales",
  # Shiny 仪表板
  "shiny", "DT", "wordcloud2",
  # 工具
  "glue", "jsonlite"
)

install_if_missing(required_packages)
message("依赖包检查完成")

# ============================================================
# Step 1: 加载配置和模块
# ============================================================
source("config.R")
source("scripts/utils.R")
source("scripts/scraper.R")
source("scripts/clean.R")

# ============================================================
# Step 2: 生成爬取任务
# ============================================================
# 调整 config.R 中的 KEYWORDS 和 CITIES 来控制范围
# 初次运行建议先用少量关键词测试
tasks <- generate_tasks(
  keywords = KEYWORDS[1:3],   # 先只跑前 3 个关键词测试
  cities   = CITIES[1:4]      # 先只跑 4 个城市
)

# ============================================================
# Step 3: 执行爬取
# ============================================================
# 注意：这一步可能需要较长时间，取决于网站反爬和网络状况
# 首次运行建议先手动测试单个 URL 能否正常抓取
raw_data <- scrape_all(tasks)

# 保存原始数据
if (nrow(raw_data) > 0) {
  save_csv(raw_data, file.path(RAW_DIR, "jobs_raw.csv"))
}

# ============================================================
# Step 4: 清洗数据
# ============================================================
if (nrow(raw_data) > 0) {
  clean_data <- clean_all(raw_data)
  save_csv(clean_data, file.path(PROCESSED_DIR, "jobs_clean.csv"))
  message("数据清洗完成，共 ", nrow(clean_data), " 条有效数据")
}

# ============================================================
# Step 5: 启动仪表板
# ============================================================
# 取消注释下面这行来启动 Shiny 应用
# shiny::runApp(".", port = SHINY_PORT, launch.browser = TRUE)

message("全部完成！运行 shiny::runApp('.') 或打开 app.R 点击 Run App 启动仪表板")
