import asyncio
import socket
import threading
import time
from collections.abc import Generator
from pathlib import Path

import pytest
import uvicorn

from ssrq_editio.adapters.db.connection import db_session
from ssrq_editio.entrypoints.app.main import app
from ssrq_editio.entrypoints.app.shared.dependencies import (
    db_connection,
    document_transformer,
    transpile_schema,
)
from ssrq_editio.entrypoints.app.views.models.base import get_view_response_cache
from ssrq_editio.models.documents import DocumentDisplay, DocumentType
from tests.ssrq_editio.fixtures.e2e_data import (
    create_e2e_transpiled_schema,
    create_static_e2e_database,
)


@pytest.fixture(scope="session")
def e2e_database(
    tmp_path_factory: pytest.TempPathFactory,
    example_path: Path,
) -> Path:
    workspace = tmp_path_factory.mktemp("editio-e2e")
    database = workspace / "ssrq-editio-e2e.sqlite3"
    data_root = workspace / "data"
    transpiled_schema = asyncio.run(create_e2e_transpiled_schema(example_path, workspace))
    asyncio.run(
        create_static_e2e_database(
            database=database,
            example_path=example_path,
            data_root=data_root,
            transpiled_schema=transpiled_schema,
        )
    )
    return database


@pytest.fixture(scope="session")
def e2e_transpiled_schema(tmp_path_factory: pytest.TempPathFactory, example_path: Path) -> Path:
    workspace = tmp_path_factory.mktemp("editio-e2e-schema")
    return asyncio.run(create_e2e_transpiled_schema(example_path, workspace))


@pytest.fixture(scope="session")
def e2e_base_url(e2e_database: Path, e2e_transpiled_schema: Path) -> Generator[str, None, None]:
    get_view_response_cache().clear()

    async def override_db_connection():
        async for session in db_session(e2e_database):
            yield session

    async def override_transpile_schema():
        return e2e_transpiled_schema

    async def override_document_transformer():
        return E2EDocumentTransformer()

    app.dependency_overrides[db_connection] = override_db_connection
    app.dependency_overrides[transpile_schema] = override_transpile_schema
    app.dependency_overrides[document_transformer] = override_document_transformer

    port = _get_free_port()
    config = uvicorn.Config(app, host="127.0.0.1", port=port, log_level="warning")
    server = uvicorn.Server(config)
    thread = threading.Thread(target=server.run, daemon=True)
    thread.start()
    _wait_until_server_accepts_connections(port)

    try:
        yield f"http://127.0.0.1:{port}"
    finally:
        server.should_exit = True
        thread.join(timeout=10)
        app.dependency_overrides.pop(db_connection, None)
        app.dependency_overrides.pop(transpile_schema, None)
        app.dependency_overrides.pop(document_transformer, None)
        get_view_response_cache().clear()


def _get_free_port() -> int:
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
        sock.bind(("127.0.0.1", 0))
        return int(sock.getsockname()[1])


def _wait_until_server_accepts_connections(port: int, timeout: float = 15.0) -> None:
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
            sock.settimeout(0.2)
            if sock.connect_ex(("127.0.0.1", port)) == 0:
                return
        time.sleep(0.05)
    raise RuntimeError(f"E2E server did not start on port {port}.")


class E2EDocumentTransformer:
    def __call__(self, xml_src: str, output_lang):
        if "SSRQ-FR-I_2_8-83.0-1" in xml_src:
            return DocumentDisplay(
                comment=None,
                descriptions=[],
                normalized_transcript=None,
                summary=None,
                transcript=(
                    "<p>{{ display_sub_document_info("
                    "sub_docs, 'SSRQ-FR-I_2_8-83.1-1', lang) }}</p>"
                    "<p>{{ display_sub_document_info("
                    "sub_docs, 'SSRQ-FR-I_2_8-83.2-1', lang) }}</p>"
                ),
                type=DocumentType.collection,
            )

        return DocumentDisplay(
            comment=None,
            descriptions=[],
            normalized_transcript="<p>Normalisierte E2E-Ansicht</p>",
            summary=None,
            transcript="""<p>Transkript E2E-Ansicht <button class="tei-pb" data-facs="OGA_Gams_Nr_5_v">[fol.&nbsp;1v]</button><span class="has-border popup" x-data="popup" x-init="init()">
    <button type="button" popovertarget=""><svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" class="tei-entity-icon">
  <circle cx="12" cy="12" r="10"></circle>
  <line x1="12" y1="16" x2="12" y2="12"></line>
  <line x1="12" y1="8" x2="12.01" y2="8"></line>
</svg></button><div class="has-marker popup-body" popover="">
    <div class="popup-content">
    Seitenumbruch
</div>
</div>
</span></p>""",
            type=DocumentType.transcript,
        )
