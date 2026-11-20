# OpenAPI description

`keygen.v1.yaml` is an [OpenAPI 3.1](https://spec.openapis.org/oas/v3.1.0) description of part of the
Keygen v1 API (JSON:API). It covers licenses (list, create, retrieve, update, delete), license
validation (`validate` by ID or key, quick validate, `validate-key`) and machines (list, activate,
retrieve, update, deactivate). Other resources are not described yet.

It is written by hand from `config/routes.rb`, the `typed_params` blocks in the controllers and the
serializers, and is checked against a running instance by the contract tests below, so it cannot
drift silently. It describes CE; EE-only fields (`permissions`, `environment`) are not listed, but
response schemas allow additional properties so EE responses still validate.

## Lint

```bash
npx @redocly/cli lint openapi/keygen.v1.yaml
```

## Contract tests

The tests call every operation in the spec against a live Keygen instance and validate the status
code, content type, documented headers and response body (and the request bodies they send) against
the spec. A final test fails if an operation has no contract test.

They need Python 3.10+ and a running Keygen with an admin account, for example Keygen CE started
from `compose.yaml` after `rails keygen:setup` (see the
[self-hosting docs](https://keygen.sh/docs/self-hosting/)):

```bash
export KEYGEN_URL=http://localhost:3000/v1
export KEYGEN_ACCOUNT_ID=<KEYGEN_ACCOUNT_ID from .env>
export KEYGEN_ADMIN_EMAIL=<KEYGEN_ADMIN_EMAIL from .env>
export KEYGEN_ADMIN_PASSWORD=<KEYGEN_ADMIN_PASSWORD from .env>

# web enforces TLS and KEYGEN_HOST. When talking to it directly (without Caddy), send the host
# and forwarded protocol it expects:
export KEYGEN_EXTRA_HEADERS='{"Host": "<KEYGEN_HOST>", "X-Forwarded-Proto": "https"}'

pip install -r openapi/requirements.txt
pytest openapi
```

Without `KEYGEN_URL` the live tests are skipped. The tests create a product and a policy in the
account they run against, and delete the licenses they create, so use a throwaway instance.

`KEYGEN_HOST` needs at least two labels (for example `api.keygen.test`), since the base domain is
derived from it.
