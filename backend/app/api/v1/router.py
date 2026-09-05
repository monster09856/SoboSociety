from fastapi import APIRouter

from app.api.v1.admin import router as admin_router
from app.api.v1.ai import router as ai_router
from app.api.v1.auth import router as auth_router
from app.api.v1.bookings import router as bookings_router
from app.api.v1.my import router as my_router
from app.api.v1.notifications import router as notifications_router
from app.api.v1.packages import router as packages_router
from app.api.v1.sessions import router as sessions_router

api_v1_router = APIRouter(prefix="/api/v1")
api_v1_router.include_router(auth_router)
api_v1_router.include_router(sessions_router)
api_v1_router.include_router(packages_router)
api_v1_router.include_router(bookings_router)
api_v1_router.include_router(my_router)
api_v1_router.include_router(admin_router)
api_v1_router.include_router(notifications_router)
api_v1_router.include_router(ai_router)

