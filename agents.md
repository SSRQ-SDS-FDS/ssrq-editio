# AGENTS.md

This guide provides essential information for coding agents working on the SSRQ-Editio project—a Python-based digital scholarly edition application for the Swiss Law Sources.

## Project Overview

**SSRQ-Editio** is a digital scholarly edition platform that transforms TEI-XML files into HTML using XSLT. It replaces an older TEIPublisher-based system with improved architecture, testing coverage, and performance.

- **Repository**: https://github.com/SSRQ-SDS-FDS/ssrq-editio
- **Production URL**: https://editio.sls-online.ch
- **Version**: 1.0.0-alpha4
- **Python**: 3.11 or 3.12
- **License**: MIT

## Technology Stack

### Backend

- **Framework**: FastAPI (0.115.0+)
- **Web Server**: Uvicorn
- **Database**: SQLite with aiosqlite
- **XSLT Processor**: Saxon (saxonche ≤12.5.0)
- **Templating**: Jinja2 with JinjaX fragments
- **CLI**: Typer
- **Utilities**: Custom ssrq-utils (Git-based dependency)

### Frontend

- **CSS Framework**: TailwindCSS 3.4.17
- **Build Tool**: Parcel 2.14.4
- **Interactivity**:
  - Alpine.js 3.14.9 (reactive components)
  - htmx 2.0.4 (AJAX interactions)
- **Image Viewer**: OpenSeadragon 5.0.1

### Build & Development Tools

- **Package Manager**: uv (Python) + npm (Node.js)
- **Task Runner**: just
- **Type Checker**: mypy 1.11.2+
- **Code Formatter**: ruff (line length: 100)
- **Linter**: ruff with predefined rules (E, F, I, C90)
- **Pre-commit**: Used for commit hooks
- **Testing**: pytest 8.3.3+
- **CSS Linting**: sqlfluff for SQL formatting

## Project Structure

```
ssrq-editio/
├── src/ssrq_editio/
│   ├── adapters/              # Data access layer
│   │   ├── db/               # SQLite database logic
│   │   │   └── sql/          # Raw SQL files
│   │   ├── data.py           # Data operations
│   │   ├── entities.py       # Entity definitions
│   │   └── file.py           # File operations
│   ├── entrypoints/
│   │   ├── app/              # FastAPI web application
│   │   └── cli/              # CLI command entrypoints
│   ├── models/               # Pydantic data models
│   ├── services/             # Business logic
│   │   ├── xslt/            # XSLT transformations
│   │   ├── documents.py      # Document operations
│   │   ├── entities.py       # Entity services
│   │   └── ...               # Other service modules
│   └── __init__.py
├── tests/                     # Pytest test files
│   ├── ssrq_editio/         # Unit and integration tests
│   ├── eXist_app/           # External app tests
│   └── examples/            # Sample XML files for testing
├── data/                     # Git submodules for volume data
│   ├── FR_I_2_8/
│   ├── GE_5/
│   ├── NE_1/, NE_3/, NE_4/
│   ├── SG_III_4/
│   ├── SH_II_1/
│   ├── VD_D_1/, VD_D_2/
│   └── ZH_NF_*/ (multiple volumes)
├── pyproject.toml           # Python project configuration
├── package.json             # Node.js dependencies
├── justfile                 # Task definitions
├── Dockerfile               # Multi-stage production build
├── tailwind.config.js       # Tailwind CSS configuration
├── data.config.json         # Volume configuration
└── README.md                # Development setup guide
```

## Setup & Environment

### Prerequisites

- Python 3.11 or 3.12 with `uv` installed
- Node.js and npm
- Rust (for Python extension building)
- Git

### Initial Setup

```bash
# Install Python and Node dependencies
uv sync --all-extras --dev
npm install

# Setup pre-commit hooks (optional but recommended)
pre-commit install

# Populate the database
editio prepare-db --clean

# Start development server
just dev
```

## Essential Commands

All commands use `just` task runner:

| Command | Purpose |
|---------|---------|
| `just dev` | Start development server with file watching and hot reload |
| `just build` | Build frontend assets (CSS + JS with Parcel) |
| `just css` | Compile TailwindCSS files (use `-w` flag to watch) |
| `just test [args]` | Run pytest (runs lint first) |
| `just lint` | Run mypy and ruff checks + SQL linting |
| `just fmt` | Format code with ruff + sqlfluff |
| `just run` | Build and start production server |
| `just help` | List all available recipes |

### CLI Commands

```bash
# Populate/rebuild SQLite database
editio prepare-db --clean
editio prepare-db --clean --no-parallel  # Sequential processing

# Start web server (used in Docker)
uvicorn src.ssrq_editio.entrypoints.app.main:app --host 0.0.0.0 --port 8000
```

## Data Management

### Database

- **Type**: SQLite (`ssrq_editio.sqlite3`)
- **Location**: Project root
- **Initialization**: Run `editio prepare-db --clean` to populate from XML
- **Access**: Via aiosqlite (async driver)
- **Schema**: Generated from TEI extraction logic

### Content Structure

- TEI-XML files stored as Git submodules in `src/ssrq_editio/data/`
- Configuration in `data.config.json` specifies which volumes to process
- Each volume has directories: `online/`, `TeX/`, `work_in_progress/`, etc.

## Code Standards & Conventions

### Python Style

- **Line Length**: 100 characters
- **Type Hints**: Enforced by mypy (`files = ["src"]`)
- **Imports**: Organized with isort (via ruff rule `I`)
- **Formatting**: Ruff formatter
- **Excluded Paths**:
  - `src/ssrq_editio/services/xslt/scripts/convert/` (3rd party code)
  - `.dependencies` directories

### Ruff Rules Enforced

- `C90`: McCabe complexity
- `E4, E7, E9`: Error codes
- `F`: pyflakes (undefined names, unused imports)
- `I`: isort (import sorting)

### SQL

- **Dialect**: SQLite
- **Location**: `src/ssrq_editio/adapters/db/sql/**/*.sql`
- **Formatting**: Enforced by sqlfluff
- **Linting**: Automatic in `just lint` and `just fmt`

### Commit Messages

- Uses **commitizen** (installed in dev dependencies)
- Pre-commit hooks enforce quality checks
- Format: Follow conventional commits standard

### Frontend Code Standards

- **TailwindCSS**: Primary styling approach
- **Alpine.js**: For reactive components (minimal framework style)
- **htmx**: For AJAX-driven interactions
- **No other JS frameworks**: Keep dependencies minimal

## Key Components & Their Roles

### Adapters Layer (`src/ssrq_editio/adapters/`)

- **db/**: SQLite database operations, migrations, schema
- **data.py**: Data transformation and extraction
- **entities.py**: Entity model mapping
- **file.py**: File I/O operations

### Services Layer (`src/ssrq_editio/services/`)

- **documents.py**: Document retrieval and processing
- **entities.py**: Entity business logic
- **kantons.py**: Canton-related services
- **volumes.py**: Volume management
- **xslt/**: XSLT transformations via Saxon
- **schema.py**: Schema validation services
- **sort.py**: Sorting logic
- **paginate.py**: Pagination utilities
- **logger.py**: Structured logging with loguru

### Models (`src/ssrq_editio/models/`)

- Pydantic data models for type-safe API contracts
- Used throughout services and API endpoints

### Entrypoints (`src/ssrq_editio/entrypoints/`)
- **app/**: FastAPI application and routes
- **cli/**: CLI command definitions (via Typer)

## Testing Strategy

### Test Structure

- **Location**: `tests/ssrq_editio/`
- **Framework**: pytest
- **Coverage Areas**:
  - `adapters/`: Database and file operations
  - `services/`: Business logic and transformations
  - `models/`: Data validation
  - `entrypoints/app/`: API endpoint functionality

### Test Data

- XML examples in `tests/examples/`: Sample documents for testing
- Includes various document types and schemas

### Running Tests

```bash
just test                    # Run all tests (with linting)
just test tests/path/...     # Run specific test file
uv run pytest -v            # Verbose output
uv run pytest --pdb         # Debug mode
```

### Best Practices

- Write tests for new features before/alongside implementation
- Use fixtures from `conftest.py` for setup/teardown
- Keep test data in `tests/examples/`
- Mock external dependencies (e.g., database)

## Important Integration Points

### Git Submodules

- Data volumes in `src/ssrq_editio/data/` are Git submodules
- Before running `prepare-db`, ensure submodules are initialized:
  ```bash
  git submodule update --init --recursive
  ```

### XML Processing
- TEI-XML files are extracted and transformed via Saxon XSLT 3.0
- Transformations occur in `services/xslt/`
- Output is stored in SQLite database

### Database Initialization
- Automatic during Docker build: `RUN uv run editio prepare-db --clean --no-parallel`
- Manual during development: `editio prepare-db --clean`
- Clears existing data and rebuilds from XML sources

## Docker & Deployment

### Multi-stage Build
1. **Builder Stage**: Compiles frontend assets (CSS/JS) using Node/Parcel
2. **Runtime Stage**: Builds Python environment with uv, copies compiled assets

### Environment Variables

- `WORKERS=2`: Number of Uvicorn workers
- `PORT=8000`: Server port
- `ALLOWED_HOSTS=*`: Allowed hosts header validation

### Runtime Process

1. Creates ssrq_editio user (security)
2. Runs `editio prepare-db --clean --no-parallel` on startup
3. Starts Uvicorn with proxy header support
4. Exposes port 8000

## Guidelines for Making Changes

### Before Starting
1. Check `just lint` passes locally
2. Write tests for new features
3. Ensure database changes are captured in SQL files
4. Update `pyproject.toml` if adding dependencies

### During Development
1. Run `just dev` for hot-reload development
2. Commit frequently with meaningful messages (commitizen)
3. Use type hints in all new Python code
4. Keep functions focused and well-documented

### Before Submitting

1. Run full test suite: `just test`
2. Test manually with `just run`
3. Verify SQL files are properly formatted
4. Check that all imports are used (`ruff check --select F401`)
5. Ensure HTML/CSS changes work in frontend

### Database Schema Changes

- Add SQL migrations in `src/ssrq_editio/adapters/db/sql/`
- Update corresponding Python model in `models/` or `adapters/entities.py`
- Test with `just test` before deployment

### Frontend Changes

- Use TailwindCSS utilities for styling
- Alpine.js for reactive state
- htmx for dynamic content loading
- Rebuild with `just build` to test changes
- Check both static assets and template rendering

## Common Pitfalls & Solutions

| Issue | Solution |
|-------|----------|
| "Module not found: ssrq-utils" | Install from Git: check `pyproject.toml` sources |
| Database is empty after `prepare-db` | Ensure Git submodules are initialized |
| CSS changes not appearing | Run `just css` to recompile TailwindCSS |
| Tests fail with import errors | Run `uv sync --all-extras --dev` |
| mypy errors on 3rd party code | Check exclude patterns in `pyproject.toml` |
| Ruff formatting conflicts | Run `just fmt` to auto-fix formatting |
| Hot reload not working | Restart `just dev` or check `watchfiles` |

## Performance Considerations

- **Database**: Using aiosqlite for async I/O
- **Frontend**: Minimal JS, HTMX for progressive enhancement
- **XSLT**: Saxon is performant but CPU-intensive for large documents
- **Caching**: cachebox library available for caching logic
- **File I/O**: Use async operations where possible

## Useful Links & References

- **FastAPI Docs**: https://fastapi.tiangolo.com
- **Saxon XSLT**: https://www.saxonica.com/welcome/welcome.xml
- **TailwindCSS**: https://tailwindcss.com
- **Alpine.js**: https://alpinejs.dev
- **htmx**: https://htmx.org
- **Pydantic**: https://docs.pydantic.dev
- **pytest**: https://docs.pytest.org

## Contacting Team Members

- **Original Author**: Bastian Politycki (bastian.politycki@unisg.ch)
- **Contributors**: Alexander Häberlin
- **Issues**: Report via GitHub: https://github.com/SSRQ-SDS-FDS/ssrq-editio/issues
