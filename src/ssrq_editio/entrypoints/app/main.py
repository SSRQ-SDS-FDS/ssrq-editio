from ssrq_editio.entrypoints.app.setup import app, setup_routers
from ssrq_editio.entrypoints.app.routers import html, api

setup_routers(
    app,
    (
        api,
        html,
    ),
)
