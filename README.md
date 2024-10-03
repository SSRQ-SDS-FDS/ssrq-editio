# Editio or the Digital Scholarly Edition of the Swiss Law Sources

This is the main application repository for SLS.

The edition can be found online via [https://editio.sls-online.ch](https://editio.sls-online.ch)

## Get up and running

The digital scholarly edition is an Python based project. Originally it was based on the [TEIPublisher](https://teipublisher.com). It has been rewritten in Python and uses XSLT to transform the TEI-XML files into HTML. The rewritten application tries to tackle some of the shortcomings of the original project:

- poor performance
- spaghetti code
- just a handful of tests
- various bugs (we had more than 100 open issues in our internal tracker)
- complex setup and configuration

### Development

#### Requirements

You need to install the following software:

1. Python (3.12 or higher) together with [`uv`](https://github.com/astral-sh/uv)
2. [Docker](https://www.docker.com)

As well as [Git](https://git-scm.com) (of course...)

From a birds-eye view, the application mainly relies on the following technologies:

- [FastAPI](https://fastapi.tiangolo.com) used for the backend
- [TailwindCSS](https://tailwindcss.com) for the styling
- [htmx](https://htmx.org) and [Alpine.js](https://alpinejs.dev) for interactivity in the frontend
- [MongoDB](https://www.mongodb.com) as the database
- [Saxon's XSLT 3.0 processor](https://www.saxonica.com/welcome/welcome.xml) to process the TEI-XML files

To get started with the development environment, you first need to install the required Python packages. They are list in the `pyproject.toml` file and can be installed in the following way:

```sh
uv sync
```

From here on you can use the `just` command (in an activated virtual environment) to executes various tasks. To see a list of all available tasks, run `just help`.

#### Populating the database

To be done.

#### Branches

The `main` branch reflects the actual production state. The `dev` branch is used for development and testing. All other branches are feature branches and should should at first be merged into `dev` and then deleted. A new version will be created on the `dev` branch and merged into `main` for deployment.

### Deployment

To be Done.
