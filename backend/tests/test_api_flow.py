from app.main import app


def test_application_loads():
    assert app is not None