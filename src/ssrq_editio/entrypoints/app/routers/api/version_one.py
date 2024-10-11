from fastapi import APIRouter

version_one = APIRouter(prefix="/v1")


@version_one.get("/")
def info() -> dict[str, str]:
    """Returns basic information about the API."""
    return {"message": "Hello, World!"}


@version_one.get("/kantons")
def kantons() -> list[str]:
    """Returns a list of all kantons (cantons) in abbreviated form."""
    return ["AG"]
