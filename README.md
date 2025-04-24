# Editio or the Digital Scholarly Edition of the Swiss Law Sources

This is the main application repository for SLS.

The edition can be found online via [https://editio.sls-online.ch](https://editio.sls-online.ch)

## Overview

The digital scholarly edition is an Python based project. Originally it was based on the [TEIPublisher](https://teipublisher.com). It has been rewritten in Python and uses XSLT to transform the TEI-XML files into HTML. The rewritten application tries to tackle some of the shortcomings of the original project:

- poor performance
- spaghetti code
- just a handful of tests
- various bugs (we had more than 100 open issues in our internal tracker)
- complex setup and configuration

## Development

### Requirements

You need to install the following software:

- Python (3.11 or 3.12) together with [`uv`](https://github.com/astral-sh/uv)
- Rust (just required for building a python extension)
- Node.js and npm (for bundling the frontend assets)
- As well as [Git](https://git-scm.com) (of course...)

From a birds-eye view, the application mainly relies on the following technologies:

- [FastAPI](https://fastapi.tiangolo.com) used for the backend
- [TailwindCSS](https://tailwindcss.com) for the styling
- [htmx](https://htmx.org) and [Alpine.js](https://alpinejs.dev) for interactivity in the frontend
- [SQLite](https://sqlite.org) as the database
- [Saxon's XSLT 3.0 processor](https://www.saxonica.com/welcome/welcome.xml) to process the TEI-XML files

To get started with the development environment, you first need to install the required Python and Node packages. They are list in the `pyproject.toml` and `package.json` files and can be installed in the following way:

```sh
uv sync --all-extras --dev
npm install
```

From here on you can use the `just` command (in an activated virtual environment) to executes various tasks. To see a list of all available tasks, run `just help`.

### Populating the database

The application uses a SQLite database. The database gets populated with information extracted from the TEI-XML files, which are stored as Git-Submodules in `src/ssrq_editio/data`. You can find a small JSON-configuration in the root of this repository, which contains a list of volumes to be used / processed.

To populate the database, you can run the following command (in an activated virtual environment):

```sh
editio prepare-db --clean
```

Make sure to checkout the git submodule before running the command.

#### Starting the development server

After the database has been populated, you can start the development server by running:

```sh
just dev
```

This command will start bundle the frontend assets, start the FastAPI-server and watch the `src` folder for any changes. Hot-Module-Replacement (HMR) is not suppoted, so you need to refresh the page in your browser to see any changes.

### Common tasks

We have a number of common tasks that can be executed using the `just` command. Here are some of the most important ones:

- `just dev`: starts the development server
- `just test`: runs the tests
- `just lint`: runs the linters
- `just fmt`: formats the code

Execute `just help` to see a complete list of available tasks.

### Committing changes

This repository uses [pre-commit](https://pre-commit.com) to ensure various checks and formatting tasks are run before committing changes. To use pre-commit, you need to install the hooks in your Python environment:

```sh
pre-commit install
```

### Branches

The `main` branch reflects the actual production state. The `dev` branch is used for development and testing. All other branches are feature branches and should should at first be merged into `dev` and then deleted. A new version will be created on the `dev` branch and merged into `main` for deployment.

### Data

The TEI-XML files are included as git-submodules in the `src/ssrq_editio/data` folder. To add new data submodules, just add a new submodule and extend the configuration found in `data.config.json`.

## Deployment

To be Done.
