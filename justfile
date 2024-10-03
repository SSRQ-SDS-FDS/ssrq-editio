web_app := "./src/ssrq_editio/entrypoints/app/main.py"

# Start the development server
dev:
	uv run fastapi dev {{web_app}}

# Format the code
fmt:
  uv run ruff format .

# Lint the source code using Mypy & Ruff
lint:
  uv run ruff check && uv run mypy

# Execute pytest, after running the linting
test: lint
  uv run pytest

# Shows all recipes using just -l
help:
	just -l
