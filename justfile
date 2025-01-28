css_dir := "./src/ssrq_editio/entrypoints/app/static/css"
sql_dir := "./src/ssrq_editio/adapters/db/sql/**/*.sql"
web_app := "./src/ssrq_editio/entrypoints/app/main.py"

export TAILWINDCSS_VERSION:="v3.4.17" # ToDo: Update to tailwindcss@latest, first check https://github.com/timonweb/pytailwindcss/issues

# Compile the CSS using TailwindCSS, pass "-w" to watch for changes
css args="":
    uv run tailwindcss -c tailwind.config.js -i {{css_dir}}/src/main.css -o {{css_dir}}/style.css -m {{args}}

# Start the development server
dev: css
	uv run watchfiles "fastapi dev {{web_app}} --no-reload" src

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
