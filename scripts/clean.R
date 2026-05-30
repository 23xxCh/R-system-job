# ============================================================
# clean.R —— 数据清洗与加工
# ============================================================
# 原始爬取数据 → 清洗 → 标准化 → 特征工程 → 可用于分析的干净数据
#
# 薪资字段是最复杂的：各网站格式不同，需要统一解析
#   "15-25K"  "15-25K·15薪"  "15000-25000元/月"  "面议"

library(dplyr)
library(tidyr)      # 数据整形：separate(), unnest()
library(stringr)    # 字符串处理
library(readr)      # 类型转换

source("config.R")
source("scripts/utils.R")

# ============================================================
# 1. 薪资解析
# ============================================================
# 把各种薪资格式统一成：salary_min, salary_max, salary_unit（月/年）
# 这是整个清洗模块最难的部分

parse_salary <- function(salary_text) {
  if (is.na(salary_text) || salary_text == "面议" || salary_text == "") {
    return(list(min = NA_real_, max = NA_real_, unit = "月", k_value = FALSE))
  }

  text <- salary_text %>% str_trim()

  # 模式 1: "15-25K" 或 "15-25k"（单位：千元/月）
  if (str_detect(text, regex("^\\d+[-~]\\d+[kK]$", ignore_case = TRUE))) {
    nums <- str_extract_all(text, "\\d+")[[1]]
    return(list(
      min   = as.numeric(nums[1]) * 1000,
      max   = as.numeric(nums[2]) * 1000,
      unit  = "月",
      k_value = TRUE
    ))
  }

  # 模式 2: "15-25K·15薪"（年薪制，乘以薪数）
  if (str_detect(text, regex("\\d+[-~]\\d+[kK][·.xX×]\\d+薪", ignore_case = TRUE))) {
    nums  <- str_extract_all(text, "\\d+")[[1]]
    months <- as.numeric(nums[3])  # 薪数（如 15 薪）
    return(list(
      min   = as.numeric(nums[1]) * 1000 * months / 12,
      max   = as.numeric(nums[2]) * 1000 * months / 12,
      unit  = "月",
      k_value = TRUE
    ))
  }

  # 模式 3: "15000-25000元/月"
  if (str_detect(text, "元/月")) {
    nums <- str_extract_all(text, "\\d+")[[1]]
    return(list(
      min   = as.numeric(nums[1]),
      max   = as.numeric(nums[2]),
      unit  = "月",
      k_value = FALSE
    ))
  }

  # 模式 4: "10-20万/年"
  if (str_detect(text, "万/年")) {
    nums <- str_extract_all(text, "[\\d.]+")[[1]]
    return(list(
      min   = as.numeric(nums[1]) * 10000 / 12,
      max   = as.numeric(nums[2]) * 10000 / 12,
      unit  = "月",
      k_value = FALSE
    ))
  }

  # 兜底：提取所有数字，假设是月薪
  nums <- str_extract_all(text, "\\d+")[[1]]
  if (length(nums) >= 2) {
    return(list(
      min   = as.numeric(nums[1]),
      max   = as.numeric(nums[2]),
      unit  = "月",
      k_value = FALSE
    ))
  }

  list(min = NA_real_, max = NA_real_, unit = "月", k_value = FALSE)
}

# 批量解析薪资列，返回带 salary_min, salary_max 的数据框
add_salary_columns <- function(df) {
  parsed <- map_dfr(df$salary, function(s) {
    result <- parse_salary(s)
    tibble(salary_min = result$min, salary_max = result$max)
  })
  bind_cols(df, parsed) %>%
    mutate(
      salary_avg = (salary_min + salary_max) / 2  # 平均薪资，方便画图
    )
}

# ============================================================
# 2. 文本清洗
# ============================================================
clean_text <- function(df) {
  df %>%
    mutate(
      # 去除岗位名中的多余空白和特殊字符
      job_title = str_squish(job_title) %>% str_replace_all("[\\[\\]【】]", ""),
      # 公司名去空白
      company = str_squish(company),
      # 城市标准化（去掉区域，只留城市名）
      city = str_extract(city, "^[\\u4e00-\\u9fa5]{2,4}") %>% coalesce(city),
      # 学历标准化
      education = case_when(
        str_detect(education, "博士") ~ "博士",
        str_detect(education, "硕士") ~ "硕士",
        str_detect(education, "本科") ~ "本科",
        str_detect(education, "大专") ~ "大专",
        str_detect(education, "不限") ~ "不限",
        TRUE ~ education
      ),
      # 经验标准化（提取数字）
      experience_years = str_extract(experience, "\\d+") %>% as.numeric()
    )
}

# ============================================================
# 3. 技能关键词提取
# ============================================================
# 从岗位描述中提取常见技能关键词，用于词云和热度分析
SKILL_KEYWORDS <- c(
  "Python", "R", "SQL", "Java", "C\\+\\+", "Go", "JavaScript",
  "TensorFlow", "PyTorch", "Keras", "Spark", "Hadoop", "Hive",
  "Tableau", "Power BI", "Excel", "SAS", "SPSS", "MATLAB",
  "机器学习", "深度学习", "NLP", "自然语言处理", "计算机视觉",
  "数据分析", "数据挖掘", "数据仓库", "ETL", "A/B测试",
  "统计学", "线性回归", "决策树", "随机森林", "XGBoost",
  "MySQL", "PostgreSQL", "MongoDB", "Redis", "Elasticsearch",
  "Docker", "Kubernetes", "Linux", "Git", "CI/CD"
)

extract_skills <- function(description) {
  if (is.na(description)) return("")
  matched <- str_extract_all(description, regex(paste(SKILL_KEYWORDS, collapse = "|"), ignore_case = TRUE))[[1]]
  paste(unique(matched), collapse = ",")
}

add_skills_column <- function(df) {
  if ("description" %in% names(df)) {
    df$skills <- map_chr(df$description, extract_skills)
  }
  df
}

# ============================================================
# 4. 主清洗流程
# ============================================================
clean_all <- function(raw_df) {
  log_info("开始清洗，原始数据 {nrow(raw_df)} 行")

  cleaned <- raw_df %>%
    # 去重（同一岗位可能被多个关键词搜到）
    distinct(job_title, company, city, .keep_all = TRUE) %>%
    # 文本清洗
    clean_text() %>%
    # 薪资解析
    add_salary_columns() %>%
    # 技能提取
    add_skills_column() %>%
    # 去掉完全没有薪资信息的行（可选：保留用于统计面议比例）
    # filter(!is.na(salary_min)) %>%
    arrange(desc(salary_avg))

  log_info("清洗完成，剩余 {nrow(cleaned)} 行")
  cleaned
}
