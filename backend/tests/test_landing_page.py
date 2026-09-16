from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


def test_landing_page_serves_html():
    """Verify GET / serves the HTML landing page for browser requests."""
    response = client.get("/", headers={"Accept": "text/html,application/xhtml+xml"})
    assert response.status_code == 200
    assert "text/html" in response.headers.get("content-type", "")
    assert "Trip Wallet" in response.text
    assert "Shared Digital Wallet" in response.text
    assert "Razorpay" in response.text


def test_landing_page_json_fallback_when_requested():
    """Verify GET / returns JSON if caller explicitly accepts only application/json."""
    response = client.get("/", headers={"Accept": "application/json"})
    assert response.status_code == 200
    data = response.json()
    assert data["message"] == "Trip Wallet API is running"


def test_api_root():
    """Verify GET /api returns the standard API JSON info."""
    response = client.get("/api")
    assert response.status_code == 200
    data = response.json()
    assert data["message"] == "Trip Wallet API is running"


def test_privacy_policy_page():
    """Verify /privacy and /privacy.html return the Privacy Policy page."""
    for path in ["/privacy", "/privacy.html"]:
        response = client.get(path)
        assert response.status_code == 200
        assert "text/html" in response.headers.get("content-type", "")
        assert "Privacy Policy" in response.text
        assert "Razorpay" in response.text


def test_terms_page():
    """Verify /terms and /terms.html return the Terms & Conditions page."""
    for path in ["/terms", "/terms.html"]:
        response = client.get(path)
        assert response.status_code == 200
        assert "text/html" in response.headers.get("content-type", "")
        assert "Terms &amp; Conditions" in response.text or "Terms & Conditions" in response.text


def test_refund_page():
    """Verify /refund and /refund.html return the Refund Policy page."""
    for path in ["/refund", "/refund.html"]:
        response = client.get(path)
        assert response.status_code == 200
        assert "text/html" in response.headers.get("content-type", "")
        assert "Refund &amp; Cancellation Policy" in response.text or "Refund & Cancellation Policy" in response.text


def test_favicon_and_styles():
    """Verify static assets are accessible."""
    res_fav = client.get("/favicon.ico")
    assert res_fav.status_code == 200

    res_css = client.get("/styles.css")
    assert res_css.status_code == 200
    assert "text/css" in res_css.headers.get("content-type", "")

    res_static_css = client.get("/static/styles.css")
    assert res_static_css.status_code == 200
