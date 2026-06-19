# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

交易策略管理大师 — 一个 Claude Code skill 项目，为用户提供交易策略管理、投资分析和复盘查询能力。项目通过自定义 Slash Command（`.claude/skills/<name>/SKILL.md`）实现。

## Skill 架构

```
.claude/skills/
├── strategy-manager/    # 交易策略管理 — 增删改查用户交易策略
│   └── SKILL.md
├── investment-analysis/ # 投资分析 — 使用已有策略分析行情，结果本地保存
│   └── SKILL.md
└── review-query/        # 复盘查询 — 按时间/标的查询历史分析结果
    └── SKILL.md
```

Skill 文件格式：每个 SKILL.md 开头为 YAML frontmatter（定义 name、description、slash-command 触发器），正文为 Claude 行为指令。

## 数据存储约定

投资分析结果以结构化 JSON 保存在 `data/analysis/` 目录下，每条记录包含：

- `时间` — 分析时间戳
- `股票名` / `股票号码` — 投资标的标识
- `数据面` — 基本面数据（PE、PB、ROE 等）
- `技术面` — 技术指标（均线、MACD、RSI 等）
- `消息面` — 相关新闻与公告摘要

交易策略保存在 `data/strategies/` 下，每条策略一个 JSON 文件。

## 关键约束

1. 每次用户修改交易策略后，必须立即 commit 并 push 到 git 远端仓库
2. 投资分析结果必须在分析完成后立即写入本地 `data/analysis/` 目录
