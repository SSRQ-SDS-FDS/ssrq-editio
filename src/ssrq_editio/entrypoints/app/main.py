from ssrq_editio.entrypoints.app.routers import api, html
from ssrq_editio.entrypoints.app.setup import app, setup_routers

setup_routers(
    app,
    (
        api,
        html,
    ),
)
