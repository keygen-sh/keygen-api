# OpenAPI Specification Generator

This tool generates programmatic OpenAPI 3.1.0 specifications for the Keygen API by parsing Rails application code, including controllers with `typed_params` blocks and JSONAPI serializers.

## Overview

The generator creates split YAML files with `$ref` references and produces separate specifications for Community Edition (CE) and Enterprise Edition (EE). It extracts parameter definitions from `typed_params` blocks using AST parsing and response schemas from JSONAPI serializers.

## Features

- **AST Parsing**: Extracts parameter definitions from `typed_params` blocks
- **Version Support**: Generates specs for all API versions (1.0 through 1.7)
- **Edition Separation**: Creates separate CE and EE specifications
- **Split YAML Structure**: Uses `$ref` references for maintainable file organization
- **JSONAPI Compatible**: Generates proper JSONAPI request/response schemas
- **Validation**: Includes built-in OpenAPI specification validation

## Requirements

- Ruby 3.4.7 (uses rbenv for version management)
- Rails 8 application with Keygen codebase
- Required environment variables for Rails application initialization

## Installation

1. **Install Ruby 3.4.7** (if not already installed):
   ```bash
   brew install rbenv ruby-build
   rbenv install 3.4.7
   rbenv global 3.4.7
   ```

2. **Install dependencies**:
   ```bash
   bundle install
   ```

3. **Verify installation**:
   ```bash
   bundle exec rake keygen:openapi:generate --dry-run
   ```

## Usage

### Environment Variables

The generator requires several environment variables to initialize the Rails application:

```bash
export KEYGEN_HOST=api.keygen.sh
export KEYGEN_DOMAIN=keygen.sh
export ENCRYPTION_PRIMARY_KEY=test_key
export ENCRYPTION_DETERMINISTIC_KEY=test_det_key
export ENCRYPTION_KEY_DERIVATION_SALT=test_salt
```

### Commands

#### Generate Specifications

Generate both CE and EE specifications:
```bash
bundle exec rake keygen:openapi:generate
```

Generate only CE specification:
```bash
EDITION=ce bundle exec rake keygen:openapi:generate
```

Generate only EE specification:
```bash
EDITION=ee bundle exec rake keygen:openapi:generate
```

Change output directory:
```bash
OUTPUT_DIR=docs/api bundle exec rake keygen:openapi:generate
```

#### Validate Specifications

Validate generated YAML files:
```bash
bundle exec rake keygen:openapi:validate
```

#### Clean Generated Files

Remove all generated specification files:
```bash
bundle exec rake keygen:openapi:clean
```

## Output Structure

```
openapi/
├── openapi.yaml                    # Community Edition root spec
├── openapi-ee.yaml                 # Enterprise Edition root spec
├── paths/                          # Individual path specifications
│   ├── accounts_account_id_licenses.yaml
│   ├── machines_id.yaml
│   └── ...
├── schemas/
│   ├── common/                     # Reusable JSONAPI schemas
│   │   ├── JsonApiDocument.yaml
│   │   ├── JsonApiData.yaml
│   │   └── ...
│   ├── requests/                   # Request body schemas
│   ├── responses/                  # Response body schemas
│   └── ...
├── parameters/                     # Common parameter definitions
│   ├── AccountIdParameter.yaml
│   ├── PageSizeParameter.yaml
│   └── ...
└── responses/                      # Common response definitions
    ├── UnauthorizedError.yaml
    ├── NotFoundError.yaml
    └── ...
```

## Architecture

### Core Components

- **`Generator`**: Main orchestrator coordinating the generation process
- **`RouteParser`**: Extracts API routes from Rails application
- **`TypedParamsParser`**: AST parser for `typed_params` blocks in controllers
- **`SerializerParser`**: Parser for JSONAPI serializer definitions
- **`ParameterSchemaBuilder`**: Converts typed_params to OpenAPI parameter schemas
- **`ResponseSchemaBuilder`**: Converts serializers to OpenAPI response schemas
- **`SpecBuilder`**: Builds the root OpenAPI specification with references
- **`YamlWriter`**: Writes the split YAML file structure

### Version & Edition Handling

- **`VersionResolver`**: Evaluates version conditionals in `typed_params`
- **`EEFilter`**: Filters Enterprise Edition features for CE specifications
- **`MigrationTracker`**: Handles parameter name migrations across versions

## Code Parsing

### TypedParams Parsing

The generator uses AST parsing to extract parameter definitions from `typed_params` blocks:

```ruby
typed_params do
  format :jsonapi

  param :name, type: :string, optional: true
  param :metadata, type: :hash do
    param :key, type: :string
    param :value, type: :string
  end
end
```

Supports:
- Nested parameters with `hash` and `array` types
- Version conditionals: `if: -> { current_api_version == '1.0' }`
- Role conditionals: `if: -> { current_bearer&.has_role?(:admin) }`
- Enterprise Edition blocks: `Keygen.ee { ... }`

### Serializer Parsing

Parses serializer source files to extract:
- Resource types and attributes
- Relationships and links
- Version and edition conditionals
- Meta information

## Validation

The generator includes validation using OpenAPI specification validators to ensure:
- All `$ref` references are valid
- Schema definitions are correct
- Parameter and response definitions conform to OpenAPI 3.1.0

## Integration

### CI/CD Pipeline

Add to your CI/CD pipeline:

```yaml
- name: Generate OpenAPI specs
  run: |
    bundle exec rake keygen:openapi:generate
    bundle exec rake keygen:openapi:validate

- name: Upload specs
  uses: actions/upload-artifact@v3
  with:
    name: openapi-specs
    path: openapi/
```

### API Documentation

Use the generated specifications with:
- **Swagger UI**: For interactive API documentation
- **OpenAPI Generator**: For SDK generation in multiple languages
- **Contract Testing**: For API behavior validation
- **API Gateways**: For automated API management

## Troubleshooting

### Common Issues

1. **Ruby version mismatch**:
   ```bash
   rbenv versions
   rbenv global 3.4.7
   ```

2. **Missing environment variables**:
   ```bash
   # Check required vars are set
   echo $KEYGEN_HOST $ENCRYPTION_PRIMARY_KEY
   ```

3. **Bundle issues**:
   ```bash
   bundle install --redownload
   bundle update bundler
   ```

4. **Validation failures**:
   - Check YAML syntax in generated files
   - Verify `$ref` paths are correct
   - Ensure all required schemas are present

### Debug Mode

Enable verbose output:
```bash
DEBUG=1 bundle exec rake keygen:openapi:generate
```

## Contributing

When adding new API endpoints:
1. Ensure controllers use `typed_params` for parameter validation
2. Create corresponding serializers for responses
3. Add version conditionals for API versioning
4. Use `Keygen.ee` blocks for Enterprise features
5. Run generation and validation after changes

## License

This tool is part of the Keygen API codebase and follows the same licensing terms.