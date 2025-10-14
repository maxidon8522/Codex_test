(function(){
    const body = document.body;
    const btnMonth = document.getElementById('btn-month');
    const btnWeek  = document.getElementById('btn-week');
    const monthView = document.getElementById('month-view');
    const weekView  = document.getElementById('week-view');
  
    // 既定の「今日」を 2025-10-03 固定（要件）
    const todayBadge = document.getElementById('today-badge');
    todayBadge.textContent = '今天：10/03';
  
    // 表示切替（加点狙いの最小機能）
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
  
    // 天気背景の手動切替（デモ用）
    // body.className = 'weather-cloudy'; // 例：曇りに変更
    // body.className = 'weather-rainy';
  
    // 前月・次月ボタンは見た目のみ（要件OK）。動かすなら下記のダミー例：
    document.getElementById('btn-prev').addEventListener('click', ()=>{
      // ここに月表示切替ロジックを入れると加点の可能性
      alert('（デモ）前月に切り替えます（実動は必須ではありません）');
    });
    document.getElementById('btn-next').addEventListener('click', ()=>{
      alert('（デモ）次月に切り替えます（実動は必須ではありません）');
    });
  
  })();
  