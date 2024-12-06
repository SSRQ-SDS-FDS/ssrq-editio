FROM ghcr.io/astral-sh/uv:python3.12-bookworm

ENV WORKERS=2
ENV PORT=8000

WORKDIR /editio

COPY data.config.json uv.lock pyproject.toml justfile tailwind.config.js /editio/
COPY src /editio/src

RUN uv venv && \
    uv sync --all-extras --dev --no-cache && \
    adduser ssrq_editio && \
    chown -R ssrq_editio:ssrq_editio /editio

USER ssrq_editio

RUN uv run editio prepare-db --clean && \
    uv run just css

EXPOSE $PORT

CMD ["sh", "-c", "uv run fastapi run --port $PORT --workers $WORKERS ./src/ssrq_editio/entrypoints/app/main.py"]
