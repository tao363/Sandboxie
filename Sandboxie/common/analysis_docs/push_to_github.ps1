# Sandboxie Common 代码分析 - Git 推送脚本

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Sandboxie Common 代码分析文档推送工具" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 设置路径
$repoPath = "F:\Project\AI\sanbox\Sandboxie"
$analysisPath = "$repoPath\Sandboxie\common\analysis_docs"

# 检查目录是否存在
if (-not (Test-Path $analysisPath)) {
    Write-Host "错误: 分析文档目录不存在!" -ForegroundColor Red
    exit 1
}

# 切换到仓库目录
Set-Location $repoPath

Write-Host "当前目录: $repoPath" -ForegroundColor Green
Write-Host ""

# 检查 Git 状态
Write-Host "检查 Git 状态..." -ForegroundColor Yellow
git status

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "文档统计信息" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# 统计文档
$mdFiles = Get-ChildItem -Path $analysisPath -Filter "*.md" -Recurse
$totalFiles = $mdFiles.Count
$totalSize = ($mdFiles | Measure-Object -Property Length -Sum).Sum
$totalLines = 0

foreach ($file in $mdFiles) {
    $lines = (Get-Content $file.FullName | Measure-Object -Line).Lines
    $totalLines += $lines
    Write-Host "  ✓ $($file.Name): $lines 行, $([math]::Round($file.Length/1KB, 2)) KB" -ForegroundColor Green
}

Write-Host ""
Write-Host "总计:" -ForegroundColor Cyan
Write-Host "  - 文档数量: $totalFiles 个" -ForegroundColor White
Write-Host "  - 总行数: $totalLines 行" -ForegroundColor White
Write-Host "  - 总大小: $([math]::Round($totalSize/1KB, 2)) KB" -ForegroundColor White
Write-Host ""

# 询问是否继续
$continue = Read-Host "是否要添加并提交这些文档? (y/n)"
if ($continue -ne "y") {
    Write-Host "操作已取消" -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Git 操作" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# 添加文件
Write-Host "添加文件到 Git..." -ForegroundColor Yellow
git add Sandboxie/common/analysis_docs/
git add Sandboxie/common/COMMON_CODE_ANALYSIS.md

# 显示将要提交的文件
Write-Host ""
Write-Host "将要提交的文件:" -ForegroundColor Yellow
git status --short

Write-Host ""

# 输入提交信息
$defaultMessage = "docs: 添加 Sandboxie Common 目录深度代码分析文档

- 添加整体架构概述
- 详细分析内存管理模块 (Pool, List, Lock)
- 包含算法实现、性能分析和最佳实践
- 提供代码示例和使用建议

文档统计:
- 文档数量: $totalFiles 个
- 总行数: $totalLines 行
- 总大小: $([math]::Round($totalSize/1KB, 2)) KB"

Write-Host "默认提交信息:" -ForegroundColor Cyan
Write-Host $defaultMessage -ForegroundColor Gray
Write-Host ""

$customMessage = Read-Host "使用默认提交信息? (y/n, 输入 n 可自定义)"
if ($customMessage -eq "n") {
    $commitMessage = Read-Host "请输入提交信息"
} else {
    $commitMessage = $defaultMessage
}

# 提交
Write-Host ""
Write-Host "提交更改..." -ForegroundColor Yellow
git commit -m $commitMessage

if ($LASTEXITCODE -ne 0) {
    Write-Host "提交失败!" -ForegroundColor Red
    exit 1
}

Write-Host "提交成功!" -ForegroundColor Green
Write-Host ""

# 询问是否推送
$push = Read-Host "是否推送到远程仓库? (y/n)"
if ($push -ne "y") {
    Write-Host "已提交到本地仓库，未推送到远程" -ForegroundColor Yellow
    exit 0
}

# 获取当前分支
$currentBranch = git rev-parse --abbrev-ref HEAD
Write-Host ""
Write-Host "当前分支: $currentBranch" -ForegroundColor Cyan

# 推送
Write-Host "推送到远程仓库..." -ForegroundColor Yellow
git push origin $currentBranch

if ($LASTEXITCODE -ne 0) {
    Write-Host "推送失败!" -ForegroundColor Red
    Write-Host "可能需要先设置远程仓库或解决冲突" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "✓ 完成!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "文档已成功推送到 GitHub!" -ForegroundColor Green
Write-Host "分支: $currentBranch" -ForegroundColor White
Write-Host ""

# 显示远程 URL
$remoteUrl = git remote get-url origin
Write-Host "远程仓库: $remoteUrl" -ForegroundColor Cyan
Write-Host ""

Write-Host "下一步建议:" -ForegroundColor Yellow
Write-Host "  1. 在 GitHub 上查看提交" -ForegroundColor White
Write-Host "  2. 创建 Pull Request (如果需要)" -ForegroundColor White
Write-Host "  3. 继续完善其他模块的分析文档" -ForegroundColor White
Write-Host ""
