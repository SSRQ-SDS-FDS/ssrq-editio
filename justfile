sql_dir := "./src/ssrq_editio/adapters/db/sql/**/*.sql"
web_app := "./src/ssrq_editio/entrypoints/app/main.py"

# Start the development server
dev:
	uv run fastapi dev {{web_app}}

# Format the code
fmt:
  uv run ruff format .
  uv run sqlfluff format {{sql_dir}} --dialect sqlite

# Lint the source code using Mypy & Ruff
lint:
  uv run ruff check && uv run mypy
  uv run sqlfluff lint {{sql_dir}} --dialect sqlite

run:
	uv run fastapi run {{web_app}}

# Execute pytest, after running the linting
test args="": lint
  uv run pytest {{args}}

# Shows all recipes using just -l
help:
	just -l
