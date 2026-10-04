import pytest
from sqlalchemy import create_engine
from sqlalchemy.pool import StaticPool
from sqlalchemy.orm import sessionmaker

from app.db.database import Base, get_db
from app.main import app

# Shared in-memory SQLite engine with StaticPool to keep schema in memory across threads
test_engine = create_engine(
    "sqlite:///:memory:",
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)
TestingSessionLocal = sessionmaker(
    autocommit=False, autoflush=False, bind=test_engine
)


@pytest.fixture(autouse=True)
def setup_test_database():
    """
    Automatically creates all tables in in-memory SQLite and overrides get_db for every test.
    """
    Base.metadata.create_all(bind=test_engine)

    def override_get_db():
        db = TestingSessionLocal()
        try:
            yield db
        finally:
            db.close()

    app.dependency_overrides[get_db] = override_get_db
    yield
    # Clear data/overrides if needed
    Base.metadata.drop_all(bind=test_engine)
    app.dependency_overrides.clear()
