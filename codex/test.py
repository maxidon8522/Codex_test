import requests
import json
from datetime import datetime
import webbrowser
import os
import time

STATION_API = "https://apis.youbike.com.tw/json/station-min-yb2.json"
JSON_FILE = "latest_youbike.json"
BIKE_API = "https://apis.youbike.com.tw/api/front/bike/lists?station_no={}"  # 駅ごと
HEADERS = {
    "User-Agent": "Mozilla/5.0",
    "Referer": "https://www.youbike.com.tw/region/main/stations/"
}

def fetch_and_save_station_data():
    try:
        response = requests.get(STATION_API, headers=HEADERS, timeout=10, verify=False)
        response.raise_for_status()
        data = response.json()
        with open(JSON_FILE, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        print("最新の駅データを取得し、保存しました。")
    except Exception as e:
        print(f"駅データ取得失敗: {e}")
        exit(1)

def load_zhongli_station_nos():
    with open(JSON_FILE, "r", encoding="utf-8") as f:
        data = json.load(f)
    station_nos = []
    for s in data:
        if s.get("district_tw") == "中壢區":
            station_nos.append((s.get("station_no"), s.get("name_tw")))
    return station_nos

def fetch_bike_list(station_no):
    url = BIKE_API.format(station_no)
    res = requests.get(url, headers=HEADERS, timeout=10, verify=False)
    res.raise_for_status()
    return res.json().get("retVal", [])

def main():
    # 毎回最新の駅データを取得
    fetch_and_save_station_data()
    # 検索キーワード入力
    keyword = input("駅名キーワード（空欄で全件）: ").strip()
    station_info_list = load_zhongli_station_nos()
    if keyword:
        station_info_list = [s for s in station_info_list if keyword in s[1]]
    bike_rows = []
    for station_no, station_name in station_info_list:
        bikes = fetch_bike_list(station_no)
        for bike in bikes:
            bike_id = bike.get("bike_no", "")
            dock_no = bike.get("pillar_no", "")
            battery = bike.get("battery_power", "")
            update_time = bike.get("modify_time", "")
            if isinstance(update_time, int):
                update_time = datetime.fromtimestamp(update_time).strftime("%Y-%m-%d %H:%M:%S")
            bike_rows.append({
                "district": "中壢區",
                "station_id": station_no,
                "station_name": station_name,
                "bike_id": bike_id,
                "dock_no": dock_no,
                "battery": f"{battery}%",
                "update_time": update_time
            })
        time.sleep(0.5)
    bike_rows.sort(key=lambda x: (x["station_id"], -int(str(x["battery"]).replace('%','') or 0)))
    html = '''
    <html><head>
    <meta charset="utf-8">
    <title>YouBike Eバイク情報</title>
    <style>
    table {{ border-collapse: collapse; width: 90%; margin: 0 auto; background: #fff; }}
    th, td {{ border: 1px solid #b3c6e0; padding: 8px 10px; text-align: center; }}
    th {{ background: #222; color: #fff; font-size: 1.1em; }}
    tr:nth-child(even) {{ background: #f2f6fc; }}
    tr:nth-child(odd) {{ background: #fff; }}
    table {{ box-shadow: 0 0 8px #b3c6e0; }}
    </style>
    </head><body>
    <h2>中壢區 YouBikeE2.0 資訊 @ {}</h2>
    <table>
    <thead><tr><th>區域</th><th>場站編號</th><th>場站名稱</th><th>車輛編號</th><th>車柱</th><th>可用電量</th><th>更新時間</th></tr></thead>
    <tbody>
    '''.format(datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
    for row in bike_rows:
        html += f"<tr><td>{row['district']}</td><td>{row['station_id']}</td><td>{row['station_name']}</td><td>{row['bike_id']}</td><td>{row['dock_no']}</td><td>{row['battery']}</td><td>{row['update_time']}</td></tr>"
    html += "</tbody></table></body></html>"
    filename = f'youbike_ebike_info_{datetime.now().strftime("%Y%m%d_%H%M%S")}.html'
    with open(filename, 'w', encoding='utf-8') as f:
        f.write(html)
    webbrowser.open('file://' + os.path.realpath(filename))
    print(f"HTMLファイルを保存しました: {filename}")

if __name__ == "__main__":
    main()