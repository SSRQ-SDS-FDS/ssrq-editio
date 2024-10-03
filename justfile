web_app := "./src/ssrq_editio/entrypoints/app/main.py"

# Start the development server
dev:
	uv run fastapi dev {{web_app}}

# Show all recipes using just -l
help:
	just -l
