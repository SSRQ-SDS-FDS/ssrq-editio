# Editio or the Digital Scholarly Edition of the Swiss Law Sources

This is the main application repository for SLS.

The edition can be found online via [https://editio.sls-online.ch](https://editio.sls-online.ch)

## Get up and running

The digital scholarly edition is an eXist-DB based project and was originally build with `ant`. Since `29f7db1` the build-process has been rewritten and is based on python tooling (like other software e.g. [the TEI-XML schema](https://github.com/SSRQ-SDS-FDS/ssrq-schema)).

### Development

#### Requirements

You need to install the following software:

1. Python (3.11 or higher) together with [`poetry`](https://python-poetry.org)
2. [Docker](https://www.docker.com)

As well as [Git](https://git-scm.com) (of course...)

#### The `editio CLI`

All tasks are abstracted with a simple CLI. Switch to the project directory and execute the following:

```sh
poetry shell # this may be optional
poetry install
```

This will activate the virtual python environment and install all dependencies. You are now ready to go.

Run `editio --help` to see all available commands.

#### Running the application

At first build the xar-application:

```sh
editio build --enable-upload --update-data dev
```

And then start the application inside a docker container:

```sh
editio run
```

This will start the application on port `8080` and you can access it via [http://localhost:8080](http://localhost:8080/exist/apps/ssrq/).

#### Running the tests

To be done....

### Deployment / Running in production

To be done....
