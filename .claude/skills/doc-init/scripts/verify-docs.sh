#!/bin/bash
# verify-docs.sh — 文档健康检查脚本
# 用法: bash scripts/verify-docs.sh [--fix]
#
# 检查项：
#   1. 导航文件中的交叉引用链接是否有效
#   2. docs/.doc-meta.json 注册表与实际文件是否一致
#   3. 文档新鲜度状态
#   4. 反模式检测（文件过大、孤立文档等）
#
# 退出码: 0=全部通过, 1=有错误, 2=有警告

set -euo pipefail

# ─── 配色 ───
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ─── 计数器 ───
ERRORS=0
WARNINGS=0
PASSED=0

# ─── 工具函数 ───
pass()  { ((PASSED++));  echo -e "  ${GREEN}✓${NC} $1"; }
warn()  { ((WARNINGS++)); echo -e "  ${YELLOW}⚠${NC} $1"; }
fail()  { ((ERRORS++));  echo -e "  ${RED}✗${NC} $1"; }
info()  { echo -e "  ${BLUE}ℹ${NC} $1"; }
header(){ echo -e "\n${BLUE}━━━ $1 ━━━${NC}"; }

# ─── 定位项目根目录 ───
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$ROOT"

# ═══════════════════════════════════════
# 1. 导航文件存在性检查
# ═══════════════════════════════════════
header "1. 导航文件检查"

NAV_FILE=""
if [ -f "AGENTS.md" ]; then
    NAV_FILE="AGENTS.md"
    pass "AGENTS.md 存在"
elif [ -f "CLAUDE.md" ]; then
    NAV_FILE="CLAUDE.md"
    pass "CLAUDE.md 存在"
else
    fail "未找到 AGENTS.md 或 CLAUDE.md"
fi

if [ -n "$NAV_FILE" ]; then
    NAV_LINES=$(wc -l < "$NAV_FILE")
    if [ "$NAV_LINES" -le 120 ]; then
        pass "$NAV_FILE 行数: $NAV_LINES (≤120)"
    else
        warn "$NAV_FILE 行数: $NAV_LINES (>120，建议精简)"
    fi
fi

if [ -d "docs" ]; then
    DOC_COUNT=$(find docs -name "*.md" -type f 2>/dev/null | wc -l)
    pass "docs/ 目录存在，包含 $DOC_COUNT 个 .md 文件"
else
    fail "docs/ 目录不存在"
fi

# ═══════════════════════════════════════
# 2. 交叉引用链接检查
# ═══════════════════════════════════════
header "2. 交叉引用链接检查"

check_links_in_file() {
    local file="$1"
    local link_count=0
    local broken_count=0

    # 提取 markdown 链接中的相对路径: [text](path) 和 → path 格式
    while IFS= read -r link; do
        # 跳过 http/https/mailto 链接和锚点链接
        if echo "$link" | grep -qE '^(https?://|mailto:|#)'; then
            continue
        fi
        # 跳过空链接
        if [ -z "$link" ]; then
            continue
        fi

        ((link_count++))

        # 解析相对路径（相对于文件所在目录）
        local file_dir
        file_dir=$(dirname "$file")
        local resolved_path="$file_dir/$link"

        # 如果以 docs/ 开头且文件在根目录，直接使用
        if echo "$link" | grep -qE '^docs/'; then
            resolved_path="$link"
        fi

        if [ ! -f "$resolved_path" ] && [ ! -d "$resolved_path" ]; then
            fail "断裂链接: $file → $link"
            ((broken_count++))
        fi
    done < <(grep -oP '\]\(\K[^)]+(?=\))' "$file" 2>/dev/null || true)

    # 也检查 → 格式的链接（常见于索引表）
    while IFS= read -r link; do
        if echo "$link" | grep -qE '^(https?://|mailto:|#)'; then
            continue
        fi
        if [ -z "$link" ]; then
            continue
        fi

        ((link_count++))

        if [ ! -f "$link" ] && [ ! -d "$link" ]; then
            fail "断裂链接: $file → $link"
            ((broken_count++))
        fi
    done < <(grep -oP '→\s*\K\S+\.md' "$file" 2>/dev/null || true)

    if [ "$link_count" -gt 0 ] && [ "$broken_count" -eq 0 ]; then
        pass "$file: $link_count 个链接全部有效"
    elif [ "$link_count" -eq 0 ]; then
        info "$file: 无链接"
    fi
}

# 检查导航文件
if [ -n "$NAV_FILE" ]; then
    check_links_in_file "$NAV_FILE"
fi

# 检查 docs/ 下所有 .md 文件
if [ -d "docs" ]; then
    while IFS= read -r doc; do
        check_links_in_file "$doc"
    done < <(find docs -name "*.md" -type f 2>/dev/null | sort)
fi

# ═══════════════════════════════════════
# 3. 新鲜度注册表检查
# ═══════════════════════════════════════
header "3. 新鲜度注册表检查"

META_FILE="docs/.doc-meta.json"

if [ -f "$META_FILE" ]; then
    pass "$META_FILE 存在"

    # 检查 JSON 格式有效性
    if command -v python3 &>/dev/null; then
        if python3 -c "import json; json.load(open('$META_FILE'))" 2>/dev/null; then
            pass "$META_FILE JSON 格式有效"

            # 检查 schema 版本
            SCHEMA=$(python3 -c "import json; d=json.load(open('$META_FILE')); print(d.get('\$schema',''))" 2>/dev/null || echo "")
            if [ "$SCHEMA" = "doc-meta-v1" ]; then
                pass "Schema 版本: doc-meta-v1"
            else
                warn "Schema 版本未知或缺失: '$SCHEMA'"
            fi

            # 检查注册的文档是否都存在
            python3 -c "
import json, sys
with open('$META_FILE') as f:
    meta = json.load(f)
docs = meta.get('documents', {})
missing = []
for path in docs:
    import os
    if not os.path.isfile(path):
        missing.append(path)
if missing:
    for m in missing:
        print(f'ORPHAN:{m}')
else:
    print(f'OK:{len(docs)}')
" 2>/dev/null | while IFS= read -r line; do
                if [[ "$line" == ORPHAN:* ]]; then
                    fail "注册表中的文件不存在: ${line#ORPHAN:}"
                elif [[ "$line" == OK:* ]]; then
                    pass "注册表中 ${line#OK:} 个文档全部存在"
                fi
            done

            # 检查是否有未注册的文档
            if [ -d "docs" ]; then
                python3 -c "
import json, os, sys
with open('$META_FILE') as f:
    meta = json.load(f)
registered = set(meta.get('documents', {}).keys())
actual = set()
for root, dirs, files in os.walk('docs'):
    for fname in files:
        if fname.endswith('.md'):
            path = os.path.join(root, fname).replace('\\\\', '/')
            actual.add(path)
unregistered = actual - registered
if unregistered:
    for u in sorted(unregistered):
        print(f'NEW:{u}')
else:
    print('ALL_REGISTERED')
" 2>/dev/null | while IFS= read -r line; do
                    if [[ "$line" == NEW:* ]]; then
                        warn "未注册的文档: ${line#NEW:}"
                    elif [[ "$line" == "ALL_REGISTERED" ]]; then
                        pass "所有文档已注册"
                    fi
                done
            fi

            # 检查 last_gardened_commit
            LAST_COMMIT=$(python3 -c "import json; d=json.load(open('$META_FILE')); print(d.get('last_gardened_commit',''))" 2>/dev/null || echo "")
            if [ -n "$LAST_COMMIT" ]; then
                CURRENT_COMMIT=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
                if [ "$LAST_COMMIT" = "$CURRENT_COMMIT" ]; then
                    pass "文档与最新 commit 同步: ${LAST_COMMIT:0:7}"
                else
                    COMMITS_BEHIND=$(git rev-list --count "$LAST_COMMIT..HEAD" 2>/dev/null || echo "?")
                    warn "文档落后 $COMMITS_BEHIND 个 commit (上次: ${LAST_COMMIT:0:7}, 当前: ${CURRENT_COMMIT:0:7})"
                fi
            else
                warn "last_gardened_commit 未设置"
            fi
        else
            fail "$META_FILE JSON 格式无效"
        fi
    elif command -v jq &>/dev/null; then
        if jq empty "$META_FILE" 2>/dev/null; then
            pass "$META_FILE JSON 格式有效 (jq)"
        else
            fail "$META_FILE JSON 格式无效"
        fi
    else
        warn "无法验证 JSON 格式（需要 python3 或 jq）"
    fi
else
    warn "$META_FILE 不存在 — garden 模式无法追踪新鲜度"
    info "运行 doc-init 技能的 init 模式来创建注册表"
fi

# ═══════════════════════════════════════
# 4. 反模式检测
# ═══════════════════════════════════════
header "4. 反模式检测"

# 检查过大的文档文件
if [ -d "docs" ]; then
    while IFS= read -r doc; do
        lines=$(wc -l < "$doc")
        if [ "$lines" -gt 300 ]; then
            warn "文件过大: $doc ($lines 行, 建议 < 300 行)"
        fi
    done < <(find docs -name "*.md" -type f 2>/dev/null)
    pass "文档大小检查完成"
fi

# 检查孤立文档（不被任何其他文件引用的 docs/ 文件）
if [ -n "$NAV_FILE" ] && [ -d "docs" ]; then
    ORPHAN_DOCS=0
    while IFS= read -r doc; do
        # 跳过模板文件
        if echo "$doc" | grep -q '_template'; then
            continue
        fi
        # 跳过 .doc-meta.json
        if echo "$doc" | grep -q '.doc-meta.json'; then
            continue
        fi
        # 检查是否被任何 .md 文件引用
        basename_doc=$(basename "$doc")
        if ! grep -rlq "$basename_doc\|$doc" "$NAV_FILE" docs/ 2>/dev/null; then
            warn "孤立文档（未被引用）: $doc"
            ((ORPHAN_DOCS++))
        fi
    done < <(find docs -name "*.md" -type f -not -name "_template*" 2>/dev/null)

    if [ "$ORPHAN_DOCS" -eq 0 ]; then
        pass "无孤立文档"
    fi
fi

# ═══════════════════════════════════════
# 5. 结果汇总
# ═══════════════════════════════════════
header "结果汇总"

echo ""
echo -e "  ${GREEN}通过:${NC} $PASSED"
echo -e "  ${YELLOW}警告:${NC} $WARNINGS"
echo -e "  ${RED}错误:${NC} $ERRORS"
echo ""

if [ "$ERRORS" -gt 0 ]; then
    echo -e "${RED}文档健康检查: 失败${NC}"
    echo "运行 doc-init 技能修复问题。"
    exit 1
elif [ "$WARNINGS" -gt 0 ]; then
    echo -e "${YELLOW}文档健康检查: 有警告${NC}"
    echo "建议运行 doc-init 技能的 garden 模式更新文档。"
    exit 2
else
    echo -e "${GREEN}文档健康检查: 全部通过${NC}"
    exit 0
fi
