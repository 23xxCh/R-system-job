# ============================================================
# config.R —— 项目全局配置
# ============================================================
# 所有可调参数集中在这里，改配置只改这一个文件

# --- 岗位搜索关键词 ---
# 每个关键词会单独发起一次爬取任务
KEYWORDS <- c(
  "数据分析师",
  "数据工程师",
  "数据科学家",
  "前端开发",
  "后端开发",
  "Java开发",
  "Python开发",
  "R语言",
  "统计分析",
  "生物统计",
  "智能制造工程师",
  "AI应用工程师",
  "AI agent开发",
  "数字化工程师",
  "机械工程师"
)

# --- 目标城市 ---
# 一线 + 新一线城市，用于构造搜索 URL
CITIES <- c(
  "北京", "上海", "广州", "深圳",           # 一线城市
  "杭州", "成都", "武汉", "南京",           # 新一线
  "重庆", "西安", "苏州", "天津",
  "长沙", "郑州", "东莞", "青岛"
)

# --- 数据源配置 ---
# 每个网站的搜索 URL 模板和解析规则
SOURCES <- list(
  zhilian = list(
    name     = "智联招聘",
    # {keyword} 和 {city} 会被实际值替换
    url_tpl  = "https://sou.zhaopin.com/?jl=854&kw={keyword}&p=1",
    enabled  = TRUE,
    delay    = c(2, 5)   # 请求间隔（秒），随机取 [min, max]
  ),
  boss = list(
    name     = "BOSS直聘",
    url_tpl  = "https://www.zhipin.com/web/geek/job?query={keyword}&city=100010000",
    enabled  = TRUE,
    delay    = c(3, 8)
  ),
  job51 = list(
    name     = "前程无忧",
    url_tpl  = "https://search.51job.com/list/000000,000000,0000,00,9,99,{keyword},2,1.html",
    enabled  = TRUE,
    delay    = c(2, 5)
  )
)

# --- 数据存储 ---
DATA_DIR      <- file.path("data")
RAW_DIR       <- file.path(DATA_DIR, "raw")
PROCESSED_DIR <- file.path(DATA_DIR, "processed")
OUTPUT_DIR    <- "output"

# --- 爬取控制 ---
MAX_PAGES_PER_SEARCH <- 3    # 每个关键词最多爬几页
MAX_RETRY            <- 3    # 请求失败重试次数
TIMEOUT_SEC          <- 30   # 页面加载超时（秒）

# --- Shiny 仪表板 ---
SHINY_PORT <- 3838             # 本地端口
