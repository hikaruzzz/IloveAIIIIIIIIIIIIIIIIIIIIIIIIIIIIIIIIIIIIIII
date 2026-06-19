#!/usr/bin/env bash
#
# 交易策略管理大师 — Release 打包脚本
# 将项目核心文件收集并打包为 .tar.gz，支持他人本地安装
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
RELEASE_DIR="$PROJECT_DIR/scripts/release"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
PACKAGE_NAME="trading-strategy-master-${TIMESTAMP}"
PACKAGE_DIR="$RELEASE_DIR/$PACKAGE_NAME"
ARCHIVE_NAME="${PACKAGE_NAME}.tar.gz"

echo "============================================"
echo "  交易策略管理大师 — Release 打包"
echo "============================================"
echo ""

# 1. 清理旧的 release 目录
rm -rf "$RELEASE_DIR"
mkdir -p "$PACKAGE_DIR"

# 2. 复制核心 Skill 文件
echo "📦 收集 Skill 文件..."
SKILLS_SRC="$PROJECT_DIR/.claude/skills"
SKILLS_DST="$PACKAGE_DIR/.claude/skills"

for skill in strategy-manager investment-analysis review-query data-source-manager a-stock-data; do
    if [ -f "$SKILLS_SRC/$skill/SKILL.md" ]; then
        mkdir -p "$SKILLS_DST/$skill"
        cp "$SKILLS_SRC/$skill/SKILL.md" "$SKILLS_DST/$skill/SKILL.md"
        echo "   ✅ .claude/skills/$skill/SKILL.md"
    else
        echo "   ⚠️  .claude/skills/$skill/SKILL.md 不存在，跳过"
    fi
done

# 3. 复制项目文档
echo ""
echo "📦 收集项目文档..."
cp "$PROJECT_DIR/CLAUDE.md" "$PACKAGE_DIR/CLAUDE.md"
echo "   ✅ CLAUDE.md"
cp "$PROJECT_DIR/README.md" "$PACKAGE_DIR/README.md"
echo "   ✅ README.md"

# 4. 复制预置数据源
echo ""
echo "📦 收集预置数据源..."
mkdir -p "$PACKAGE_DIR/data/sources"
for src in akshare-sdk.json a-stock-data.json _default.json; do
    if [ -f "$PROJECT_DIR/data/sources/$src" ]; then
        cp "$PROJECT_DIR/data/sources/$src" "$PACKAGE_DIR/data/sources/$src"
        echo "   ✅ data/sources/$src"
    fi
done

# 5. 创建空目录（用户数据占位）
echo ""
echo "📦 创建用户数据目录..."
mkdir -p "$PACKAGE_DIR/data/strategies"
touch "$PACKAGE_DIR/data/strategies/.gitkeep"
echo "   ✅ data/strategies/ (空目录，放你的策略)"

mkdir -p "$PACKAGE_DIR/data/analysis"
touch "$PACKAGE_DIR/data/analysis/.gitkeep"
echo "   ✅ data/analysis/ (空目录，放分析记录)"

# 6. 生成安装说明
echo ""
echo "📦 生成安装说明..."
cat > "$PACKAGE_DIR/INSTALL.md" << 'INSTALL_DOC'
# 交易策略管理大师 — 安装说明

## 安装步骤

1. 将解压后的 `trading-strategy-master-*` 目录放到你希望的位置

2. 在 Claude Code 中注册项目：
   ```bash
   cd /path/to/trading-strategy-master-*
   # Claude Code 会自动识别项目根目录下的 CLAUDE.md 和 .claude/skills/
   ```

3. 验证安装：
   ```bash
   /share-strategy-manager 查看策略列表
   /share-data-source-manager 查看数据源列表
   ```

## 目录结构

```
.
├── CLAUDE.md                 # 项目指令（Claude Code 自动加载）
├── README.md                 # 项目文档
├── INSTALL.md                # 本文件
├── .claude/
│   └── skills/               # 4 个核心 Skill
│       ├── strategy-manager/   → /share-strategy-manager
│       ├── investment-analysis/→ /share-investment-analysis
│       ├── review-query/       → /share-review-query
│       └── data-source-manager/→ /share-data-source-manager
└── data/
    ├── sources/              # 预置数据源（含默认渠道）
    ├── strategies/           # 你的策略放这里
    └── analysis/             # 分析结果自动保存这里
```

## 快速开始

```bash
# 1. 查看预置数据源，设置默认获取渠道
/share-data-source-manager 查看数据源列表
/share-data-source-manager 使用 a-stock-data 作为默认数据源

# 2. 创建你的第一条策略
/share-strategy-manager 新增一条策略

# 3. 开始投资分析
/share-investment-analysis 帮我分析 XX股票

# 4. 复盘查看
/share-review-query 查看最近的分析记录
```

## 数据安全

- 你的策略和分析记录保存在 `data/` 目录下
- 策略变更会自动 git commit + push（如果在 git 仓库中）
- 建议初始化 git 并配置远端仓库以保证数据安全：
  ```bash
  git init
  git remote add origin <your-repo-url>
  ```
INSTALL_DOC
echo "   ✅ INSTALL.md"

# 7. 打包
echo ""
echo "📦 打包压缩..."
cd "$RELEASE_DIR"
tar -czf "$ARCHIVE_NAME" "$PACKAGE_NAME"
PACKAGE_SIZE=$(du -h "$ARCHIVE_NAME" | cut -f1)

# 8. 输出结果
echo ""
echo "============================================"
echo "  ✅ Release 打包完成"
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
echo "  安装方式："
echo "    1. 将 $ARCHIVE_NAME 发送给他人"
echo "    2. 解压：tar -xzf $ARCHIVE_NAME"
echo "    3. 进入目录，Claude Code 自动识别"
echo ""
