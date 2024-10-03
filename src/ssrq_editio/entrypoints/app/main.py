from fastapi import Request
from fastapi.responses import HTMLResponse
from ssrq_editio.entrypoints.app.setup import app, templates


@app.get("/", response_class=HTMLResponse)
def hello(request: Request):
    return templates.TemplateResponse("index.html.j2", {"request": request})
