from ssrq_editio.entrypoints.app.routers import api, html, register_error_handlers
from ssrq_editio.entrypoints.app.setup import app, setup_routers

setup_routers(
    app,
    register_error_handlers,
    (
        api,
        html,
    ),
)
