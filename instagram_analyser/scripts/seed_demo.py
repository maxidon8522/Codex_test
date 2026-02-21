"""Populate the local database with demo objects for manual testing."""

from __future__ import annotations

from datetime import datetime, timedelta, timezone

from app.db import Base, SessionLocal, engine
from app.models.core import AuthProvider, HashtagStat, IGAccount, Insight, Media, MediaType, User, UserRole
from app.services import adoption as adoption_service
from app.services import suggestions as suggestion_service


def utcnow() -> datetime:
    return datetime.now(timezone.utc)


def seed():
    Base.metadata.create_all(bind=engine)

    with SessionLocal() as session:
        existing_media = session.query(Media).count()
        if existing_media:
            print("Seed skipped: media already present.")
            return

        user = User(email="demo@instagram.local", provider=AuthProvider.FACEBOOK, role=UserRole.ADMIN)
        session.add(user)
        session.flush()

        ig_account = IGAccount(
            user_id=user.id,
            ig_user_id="17841400000000000",
            username="taiwan_food_spots",
            token="demo_long_lived_token",
            token_expiry=utcnow() + timedelta(days=45),
        )
        session.add(ig_account)
        session.flush()

        media = Media(
            ig_media_id="1234567890",
            ig_account_id=ig_account.id,
            type=MediaType.REEL,
            caption="Jiufen night market highlights! Save for your next trip ✨",
            permalink="https://instagram.com/p/demo1",
            posted_at=utcnow() - timedelta(days=2),
            hashtags=["taiwan", "jiufen", "nightmarket", "taipeifood", "lanternfestival"],
        )
        session.add(media)
        session.flush()

        insights = [
            Insight(
                media_id=media.id,
                snapshot_at=media.posted_at + timedelta(hours=24),
                reach=8200,
                views=9100,
                saves=540,
                likes=1200,
                comments=67,
                follows=58,
                impressions=11500,
            ),
            Insight(
                media_id=media.id,
                snapshot_at=media.posted_at + timedelta(hours=72),
                reach=10200,
                views=12250,
                saves=670,
                likes=1540,
                comments=88,
                follows=73,
                impressions=14100,
            ),
        ]
        session.add_all(insights)

        # Add sample hashtag stat for analytics endpoint.
        tag_stat = HashtagStat(
            tag="taiwan",
            window_start=utcnow() - timedelta(days=7),
            window_end=utcnow(),
            volume_estimate=42000,
            sample_size=1800,
            velocity_estimate=1.3,
            metadata={"regional_overlap": ["taipeifood", "jiufen"]},
        )
        session.add(tag_stat)

        session.commit()

        # Generate suggestion and adoption data.
        with SessionLocal() as worker_session:
            suggestion_service.generate_stubbed_suggestion(worker_session, str(media.id))
            adoption_service.evaluate_media_adoption(worker_session, str(media.id))
            worker_session.commit()

    print("Demo data inserted. Ready to query via the API.")


if __name__ == "__main__":
    seed()
