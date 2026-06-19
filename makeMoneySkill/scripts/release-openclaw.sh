#!/usr/bin/env bash
#
# 交易策略管理大师 — OpenClaw Release 打包脚本
# 将 Claude Code 版本转换为 OpenClaw 兼容格式并打包
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
RELEASE_DIR="$SCRIPT_DIR/release"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
PACKAGE_NAME="trading-strategy-master-openclaw-${TIMESTAMP}"
PACKAGE_DIR="$RELEASE_DIR/$PACKAGE_NAME"
ARCHIVE_NAME="${PACKAGE_NAME}.tar.gz"

echo "============================================"
echo "  交易策略管理大师 — OpenClaw Release 打包"
echo "============================================"
echo ""

# 1. 清理旧产物
rm -rf "$PACKAGE_DIR"
mkdir -p "$PACKAGE_DIR"

# ──────────────────────────────────────────────
# 2. 转换并复制 Skill 文件
# ──────────────────────────────────────────────
echo "📦 转换 Skill 文件 (Claude Code → OpenClaw)..."
CLAUDE_SKILLS="$PROJECT_DIR/.claude/skills"
OPENCLAW_SKILLS="$PACKAGE_DIR/skills"

declare -A SKILL_NAMES=(
    ["strategy-manager"]="share-strategy-manager"
    ["investment-analysis"]="share-investment-analysis"
    ["review-query"]="share-review-query"
    ["data-source-manager"]="share-data-source-manager"
    ["a-stock-data"]="share-a-stock-data"
)

for dir in strategy-manager investment-analysis review-query data-source-manager a-stock-data; do
    SRC="$CLAUDE_SKILLS/$dir/SKILL.md"
    NAME="${SKILL_NAMES[$dir]}"

    if [ ! -f "$SRC" ]; then
        echo "   ⚠️  $SRC 不存在，跳过"
        continue
    fi

    DST_DIR="$OPENCLAW_SKILLS/$dir"
    mkdir -p "$DST_DIR"
    DST="$DST_DIR/SKILL.md"

    # 读取原始内容（跳过第一行 `---` 和 `name:` `description:` 行），重新组装 OpenClaw 格式
    ORIG_NAME=$(grep "^name:" "$SRC" | head -1 | sed 's/^name: *//')
    ORIG_DESC=$(grep "^description:" "$SRC" | head -1 | sed 's/^description: *//')

    # 写入 OpenClaw 兼容 frontmatter
    cat > "$DST" << EOF
---
name: ${NAME}
description: ${ORIG_DESC}
user-invocable: true
---
EOF

    # 提取 body（跳过 YAML frontmatter 块），做内容替换
    awk 'BEGIN { in_fm=0; started=0 }
         /^---$/ { if (!started) { started=1; in_fm=1; next } else if (in_fm) { in_fm=0; next } }
         !in_fm { print }' "$SRC" | \

    # 路径引用转换
    sed \
        -e 's|\.claude/skills/|skills/|g' \
        -e 's|CLAUDE\.md|AGENTS.md|g' \
        -e 's|Claude Code [Ss]kill|OpenClaw Skill|g' \
        -e 's|使用 `Skill` 工具|使用 `/skill` 命令|g' \
        -e 's|Skill("\([^"]*\)"|`/skill \1`|g' \
        -e 's|调用 Skill 工具|调用 `/skill` 命令|g' \
        -e 's|通过 `Skill` 工具调用对应 skill|通过 `/skill <name>` 调用对应 skill|g' \
        >> "$DST"

    echo "   ✅ skills/$dir/SKILL.md  ($ORIG_NAME → $NAME)"
done

# ──────────────────────────────────────────────
# 3. 转换 CLAUDE.md → AGENTS.md
# ──────────────────────────────────────────────
echo ""
echo "📦 转换项目指令 (CLAUDE.md → AGENTS.md)..."

cat > "$PACKAGE_DIR/AGENTS.md" << 'AGENTS_HEADER'
# AGENTS.md

This file provides guidance to OpenClaw when working with code in this repository.

## 项目概述

交易策略管理大师 — 一个 OpenClaw skill 项目，为用户提供交易策略管理、投资分析和复盘查询能力。项目通过 OpenClaw Slash Command（`skills/<name>/SKILL.md`）实现。

## Skill 架构

```
skills/
├── strategy-manager/     # 交易策略管理 — 增删改查用户交易策略
│   └── SKILL.md
├── investment-analysis/  # 投资分析 — 使用已有策略分析行情，结果本地保存
│   └── SKILL.md
├── review-query/         # 复盘查询 — 按时间/标的查询历史分析结果
│   └── SKILL.md
├── data-source-manager/  # 数据获取管理 — 增删改查投资标的获取渠道
│   └── SKILL.md
└── a-stock-data/         # 数据获取 Skill（默认渠道调用）
    └── SKILL.md
```

Skill 文件格式：每个 SKILL.md 开头为 YAML frontmatter（定义 name、description、user-invocable），正文为 OpenClaw 行为指令。

## 数据存储约定

投资分析结果以结构化 JSON 保存在 `data/analysis/` 目录下，每条记录包含：

- `时间` — 分析时间戳
- `股票名` / `股票号码` — 投资标的标识
- `数据面` — 基本面数据（PE、PB、ROE 等）
- `技术面` — 技术指标（均线、MACD、RSI 等）
- `消息面` — 相关新闻与公告摘要

交易策略保存在 `data/strategies/` 下，每条策略一个 JSON 文件。

数据获取渠道保存在 `data/sources/` 下，每条渠道一个 JSON 文件。

## 关键约束

1. 每次用户修改交易策略后，必须立即 commit 并 push 到 git 远端仓库
2. 投资分析结果必须在分析完成后立即写入本地 `data/analysis/` 目录
AGENTS_HEADER

echo "   ✅ AGENTS.md"

# ──────────────────────────────────────────────
# 4. 复制项目文档
# ──────────────────────────────────────────────
echo ""
echo "📦 复制项目文档..."
cp "$PROJECT_DIR/README.md" "$PACKAGE_DIR/README.md"
echo "   ✅ README.md"

# ──────────────────────────────────────────────
# 5. 复制预置数据源
# ──────────────────────────────────────────────
echo ""
echo "📦 复制预置数据源..."
mkdir -p "$PACKAGE_DIR/data/sources"
for src in akshare-sdk.json a-stock-data.json _default.json; do
    if [ -f "$PROJECT_DIR/data/sources/$src" ]; then
        cp "$PROJECT_DIR/data/sources/$src" "$PACKAGE_DIR/data/sources/$src"
        echo "   ✅ data/sources/$src"
    fi
done

# ──────────────────────────────────────────────
# 5b. 全局替换残留的 "Claude Code" → "OpenClaw"（README、JSON 等非 skill 文件）
# ──────────────────────────────────────────────
echo ""
echo "📦 清理残留的平台引用..."
# 跳过 INSTALL.md（它是故意对比两个版本的）
find "$PACKAGE_DIR" -type f \( -name "*.md" -o -name "*.json" \) ! -name "INSTALL.md" \
    -exec sed -i 's|Claude Code|OpenClaw|g' {} +
echo "   ✅ Claude Code → OpenClaw（README / AGENTS.md / JSON）"

# ──────────────────────────────────────────────
# 6. 创建空目录
# ──────────────────────────────────────────────
echo ""
echo "📦 创建用户数据目录..."
mkdir -p "$PACKAGE_DIR/data/strategies"
touch "$PACKAGE_DIR/data/strategies/.gitkeep"
echo "   ✅ data/strategies/ (空目录，放你的策略)"

mkdir -p "$PACKAGE_DIR/data/analysis"
touch "$PACKAGE_DIR/data/analysis/.gitkeep"
echo "   ✅ data/analysis/ (空目录，放分析记录)"

# ──────────────────────────────────────────────
# 7. 生成 OpenClaw 安装说明
# ──────────────────────────────────────────────
echo ""
echo "📦 生成安装说明..."
cat > "$PACKAGE_DIR/INSTALL.md" << 'INSTALL_DOC'
# 交易策略管理大师 — OpenClaw 安装说明

## 安装步骤

1. 解压到你的工作目录：
   ```bash
   tar -xzf trading-strategy-master-openclaw-*.tar.gz
   cd trading-strategy-master-openclaw-*
   ```

2. OpenClaw 会自动识别项目根目录下的：
   - `AGENTS.md` — 项目指令
   - `skills/` — 技能目录

3. 验证安装：
   ```bash
   /skill share-strategy-manager 查看策略列表
   /skill share-data-source-manager 查看数据源列表
   ```

## 目录结构

```
.
├── AGENTS.md                 # 项目指令（OpenClaw 自动加载）
├── README.md                 # 项目文档
├── INSTALL.md                # 本文件
├── skills/                   # 5 个 Skill（OpenClaw 格式）
│   ├── strategy-manager/       → /skill share-strategy-manager
│   ├── investment-analysis/    → /skill share-investment-analysis
│   ├── review-query/           → /skill share-review-query
│   ├── data-source-manager/    → /skill share-data-source-manager
│   └── a-stock-data/           → /skill share-a-stock-data
└── data/
    ├── sources/              # 预置数据源（含默认渠道）
    ├── strategies/           # 你的策略放这里
    └── analysis/             # 分析结果自动保存这里
```

## 快速开始

```bash
# 1. 查看预置数据源
/skill share-data-source-manager 查看数据源列表

# 2. 设置默认获取渠道
/skill share-data-source-manager 使用 a-stock-data 作为默认数据源

# 3. 创建你的第一条策略
/skill share-strategy-manager 新增一条策略

# 4. 开始投资分析
/skill share-investment-analysis 帮我分析 XX股票

# 5. 复盘
/skill share-review-query 查看最近的分析记录
```

## 与 Claude Code 版本的区别

| 项目 | Claude Code | OpenClaw |
|------|------------|----------|
| 技能目录 | `.claude/skills/` | `skills/` |
| 项目指令 | `CLAUDE.md` | `AGENTS.md` |
| 调用方式 | `/share-xxx` 或 `Skill` 工具 | `/skill share-xxx` |
| 前端格式 | 标准 YAML | YAML + `user-invocable: true` |

## 数据安全

- 策略和分析结果保存在 `data/` 下
- 建议初始化 git 并配置远端：
  ```bash
  git init
  git remote add origin <your-repo-url>
  ```
INSTALL_DOC
echo "   ✅ INSTALL.md"

# ──────────────────────────────────────────────
# 8. 打包
# ──────────────────────────────────────────────
echo ""
echo "📦 打包压缩..."
cd "$RELEASE_DIR"
tar -czf "$ARCHIVE_NAME" "$PACKAGE_NAME"
PACKAGE_SIZE=$(du -h "$ARCHIVE_NAME" | cut -f1)

# ──────────────────────────────────────────────
# 9. 预览内容
# ──────────────────────────────────────────────
echo ""
echo "============================================"
echo "  ✅ OpenClaw Release 打包完成"
echo "============================================"
echo ""
echo "  包名：  $ARCHIVE_NAME"
echo "  大小：  $PACKAGE_SIZE"
echo "  路径：  $RELEASE_DIR/$ARCHIVE_NAME"
echo ""
echo "  包含文件："
echo "  ----------------------------------------"
tar -tzf "$ARCHIVE_NAME" | while read line; do
    if [[ "$line" != */ ]]; then
        echo "    $line"
    fi
done
echo "  ----------------------------------------"
echo ""
echo "  与 Claude Code 版本的关键差异："
echo "    • .claude/skills/  →  skills/"
echo "    • CLAUDE.md        →  AGENTS.md"
echo "    • Skill 工具调用    →  /skill <name>"
echo "    • frontmatter      →  新增 user-invocable: true"
echo ""
echo "  安装：tar -xzf $ARCHIVE_NAME && cd $PACKAGE_NAME"
echo ""
