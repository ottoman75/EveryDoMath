#!/usr/bin/env python3
"""App Store 검색 순위 기준선 측정.

30일 뒤 비교하려면 **같은 방법으로** 다시 재야 한다 — 같은 API, 같은 키워드,
limit=200. 숫자만 바꿔 적으면 비교가 아니라 착각이 된다.

주의: iTunes Search API 의 순위는 기기 App Store 검색과 완전히 같지 않다.
절대 순위가 아니라 **같은 자로 잰 변화**를 보는 용도다.

사용: python3 marketing/scripts/keyword_rank.py
"""
import json, time, urllib.parse, urllib.request

APP_ID = 6816351885
KWS = ["매일매일 수학","초등 수학","초등 연산","구구단","받아내림","학습지","문제집",
       "암산","분수 연습","초등학생 수학"]
print(f"{'키워드':<14} {'순위':>6}  {'결과수':>5}")
print("-"*32)
for kw in KWS:
    url = ("https://itunes.apple.com/search?term=" + urllib.parse.quote(kw) +
           "&country=kr&entity=software&limit=200")
    try:
        d = json.load(urllib.request.urlopen(url, timeout=20))
        ids = [r.get("trackId") for r in d.get("results", [])]
        rank = ids.index(APP_ID) + 1 if APP_ID in ids else None
        print(f"{kw:<14} {str(rank) if rank else '미노출':>6}  {len(ids):>5}")
    except Exception as e:
        print(f"{kw:<14} {'오류':>6}  {e}")
    time.sleep(3)
