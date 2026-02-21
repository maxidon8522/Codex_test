(function(){
  const ICS_URL = './assets/thu_calendar.ics';
  const GEO_BASE = 'https://nominatim.openstreetmap.org/reverse';
  const WEATHER_BASE = 'https://api.open-meteo.com/v1/forecast';
  const WEATHER_CLASSES = [
    'weather-sunny',
    'weather-sunny-cloudy',
    'weather-cloudy',
    'weather-cloudy-rainy',
    'weather-rainy',
    'weather-thunder'
  ];
  const WEEKDAY_LABELS = ['日','一','二','三','四','五','六'];
  const REMINDER_DATES = new Set(['10-27','11-01']);
  const ACTIVITY_DATES = new Set(['10-21','10-24','10-25']);
  const DEFAULT_COORDS = { latitude: 24.179, longitude: 120.646, label: '台中市西屯區' };

  const state = {
    events: [],
    currentMonth: startOfMonth(new Date()),
    currentWeekStart: null,
    today: startOfDay(new Date())
  };
  state.currentWeekStart = getWeekStart(state.today);

  const dom = {};
  let loadingTasks = 0;

  document.addEventListener('DOMContentLoaded', init);

  function init(){
    cacheDom();
    bindEvents();
    syncWeekdayHighlights();
    updateTodayBadge();
    setDateLine(new Date());
    renderMonthView();
    renderWeekView();
    loadCalendarEvents();
    loadWeatherData();
  }

  function cacheDom(){
    dom.body = document.body;
    dom.btnMonth = document.getElementById('btn-month');
    dom.btnWeek = document.getElementById('btn-week');
    dom.btnPrev = document.getElementById('btn-prev');
    dom.btnNext = document.getElementById('btn-next');
    dom.monthView = document.getElementById('month-view');
    dom.weekView = document.getElementById('week-view');
    dom.monthGrid = dom.monthView?.querySelector('.grid');
    dom.monthTitle = dom.monthView?.querySelector('.month-title');
    dom.weekGrid = dom.weekView?.querySelector('.grid');
    dom.currentLabel = document.getElementById('current-label');
    dom.todayBadge = document.getElementById('today-badge');
    dom.location = document.getElementById('current-location');
    dom.condition = document.getElementById('current-condition');
    dom.temperature = document.getElementById('current-temperature');
    dom.dateLine = document.getElementById('current-date-line');
    dom.forecastList = document.getElementById('forecast-list');
    dom.loadingMask = document.getElementById('loading-mask');
  }

  function bindEvents(){
    dom.btnMonth?.addEventListener('click', ()=> switchView('month'));
    dom.btnWeek?.addEventListener('click', ()=> {
      switchView('week');
      renderWeekView();
    });
    dom.btnPrev?.addEventListener('click', ()=> changeMonth(-1));
    dom.btnNext?.addEventListener('click', ()=> changeMonth(1));
  }

  function switchView(view){
    if(!dom.body) return;
    dom.body.setAttribute('data-view', view);
    const showingMonth = view === 'month';
    if(dom.monthView){ dom.monthView.hidden = !showingMonth; }
    if(dom.weekView){ dom.weekView.hidden = showingMonth; }
    dom.btnMonth?.classList.toggle('active', showingMonth);
    dom.btnWeek?.classList.toggle('active', !showingMonth);
    dom.btnMonth?.setAttribute('aria-pressed', showingMonth ? 'true' : 'false');
    dom.btnWeek?.setAttribute('aria-pressed', showingMonth ? 'false' : 'true');
  }

  function changeMonth(offset){
    const current = state.currentMonth;
    state.currentMonth = new Date(current.getFullYear(), current.getMonth() + offset, 1);
    state.currentWeekStart = getWeekStart(state.currentMonth);
    renderMonthView();
    renderWeekView();
  }

  function updateTodayBadge(){
    if(!dom.todayBadge) return;
    const month = pad(state.today.getMonth() + 1);
    const date = pad(state.today.getDate());
    dom.todayBadge.textContent = `今天：${month}/${date}`;
  }

  function setDateLine(date){
    if(!dom.dateLine) return;
    const weekday = `星期${WEEKDAY_LABELS[date.getDay()]}`;
    dom.dateLine.textContent = `${weekday}｜${formatFullDate(date)}`;
  }

  function syncWeekdayHighlights(){
    const index = state.today.getDay();
    document.querySelectorAll('.weekdays').forEach(group => {
      Array.from(group.children).forEach((node, idx)=>{
        node.classList.toggle('is-today', idx === index);
      });
    });
  }

  function renderMonthView(){
    if(!dom.monthGrid) return;
    const year = state.currentMonth.getFullYear();
    const month = state.currentMonth.getMonth();
    const firstDay = new Date(year, month, 1);
    const daysInMonth = new Date(year, month + 1, 0).getDate();
    const totalCells = Math.ceil((firstDay.getDay() + daysInMonth) / 7) * 7;
    const gridStart = new Date(firstDay);
    gridStart.setDate(firstDay.getDate() - firstDay.getDay());

    const label = formatMonthLabel(state.currentMonth);
    if(dom.monthTitle) dom.monthTitle.textContent = label;
    if(dom.currentLabel) dom.currentLabel.textContent = label;

    dom.monthGrid.innerHTML = '';
    for(let i = 0; i < totalCells; i++){
      const cellDate = new Date(gridStart);
      cellDate.setDate(gridStart.getDate() + i);
      const cell = document.createElement('div');
      cell.className = 'day';
      if(cellDate.getMonth() !== month) cell.classList.add('muted');
      if(isSameDay(cellDate, state.today)) cell.classList.add('is-today');
      const dateSpan = document.createElement('span');
      dateSpan.className = 'date';
      dateSpan.textContent = cellDate.getDate();
      const notes = document.createElement('div');
      notes.className = 'notes';

      const dayEvents = getEventsForDay(cellDate);
      dayEvents.slice(0, 2).forEach(event => {
        const tag = document.createElement('div');
        tag.classList.add('tag', `tag-${event.category}`);
        tag.textContent = event.summary;
        notes.appendChild(tag);
      });

      cell.append(dateSpan, notes);
      dom.monthGrid.appendChild(cell);
    }
  }

  function renderWeekView(){
    if(!dom.weekGrid) return;
    const weekStart = state.currentWeekStart;
    const weekEnd = new Date(weekStart);
    weekEnd.setDate(weekStart.getDate() + 7);
    dom.weekGrid.innerHTML = '';

    const weekEvents = state.events.filter(evt => evt.start < weekEnd && evt.end > weekStart);
    weekEvents.forEach(event => renderWeekEvent(event, weekStart));
  }

  function renderWeekEvent(event, weekStart){
    for(let offset = 0; offset < 7; offset++){
      const dayStart = new Date(weekStart);
      dayStart.setDate(weekStart.getDate() + offset);
      const dayEnd = new Date(dayStart);
      dayEnd.setDate(dayStart.getDate() + 1);
      if(event.end <= dayStart || event.start >= dayEnd) continue;

      const column = offset + 1;
      const segmentStart = event.start > dayStart ? event.start : dayStart;
      const segmentEnd = event.end < dayEnd ? event.end : dayEnd;
      const block = document.createElement('div');
      block.classList.add('event', event.category === 'reminder' ? 'event-reminder' : 'event-activity');
      block.title = `${event.summary}\n${formatFullDate(segmentStart)} ${event.isAllDay ? '全天' : formatTimeRange(segmentStart, segmentEnd)}`;

      if(event.isAllDay){
        block.classList.add('is-all-day');
        block.style.gridRow = '1 / 49';
        block.textContent = `${event.summary}｜全天`;
      }else{
        const startSlot = getSlotIndex(segmentStart, 'start');
        const endSlot = Math.max(startSlot + 1, getSlotIndex(segmentEnd, 'end'));
        block.style.gridRow = `${startSlot + 1} / ${Math.min(endSlot + 1, 49)}`;
        block.textContent = `${event.summary}｜${formatTimeRange(segmentStart, segmentEnd)}`;
      }
      block.style.gridColumn = column;
      dom.weekGrid.appendChild(block);
    }
  }

  function getSlotIndex(date, mode){
    const totalMinutes = date.getHours() * 60 + date.getMinutes();
    const value = mode === 'end' ? Math.ceil(totalMinutes / 30) : Math.floor(totalMinutes / 30);
    return Math.max(0, Math.min(48, value));
  }

  function getEventsForDay(date){
    return state.events.filter(event => eventIntersectsDay(event, date));
  }

  function eventIntersectsDay(event, date){
    const dayStart = startOfDay(date);
    const dayEnd = new Date(dayStart);
    dayEnd.setDate(dayStart.getDate() + 1);
    return event.start < dayEnd && event.end > dayStart;
  }

  async function loadCalendarEvents(){
    showLoading();
    try{
      const res = await fetch(ICS_URL);
      if(!res.ok) throw new Error('行事曆載入失敗');
      const text = await res.text();
      state.events = parseICSEvents(text);
      renderMonthView();
      renderWeekView();
    }catch(err){
      console.error(err);
    }finally{
      hideLoading();
    }
  }

  function parseICSEvents(text){
    const events = [];
    const lines = text.split(/\r?\n/);
    let current = null;
    lines.forEach(rawLine => {
      const line = rawLine.trim();
      if(!line) return;
      if(line === 'BEGIN:VEVENT'){
        current = {};
        return;
      }
      if(line === 'END:VEVENT'){
        if(current?.start && current?.end){
          current.category = determineCategory(current);
          events.push(current);
        }
        current = null;
        return;
      }
      if(!current) return;
      if(line.startsWith('SUMMARY')){
        current.summary = line.split(':').slice(1).join(':').trim();
      }else if(line.startsWith('DTSTART')){
        const parsed = parseICSDateValue(line);
        current.start = parsed.date;
        current.isAllDay = parsed.isAllDay;
      }else if(line.startsWith('DTEND')){
        const parsed = parseICSDateValue(line);
        current.end = parsed.date;
      }
    });
    return events.sort((a,b)=> a.start - b.start);
  }

  function parseICSDateValue(line){
    const [meta, valueRaw] = line.split(':');
    const value = valueRaw.trim();
    const isAllDay = meta.includes('VALUE=DATE');
    return { date: parseICSTimestamp(value, isAllDay), isAllDay };
  }

  function parseICSTimestamp(value, isAllDay){
    const year = Number(value.slice(0,4));
    const month = Number(value.slice(4,6)) - 1;
    const day = Number(value.slice(6,8));
    if(isAllDay || value.length === 8){
      return new Date(year, month, day);
    }
    const hour = Number(value.slice(9,11) || 0);
    const minute = Number(value.slice(11,13) || 0);
    return new Date(year, month, day, hour, minute);
  }

  function determineCategory(event){
    const key = `${pad(event.start.getMonth() + 1)}-${pad(event.start.getDate())}`;
    if(REMINDER_DATES.has(key)) return 'reminder';
    if(ACTIVITY_DATES.has(key)) return 'activity';
    return /提醒|deadline|due/i.test(event.summary || '') ? 'reminder' : 'activity';
  }

  async function loadWeatherData(){
    showLoading();
    try{
      if(dom.location) dom.location.textContent = '定位中…';
      const coords = await getUserCoordinates();
      const [placeName, weather] = await Promise.all([
        reverseGeocode(coords).catch(()=> coords.label || DEFAULT_COORDS.label),
        fetchWeather(coords)
      ]);
      updateWeatherCard(placeName, weather.current);
      updateForecastPanel(weather.daily);
    }catch(err){
      console.error(err);
      if(dom.location) dom.location.textContent = '天氣資料暫不可用';
      if(dom.condition) dom.condition.textContent = '--';
      if(dom.temperature) dom.temperature.textContent = '--';
    }finally{
      hideLoading();
    }
  }

  function getUserCoordinates(){
    return new Promise(resolve => {
      if(!navigator.geolocation){
        resolve(DEFAULT_COORDS);
        return;
      }
      navigator.geolocation.getCurrentPosition(
        ({ coords }) => resolve({ latitude: coords.latitude, longitude: coords.longitude }),
        () => resolve(DEFAULT_COORDS),
        { enableHighAccuracy: true, timeout: 8000, maximumAge: 300000 }
      );
    });
  }

  async function reverseGeocode(coords){
    const params = new URLSearchParams({
      format: 'json',
      lat: coords.latitude,
      lon: coords.longitude,
      zoom: '16',
      addressdetails: '1',
      'accept-language': 'zh-TW'
    });
    const res = await fetch(`${GEO_BASE}?${params.toString()}`, {
      headers: { Accept: 'application/json' }
    });
    if(!res.ok) throw new Error('reverse geocode failed');
    const data = await res.json();
    const address = data?.address || {};
    const parts = [
      address.city || address.town || address.county,
      address.suburb || address.village || address.district
    ].filter(Boolean);
    return parts.join(' ') || data?.display_name || DEFAULT_COORDS.label;
  }

  async function fetchWeather(coords){
    const params = new URLSearchParams({
      latitude: coords.latitude,
      longitude: coords.longitude,
      timezone: 'auto',
      current_weather: 'true',
      daily: 'weathercode,temperature_2m_max,temperature_2m_min',
      forecast_days: '7'
    });
    const res = await fetch(`${WEATHER_BASE}?${params.toString()}`);
    if(!res.ok) throw new Error('weather fetch failed');
    const data = await res.json();
    return {
      current: {
        temperature: Math.round(data.current_weather?.temperature ?? 0),
        weathercode: data.current_weather?.weathercode ?? 0
      },
      daily: data.daily
    };
  }

  function updateWeatherCard(locationLabel, current){
    if(dom.location) dom.location.textContent = locationLabel;
    const weatherInfo = mapWeatherCode(current.weathercode);
    if(dom.condition) dom.condition.textContent = weatherInfo.label;
    if(dom.temperature) dom.temperature.textContent = `${current.temperature}°C`;
    setDateLine(new Date());
    updateWeatherBackground(weatherInfo.className);
  }

  function updateForecastPanel(daily){
    if(!dom.forecastList || !daily) return;
    dom.forecastList.innerHTML = '';
    daily.time.forEach((isoDate, idx) => {
      const item = document.createElement('li');
      const date = new Date(isoDate);
      const label = idx === 0 ? '今天' : `週${WEEKDAY_LABELS[date.getDay()]}`;
      const weatherInfo = mapWeatherCode(daily.weathercode[idx]);
      const max = Math.round(daily.temperature_2m_max[idx]);
      const min = Math.round(daily.temperature_2m_min[idx]);
      const strong = document.createElement('strong');
      strong.textContent = label;
      const condition = document.createElement('span');
      condition.textContent = weatherInfo.label;
      const temp = document.createElement('span');
      temp.className = 'temp';
      temp.textContent = `${max}°C / ${min}°C`;
      item.append(strong, condition, temp);
      dom.forecastList.appendChild(item);
    });
  }

  function mapWeatherCode(code){
    if(code === undefined || code === null) return { label: 'N/A', className: 'weather-cloudy' };
    if([0,1].includes(code)) return { label: '晴朗', className: 'weather-sunny' };
    if(code === 2) return { label: '晴時多雲', className: 'weather-sunny-cloudy' };
    if([3,45,48].includes(code)) return { label: '陰天', className: 'weather-cloudy' };
    if([51,53,55,56,57,61,63,65].includes(code)) return { label: '雨勢', className: 'weather-cloudy-rainy' };
    if([80,81,82].includes(code)) return { label: '陣雨', className: 'weather-rainy' };
    if([95,96,99].includes(code)) return { label: '雷雨', className: 'weather-thunder' };
    return { label: '多雲', className: 'weather-cloudy' };
  }

  function updateWeatherBackground(className){
    if(!dom.body) return;
    WEATHER_CLASSES.forEach(name => dom.body.classList.remove(name));
    dom.body.classList.add(className);
  }

  function showLoading(){
    loadingTasks += 1;
    if(dom.loadingMask){
      dom.loadingMask.classList.remove('hidden');
      dom.loadingMask.setAttribute('aria-hidden', 'false');
    }
  }

  function hideLoading(){
    loadingTasks = Math.max(0, loadingTasks - 1);
    if(loadingTasks === 0 && dom.loadingMask){
      dom.loadingMask.classList.add('hidden');
      dom.loadingMask.setAttribute('aria-hidden', 'true');
    }
  }

  function startOfDay(date){
    const copy = new Date(date);
    copy.setHours(0,0,0,0);
    return copy;
  }

  function startOfMonth(date){
    return new Date(date.getFullYear(), date.getMonth(), 1);
  }

  function getWeekStart(date){
    const start = startOfDay(date);
    const diff = start.getDay();
    start.setDate(start.getDate() - diff);
    return start;
  }

  function isSameDay(a, b){
    return a.getFullYear() === b.getFullYear() &&
      a.getMonth() === b.getMonth() &&
      a.getDate() === b.getDate();
  }

  function formatMonthLabel(date){
    return `${date.getFullYear()}年${pad(date.getMonth() + 1)}月`;
  }

  function formatFullDate(date){
    return `${date.getFullYear()}年${pad(date.getMonth() + 1)}月${pad(date.getDate())}日`;
  }

  function formatTimeRange(start, end){
    return `${pad(start.getHours())}:${pad(start.getMinutes())} - ${pad(end.getHours())}:${pad(end.getMinutes())}`;
  }

  function pad(number){
    return String(number).padStart(2, '0');
  }
})();
