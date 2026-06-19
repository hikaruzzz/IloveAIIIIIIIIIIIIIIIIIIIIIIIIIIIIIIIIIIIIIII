---
name: share-data-source-manager
description: 管理投资标的的数据获取渠道 — 支持增删改查
---

# 数据获取管理

当用户调用 `/share-data-source-manager` 或提及「数据源」「数据渠道」「获取渠道」「数据来源」时，按以下规则执行。

## 数据存储

- 所有数据源保存在 `data/sources/` 目录下
- 每条数据源一个 JSON 文件，文件名使用渠道名称（英文 slug），如 `eastmoney-api.json`
- 数据源 JSON 结构：

```json
{
  "name": "东方财富 API",
  "slug": "eastmoney-api",
  "type": "api",
  "description": "东方财富免费行情接口，支持 A 股实时与历史数据",
  "url": "https://push2his.eastmoney.com/api/qt/stock/trends2/get",
  "docUrl": "https://www.eastmoney.com/api-doc",
  "market": ["A股", "港股"],
  "dataTypes": ["实时行情", "历史K线", "财务数据", "板块资金"],
  "frequency": "实时",
  "cost": "免费",
  "needAuth": false,
  "authType": "",
  "apiKey": "",
  "secretKey": "",
  "rateLimit": "无明确限制",
  "notes": "适合个人开发者，数据覆盖全面，稳定性较好",
  "status": "active",
  "createdAt": "2026-06-19T16:00:00+08:00",
  "updatedAt": "2026-06-19T16:00:00+08:00"
}
```

### 字段说明

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `name` | string | ✅ | 渠道名称 |
| `slug` | string | ✅ | 英文标识，自动生成 |
| `type` | string | ✅ | 渠道类型：`api` / `website` / `data-vendor` / `rss` / `sdk` / `other` |
| `description` | string | ✅ | 一句话说明 |
| `url` | string |  | 接口地址或网站地址 |
| `docUrl` | string |  | 文档地址 |
| `market` | string[] | ✅ | 支持的交易市场 |
| `dataTypes` | string[] | ✅ | 提供的数据类型 |
| `frequency` | string |  | 数据更新频率 |
| `cost` | string | ✅ | 费用：`免费` / `付费` / `免费+付费` |
| `needAuth` | boolean | ✅ | 是否需要认证 |
| `authType` | string |  | 认证方式：`api_key` / `oauth` / `token` / `cookie` / `none` |
| `apiKey` | string |  | API Key（敏感，仅本地存储） |
| `secretKey` | string |  | Secret Key（敏感，仅本地存储） |
| `rateLimit` | string |  | 频率限制说明 |
| `notes` | string |  | 使用备注、踩坑记录 |
| `status` | string | ✅ | 状态：`active` / `inactive` / `deprecated` |
| `createdAt` | string | ✅ | 创建时间 |
| `updatedAt` | string | ✅ | 更新时间 |

### 渠道类型（type）

- `api` — RESTful / WebSocket API 接口
- `website` — 网页抓取（东方财富、同花顺官网等）
- `data-vendor` — 专业数据商（Wind、彭博、Choice 等）
- `rss` — RSS 新闻源
- `sdk` — Python/JavaScript SDK 包（tushare、akshare 等）
- `other` — 其他渠道

### 数据类型（dataTypes）

常用取值：`实时行情` `历史K线` `财务数据` `公司公告` `新闻资讯` `研报` `资金流向` `龙虎榜` `板块数据` `指数数据` `期权数据` `期货数据` `加密货币` `宏观经济` `社交媒体`

## 操作流程

### 1. 查看数据源列表

- 读取 `data/sources/` 下所有 JSON 文件
- 以表格形式展示：名称、类型、市场、数据类型、费用、状态、更新时间
- 支持按状态筛选：`active` / `inactive` / `deprecated`

### 2. 查看单个数据源详情

- 询问用户要查看哪个数据源
- 读取对应 JSON，格式化展示所有字段
- **敏感字段**（`apiKey`、`secretKey`）默认脱敏显示（如 `sk-xxx...xxx`），除非用户明确要求查看完整值

### 3. 新增数据源

引导用户提供以下信息：

1. 渠道名称（必须）
2. 渠道类型（必须，从 `type` 枚举中选择）
3. 一句话描述（必须）
4. 接口/网站地址
5. 支持的交易市场（必须，至少一个）
6. 提供的数据类型（必须，至少一个）
7. 数据更新频率
8. 费用情况（必须）
9. 是否需要认证 → 如需要，认证方式和密钥
10. 频率限制说明
11. 使用备注

- 如果用户一次性提供了完整信息，直接创建，不必逐步追问
- 自动生成 `slug`（渠道名称的英文/拼音缩写）
- 自动填写 `createdAt`、`updatedAt` 和默认 `status: "active"`
- 写入 JSON 文件到 `data/sources/<slug>.json`

### 4. 修改数据源

- 先展示当前数据源内容（敏感字段脱敏）
- 询问用户要修改哪些字段
- 修改后更新 `updatedAt` 字段
- 覆盖写入原 JSON 文件
- 如果用户要更新密钥信息，直接替换，不要展示旧值

### 5. 删除数据源

- 展示数据源名称和描述，确认用户意图
- 删除对应的 JSON 文件
- 提醒用户检查是否有策略或分析引用了该数据源

### 6. 按市场/类型筛选

- `按市场筛选` — 如"A股有哪些数据源"
- `按类型筛选` — 如"有哪些 API 接口"
- `按数据类型筛选` — 如"能获取实时行情的渠道有哪些"
- 支持组合筛选

### 7. 设置默认获取渠道

默认获取渠道是投资分析时必须使用的唯一数据来源。用户只能设置一个默认渠道。

**查看当前默认渠道：**
- 读取 `data/sources/_default.json`
- 如果存在，展示当前默认渠道的名称和关键信息
- 如果不存在，告知用户尚未设置

**设置默认渠道：**
- 先列出所有 `status: "active"` 的数据源供用户选择
- 用户选择后，将默认配置写入 `data/sources/_default.json`，格式：
```json
{
  "slug": "akshare-sdk",
  "setAt": "2026-06-19T17:00:00+08:00"
}
```
- 如果已有默认渠道，覆盖旧值
- 设置成功后，提示用户：「投资分析将强制使用此渠道获取数据」

**取消默认渠道：**
- 删除 `data/sources/_default.json`
- 警告用户：取消后投资分析将无法执行

**约束：**
- 只有 `status: "active"` 的数据源才能设为默认
- 如果用户尝试设为默认的数据源状态为 `inactive` 或 `deprecated`，拒绝并提示先激活该数据源
- 删除数据源时，如果该数据源是当前默认渠道，阻止删除并提示先取消默认或切换默认

## 常用预置数据源

当用户首次使用时，可以询问是否需要预置以下常用免费数据源：

| 名称 | 类型 | 市场 | 数据类型 |
|------|------|------|----------|
| AKShare | SDK | A股/港股/美股/期货 | 全品类 |
| Tushare | SDK/API | A股 | 行情/财务/资金 |
| 东方财富 | Website/API | A股/港股 | 行情/财务/资金 |
| 新浪财经 | API | A股/港股/美股 | 实时行情 |
| 雪球 | Website/API | A股/港股/美股 | 行情/新闻/讨论 |
| CoinGecko | API | 加密货币 | 行情/市值 |

## 关键约束

每次新增、修改、删除数据源后，**必须**执行以下命令：

```bash
git add data/sources/
git commit -m "datasource: <操作描述>"
git push origin main
```

commit message 示例：
- `datasource: 新增 东方财富 API 数据源`
- `datasource: 更新 AKShare 配置信息`
- `datasource: 删除 已失效的新浪 RSS 源`

此步骤不可省略，不可询问用户是否执行，直接完成。
