library(jsonlite)
library(dplyr)
library(readr)
library(stringr)
library(purrr)

setwd("E:/Show work/R-system")

json_files <- list.files("data/raw", pattern="\\.json$", full.names=TRUE)
cat("找到", length(json_files), "个 JSON 文件\n")

all_data <- list()
for (f in json_files) {
  raw <- fromJSON(f, flatten=TRUE)
  df <- tibble(
    job_title    = raw$t,
    salary       = raw$s,
    company      = raw$cp,
    city         = raw$ci,
    experience   = raw$e,
    education    = raw$ed,
    company_size = raw$sz,
    industry     = raw$`in`,
    source       = raw$src,
    keyword      = raw$kw
  )
  all_data[[basename(f)]] <- df
}

combined <- bind_rows(all_data)
cat("合并完成，共", nrow(combined), "条数据\n")

cleaned <- combined %>%
  mutate(
    salary = str_squish(salary),
    company = str_squish(company),
    city = str_extract(city, "^.{2,4}") %>% coalesce(city),
    education = case_when(
      str_detect(education, "硕士") ~ "硕士",
      str_detect(education, "本科") ~ "本科",
      str_detect(education, "大专") ~ "大专",
      TRUE ~ education
    ),
    experience_years = as.numeric(str_extract(experience, "\\d+"))
  )

parse_sal <- function(s) {
  if (is.na(s) || s == "面议") return(tibble(salary_min=NA_real_, salary_max=NA_real_))
  nums <- str_extract_all(s, "\\d+")[[1]]
  if (str_detect(s, "万")) {
    nums <- as.numeric(nums)
    if (length(nums) >= 2) return(tibble(salary_min=nums[1]*10000/12, salary_max=nums[2]*10000/12))
  }
  if (length(nums) >= 2) return(tibble(salary_min=as.numeric(nums[1]), salary_max=as.numeric(nums[2])))
  tibble(salary_min=NA_real_, salary_max=NA_real_)
}

sal_parsed <- map_dfr(cleaned$salary, parse_sal)
cleaned <- bind_cols(cleaned, sal_parsed) %>% mutate(salary_avg = (salary_min + salary_max) / 2)

readr::write_csv(cleaned, "data/processed/jobs_clean.csv")
cat("清洗数据已保存，共", nrow(cleaned), "行，", ncol(cleaned), "列\n")
cat("\n字段:", paste(names(cleaned), collapse=", "), "\n")
cat("\n前5条数据:\n")
print(head(cleaned %>% select(job_title, salary, company, city, education, salary_avg), 5))
