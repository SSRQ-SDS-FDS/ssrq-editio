import pytest
from playwright.sync_api import Page


@pytest.fixture
def assert_no_errors(page: Page):
    page_errors = []
    console_errors = []

    page.on("pageerror", lambda err: page_errors.append(err))
    page.on("console", lambda msg: console_errors.append(msg.text) if msg.type == "error" else None)

    yield

    messages = [
        *(f"JavaScript expection: {error}" for error in page_errors),
        *(f"console.error: {error}" for error in console_errors),
    ]

    assert not messages, "\n".join(messages)
