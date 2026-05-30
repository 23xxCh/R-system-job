# ============================================================
# app.R —— Shiny 交互式仪表板
# ============================================================
# 功能：
#   Tab1: 城市分布 —— 各城市岗位数量柱状图
#   Tab2: 薪资分析 —— 薪资分布直方图 + 按学历/经验箱线图
#   Tab3: 行业热度 —— 技能关键词词云 + 行业分布饼图
#   Tab4: 岗位搜索 —— 按条件筛选，导出结果
#
# 运行方式：在 RStudio 中打开此文件，点击 "Run App" 按钮
# 或者在控制台执行：shiny::runApp("E:/Show work/R-system")

library(shiny)          # Web 应用框架
library(dplyr)          # 数据操作
library(ggplot2)        # 绑图
library(plotly)         # 交互式图表（悬停、缩放）
library(DT)             # 交互式数据表格（搜索、排序、分页）
library(wordcloud2)     # 词云
library(scales)         # 美化坐标轴（如 comma, dollar）
library(stringr)        # 字符串处理（str_detect 等）

source("config.R")
source("scripts/utils.R")
source("scripts/clean.R")

# ============================================================
# 数据加载
# ============================================================
# 启动时读取清洗后的数据
load_data <- function() {
  path <- file.path(PROCESSED_DIR, "jobs_clean.csv")
  if (file.exists(path)) {
    load_csv(path)
  } else {
    # 如果没有清洗数据，尝试加载原始数据
    raw_path <- file.path(RAW_DIR, "jobs_raw.csv")
    if (file.exists(raw_path)) {
      raw <- load_csv(raw_path)
      clean_all(raw)
    } else {
      # 返回空数据框，避免 UI 报错
      data.frame(
        job_title = character(), company = character(),
        salary = character(), city = character(),
        education = character(), experience = character(),
        source = character(), stringsAsFactors = FALSE
      )
    }
  }
}

# ============================================================
# UI 定义
# ============================================================
ui <- fluidPage(
  # --- 标题 ---
  titlePanel("求职市场数据分析仪表板"),

  # --- 侧边栏：筛选条件 ---
  sidebarLayout(
    sidebarPanel(
      width = 3,
      h4("筛选条件"),

      # 数据源选择
      checkboxGroupInput("source_filter", "数据来源",
        choices  = c("智联招聘", "BOSS直聘", "前程无忧"),
        selected = c("智联招聘", "BOSS直聘", "前程无忧")
      ),

      # 城市选择（从数据中动态获取）
      selectInput("city_filter", "城市",
        choices  = c("全部", CITIES),
        selected = "全部"
      ),

      # 学历要求
      checkboxGroupInput("edu_filter", "学历要求",
        choices  = c("博士", "硕士", "本科", "大专", "不限"),
        selected = c("博士", "硕士", "本科", "大专", "不限")
      ),

      # 实习岗位筛选
      checkboxInput("intern_filter", "仅显示实习岗位", value = FALSE),

      # 薪资范围滑块
      sliderInput("salary_filter", "月薪范围（千元）",
        min = 0, max = 100, value = c(0, 100), step = 5,
        post = "K"
      ),

      # 关键词搜索（用于 Tab4）
      textInput("keyword_search", "搜索关键词", placeholder = "如：Python, 机器学习"),

      hr(),
      # 刷新数据按钮
      actionButton("refresh", "刷新数据", class = "btn-primary btn-sm"),
      br(), br(),
      # 数据统计
      textOutput("data_stats")
    ),

    # --- 主面板：分析图表 ---
    mainPanel(
      width = 9,
      tabsetPanel(
        # Tab 1: 城市分布
        tabPanel("城市分布",
          br(),
          plotlyOutput("city_bar", height = "500px"),
          br(),
          h4("各城市薪资对比"),
          plotlyOutput("city_salary_box", height = "400px")
        ),

        # Tab 2: 薪资分析
        tabPanel("薪资分析",
          br(),
          fluidRow(
            column(6, plotlyOutput("salary_hist", height = "400px")),
            column(6, plotlyOutput("salary_by_edu", height = "400px"))
          ),
          br(),
          fluidRow(
            column(6, plotlyOutput("salary_by_exp", height = "400px")),
            column(6, plotlyOutput("salary_by_source", height = "400px"))
          )
        ),

        # Tab 3: 行业热度
        tabPanel("行业热度",
          br(),
          fluidRow(
            column(6, h4("行业分布词云"), wordcloud2Output("skill_cloud", height = "400px")),
            column(6, h4("数据来源分布"), plotlyOutput("source_pie", height = "400px"))
          ),
          br(),
          h4("岗位关键词 Top 20"),
          plotlyOutput("keyword_bar", height = "400px")
        ),

        # Tab 4: 岗位搜索
        tabPanel("岗位搜索",
          br(),
          DTOutput("job_table"),
          br(),
          downloadButton("download_csv", "导出筛选结果", class = "btn-success")
        ),

        # Tab 5: 实习分析
        tabPanel("实习分析",
          br(),
          fluidRow(
            column(6, plotlyOutput("intern_city_bar", height = "400px")),
            column(6, plotlyOutput("intern_keyword_bar", height = "400px"))
          ),
          br(),
          h4("实习岗位薪资分布"),
          plotlyOutput("intern_salary_hist", height = "400px")
        )
      )
    )
  )
)

# ============================================================
# Server 逻辑
# ============================================================
server <- function(input, output, session) {

  # --- 响应式数据：根据筛选条件过滤 ---
  filtered_data <- reactive({
    df <- load_data()

    # 数据源筛选
    if (!is.null(input$source_filter)) {
      df <- df %>% filter(source %in% input$source_filter)
    }

    # 城市筛选（数据是"北京·朝阳·建外"格式，用前缀匹配）
    if (input$city_filter != "全部") {
      df <- df %>% filter(str_detect(city, paste0("^", input$city_filter)))
    }

    # 学历筛选
    if (!is.null(input$edu_filter)) {
      df <- df %>% filter(education %in% input$edu_filter)
    }

    # 薪资筛选
    df <- df %>%
      filter(
        is.na(salary_avg) |
        (salary_avg >= input$salary_filter[1] * 1000 &
         salary_avg <= input$salary_filter[2] * 1000)
      )

    # 实习岗位筛选
    if (input$intern_filter) {
      df <- df %>% filter(str_detect(job_title, "实习"))
    }

    df
  })

  # --- 数据统计 ---
  output$data_stats <- renderText({
    df <- filtered_data()
    paste0("共 ", nrow(df), " 条岗位数据")
  })

  # ============================================================
  # Tab 1: 城市分布
  # ============================================================
  output$city_bar <- renderPlotly({
    df <- filtered_data()
    city_counts <- df %>%
      count(city, sort = TRUE) %>%
      head(20)

    p <- ggplot(city_counts, aes(x = reorder(city, n), y = n, fill = n)) +
      geom_col(show.legend = FALSE) +
      coord_flip() +
      scale_fill_gradient(low = "#4ECDC4", high = "#FF6B6B") +
      labs(x = NULL, y = "岗位数量", title = "各城市岗位数量 Top 20") +
      theme_minimal(base_size = 14)

    ggplotly(p, tooltip = c("x", "y"))
  })

  output$city_salary_box <- renderPlotly({
    df <- filtered_data() %>% filter(!is.na(salary_avg))
    top_cities <- df %>% count(city, sort = TRUE) %>% head(10) %>% pull(city)
    df <- df %>% filter(city %in% top_cities)

    p <- ggplot(df, aes(x = reorder(city, salary_avg, FUN = median), y = salary_avg / 1000)) +
      geom_boxplot(fill = "#4ECDC4", alpha = 0.7) +
      coord_flip() +
      labs(x = NULL, y = "月薪（千元）", title = "各城市薪资分布") +
      theme_minimal(base_size = 14)

    ggplotly(p)
  })

  # ============================================================
  # Tab 2: 薪资分析
  # ============================================================
  output$salary_hist <- renderPlotly({
    df <- filtered_data() %>% filter(!is.na(salary_avg))

    p <- ggplot(df, aes(x = salary_avg / 1000)) +
      geom_histogram(bins = 30, fill = "#4ECDC4", color = "white", alpha = 0.8) +
      labs(x = "月薪（千元）", y = "岗位数量", title = "薪资分布直方图") +
      theme_minimal(base_size = 14)

    ggplotly(p)
  })

  output$salary_by_edu <- renderPlotly({
    df <- filtered_data() %>% filter(!is.na(salary_avg), !is.na(education))

    p <- ggplot(df, aes(x = education, y = salary_avg / 1000, fill = education)) +
      geom_boxplot(show.legend = FALSE, alpha = 0.8) +
      scale_fill_brewer(palette = "Set2") +
      labs(x = "学历要求", y = "月薪（千元）", title = "不同学历薪资对比") +
      theme_minimal(base_size = 14)

    ggplotly(p)
  })

  output$salary_by_exp <- renderPlotly({
    df <- filtered_data() %>% filter(!is.na(salary_avg), !is.na(experience_years))

    p <- ggplot(df, aes(x = experience_years, y = salary_avg / 1000)) +
      geom_point(alpha = 0.3, color = "#FF6B6B") +
      geom_smooth(method = "loess", se = TRUE, color = "#4ECDC4") +
      labs(x = "工作经验（年）", y = "月薪（千元）", title = "经验与薪资关系") +
      theme_minimal(base_size = 14)

    ggplotly(p)
  })

  output$salary_by_source <- renderPlotly({
    df <- filtered_data() %>% filter(!is.na(salary_avg))

    p <- ggplot(df, aes(x = source, y = salary_avg / 1000, fill = source)) +
      geom_violin(alpha = 0.6, show.legend = FALSE) +
      scale_fill_brewer(palette = "Set3") +
      labs(x = "数据来源", y = "月薪（千元）", title = "各平台薪资分布对比") +
      theme_minimal(base_size = 14)

    ggplotly(p)
  })

  # ============================================================
  # Tab 3: 行业热度
  # ============================================================
  output$skill_cloud <- renderWordcloud2({
    df <- filtered_data()
    # 用行业字段做词云（因为没有岗位描述全文，无法提取技能词）
    if (!"industry" %in% names(df)) return(NULL)

    all_ind <- df %>%
      filter(!is.na(industry), industry != "") %>%
      count(industry, sort = TRUE) %>%
      rename(word = industry, freq = n) %>%
      head(100)

    if (nrow(all_ind) == 0) return(NULL)
    wordcloud2(all_ind, size = 0.8, color = "random-dark")
  })

  output$source_pie <- renderPlotly({
    df <- filtered_data()
    source_counts <- df %>% count(source)

    plot_ly(source_counts, labels = ~source, values = ~n, type = "pie",
            textinfo = "label+percent",
            marker = list(colors = c("#4ECDC4", "#FF6B6B", "#45B7D1"))) %>%
      layout(title = "数据来源分布")
  })

  output$keyword_bar <- renderPlotly({
    df <- filtered_data()
    if (!"keyword" %in% names(df)) return(NULL)

    kw_counts <- df %>%
      count(keyword, sort = TRUE) %>%
      head(20)

    p <- ggplot(kw_counts, aes(x = reorder(keyword, n), y = n)) +
      geom_col(fill = "#45B7D1") +
      coord_flip() +
      labs(x = NULL, y = "岗位数量", title = "搜索关键词岗位数量") +
      theme_minimal(base_size = 14)

    ggplotly(p)
  })

  # ============================================================
  # Tab 4: 岗位搜索
  # ============================================================
  output$job_table <- renderDT({
    df <- filtered_data()

    # 关键词搜索
    if (nchar(input$keyword_search) > 0) {
      pattern <- input$keyword_search
      df <- df %>%
        filter(
          str_detect(job_title, regex(pattern, ignore_case = TRUE)) |
          str_detect(company, regex(pattern, ignore_case = TRUE)) |
          if ("description" %in% names(df)) str_detect(description, regex(pattern, ignore_case = TRUE)) else TRUE
        )
    }

    # 选择展示列
    display_cols <- intersect(
      c("job_title", "company", "salary", "city", "education",
        "experience", "company_size", "industry", "source"),
      names(df)
    )
    df %>% select(all_of(display_cols))
  },
  options = list(
    pageLength = 20,
    scrollX = TRUE,
    searching = TRUE,
    order = list(list(0, "desc"))
  ),
  filter = "top",
  rownames = FALSE
  )

  # 导出 CSV
  output$download_csv <- downloadHandler(
    filename = function() {
      paste0("jobs_filtered_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".csv")
    },
    content = function(file) {
      readr::write_csv(filtered_data(), file)
    }
  )

  # ============================================================
  # Tab 5: 实习分析
  # ============================================================
  output$intern_city_bar <- renderPlotly({
    df <- filtered_data() %>% filter(str_detect(job_title, "实习"))
    city_counts <- df %>%
      count(city, sort = TRUE) %>%
      head(15)

    p <- ggplot(city_counts, aes(x = reorder(city, n), y = n, fill = n)) +
      geom_col(show.legend = FALSE) +
      coord_flip() +
      scale_fill_gradient(low = "#4ECDC4", high = "#FF6B6B") +
      labs(x = NULL, y = "岗位数量", title = "实习岗位城市分布 Top 15") +
      theme_minimal(base_size = 14)

    ggplotly(p, tooltip = c("x", "y"))
  })

  output$intern_keyword_bar <- renderPlotly({
    df <- filtered_data() %>% filter(str_detect(job_title, "实习"))
    if (!"keyword" %in% names(df)) return(NULL)

    kw_counts <- df %>%
      count(keyword, sort = TRUE) %>%
      head(15)

    p <- ggplot(kw_counts, aes(x = reorder(keyword, n), y = n)) +
      geom_col(fill = "#45B7D1") +
      coord_flip() +
      labs(x = NULL, y = "岗位数量", title = "实习岗位关键词分布") +
      theme_minimal(base_size = 14)

    ggplotly(p)
  })

  output$intern_salary_hist <- renderPlotly({
    df <- filtered_data() %>%
      filter(str_detect(job_title, "实习"), !is.na(salary_avg))

    p <- ggplot(df, aes(x = salary_avg / 1000)) +
      geom_histogram(bins = 20, fill = "#4ECDC4", color = "white", alpha = 0.8) +
      labs(x = "月薪（千元）", y = "岗位数量", title = "实习岗位薪资分布") +
      theme_minimal(base_size = 14)

    ggplotly(p)
  })
}

# ============================================================
# 启动应用
# ============================================================
shinyApp(ui, server)
