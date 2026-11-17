# syntax=docker/dockerfile:1.7

FROM node:24-slim AS node

FROM node AS builder

WORKDIR /editio

COPY justfile tailwind.config.js package.json package-lock.json /editio/
COPY src/ssrq_editio/entrypoints/app /editio/src/ssrq_editio/entrypoints/app

RUN --mount=type=cache,target=/root/.npm \
    npm ci && \
    npx rust-just build

FROM ghcr.io/astral-sh/uv:python3.14-trixie AS base

ARG SQLITE_VERSION=3.46.1

ENV WORKERS=2
ENV PORT=8000
ENV ALLOWED_HOSTS=*

WORKDIR /editio

RUN apt-get update && \
   apt-get install -y --no-install-recommends \
      curl build-essential ca-certificates libbrotli1 && \
    dpkg --compare-versions \
      "$(dpkg-query -W -f='${Version}' libbrotli1)" \
      ge '1.1.0-2+deb13u1' && \
    rm -rf /var/lib/apt/lists/* && \
    curl https://sh.rustup.rs -sSf | bash -s -- -y

ENV PATH="/editio/.venv/bin:/root/.cargo/bin:${PATH}"

# Verify the SQLite library actually used by Python in both stages.
COPY scripts/check_sqlite_version.py /editio/scripts/check_sqlite_version.py
RUN uv run --no-project --no-managed-python python scripts/check_sqlite_version.py

FROM base AS development

COPY --from=node /usr/local/bin/node /usr/local/bin/node
COPY --from=node /usr/local/lib/node_modules /usr/local/lib/node_modules
RUN ln -s /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm && \
    ln -s /usr/local/lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx

COPY pyproject.toml uv.lock package.json package-lock.json justfile tailwind.config.js /editio/
COPY src /editio/src
RUN --mount=type=cache,target=/root/.cache/uv uv sync --frozen --all-extras --dev
RUN --mount=type=cache,target=/root/.npm npm ci

EXPOSE 8000
CMD ["just", "dev", "0.0.0.0"]

FROM base AS production

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
