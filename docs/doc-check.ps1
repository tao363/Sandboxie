#!/usr/bin/env pwsh
#Requires -Version 5.1
<#
.SYNOPSIS
    Sandboxie-Plus 文档校验脚本

.DESCRIPTION
    检查文档完整性、交叉引用和陈旧文档。

.PARAMETER CheckLinks
    检查文档中的交叉引用链接是否有效

.PARAMETER CheckStale
    检查是否有陈旧文档（代码变更但文档未更新）

.PARAMETER Report
    生成详细报告

.EXAMPLE
    .\doc-check.ps1 -CheckLinks -Report
#>

param(
    [switch]$CheckLinks,
    [switch]$CheckStale,
    [switch]$Report
)

$ErrorActionPreference = "Continue"
$docsDir = Join-Path $PSScriptRoot "..\docs"
$rootDir = Join-Path $PSScriptRoot ".."

function Test-MarkdownLinks {
    param([string]$filePath)
    
    $content = Get-Content $filePath -Raw
    $errors = @()
    
    $linkPattern = '\[([^\]]+)\]\(([^)]+)\)'
    $matches = [regex]::Matches($content, $linkPattern)
    
    foreach ($match in $matches) {
        $link = $match.Groups[2].Value
        
        if ($link -match '^(http|https)://') {
            continue
        }
        
        if ($link -match '^#') {
            continue
        }
        
        $targetPath = $link -replace '^\.\./', ''
        $targetPath = $link -replace '^\.\/', ''
        
        if ($link -match '^\.\./') {
            $docDir = Split-Path $filePath -Parent
            $targetPath = Join-Path $docDir $link
        }
        else {
            $targetPath = Join-Path $rootDir $link
        }
        
        $targetPath = (Resolve-Path $targetPath -ErrorAction SilentlyContinue).Path
        
        if (-not $targetPath -or -not (Test-Path $targetPath)) {
            $errors += "Broken link: $link"
        }
    }
    
    return $errors
}

function Get-DocumentStatus {
    $metaFile = Join-Path $docsDir ".doc-meta.json"
    
    if (-not (Test-Path $metaFile)) {
        Write-Warning "No .doc-meta.json found"
        return @{}
    }
    
    $meta = Get-Content $metaFile | ConvertFrom-Json
    return $meta.documents
}

function Test-StaleDocuments {
    $documents = Get-DocumentStatus
    $stale = @()
    
    foreach ($docPath in $documents.PSObject.Properties.Name) {
        $doc = $documents.$docPath
        $fullPath = Join-Path $rootDir $docPath
        
        if (-not (Test-Path $fullPath)) {
            $stale += @{
                Document = $docPath
                Reason = "File missing"
            }
            continue
        }
        
        $lastWrite = (Get-Item $fullPath).LastWriteTime
        $verifiedDate = [datetime]::Parse($doc.last_verified)
        
        $daysSinceVerified = (Get-Date) - $verifiedDate
        
        if ($daysSinceVerified.Days -gt 30) {
            $stale += @{
                Document = $docPath
                Reason = "Not verified in $($daysSinceVerified.Days) days"
            }
        }
    }
    
    return $stale
}

function Write-Report {
    Write-Host "=== Sandboxie-Plus 文档状态报告 ===" -ForegroundColor Cyan
    Write-Host ""
    
    $allDocs = Get-ChildItem -Path $docsDir -Filter "*.md" -Recurse
    Write-Host "文档总数: $($allDocs.Count)" -ForegroundColor Green
    
    $templates = $allDocs | Where-Object { $_.Name -like "*template*" -or $_.Name -like "_*" }
    Write-Host "模板文件: $($templates.Count)" -ForegroundColor Yellow
    
    Write-Host ""
    Write-Host "目录结构:" -ForegroundColor Cyan
    
    $dirs = Get-ChildItem -Path $docsDir -Directory
    foreach ($dir in $dirs) {
        $count = (Get-ChildItem -Path $dir.FullName -Filter "*.md" -Recurse).Count
        Write-Host "  $($dir.Name)/ : $count 文件"
    }
    
    if ($CheckLinks) {
        Write-Host ""
        Write-Host "检查交叉引用..." -ForegroundColor Cyan
        
        $brokenLinks = @{}
        foreach ($doc in $allDocs) {
            $errors = Test-MarkdownLinks $doc.FullName
            if ($errors.Count -gt 0) {
                $brokenLinks[$doc.Name] = $errors
            }
        }
        
        if ($brokenLinks.Count -gt 0) {
            Write-Host "发现 $($brokenLinks.Count) 个文档有断链:" -ForegroundColor Red
            foreach ($docName in $brokenLinks.Keys) {
                Write-Host "  $docName :"
                foreach ($error in $brokenLinks[$docName]) {
                    Write-Host "    - $error"
                }
            }
        }
        else {
            Write-Host "所有交叉引用有效" -ForegroundColor Green
        }
    }
    
    if ($CheckStale) {
        Write-Host ""
        Write-Host "检查陈旧文档..." -ForegroundColor Cyan
        
        $stale = Test-StaleDocuments
        
        if ($stale.Count -gt 0) {
            Write-Host "发现 $($stale.Count) 个陈旧文档:" -ForegroundColor Yellow
            foreach ($item in $stale) {
                Write-Host "  $($item.Document) : $($item.Reason)"
            }
        }
        else {
            Write-Host "所有文档状态良好" -ForegroundColor Green
        }
    }
    
    Write-Host ""
    Write-Host "=== 报告完成 ===" -ForegroundColor Cyan
}

if ($Report -or (-not $CheckLinks -and -not $CheckStale)) {
    Write-Report
}
elseif ($CheckLinks) {
    Write-Host "检查交叉引用..." -ForegroundColor Cyan
    $allDocs = Get-ChildItem -Path $docsDir -Filter "*.md" -Recurse
    
    foreach ($doc in $allDocs) {
        $errors = Test-MarkdownLinks $doc.FullName
        if ($errors.Count -gt 0) {
            Write-Host "$($doc.Name) :" -ForegroundColor Yellow
            foreach ($error in $errors) {
                Write-Host "  - $error"
            }
        }
    }
}
elseif ($CheckStale) {
    Write-Host "检查陈旧文档..." -ForegroundColor Cyan
    $stale = Test-StaleDocuments
    
    foreach ($item in $stale) {
        Write-Host "$($item.Document) : $($item.Reason)" -ForegroundColor Yellow
    }
}
