from fastapi import FastAPI, Depends
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.api.routes.auth import router as auth_router
from app.api.routes.trips import router as trips_router
from app.api.routes.members import router as members_router
from app.api.routes.wallet import router as wallet_router
from app.api.routes.expenses import router as expenses_router
from app.api.routes.settlement import router as settlement_router
from app.api.routes.statistics import router as statistics_router

app = FastAPI(
    title="Trip Wallet API",
    description="Backend API for the Trip Wallet application",
    version="1.0.0",
)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
app.include_router(auth_router)
app.include_router(trips_router)
app.include_router(members_router)
app.include_router(wallet_router)
app.include_router(expenses_router)
app.include_router(settlement_router)
app.include_router(statistics_router)

@app.get("/")
def root():
    return {
        "message": "Trip Wallet API is running",
        "version": "1.0.0",
    }


@app.get("/health")
def health_check(db: Session = Depends(get_db)):

    db.execute(text("SELECT 1"))

    return {
        "status": "healthy",
        "database": "connected",
    }