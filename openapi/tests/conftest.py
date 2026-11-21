"""Fixtures for the OpenAPI contract tests.

The tests talk to a running Keygen instance, so they are skipped unless KEYGEN_URL is set.
See openapi/README.md.
"""

import json
import os
import pathlib

import pytest
import requests
import yaml

SPEC_PATH = pathlib.Path(__file__).resolve().parents[1] / "keygen.v1.yaml"
JSONAPI = "application/vnd.api+json"


def pytest_collection_modifyitems(config, items):
    if os.environ.get("KEYGEN_URL"):
        return

    skip = pytest.mark.skip(reason="KEYGEN_URL is not set; no Keygen instance to test against")

    for item in items:
        if "live" in item.keywords:
            item.add_marker(skip)


@pytest.fixture(scope="session")
def spec():
    with open(SPEC_PATH) as f:
        return yaml.safe_load(f)


@pytest.fixture(scope="session")
def settings():
    return {
        # e.g. http://localhost:3000/v1
        "url": os.environ.get("KEYGEN_URL", "").rstrip("/"),
        "account": os.environ.get("KEYGEN_ACCOUNT_ID", ""),
        "email": os.environ.get("KEYGEN_ADMIN_EMAIL", ""),
        "password": os.environ.get("KEYGEN_ADMIN_PASSWORD", ""),
        # extra headers as JSON, e.g. {"Host": "keygen.example.com", "X-Forwarded-Proto": "https"}
        "headers": json.loads(os.environ.get("KEYGEN_EXTRA_HEADERS", "{}")),
    }


@pytest.fixture(scope="session")
def http(settings):
    session = requests.Session()
    session.headers.update({"Accept": JSONAPI, **settings["headers"]})
    return session


@pytest.fixture(scope="session")
def admin_token(http, settings):
    """Exchanges the admin email and password for a token (an endpoint outside the spec)."""
    res = http.post(
        f"{settings['url']}/accounts/{settings['account']}/tokens",
        auth=(settings["email"], settings["password"]),
    )
    assert res.status_code == 201, res.text

    return res.json()["data"]["attributes"]["token"]
