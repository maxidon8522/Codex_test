# Instagram Analyser (MVP)

FastAPI-based backend service that ingests Instagram insights, evaluates hashtags, triggers Gemini-based coaching suggestions, and tracks adoption of operational feedback.

## Key Capabilities

- Ingest creator insights, media metadata, and hashtag usage into a relational store.
- Generate Gemini-style coaching suggestions (stubbed locally until real integration).
- Evaluate adoption rules such as hashtag ranges and CTA usage.
- Provide hashtag analysis heuristics (duplicates, clusters, risky patterns).
- Queue ingestion jobs sequentially (placeholder scheduler response today).

## Getting Started

1. Create and activate a Python 3.11 virtual environment.
2. Install dependencies: `pip install -r requirements.txt`.
3. Export required environment variables (see `app/config.py` for details). A `.env` example:
   ```
   DATABASE_URL=sqlite:///./instagram_analyser.db
   ENVIRONMENT=dev
   ```
4. Run the server: `uvicorn app.main:app --reload`.

### Populate Demo Data

- Optional: seed a demo dataset for local exploration with `python scripts/seed_demo.py`.

## API Overview

- `POST /auth/login/facebook`: exchange short-lived token for a mock long-lived credential.
- `GET /ig/accounts`: list linked Instagram creator accounts.
- `POST /ig/sync`: enqueue ingestion job (returns queued stub).
- `GET /media`: list media with latest insights, adoption score, and pagination.
- `GET /media/{id}`: retrieve full insight history, suggestions, and adoption results.
- `POST /media/{id}/suggest`: generate Gemini-style coaching suggestions (stubbed).
- `POST /media/{id}/adoption/evaluate`: recompute rule adoption for a post.
- `GET /tags/analysis?tags=...`: evaluate hashtag usage (duplicates, clusters, risks).

## Architecture Overview

- FastAPI: HTTP API surface for ingestion, hashtag analysis, suggestions, and scheduling.
- SQLAlchemy: Persistence layer that maps the data model described in `instagram_analays.txt`.
- Celery + Redis: Background queue for sequential ingestion jobs (stubbed response for now).
- Gemini: LLM-backed suggestion generator (stubbed locally until API keys are configured).

Refer to `instagram_analays.txt` for the full product requirements that drive this implementation.
