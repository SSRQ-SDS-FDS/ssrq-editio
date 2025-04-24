FROM node:23-slim AS builder

WORKDIR /editio

COPY tailwind.config.js package.json package-lock.json /editio/
COPY src /editio/src

RUN npm install && \
    npx tailwindcss -c tailwind.config.js -i ./src/ssrq_editio/entrypoints/app/static/css/src/main.css -o ./src/ssrq_editio/entrypoints/app/static/css/style.css -m && \
    npx parcel build --dist-dir ./src/ssrq_editio/entrypoints/app/static/js/dist

FROM ghcr.io/astral-sh/uv:python3.12-bookworm

ENV WORKERS=2
ENV PORT=8000
ENV ALLOWED_HOSTS=*

WORKDIR /editio

COPY data.config.json uv.lock pyproject.toml justfile /editio/
COPY src /editio/src

RUN apt-get update && \
    apt-get install -y curl build-essential && \
    apt-get update && \
    curl https://sh.rustup.rs -sSf | bash -s -- -y

ENV PATH="/root/.cargo/bin:${PATH}"

RUN uv venv && \
    uv sync --all-extras --dev --no-cache && \
    adduser ssrq_editio && \
    chown -R ssrq_editio:ssrq_editio /editio

COPY --from=builder /editio/src/ssrq_editio/entrypoints/app/static/css/style.css /editio/src/ssrq_editio/entrypoints/app/static/css/style.css
COPY --from=builder /editio/src/ssrq_editio/entrypoints/app/static/js/dist /editio/src/ssrq_editio/entrypoints/app/static/js/dist

USER ssrq_editio

RUN uv run editio prepare-db --clean --no-parallel

EXPOSE $PORT

CMD ["sh", "-c", "uv run uvicorn src.ssrq_editio.entrypoints.app.main:app --host 0.0.0.0 --port $PORT --workers $WORKERS --proxy-headers --forwarded-allow-ips=$ALLOWED_HOSTS"]
