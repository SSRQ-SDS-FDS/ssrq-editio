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

#### Running the application (in dev mode)

At first build the xar-application:

```sh
editio build 'dev'
```

If you want to update the data subrepo set the `-u` flag.

And then start the application inside a docker container:

```sh
editio run
```

This will start the application on port `8080` and you can access it via [http://localhost:8080](http://localhost:8080/exist/apps/ssrq/).

**Note**: If you're making any changes to the XQuery code, you need to rebuild the application and restart the container. Otherwise you will have to run `editio sync` before you make any changes to the code. This is a more stable drop-in replacement for the `sync`-command of the [eXist-DB plugin for VSCode](https://code.visualstudio.com) and will upload all changed files to the running container. The `sync`-command does not depend on VSCode and can be used with any environment.

#### Running the tests

To be done....

### Deployment / Running in production

#### Staging-Server

The deployment of the staging-version is automated via GitHub-Actions. See the workflow-files for more details.

#### Branches

The `main` branch reflects the actual production state. The `dev` branch is used for development and testing. All other branches are feature branches and should should at first be merged into `dev` and then deleted. A new version will be created on the `dev` branch and merged into `main` for deployment.
