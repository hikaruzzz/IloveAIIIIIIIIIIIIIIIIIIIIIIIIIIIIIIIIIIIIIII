# 交易策略管理大师

一个 Claude Code Skill 项目，将交易策略管理、投资分析、复盘查询、数据获取整合为一套完整的分析工作流。全部通过自定义 Slash Command 驱动。

## 项目架构

```
.claude/skills/
├── strategy-manager/        # 交易策略管理
├── investment-analysis/     # 投资分析
├── review-query/            # 复盘查询
└── data-source-manager/     # 数据获取管理

data/
├── strategies/              # 策略定义（JSON）
├── sources/                 # 数据源配置（JSON）+ 默认渠道指向
└── analysis/                # 历史分析记录（JSON）
```

## 四大 Skill

### 交易策略管理 `share-strategy-manager`

增删改查用户交易策略。每条策略定义入场/出场规则、技术指标、风控参数，支持多市场多周期。策略修改后自动 git commit + push。

### 投资分析 `share-investment-analysis`

核心分析引擎。完整流程：

```
前置检查（默认数据源）
    │
    ▼
标的输入 → 全量策略自动筛选
    │
    ▼
按策略倒推数据需求 → 去重汇总清单
    │
    ▼
skill 类型数据源自动调用 / 其他类型提示用户提供
    │
    ▼
逐条策略独立匹配（入场/出场规则逐项比对）
    +
支撑位 & 压力位预测（基于均线、前高前低、斐波那契、布林带等，标注强度 ⭐1-5）
    │
    ▼
综合结论（多策略共振/分歧分析）→ 保存 JSON
```

**设计要点：**

- **不做策略选择**：自动对所有适用策略并行分析，不询问用户偏好
- **需求驱动获取**：先解析策略需要的指标，去重后精准请求，不盲目拉全量数据
- **skill 数据源自动调用**：数据源为 skill 类型时，直接通过 Skill 工具调用，无需用户手工提供
- **必须输出支撑压力位**：至少各 3 个关键价位，标注强度和计算依据

### 复盘查询 `share-review-query`

按时间、标的、策略、信号方向等多维度查询历史分析记录。支持列表模式和详情模式，亦可结合实盘走势做复盘偏差分析。

### 数据获取管理 `share-data-source-manager`

管理投资标的的行情数据获取渠道。支持 API、SDK、Website、Skill 等多种渠道类型。

**核心机制 — 默认获取渠道：**

- 用户指定一个渠道为默认（`data/sources/_default.json`）
- 投资分析**强制锁定**该默认渠道，不可使用其他来源
- 无默认渠道时投资分析直接终止
- 只有 `active` 状态渠道可设为默认
- 当前默认渠道不可删除

**skill 类型渠道联动：**

- 新增 skill 类型数据源时，自动在 `.claude/skills/<slug>/` 创建对应 skill
- 删除 skill 类型数据源时，同步删除对应 skill 目录
- skill 类型渠道可直接被投资分析调用获取数据

## 数据流全景

```
用户创建策略 ──→ data/strategies/*.json ──→ git commit & push
                                                 │
用户设置默认数据源 ──→ data/sources/_default.json │
                                                 │
用户发起投资分析 ──→ 1. 检查默认数据源            │
                   2. 筛选适用策略 ←──────────────┘
                   3. 倒推数据需求清单
                   4. 调用数据源获取数据
                   5. 逐策略匹配 + 支撑压力位
                   6. 综合结论
                   7. 保存 data/analysis/*.json

用户复盘查询 ──→ data/analysis/*.json ──→ 多维度筛选 + 偏差分析
```

## 数据模型

### 策略 JSON — `data/strategies/<slug>.json`

| 字段 | 说明 |
|------|------|
| `name` / `slug` | 策略标识 |
| `type` | trend / momentum / mean-reversion / arbitrage / custom |
| `market` | 适用市场，支持「通用」表示不限 |
| `timeframe` | 日线 / 小时线 / ... |
| `indicators` | 技术指标及参数 |
| `entryRules` | 入场条件列表 |
| `exitRules` | 出场条件列表 |
| `riskManagement` | 止损/止盈/仓位 |

### 数据源 JSON — `data/sources/<slug>.json`

| 字段 | 说明 |
|------|------|
| `name` / `slug` | 渠道标识 |
| `type` | api / website / data-vendor / rss / sdk / skill / other |
| `market` | 覆盖的交易市场 |
| `dataTypes` | 提供的数据品类 |
| `cost` / `needAuth` | 费用和认证信息 |
| `status` | active / inactive / deprecated |

### 分析记录 JSON — `data/analysis/<时间>-<标的>.json`

每条记录包含：基本信息（标的、时间、数据来源）、数据需求清单、三面数据（数据面/技术面/消息面）、支撑压力位、逐策略匹配结果、综合结论。

## 关键设计决策

1. **数据源与 Skill 联动**：skill 类型数据源自动创建/删除对应 Skill，投资分析时通过 Skill 工具直接调用获取数据
2. **默认渠道单一路径**：分析全程锁定一个数据源，确保数据一致性，防止多源混淆
3. **需求驱动**：先看策略需要什么数据再去获取，而非盲目拉取
4. **全量策略并行**：不替用户选策略，所有适用策略平等分析，让结论从策略共振/分歧中自然显现
5. **自动版本管理**：策略和数据源变更自动 git commit + push

## 使用示例

```bash
# 管理策略
/share-strategy-manager 新增一条趋势跟踪策略
/share-strategy-manager 查看所有策略

# 管理数据源
/share-data-source-manager 新增一个 skill 类型的获取渠道
/share-data-source-manager 设为默认数据源

# 投资分析（自动使用默认数据源 + 全部适用策略）
/share-investment-analysis 帮我分析伦敦现金

# 复盘查询
/share-review-query 最近一周的分析记录
/share-review-query 查询 600519 的历史分析
```
