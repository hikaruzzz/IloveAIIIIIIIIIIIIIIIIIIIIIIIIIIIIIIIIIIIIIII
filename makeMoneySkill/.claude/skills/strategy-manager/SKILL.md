---
name: share-strategy-manager
description: 管理用户的交易策略 — 支持增删改查
---

# 交易策略管理

当用户调用 `/share-strategy-manager` 或提及「管理策略」「增删改查策略」时，按以下规则执行。

## 数据存储

- 所有策略保存在 `data/strategies/` 目录下
- 每条策略一个 JSON 文件，文件名使用策略名称（英文 slug），如 `ma-trend-following.json`
- 策略 JSON 结构：

```json
{
  "name": "策略名称",
  "slug": "ma-trend-following",
  "description": "策略描述，一句话说明",
  "type": "trend | momentum | mean-reversion | arbitrage | custom",
  "market": "A股 | 港股 | 美股 | 加密货币",
  "timeframe": "日线 | 周线 | 小时线 | 15分钟线",
  "indicators": [
    {"name": "MA", "params": {"period": 20}},
    {"name": "MACD", "params": {"fast": 12, "slow": 26, "signal": 9}}
  ],
  "entryRules": [
    "当 MA5 上穿 MA20 时买入",
    "MACD 金叉确认"
  ],
  "exitRules": [
    "当 MA5 下穿 MA20 时卖出",
    "止损 -5%"
  ],
  "riskManagement": {
    "stopLoss": "-5%",
    "takeProfit": "+15%",
    "positionSize": "总资金的 20%"
  },
  "createdAt": "2026-06-19T10:00:00+08:00",
  "updatedAt": "2026-06-19T10:00:00+08:00"
}
```

## 操作流程

### 1. 查看策略列表

- 读取 `data/strategies/` 下所有 JSON 文件
- 以表格形式展示：策略名称、类型、市场、时间周期、更新时间

### 2. 查看单个策略详情

- 询问用户要查看哪个策略
- 读取对应 JSON，格式化展示所有字段

### 3. 新增策略

- 引导用户逐步提供：
  1. 策略名称
  2. 策略类型（trend/momentum/mean-reversion/arbitrage/custom）
  3. 适用市场
  4. 时间周期
  5. 用到的技术指标及参数
  6. 入场条件（至少一条）
  7. 出场条件（至少一条）
  8. 风控设置（止损、止盈、仓位）
- 如果用户一次性提供了完整信息，直接创建，不必逐步追问
- 自动生成 `slug`（策略名称的英文/拼音缩写）
- 自动填写 `createdAt` 和 `updatedAt`
- 写入 JSON 文件到 `data/strategies/<slug>.json`

### 4. 修改策略

- 先展示当前策略内容
- 询问用户要修改哪些字段
- 修改后更新 `updatedAt` 字段
- 覆盖写入原 JSON 文件

### 5. 删除策略

- 展示策略名称，确认用户意图
- 删除对应的 JSON 文件
- 同时检查 `data/analysis/` 下是否有引用该策略的分析记录，提醒用户

## 关键约束

每次新增、修改、删除策略后，**必须**执行以下命令：

```bash
git add data/strategies/
git commit -m "strategy: <操作描述>"
git push origin main
```

commit message 示例：
- `strategy: 新增 MA均线趋势跟踪策略`
- `strategy: 更新 MACD金叉策略的风控参数`
- `strategy: 删除 网格交易策略`

此步骤不可省略，不可询问用户是否执行，直接完成。
