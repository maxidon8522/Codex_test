(function(){
    const body = document.body;
    const btnMonth = document.getElementById('btn-month');
    const btnWeek  = document.getElementById('btn-week');
    const monthView = document.getElementById('month-view');
    const weekView  = document.getElementById('week-view');
  
    // 預設今日為 2025-10-03（繁體中文） / 既定の今日を2025-10-03に固定（日本語）
    const todayBadge = document.getElementById('today-badge');
    todayBadge.textContent = '今日：10/03';
  
    // 切換月曆與週曆的基本函式（繁體中文） / 月表示と週表示を切り替える基本関数（日本語）
    function show(view){
      if(view === 'month'){
        body.setAttribute('data-view','month');
        monthView.hidden = false;
        weekView.hidden = true;
        btnMonth.classList.add('active'); btnMonth.setAttribute('aria-pressed','true');
        btnWeek.classList.remove('active'); btnWeek.setAttribute('aria-pressed','false');
      }else{
        body.setAttribute('data-view','week');
        monthView.hidden = true;
        weekView.hidden = false;
        btnWeek.classList.add('active'); btnWeek.setAttribute('aria-pressed','true');
        btnMonth.classList.remove('active'); btnMonth.setAttribute('aria-pressed','false');
      }
    }
    btnMonth.addEventListener('click', ()=> show('month'));
    btnWeek .addEventListener('click', ()=> show('week'));
  
    // 天氣背景可手動切換做展示（繁體中文） / 天気背景は手動切替でデモ可能（日本語）
    // body.className = 'weather-cloudy';
    // body.className = 'weather-rainy';
  
    // 上一個月與下一個月按鈕僅示意（繁體中文） / 前月・次月ボタンは見た目のみ（日本語）
    document.getElementById('btn-prev').addEventListener('click', ()=>{
      // 若要加入實際邏輯可在此撰寫（繁體中文） / 実際のロジックを追加する場合はここに記述（日本語）
      alert('（示範）切換至上個月，實際功能非必須。');
    });
    document.getElementById('btn-next').addEventListener('click', ()=>{
      alert('（示範）切換至下個月，實際功能非必須。');
    });
  
  })();
  
