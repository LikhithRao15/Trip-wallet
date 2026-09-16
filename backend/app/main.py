import logging
from pathlib import Path
from fastapi import FastAPI, Depends, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse, FileResponse
from fastapi.staticfiles import StaticFiles
from sqlalchemy import text
from sqlalchemy.orm import Session

from app.core.config import settings
from app.db.database import get_db
from app.api.routes.auth import router as auth_router
from app.api.routes.trips import router as trips_router
from app.api.routes.members import router as members_router
from app.api.routes.wallet import router as wallet_router
from app.api.routes.expenses import router as expenses_router
from app.api.routes.settlement import router as settlement_router
from app.api.routes.statistics import router as statistics_router
from app.api.routes.reports import router as reports_router
from app.api.routes.notifications import router as notifications_router
from app.api.routes.activity import router as activity_router
from app.api.routes.sync import router as sync_router
from app.api.routes.payments import router as payments_router,webhook_router

logger = logging.getLogger("trip_wallet")
logging.basicConfig(level=settings.LOG_LEVEL)

app = FastAPI(
    title="Trip Wallet API",
    description="Backend API for the Trip Wallet application",
    version="1.0.0",
)

# Production CORS configuration
cors_origins = settings.cors_origin_list
allow_creds = True
if "*" in cors_origins and settings.ENVIRONMENT == "production":
    # In production, do not pair allow_origins=["*"] with allow_credentials=True
    allow_creds = False

app.add_middleware(
    CORSMiddleware,
    allow_origins=cors_origins,
    allow_credentials=allow_creds,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    """
    Catch-all exception handler to ensure internal stack traces, SQL errors,
    or implementation paths are never leaked to clients.
    """
    logger.exception("Unhandled server exception on %s %s: %s", request.method, request.url.path, exc)
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={"detail": "An internal server error occurred. Please try again later."},
    )


app.include_router(auth_router)
app.include_router(trips_router)
app.include_router(members_router)
app.include_router(wallet_router)
app.include_router(expenses_router)
app.include_router(settlement_router)
app.include_router(statistics_router)
app.include_router(reports_router)
app.include_router(notifications_router)
app.include_router(activity_router)
app.include_router(sync_router)
app.include_router(payments_router)
app.include_router(webhook_router)


STATIC_DIR = Path(__file__).resolve().parent / "static"
if STATIC_DIR.exists():
    app.mount("/static", StaticFiles(directory=str(STATIC_DIR)), name="static")


@app.get("/", response_class=FileResponse)
def landing_page(request: Request):
    """
    Serve the public Trip Wallet landing website.
    Returns JSON only if the client explicitly requests application/json without text/html.
    """
    accept = request.headers.get("accept", "")
    if "application/json" in accept and "text/html" not in accept:
        return JSONResponse({
            "message": "Trip Wallet API is running",
            "version": "1.0.0",
        })
    index_file = STATIC_DIR / "index.html"
    if index_file.exists():
        return FileResponse(str(index_file), media_type="text/html")
    return JSONResponse({
        "message": "Trip Wallet API is running",
        "version": "1.0.0",
    })


@app.get("/api")
def api_root():
    return {
        "message": "Trip Wallet API is running",
        "version": "1.0.0",
    }


@app.get("/privacy", response_class=FileResponse)
@app.get("/privacy.html", response_class=FileResponse, include_in_schema=False)
def privacy_policy():
    privacy_file = STATIC_DIR / "privacy.html"
    if privacy_file.exists():
        return FileResponse(str(privacy_file), media_type="text/html")
    return JSONResponse(status_code=404, content={"detail": "Privacy policy not found"})


@app.get("/terms", response_class=FileResponse)
@app.get("/terms.html", response_class=FileResponse, include_in_schema=False)
def terms_and_conditions():
    terms_file = STATIC_DIR / "terms.html"
    if terms_file.exists():
        return FileResponse(str(terms_file), media_type="text/html")
    return JSONResponse(status_code=404, content={"detail": "Terms & conditions not found"})


@app.get("/refund", response_class=FileResponse)
@app.get("/refund.html", response_class=FileResponse, include_in_schema=False)
def refund_policy():
    refund_file = STATIC_DIR / "refund.html"
    if refund_file.exists():
        return FileResponse(str(refund_file), media_type="text/html")
    return JSONResponse(status_code=404, content={"detail": "Refund policy not found"})


@app.get("/favicon.ico", include_in_schema=False)
def favicon():
    fav = STATIC_DIR / "favicon.svg"
    if fav.exists():
        return FileResponse(str(fav), media_type="image/svg+xml")
    return JSONResponse(status_code=404, content={"detail": "Favicon not found"})


@app.get("/styles.css", include_in_schema=False)
def root_styles():
    css = STATIC_DIR / "styles.css"
    if css.exists():
        return FileResponse(str(css), media_type="text/css")
    return JSONResponse(status_code=404, content={"detail": "Stylesheet not found"})


@app.get("/health")
def health_check(db: Session = Depends(get_db)):
    try:
        db.execute(text("SELECT 1"))
        db_status = "connected"
    except Exception as e:
        logger.error("Health check database error: %s", e)
        return JSONResponse(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            content={
                "status": "unhealthy",
                "database": "disconnected",
            },
        )

    return {
        "status": "healthy",
        "database": db_status,
    }