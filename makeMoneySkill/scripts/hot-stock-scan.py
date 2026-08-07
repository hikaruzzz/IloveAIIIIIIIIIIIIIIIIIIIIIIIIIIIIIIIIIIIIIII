#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
妖股池扫描器 — 拉取全市场涨停池，按 hot-money-stock 策略识别规则筛选分级
用法: python3 hot-stock-scan.py [YYYYMMDD]  (默认当日)
输出: 控制台报告 + data/scans/{date}-hot-stock-pool.json
"""
import json, sys, os, urllib.request
from datetime import datetime, timedelta
from collections import Counter

DATE = sys.argv[1] if len(sys.argv) > 1 else datetime.now().strftime("%Y%m%d")
BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_DIR = os.path.join(BASE, "data", "scans")
os.makedirs(OUT_DIR, exist_ok=True)

URL = (f"https://push2ex.eastmoney.com/getTopicZTPool?ut=7eea3edcaed734bea9cbfc24409ed989"
       f"&dpt=wz.ztzt&Pageindex=0&pagesize=200&sort=fbt%3Aasc&date={DATE}")

def fetch():
    req = urllib.request.Request(URL, headers={"Referer": "https://quote.eastmoney.com/", "User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req, timeout=15) as r:
        return json.loads(r.read().decode())

def main():
    try:
        d = fetch()
    except Exception as e:
        print(f"⛔ 涨停池获取失败: {e}")
        print("提示: 可检查网络/接口，或改用 /share-a-stock-data 手动获取")
        return
    pool = d["data"]["pool"]
    print(f"📅 {DATE} 涨停池: 共 {d['data']['tc']} 只涨停")

    hot, potential, watch = [], [], []
    for s in pool:
        name, code = s["n"], s["c"]
        price = s["p"] / 100
        lbc, hs, zbc = s["lbc"], s["hs"], s["zbc"]
        fund = s["fund"] / 1e8
        ltsz = s["ltsz"] / 1e8
        hybk = s["hybk"]
        zttj = s.get("zttj", {})
        gene = zttj.get("ct", 1)  # 近期涨停次数(基因)
        one_word = hs < 2.5 and zbc == 0  # 一字板判断
        tags = []
        if one_word: tags.append("一字板·无换手")
        if lbc >= 4: tags.append("加速末端·不追")
        if zbc >= 5: tags.append(f"炸板{zbc}次·封板不稳")
        if ltsz > 200: tags.append("大盘·难妖")
        if gene >= 4: tags.append(f"{zttj.get('days','?')}日{gene}涨停·基因强")

        item = {
            "代码": code, "名称": name, "现价": round(price, 2), "连板": lbc,
            "换手": round(hs, 1), "封单亿": round(fund, 2), "炸板": zbc,
            "流通市值亿": round(ltsz, 0), "行业": hybk, "涨停基因": f"{zttj.get('days','?')}日{gene}次",
            "标签": tags
        }
        # 分级: 高度妖股 = 3板+ 健康换手 小市值 低炸板
        if lbc >= 3 and 2.5 <= hs <= 25 and zbc <= 2 and ltsz <= 150:
            hot.append(item)
        elif lbc == 2 and 2.5 <= hs <= 25 and zbc <= 2 and ltsz <= 150:
            potential.append(item)
        else:
            watch.append(item)

    def show(title, emoji, items):
        print(f"\n{emoji} {title} ({len(items)}只)")
        if not items:
            print("  (无)")
        for it in items:
            tag = " ".join(it["标签"]) if it["标签"] else ""
            print(f"  {it['名称']}({it['代码']}) {it['现价']}元 {it['连板']}连板 "
                  f"换手{it['换手']}% 封单{it['封单亿']}亿 炸板{it['炸板']} 流通{it['流通市值亿']:.0f}亿 "
                  f"[{it['行业']}] 基因:{it['涨停基因']} {tag}")

    show("🔥 高度妖股 (3板+·健康换手·小市值)", "🔥", hot)
    show("⚡ 潜力妖股 (2板·待确认加速)", "⚡", potential)
    show("👀 观察池 (首板/一字/高炸板/大盘)", "👀", watch)

    # 关联策略状态
    print("\n📌 策略状态参考 (hot-money-stock):")
    for it in hot:
        if it["连板"] >= 4:
            print(f"  {it['名称']}: {it['连板']}连板加速末端 → 持仓兑现区/不追入")
        else:
            print(f"  {it['名称']}: {it['连板']}连板确认期 → 按纪律试错区间(≤10%仓位), 断板即离场")
    for it in potential:
        print(f"  {it['名称']}: 2板确认 → 试错窗口(≤10%), 断板减半/破前日涨停价清仓")

    # 保存
    out = {
        "日期": DATE, "涨停总数": d["data"]["tc"],
        "高度妖股": hot, "潜力妖股": potential, "观察池": watch,
        "生成时间": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        "策略依据": "hot-money-stock 识别规则: 题材+涨停基因+底部结构+健康换手+小市值",
        "风险提示": "妖股池仅为识别结果，不预测连板高度；参与必须遵守断板纪律与仓位隔离(单票≤20%/同题材≤30%/策略资金≤30%)。不构成投资建议。"
    }
    path = os.path.join(OUT_DIR, f"{DATE}-hot-stock-pool.json")
    with open(path, "w", encoding="utf-8") as f:
        json.dump(out, f, ensure_ascii=False, indent=2)
    print(f"\n✅ 扫描结果已保存: {path}")

if __name__ == "__main__":
    main()
