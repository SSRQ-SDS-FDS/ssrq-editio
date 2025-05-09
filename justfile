css_build_command := "npx tailwindcss -c tailwind.config.js -i " + css_dir + "/src/main.css -o " + css_dir + "/style.css"
css_dir := "./src/ssrq_editio/entrypoints/app/static/css"
js_build_command := "npx parcel build --dist-dir " + js_output_dir
js_output_dir := "./src/ssrq_editio/entrypoints/app/static/js/dist"
sql_dir := "./src/ssrq_editio/adapters/db/sql/**/*.sql"
web_app := "./src/ssrq_editio/entrypoints/app/main.py"


# Build JS using Parcel, depending on the CSS build
build args="": css
    {{js_build_command}} {{args}}

# Compile the CSS using TailwindCSS, pass "-w" to watch for changes
css args="":
    {{css_build_command}} -m {{args}}

# Build CSS / JS and start the development server – files in src will be watched
dev:
	uv run watchfiles "sh -c 'pkill -f \"fastapi dev {{web_app}}\" || true; sleep 1; {{css_build_command}} && {{js_build_command}} --no-optimize && fastapi dev {{web_app}} --no-reload'" src

# Format the code
fmt:
  uv run ruff format .
  uv run sqlfluff format {{sql_dir}} --dialect sqlite

# Lint the source code using Mypy & Ruff
lint:
  uv run ruff check && uv run mypy
  uv run sqlfluff lint {{sql_dir}} --dialect sqlite

run: build
	uv run fastapi run {{web_app}}

# Execute pytest, after running the linting
test args="": lint
  uv run pytest {{args}}

# Shows all recipes using just -l
help:
	just -l
