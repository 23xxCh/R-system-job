# ============================================================
# test_env.R —— 环境验证脚本
# ============================================================
# 运行这个脚本来确认你的 R 环境一切正常
# 在 RStudio 中选中全部代码，按 Ctrl+Enter 执行

cat("=== R 环境检查 ===\n\n")

# 1. R 版本
cat("R 版本:", R.version.string, "\n")

# 2. 检查关键包是否安装
check_pkg <- function(pkg) {
  if (requireNamespace(pkg, quietly = TRUE)) {
    ver <- packageVersion(pkg)
    cat(sprintf("  %-15s ✓ (v%s)\n", pkg, ver))
    return(TRUE)
  } else {
    cat(sprintf("  %-15s ✗ 未安装\n", pkg))
    return(FALSE)
  }
}

cat("\n核心包检查:\n")
core_pkgs <- c("rvest", "dplyr", "ggplot2", "shiny", "plotly", "DT", "wordcloud2")
results <- sapply(core_pkgs, check_pkg)

if (all(results)) {
  cat("\n所有核心包已就绪！可以开始项目了。\n")
} else {
  missing <- names(results[!results])
  cat("\n缺少以下包，请运行:\n")
  cat(sprintf('  install.packages(c("%s"))\n', paste(missing, collapse = '", "')))
}

# 3. 测试基本绘图
cat("\n生成测试图...\n")
plot(1:10, pch = 19, col = "steelblue", main = "R 绘图测试 - 如果你看到这张图说明一切正常")
cat("测试完成！\n")
