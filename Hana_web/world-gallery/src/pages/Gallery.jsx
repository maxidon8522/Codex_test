import { Link } from 'react-router-dom';
import PINS from '../data/pins.js';

function GalleryCard({ pin }) {
  return (
    <article className="group flex flex-col overflow-hidden rounded-3xl border border-white/10 bg-slate-950/60 backdrop-blur transition hover:border-accent/60 hover:shadow-[0_30px_80px_-40px_rgba(56,189,248,0.8)]">
      <div className="relative h-56 overflow-hidden bg-slate-900">
        <img
          src={pin.thumb}
          alt={pin.title}
          className="h-full w-full object-cover transition duration-700 group-hover:scale-105"
          loading="lazy"
        />
        <span
          className="absolute right-4 top-4 inline-flex h-3 w-3 rounded-full"
          style={{ backgroundColor: pin.color }}
        />
      </div>
      <div className="flex flex-1 flex-col gap-4 p-6">
        <div>
          <h3 className="text-lg font-semibold text-white">{pin.title}</h3>
          <p className="mt-2 text-sm text-slate-400">{pin.excerpt}</p>
        </div>
        <div className="flex flex-wrap gap-2 text-xs text-slate-400">
          <span className="rounded-full border border-slate-700 px-3 py-1 uppercase tracking-[0.3em] text-slate-300">
            {pin.lat.toFixed(3)}, {pin.lng.toFixed(3)}
          </span>
          {pin.tags.map((tag) => (
            <span
              key={tag}
              className="rounded-full border border-slate-700/60 bg-slate-900/60 px-3 py-1 font-medium text-slate-400"
            >
              {tag}
            </span>
          ))}
        </div>
        <div className="mt-auto flex items-center justify-between">
          <Link
            to={pin.link}
            className="text-sm font-semibold text-accent transition hover:text-sky-200"
          >
            View details →
          </Link>
          <button
            type="button"
            className="rounded-full border border-slate-700 px-4 py-1 text-xs font-medium uppercase tracking-[0.3em] text-slate-400 transition hover:border-accent/60 hover:text-accent"
          >
            Pin
          </button>
        </div>
      </div>
    </article>
  );
}

function Gallery() {
  return (
    <div className="min-h-screen bg-gradient-to-br from-black via-slate-950 to-[#020617] text-slate-100">
      <div className="mx-auto flex w-full max-w-7xl flex-col gap-12 px-6 pb-20 pt-16 lg:px-10">
        <header className="flex flex-col gap-6">
          <div className="flex items-center gap-3 text-xs uppercase tracking-[0.4em] text-slate-400">
            <Link
              to="/"
              className="rounded-full border border-slate-700 px-3 py-1 text-slate-300 transition hover:border-accent/60 hover:text-accent"
            >
              Home
            </Link>
            <span className="text-slate-500">/</span>
            <span className="text-slate-200">Gallery</span>
          </div>
          <div className="flex flex-wrap items-end justify-between gap-6">
            <div>
              <h1 className="text-4xl font-semibold leading-snug text-white sm:text-5xl">
                World Gallery Collection
              </h1>
              <p className="mt-4 max-w-2xl text-base text-slate-300">
                Explore the latest architecture and art installations mapped on
                the globe. Each project links back to its dedicated detail page
                and location.
              </p>
            </div>
            <div className="flex gap-3">
              <button
                type="button"
                className="rounded-full border border-slate-700 px-4 py-2 text-xs font-semibold uppercase tracking-[0.3em] text-slate-300 transition hover:border-accent/60 hover:text-accent"
              >
                Filter tags
              </button>
              <button
                type="button"
                className="rounded-full border border-slate-700 px-4 py-2 text-xs font-semibold uppercase tracking-[0.3em] text-slate-300 transition hover:border-accent/60 hover:text-accent"
              >
                Sort by
              </button>
            </div>
          </div>
        </header>

        <section className="grid gap-8 md:grid-cols-2 xl:grid-cols-3">
          {PINS.map((pin) => (
            <GalleryCard key={pin.id} pin={pin} />
          ))}
        </section>
      </div>
    </div>
  );
}

export default Gallery;
