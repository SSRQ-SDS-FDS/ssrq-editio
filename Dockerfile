# syntax=docker/dockerfile:1.7

FROM node:23-slim AS builder

WORKDIR /editio

COPY justfile tailwind.config.js package.json package-lock.json /editio/
COPY src/ssrq_editio/entrypoints/app /editio/src/ssrq_editio/entrypoints/app

RUN --mount=type=cache,target=/root/.npm \
    npm ci && \
    npx rust-just build

FROM ghcr.io/astral-sh/uv:python3.12-bookworm

ENV WORKERS=2
ENV PORT=8000
ENV ALLOWED_HOSTS=*

WORKDIR /editio

RUN apt-get update && \
    apt-get install -y --no-install-recommends curl build-essential ca-certificates && \
    rm -rf /var/lib/apt/lists/* && \
    curl https://sh.rustup.rs -sSf | bash -s -- -y

ENV PATH="/editio/.venv/bin:/root/.cargo/bin:${PATH}"

COPY uv.lock pyproject.toml /editio/

RUN --mount=type=cache,target=/root/.cache/uv \
    uv venv && \
    uv sync --frozen --no-dev --no-install-project

COPY data.config.json /editio/
COPY src /editio/src

RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-dev && \
    adduser --disabled-password --gecos "" ssrq_editio && \
    chown -R ssrq_editio:ssrq_editio /editio

COPY --from=builder /editio/src/ssrq_editio/entrypoints/app/static/css/dist /editio/src/ssrq_editio/entrypoints/app/static/css/dist
COPY --from=builder /editio/src/ssrq_editio/entrypoints/app/static/js/dist /editio/src/ssrq_editio/entrypoints/app/static/js/dist

USER ssrq_editio

RUN editio prepare-db --clean --no-parallel

EXPOSE $PORT

CMD ["sh", "-c", "uvicorn src.ssrq_editio.entrypoints.app.main:app --host 0.0.0.0 --port $PORT --workers $WORKERS --proxy-headers --forwarded-allow-ips=$ALLOWED_HOSTS"]
