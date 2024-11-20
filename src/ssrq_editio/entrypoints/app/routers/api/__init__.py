from fastapi import APIRouter

from .version_one import version_one

api = APIRouter(prefix="/api")

api.include_router(version_one)
