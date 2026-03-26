# Sandboxie-Plus 文档健康检查脚本
# 建议在 CI 中定期运行，或在每次 PR 前手动运行

param(
    [switch]$Verbose
)

$ErrorCount = 0
$WarningCount = 0
$DocsPath = Join-Path $PSScriptRoot "..\docs"

Write-Host "=== Sandboxie 文档健康检查 ===" -ForegroundColor Cyan
Write-Host ""

# 1. 检查所有文档链接
Write-Host "检查内部链接..." -ForegroundColor Yellow

$mdFiles = Get-ChildItem -Path $DocsPath -Filter "*.md" -Recurse
$agentsFile = Join-Path $PSScriptRoot "..\AGENTS.md"

if (Test-Path $agentsFile) {
    $mdFiles += Get-Item $agentsFile
}

foreach ($file in $mdFiles) {
    $content = Get-Content $file.FullName -Raw
    $links = [regex]::Matches($content, '\]\(([^)]+)\)') | ForEach-Object { $_.Groups[1].Value }
    
    foreach ($link in $links) {
        # 跳过外部链接和锚点
        if ($link -match '^https?://' -or $link -match '^#' -or $link -match '^mailto:') {
            continue
        }
        
        # 解析相对路径
        $targetPath = Join-Path (Split-Path $file.FullName -Parent) $link
        
        if (-not (Test-Path $targetPath)) {
            Write-Host "  BROKEN: $($file.Name) -> $link" -ForegroundColor Red
            $ErrorCount++
        }
    }
}

Write-Host "  链接检查完成" -ForegroundColor Green
Write-Host ""

# 2. 检查文档新鲜度
Write-Host "检查文档新鲜度..." -ForegroundColor Yellow

$staleDays = 90
$cutoffDate = (Get-Date).AddDays(-$staleDays)

$staleFiles = Get-ChildItem -Path $DocsPath -Filter "*.md" -Recurse | 
    Where-Object { $_.LastWriteTime -lt $cutoffDate }

foreach ($file in $staleFiles) {
    $daysOld = [math]::Floor((Get-Date) - $file.LastWriteTime).TotalDays
    Write-Host "  STALE ($daysOld 天未更新): $($file.FullName)" -ForegroundColor Yellow
    $WarningCount++
}

Write-Host "  新鲜度检查完成" -ForegroundColor Green
Write-Host ""

# 3. 检查 quality.md 更新日期
Write-Host "检查质量评级..." -ForegroundColor Yellow

$qualityFile = Join-Path $DocsPath "quality.md"
if (Test-Path $qualityFile) {
    $qualityContent = Get-Content $qualityFile -Raw
    $dateMatch = [regex]::Match($qualityContent, '最后更新:\s*(\d{4}-\d{2}-\d{2})')
    
    if ($dateMatch.Success) {
        $lastUpdate = [datetime]::ParseExact($dateMatch.Groups[1].Value, "yyyy-MM-dd", $null)
        $daysAgo = [math]::Floor((Get-Date) - $lastUpdate).TotalDays)
        
        if ($daysAgo -gt 30) {
            Write-Host "  WARNING: quality.md 已 $daysAgo 天未更新" -ForegroundColor Yellow
            $WarningCount++
        } else {
            Write-Host "  quality.md 更新于 $daysAgo 天前" -ForegroundColor Green
        }
    }
}

Write-Host ""

# 4. 检查 tech-debt.md
Write-Host "检查技术债务..." -ForegroundColor Yellow

$techDebtFile = Join-Path $DocsPath "plans\tech-debt.md"
if (Test-Path $techDebtFile) {
    $techDebtContent = Get-Content $techDebtFile -Raw
    $highPriorityCount = ([regex]::Matches($techDebtContent, '\| TD-\d+ \|')).Count
    
    Write-Host "  高优先级债务: $highPriorityCount 项" -ForegroundColor Cyan
}

Write-Host ""

# 5. 检查 AGENTS.md 行数
Write-Host "检查 AGENTS.md 行数..." -ForegroundColor Yellow

if (Test-Path $agentsFile) {
    $lineCount = (Get-Content $agentsFile).Count
    if ($lineCount -gt 120) {
        Write-Host "  WARNING: AGENTS.md 有 $lineCount 行，超过建议的 120 行" -ForegroundColor Yellow
        $WarningCount++
    } else {
        Write-Host "  AGENTS.md 有 $lineCount 行 (建议 <= 120)" -ForegroundColor Green
    }
}

Write-Host ""

# 6. 统计文档数量
Write-Host "文档统计..." -ForegroundColor Yellow

$totalDocs = (Get-ChildItem -Path $DocsPath -Filter "*.md" -Recurse).Count
Write-Host "  总文档数: $totalDocs" -ForegroundColor Cyan

Write-Host ""

# 总结
Write-Host "=== 检查完成 ===" -ForegroundColor Cyan
Write-Host "错误: $ErrorCount" -ForegroundColor $(if ($ErrorCount -gt 0) { "Red" } else { "Green" })
Write-Host "警告: $WarningCount" -ForegroundColor $(if ($WarningCount -gt 0) { "Yellow" } else { "Green" })

if ($ErrorCount -gt 0) {
    exit 1
}

exit 0
