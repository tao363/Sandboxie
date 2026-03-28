#!/bin/bash
# scripts/verify-docs.sh — 文档健康检查脚本
# 检查导航文件引用、交叉引用完整性、新鲜度注册表一致性

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

ERRORS=0
WARNINGS=0

echo "=== 文档健康检查 ==="
echo ""

# 1. 检查导航文件存在性
echo "--- 1. 导航文件检查 ---"
if [ -f "AGENTS.md" ]; then
    echo "  [OK] AGENTS.md 存在"
    AGENTS_LINES=$(wc -l < "AGENTS.md")
    if [ "$AGENTS_LINES" -gt 150 ]; then
        echo "  [WARN] AGENTS.md 有 $AGENTS_LINES 行（建议 < 120 行）"
        WARNINGS=$((WARNINGS + 1))
    else
        echo "  [OK] AGENTS.md 行数合理（$AGENTS_LINES 行）"
    fi
else
    echo "  [ERROR] AGENTS.md 不存在"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# 2. 检查 docs/ 目录结构
echo "--- 2. 目录结构检查 ---"
REQUIRED_DIRS=("docs/architecture" "docs/guides")
for dir in "${REQUIRED_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        echo "  [OK] $dir/ 存在"
    else
        echo "  [ERROR] $dir/ 不存在"
        ERRORS=$((ERRORS + 1))
    fi
done

REQUIRED_FILES=("docs/architecture/overview.md" "docs/guides/coding-conventions.md")
for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        FILE_SIZE=$(wc -c < "$file")
        if [ "$FILE_SIZE" -lt 100 ]; then
            echo "  [WARN] $file 内容太少（$FILE_SIZE 字节）"
            WARNINGS=$((WARNINGS + 1))
        else
            echo "  [OK] $file 存在且有内容"
        fi
    else
        echo "  [ERROR] $file 不存在"
        ERRORS=$((ERRORS + 1))
    fi
done
echo ""

# 3. 检查导航文件中的链接引用
echo "--- 3. 导航文件链接检查 ---"
if [ -f "AGENTS.md" ]; then
    # 提取 markdown 链接中的文件路径（兼容 Windows Git Bash）
    LINKS=$(grep -o '(docs/[^)]*\.md)' "AGENTS.md" | tr -d '()' || true)
    LINK_COUNT=0
    BROKEN_COUNT=0
    while IFS= read -r link; do
        if [ -z "$link" ]; then continue; fi
        LINK_COUNT=$((LINK_COUNT + 1))
        if [ ! -f "$link" ]; then
            echo "  [ERROR] 断裂链接: $link"
            ERRORS=$((ERRORS + 1))
            BROKEN_COUNT=$((BROKEN_COUNT + 1))
        fi
    done <<< "$LINKS"
    echo "  检查了 $LINK_COUNT 个链接，$BROKEN_COUNT 个断裂"
fi
echo ""

# 4. 检查 .doc-meta.json 新鲜度注册表
echo "--- 4. 新鲜度注册表检查 ---"
META_FILE="docs/.doc-meta.json"
if [ -f "$META_FILE" ]; then
    echo "  [OK] $META_FILE 存在"

    # 检查 JSON 格式是否合法
    if command -v python3 &>/dev/null; then
        python3 -c "
import json, sys, os

with open('$META_FILE', encoding='utf-8') as f:
    meta = json.load(f)

print('  [OK] JSON 格式合法')

# 检查必要字段
if '\$schema' not in meta:
    print('  [WARN] 缺少 \$schema 字段')
if 'last_gardened_commit' not in meta:
    print('  [WARN] 缺少 last_gardened_commit 字段')
if 'documents' not in meta:
    print('  [ERROR] 缺少 documents 字段')
    sys.exit(1)

# 检查注册的文档是否存在
docs = meta.get('documents', {})
orphans = []
for doc_path in docs:
    if not os.path.isfile(doc_path):
        orphans.append(doc_path)
        print(f'  [ERROR] 注册表中的文件不存在: {doc_path}')

# 检查 docs/ 下的 .md 文件是否都已注册
import glob
actual_docs = set()
for f in glob.glob('docs/**/*.md', recursive=True):
    f = f.replace('\\\\', '/')
    if '/_template' not in f and '/000-template' not in f:
        actual_docs.add(f)

registered = set(docs.keys())
unregistered = actual_docs - registered
for u in sorted(unregistered):
    print(f'  [WARN] 未注册的文档: {u}')

print(f'  注册文档: {len(registered)} 个，未注册: {len(unregistered)} 个，孤儿: {len(orphans)} 个')
" 2>/dev/null || echo "  [WARN] JSON 解析失败"
    else
        echo "  [WARN] python3 不可用，跳过 JSON 验证"
    fi
else
    echo "  [ERROR] $META_FILE 不存在"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# 5. 检查文档文件大小
echo "--- 5. 文档大小检查 ---"
if command -v find &>/dev/null; then
    LARGE_FILES=0
    while IFS= read -r file; do
        LINES=$(wc -l < "$file")
        if [ "$LINES" -gt 500 ]; then
            echo "  [WARN] $file 有 $LINES 行（建议 < 300 行）"
            WARNINGS=$((WARNINGS + 1))
            LARGE_FILES=$((LARGE_FILES + 1))
        fi
    done < <(find docs -name "*.md" -type f 2>/dev/null)
    if [ "$LARGE_FILES" -eq 0 ]; then
        echo "  [OK] 所有文档大小合理"
    fi
fi
echo ""

# 6. 汇总
echo "=== 检查完成 ==="
echo "  错误: $ERRORS"
echo "  警告: $WARNINGS"

if [ "$ERRORS" -gt 0 ]; then
    echo "  状态: FAIL"
    exit 1
else
    echo "  状态: PASS"
    exit 0
fi
