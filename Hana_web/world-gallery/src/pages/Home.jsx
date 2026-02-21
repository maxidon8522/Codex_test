import { Link } from 'react-router-dom';
import GlobeCanvas from '../components/GlobeCanvas.jsx';
import PINS from '../data/pins.js';

const FEATURED = PINS.slice(0, 3);

function Home() {
  return (
    <div className="relative min-h-screen overflow-hidden bg-gradient-to-br from-black via-black to-[#050a1a] text-slate-100">
      <div className="absolute inset-0">
        <GlobeCanvas pins={PINS} className="min-h-screen" />
      </div>
      <div className="relative z-10 flex min-h-screen w-full justify-end">
        <aside className="flex w-full max-w-lg shrink-0 flex-col border-t border-white/10 bg-black/60 px-6 py-8 backdrop-blur-md lg:w-[380px] lg:border-l lg:border-t-0 lg:px-8">
          <div className="flex items-start justify-between">
            <p className="text-sm uppercase tracking-[0.4em] text-slate-300">
              Pins ({FEATURED.length})
            </p>
            <button
              type="button"
              className="rounded-full border border-slate-700 px-3 py-1 text-xs font-medium text-slate-300 transition hover:border-slate-500 hover:text-white"
            >
              Clear
            </button>
          </div>
          <ul className="mt-6 space-y-4">
            {FEATURED.map((pin) => (
              <li
                key={pin.id}
                className="flex items-start gap-4 rounded-2xl border border-white/10 bg-white/5 p-4 shadow-[0_24px_60px_-30px_rgba(56,189,248,0.7)]"
              >
                <div className="h-12 w-12 overflow-hidden rounded-xl bg-slate-900/60">
                  <img
                    src={pin.thumb}
                    alt={pin.title}
                    className="h-full w-full object-cover"
                    loading="lazy"
                  />
                </div>
                <div className="flex-1">
                  <p className="text-sm font-semibold text-white">
                    {pin.title}
                  </p>
                  <p className="mt-1 text-xs text-slate-400">
                    {pin.lat.toFixed(3)}, {pin.lng.toFixed(3)}
                  </p>
                  <Link
                    to={pin.link}
                    className="mt-2 inline-flex items-center text-xs font-medium text-accent transition hover:text-sky-200"
                  >
                    Open work →
                  </Link>
                </div>
                <span
                  className="mt-1 inline-flex h-2.5 w-2.5 rounded-full"
                  style={{ backgroundColor: pin.color }}
                />
              </li>
            ))}
          </ul>
          <p className="mt-6 text-xs leading-relaxed text-slate-400">
            使い方: 地球をクリックすると、その場所にピンを追加できます。
          </p>
          <div className="mt-8 flex flex-col gap-2">
            <Link
              to="/gallery"
              className="rounded-full border border-accent px-8 py-3 text-sm font-semibold uppercase tracking-[0.4em] text-accent transition hover:bg-accent hover:text-black"
            >
              ギャラリーに入る
            </Link>
            <button
              type="button"
              className="rounded-full border border-transparent px-6 py-2 text-[10px] font-medium uppercase tracking-[0.6em] text-slate-500 opacity-60 transition hover:opacity-80"
            >
              システムアクセス
            </button>
          </div>
        </aside>
      </div>
      <div className="pointer-events-none absolute inset-x-0 bottom-6 text-center text-xs font-semibold tracking-[0.3em] text-slate-500/80">
        © 2025 Your Name – World Gallery
      </div>
    </div>
  );
}

export default Home;
