FROM stadlerpeter/existdb:6

USER wegajetty

ARG BUILD_DIR
ARG KEEP_ATOM_EDITOR
ENV TEMPLATING_VERSION=1.1.0

ADD --chown=wegajetty https://github.com/eeditiones/tei-publisher-lib/releases/download/v2.11.0/tei-publisher-lib-2.11.0.xar ${EXIST_HOME}/autodeploy/
ADD --chown=wegajetty https://github.com/eXist-db/shared-resources/releases/download/v0.9.1/shared-resources-0.9.1.xar ${EXIST_HOME}/autodeploy/
ADD --chown=wegajetty https://github.com/eXist-db/templating/releases/download/v${TEMPLATING_VERSION}/templating-${TEMPLATING_VERSION}.xar ${EXIST_HOME}/autodeploy/
ADD --chown=wegajetty https://github.com/eXist-db/atom-editor-support/releases/download/v1.1.0/atom-editor-1.1.0.xar ${EXIST_HOME}/autodeploy/

# We only need the atom-editor-module in development mode
RUN if [ "${KEEP_ATOM_EDITOR}" != "true" ]; then rm -f ${EXIST_HOME}/autodeploy/atom-editor-1.1.0.xar; fi

COPY ${BUILD_DIR}/*.xar ${EXIST_HOME}/autodeploy/
