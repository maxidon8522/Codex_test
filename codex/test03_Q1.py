import requests, json, os, webbrowser, subprocess, time
from pathlib import Path
import tempfile
from datetime import datetime
import urllib3

# --- APIエンドポイント定義 ---
STATIC_INFO_URL = "https://apis.youbike.com.tw/json/station-min-yb2.json"

REALTIME_BIKE_URL = "https://apis.youbike.com.tw/api/front/bike/lists"

JSON_FILE = "youbike_zhongli_data.html"

HEADERS = {
    "User-Agent": ("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
                   "AppleWebKit/537.36 (KHTML, like Gecko) "
                   "Chrome/120.0.0.0 Safari/537.36")
}
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

def get_station_list(district_name, keywords):
    """ステップ1: 特定の区のステーションリストを取得する"""
    print(f"[{datetime.now().strftime('%H:%M:%S')}] ステップ1: 全ステーションのリストを取得中...")
    try:
        res = requests.get(STATIC_INFO_URL, headers=HEADERS, timeout=10, verify=False)
        res.raise_for_status()
        all_stations = res.json()
        
        filtered_stations = [
            s for s in all_stations
            if s.get("district_tw") == district_name
            and (not keywords or any(k in s.get("name_tw", "") for k in keywords))
        ]
        print(f"[{datetime.now().strftime('%H:%M:%S')}] {district_name}で{len(filtered_stations)}件のステーションが見つかりました。")
        return filtered_stations
    except Exception as e:
        print(f"ステーションリストの取得に失敗しました: {e}")
        return []

def get_realtime_station_data(station_list):
    """各ステーションのリアルタイムデータを取得し、情報を結合する"""
    print(f"[{datetime.now().strftime('%H:%M:%S')}] ステップ2: 各ステーションのリアルタイム情報を取得します...")
    final_data = []

    for i, station in enumerate(station_list):
        station_id = station.get("station_no")
        station_name = station.get("name_tw")
        print(f"  ({i+1}/{len(station_list)}) {station_name} ({station_id}) の情報を取得中...")

        try:
            params = {"station_no": station_id}
            res = requests.get(REALTIME_BIKE_URL, params=params, headers=HEADERS, timeout=5, verify=False)
            if res.status_code == 200 and res.text:
                details = res.json()
                if details.get("retCode") == 1:
                    bike_list = details.get("retVal", [])
                    # battery_powerのリストを作る
                    battery_levels = [b.get('battery_power', 0) for b in bike_list if b.get('battery_power') is not None]
                    # 最大バッテリー値
                    max_battery = max(battery_levels) if battery_levels else 0
                    bike_count = len(bike_list)
                    final_data.append({
                        "district": station.get("district_tw", ""),
                        "station_id": station_id,
                        "station_name": station_name,
                        "address": station.get("address_tw", ""),
                        "bike_count": bike_count,
                        "battery_percent": max_battery,
                        "updated_at": datetime.now().strftime('%Y-%m-%d %H:%M:%S')
                    })
            time.sleep(0.3)
        except Exception as e:
            print(f"    → {station_name} の情報取得でエラー: {e}")
            continue

    return final_data



def rank_stations_by_battery(lst, top_n=5):
    """バッテリー残量で上位N件を返す"""
    return sorted(lst, key=lambda x: int(x.get("battery_percent") or 0), reverse=True)[:top_n]

def generate_html(lst, district_name, keywords):
    """結果をHTMLファイルとして生成する"""
    now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    keyword_str = '、'.join(keywords) if keywords else "全站"
    title = f"{district_name} {keyword_str} YouBikeE2.0 資訊 @ {now}"

    ranking = rank_stations_by_battery(lst)
    rank_html = "<h3>🔋 バッテリー残量ランキング（上位5件・最大値）</h3><ol>"
    for s in ranking:
        rank_html += f"<li>{s['station_name']}（{s['battery_percent']}%）</li>"
    rank_html += "</ol>"

    rows = ""
    for s in sorted(lst, key=lambda x: x["station_id"]): # station_idでソート
        rows += (
            f"<tr><td>{s['district']}</td><td>{s['station_id']}</td><td>{s['station_name']}</td>"
            f"<td>{s['address']}</td><td>{s['bike_count']}</td><td>{s['battery_percent']}%</td>"
            f"<td>{s['updated_at']}</td></tr>"
        )
    
    html_content = f"""<!DOCTYPE html>
<html lang="ja"><head><meta charset="UTF-8"><title>{title}</title>
<style>
body{{font-family:Arial,Helvetica,sans-serif;background:#f5f5f5;margin:20px}}h2,h3{{text-align:center}}
table{{width:100%;border-collapse:collapse;background:#fff;margin:0 auto;box-shadow:0 2px 5px rgba(0,0,0,0.1)}}
th,td{{padding:10px;border-bottom:1px solid #ddd;text-align:left}}th{{background:#222;color:#fff;text-align:center}}
td:nth-child(1),td:nth-child(2),td:nth-child(5),td:nth-child(6),td:nth-child(7){{text-align:center}}
tr:nth-child(even){{background:#f9f9f9}}tr:hover{{background:#f1f1f1}}
ol{{width:60%;margin:20px auto;padding:10px;background:#fff;box-shadow:0 2px 5px rgba(0,0,0,0.1)}}
</style></head><body>
<h2>{title}</h2>{rank_html}
<table><thead><tr><th>區域</th><th>場站編號</th><th>場站名稱</th><th>地址</th><th>車輛數</th><th>可用電量(最大)</th><th>更新時間</th></tr></thead>
<tbody>{rows}</tbody></table></body></html>"""
    
    try:
        filepath = f"{district_name}_YouBike_{datetime.now().strftime('%Y%m%d_%H%M%S')}.html"
        with open(filepath, "w", encoding="utf-8") as f:
            f.write(html_content)
        print(f"[{datetime.now().strftime('%H:%M:%S')}] HTMLファイルが生成されました: {filepath}")
        return filepath
    except Exception as e:
        print(f"HTMLファイルの保存に失敗しました: {e}")
        return None

def open_html_file(filepath):
    """生成されたHTMLをブラウザで開く"""
    if not filepath: return
    abs_path = os.path.realpath(filepath)
    uri = Path(abs_path).as_uri()
    print(f"ブラウザで開いています: {uri}")
    webbrowser.open(uri)

def main():
    """メイン処理"""
    district = "中壢區"
    keyword_input = input("検索キーワード（カンマ区切り、空=全件）: ")
    keywords = [k.strip() for k in keyword_input.split(',') if k.strip()]
    
 
    station_list = get_station_list(district, keywords)
    
    if not station_list:
        print("処理対象のステーションが見つかりませんでした。")
        return
        

    full_data = get_realtime_station_data(station_list)
    
    if not full_data:
        print("リアルタイムデータの取得に失敗しました。")
        return
    
    # HTML生成と表示
    html_path = generate_html(full_data, district, keywords)
    open_html_file(html_path)

if __name__ == "__main__":
    main()