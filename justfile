# CSS input/output pairs: "input_file:output_file"
css_files := "src/main.css:style.css src/utilities/transcript.css:transcript.css"
css_dir := "./src/ssrq_editio/entrypoints/app/static/css"
js_build_command := "npx parcel build --dist-dir " + js_output_dir
js_output_dir := "./src/ssrq_editio/entrypoints/app/static/js/dist"
sql_dir := "./src/ssrq_editio/adapters/db/sql/**/*.sql"
web_app := "./src/ssrq_editio/entrypoints/app/main.py"


# Build JS using Parcel, depending on the CSS build
build args="": css
    {{js_build_command}} {{args}}

# Compile all CSS files using TailwindCSS, pass "-w" to watch for changes
css args="":
    #!/usr/bin/env sh
    for pair in {{css_files}}; do
        input_file=$(echo "$pair" | cut -d':' -f1)
        output_file=$(echo "$pair" | cut -d':' -f2)
        npx tailwindcss -c tailwind.config.js -i "{{css_dir}}/$input_file" -o "{{css_dir}}/dist/$output_file" -m {{args}}
    done

# Build CSS / JS and start the development server – files in src will be watched
dev:
	uv run watchfiles "sh -c 'pkill -f \"fastapi dev {{web_app}}\" || true; sleep 1; just css && {{js_build_command}} --no-optimize && fastapi dev {{web_app}} --no-reload'" src --ignore-paths {{js_output_dir}},{{css_dir}}/dist

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
