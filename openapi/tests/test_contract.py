"""Contract tests: every operation in keygen.v1.yaml is called against a live Keygen instance and
the response (status, content type, headers and body) is checked against the spec.

Run `pytest openapi/tests` with the environment described in openapi/README.md.
"""

import uuid

import pytest
from jsonschema import Draft202012Validator, FormatChecker
from openapi_spec_validator import validate as validate_spec

from conftest import JSONAPI

pytestmark = pytest.mark.live

METHODS = ("get", "post", "put", "patch", "delete")


class Contract:
    """Calls operations by operationId and checks the exchange against the spec."""

    def __init__(self, spec, http, settings, admin_token):
        self.spec = spec
        self.http = http
        self.settings = settings
        self.admin_token = admin_token
        self.covered = set()
        self.operations = {}

        for path, item in spec["paths"].items():
            for method in METHODS:
                if op := item.get(method):
                    self.operations[op["operationId"]] = (path, method, op, item)

    def resolve(self, node):
        while isinstance(node, dict) and "$ref" in node:
            ref = node["$ref"]
            assert ref.startswith("#/"), ref

            node = self.spec
            for part in ref[2:].split("/"):
                node = node[part]

        return node

    def validate(self, schema, instance):
        root = {"$schema": "https://json-schema.org/draft/2020-12/schema", "components": self.spec["components"], **schema}
        errors = sorted(Draft202012Validator(root, format_checker=FormatChecker()).iter_errors(instance), key=str)

        assert not errors, "\n".join(f"{'/'.join(map(str, e.absolute_path))}: {e.message}" for e in errors)

    def call(self, operation_id, *, status, params=None, query=None, body=None, token=True, license_key=None):
        path, method, op, item = self.operations[operation_id]
        params = {"account": self.settings["account"], **(params or {})}

        # every path parameter in the URL must be declared in the spec
        declared = {self.resolve(p)["name"] for p in [*item.get("parameters", []), *op.get("parameters", [])]}
        url_params = {p for p in params if "{" + p + "}" in path}
        assert url_params <= declared

        url = self.settings["url"] + path.format(**params)
        headers = {}

        if license_key:
            headers["Authorization"] = f"License {license_key}"
        elif token:
            headers["Authorization"] = f"Bearer {self.admin_token}"

        kwargs = {}
        if body is not None:
            request_schema = self.resolve(op["requestBody"])["content"][JSONAPI]["schema"]
            self.validate(request_schema, body)

            headers["Content-Type"] = JSONAPI
            kwargs["json"] = body

        res = self.http.request(method.upper(), url, params=query, headers=headers, **kwargs)

        documented = {k: self.resolve(v) for k, v in op["responses"].items()}
        assert res.status_code == status, f"{operation_id}: expected {status}, got {res.status_code}: {res.text}"
        assert str(res.status_code) in documented, f"{operation_id}: status {res.status_code} is not documented"

        response = documented[str(res.status_code)]

        for name in response.get("headers", {}):
            if name in ("Keygen-Version", "Keygen-Signature", "Digest"):
                assert name in res.headers, f"{operation_id}: missing documented header {name}"

        if content := response.get("content"):
            assert res.headers["Content-Type"].split(";")[0] == JSONAPI
            self.validate(content[JSONAPI]["schema"], res.json())
        else:
            assert res.content == b""

        self.covered.add(operation_id)

        return res


@pytest.fixture(scope="module")
def contract(spec, http, settings, admin_token):
    return Contract(spec, http, settings, admin_token)


@pytest.fixture(scope="module")
def policy(http, settings, admin_token):
    """A strict, floating policy that allows 2 machines (products and policies are outside the spec)."""
    base = f"{settings['url']}/accounts/{settings['account']}"
    headers = {"Authorization": f"Bearer {admin_token}", "Content-Type": JSONAPI}
    suffix = uuid.uuid4().hex[:8]

    res = http.post(f"{base}/products", headers=headers, json={"data": {"type": "products", "attributes": {"name": f"contract-{suffix}"}}})
    assert res.status_code == 201, res.text
    product_id = res.json()["data"]["id"]

    res = http.post(f"{base}/policies", headers=headers, json={"data": {
        "type": "policies",
        "attributes": {"name": f"contract-{suffix}", "floating": True, "strict": True, "maxMachines": 2, "authenticationStrategy": "LICENSE"},
        "relationships": {"product": {"data": {"type": "products", "id": product_id}}},
    }})
    assert res.status_code == 201, res.text

    return res.json()["data"]["id"]


def license_body(policy, **attributes):
    return {"data": {
        "type": "licenses",
        "attributes": attributes,
        "relationships": {"policy": {"data": {"type": "policies", "id": policy}}},
    }}


def machine_body(license_id, fingerprint, **attributes):
    return {"data": {
        "type": "machines",
        "attributes": {"fingerprint": fingerprint, **attributes},
        "relationships": {"license": {"data": {"type": "licenses", "id": license_id}}},
    }}


@pytest.fixture
def license(contract, policy):
    res = contract.call("createLicense", status=201, body=license_body(policy, name="Contract test", metadata={"seats": 5}))
    data = res.json()["data"]

    yield data

    contract.http.delete(
        f"{contract.settings['url']}/accounts/{contract.settings['account']}/licenses/{data['id']}",
        headers={"Authorization": f"Bearer {contract.admin_token}"},
    )


def test_spec_is_valid_openapi(spec):
    validate_spec(spec)


def test_create_and_read_license(contract, license):
    assert license["attributes"]["name"] == "Contract test"
    assert license["attributes"]["metadata"] == {"seats": 5}
    assert license["attributes"]["status"] == "ACTIVE"

    by_id = contract.call("getLicense", status=200, params={"license": license["id"]}).json()["data"]
    by_key = contract.call("getLicense", status=200, params={"license": license["attributes"]["key"]}).json()["data"]

    assert by_id["id"] == by_key["id"] == license["id"]


def test_list_licenses_with_each_pagination_style(contract, policy, license):
    plain = contract.call("listLicenses", status=200, query={"limit": 1}).json()
    assert len(plain["data"]) == 1
    assert "links" not in plain

    offset = contract.call("listLicenses", status=200, query={"page[number]": 1, "page[size]": 1}).json()
    assert len(offset["data"]) == 1
    assert offset["links"]["meta"]["count"] >= 1

    keyset = contract.call("listLicenses", status=200, query={"page[cursor]": "", "page[size]": 1}).json()
    assert len(keyset["data"]) == 1
    assert "next" in keyset["links"]

    filtered = contract.call("listLicenses", status=200, query={"status": "ACTIVE", "policy": policy, "order": "asc"}).json()
    assert license["id"] in [l["id"] for l in filtered["data"]]


def test_update_license(contract, license):
    body = {"data": {"type": "licenses", "attributes": {"name": "Renamed", "metadata": {"tier": "pro"}}}}
    updated = contract.call("updateLicense", status=200, params={"license": license["id"]}, body=body).json()["data"]

    assert updated["attributes"]["name"] == "Renamed"
    assert updated["attributes"]["metadata"] == {"tier": "pro"}


def test_validation_flow(contract, license):
    key = license["attributes"]["key"]

    # an invalid license is still a 200: the result is in meta
    res = contract.call("quickValidateLicense", status=200, params={"license": license["id"]}).json()
    assert res["meta"]["valid"] is False
    assert res["meta"]["code"] == "NO_MACHINES"

    contract.call("activateMachine", status=201, body=machine_body(license["id"], "fp-validate"))

    body = {"meta": {"nonce": 42, "scope": {"fingerprint": "fp-validate"}}}
    res = contract.call("validateLicense", status=200, params={"license": license["id"]}, body=body).json()
    assert (res["meta"]["valid"], res["meta"]["code"]) == (True, "VALID")
    assert res["meta"]["nonce"] == 42
    assert res["meta"]["scope"] == {"fingerprint": "fp-validate"}

    # body is optional
    contract.call("validateLicense", status=200, params={"license": license["id"]})

    # by key, with and without authentication
    for auth in ({"token": True}, {"token": False}):
        res = contract.call("validateLicenseKey", status=200, body={"meta": {"key": key, "scope": {"fingerprint": "fp-validate"}}}, **auth).json()
        assert res["data"]["id"] == license["id"]
        assert res["meta"]["valid"] is True

    res = contract.call("validateLicenseKey", status=200, token=False, body={"meta": {"key": key, "scope": {"fingerprint": "other"}}}).json()
    assert res["meta"]["code"] == "FINGERPRINT_SCOPE_MISMATCH"

    res = contract.call("validateLicenseKey", status=200, token=False, body={"meta": {"key": "does-not-exist"}}).json()
    assert res["data"] is None
    assert res["meta"]["code"] == "NOT_FOUND"


def test_machine_lifecycle_with_token(contract, license):
    machine = contract.call("activateMachine", status=201, body=machine_body(
        license["id"], "fp-lifecycle", name="Build box", platform="linux", cores=4, metadata={"rack": 1},
    )).json()["data"]

    assert machine["attributes"]["heartbeatStatus"] == "NOT_STARTED"
    assert machine["relationships"]["license"]["data"]["id"] == license["id"]

    by_fingerprint = contract.call("getMachine", status=200, params={"machine": "fp-lifecycle"}).json()["data"]
    assert by_fingerprint["id"] == machine["id"]

    listed = contract.call("listMachines", status=200, query={"license": license["id"], "fingerprint": "fp-lifecycle"}).json()
    assert [m["id"] for m in listed["data"]] == [machine["id"]]

    paged = contract.call("listMachines", status=200, query={"page[number]": 1, "page[size]": 1}).json()
    assert paged["links"]["meta"]["count"] >= 1

    body = {"data": {"type": "machines", "attributes": {"name": "Renamed box", "cores": 8}}}
    updated = contract.call("updateMachine", status=200, params={"machine": machine["id"]}, body=body).json()["data"]
    assert updated["attributes"]["name"] == "Renamed box"
    assert updated["attributes"]["cores"] == 8

    contract.call("deactivateMachine", status=204, params={"machine": machine["id"]})
    contract.call("getMachine", status=404, params={"machine": machine["id"]})


def test_machine_with_license_key_auth(contract, license):
    key = license["attributes"]["key"]

    machine = contract.call("activateMachine", status=201, license_key=key, body=machine_body(license["id"], "fp-license-auth")).json()["data"]
    contract.call("getMachine", status=200, license_key=key, params={"machine": machine["id"]})
    contract.call("deactivateMachine", status=204, license_key=key, params={"machine": machine["id"]})


def test_machine_limits_are_enforced(contract, license):
    for n in range(2):
        contract.call("activateMachine", status=201, body=machine_body(license["id"], f"fp-limit-{n}"))

    res = contract.call("activateMachine", status=422, body=machine_body(license["id"], "fp-limit-2")).json()
    assert res["errors"][0]["code"] == "MACHINE_LIMIT_EXCEEDED"
    assert res["errors"][0]["source"]["pointer"] == "/data"


def test_duplicate_fingerprint_is_unprocessable(contract, license):
    contract.call("activateMachine", status=201, body=machine_body(license["id"], "fp-dup"))

    res = contract.call("activateMachine", status=422, body=machine_body(license["id"], "fp-dup")).json()
    assert res["errors"][0]["code"] == "FINGERPRINT_TAKEN"


def test_error_responses(contract, policy):
    missing = str(uuid.uuid4())

    contract.call("listLicenses", status=401, token=False)
    contract.call("getLicense", status=404, params={"license": missing})
    contract.call("getMachine", status=404, params={"machine": missing})
    contract.call("quickValidateLicense", status=404, params={"license": missing})

    # relationships are required; skip the request-body check since this body is deliberately invalid
    res = contract.http.post(
        f"{contract.settings['url']}/accounts/{contract.settings['account']}/licenses",
        headers={"Authorization": f"Bearer {contract.admin_token}", "Content-Type": JSONAPI},
        json={"data": {"type": "licenses"}},
    )
    assert res.status_code == 400
    contract.validate({"$ref": "#/components/schemas/ErrorResponse"}, res.json())
    assert res.json()["errors"][0]["source"]["pointer"] == "/data/relationships"

    res = contract.call("createLicense", status=422, body=license_body(missing))
    assert res.json()["errors"][0]["source"]["pointer"] == "/data/relationships/policy"


def test_delete_license(contract, license):
    contract.call("deleteLicense", status=204, params={"license": license["id"]})
    contract.call("getLicense", status=404, params={"license": license["id"]})


def test_every_operation_is_covered(contract):
    """Keeps the spec honest: a new operation without a contract test fails here. Runs last."""
    assert contract.covered == set(contract.operations)
