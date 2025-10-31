# SensitiveString - Python Implementation

A Python implementation of SensitiveString for wrapping sensitive values (passwords, API keys, tokens) to prevent accidental exposure in logs, console output, and serialization.

PRs for the remaining phases are welcome.

## Basic Usage

```python
from sensitive_string import SensitiveString

# Wrap a sensitive value
password = SensitiveString("my-secret-password")

# Safe operations - these all show the hash
print(password)  # sha256:2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824
print(f"Password: {password}")  # Password: sha256:...
str(password)  # sha256:...
repr(password)  # SensitiveString(sha256:...)

# Intentional access when you actually need the plaintext
actual_password = password.get_value()  # or password.value
```

## Logging

Python's standard `logging` module automatically calls `__str__()`, so SensitiveStrings work safely by default:

```python
import logging

logger = logging.getLogger(__name__)
password = SensitiveString("secret123")

logger.info("Password is: %s", password)  # ✅ Shows hash
logger.info(f"Password is: {password}")   # ✅ Shows hash
```

## JSON Serialization

⚠️ **TODO**: Python's `json` module does NOT automatically call `__str__()` or provide hooks like TypeScript's `toJSON()`.

We need to decide on an approach for each use case:

### Standard Library `json`

- [ ] **TODO**: Provide custom `JSONEncoder` class
- [ ] **TODO**: Provide wrapper functions (`dumps()`, `dump()`) with automatic encoder
- [ ] **TODO**: Document the need to use `cls=SensitiveStringEncoder` parameter
- [ ] **TODO**: Decide on approach for plaintext serialization (when deliberately needed)

### Django REST Framework

- [ ] **TODO**: Implement custom `serializers.Field` subclass
- [ ] **TODO**: Document how to use in DRF serializers
- [ ] **TODO**: Consider auto-discovery mechanisms

### FastAPI / Pydantic

- [ ] **TODO**: Implement Pydantic v2 `__get_pydantic_core_schema__` for automatic handling
- [ ] **TODO**: Provide `@field_serializer` examples for Pydantic v1
- [ ] **TODO**: Test with FastAPI response models
- [ ] **TODO**: Document plaintext serialization for request bodies (when needed)

### Flask

- [ ] **TODO**: Determine if Flask-specific integration needed
- [ ] **TODO**: Document usage with `flask.jsonify()`

## Structured Logging

### structlog

- [ ] **TODO**: Implement custom processor for sanitizing SensitiveStrings
- [ ] **TODO**: Document processor configuration
- [ ] **TODO**: Test with various structlog output formats (JSON, console, etc.)

### loguru

- [ ] **TODO**: Test that loguru's automatic `__str__()` calling works correctly
- [ ] **TODO**: Document any gotchas

## Other Serialization Formats

### YAML

- [ ] **TODO**: Test behavior with PyYAML
- [ ] **TODO**: Provide custom representer if needed
- [ ] **TODO**: Test with ruamel.yaml

### TOML

- [ ] **TODO**: Determine if TOML serialization support is needed
- [ ] **TODO**: Test with tomli/tomllib

### Pickle

- [ ] **TODO**: Implement `__reduce__` to prevent plaintext in pickles
- [ ] **TODO**: Decide if pickle support should be explicitly disabled

### msgpack

- [ ] **TODO**: Determine if msgpack support is needed
- [ ] **TODO**: Provide custom serializer if needed

## Database ORMs

### SQLAlchemy

- [ ] **TODO**: Implement custom type decorator
- [ ] **TODO**: Decide on storage format (hash vs plaintext with encryption)
- [ ] **TODO**: Document usage with models

### Django ORM

- [ ] **TODO**: Implement custom field type
- [ ] **TODO**: Decide on storage approach
- [ ] **TODO**: Document usage in models

## Testing Utilities

- [ ] **TODO**: Provide test helpers for asserting on SensitiveStrings
- [ ] **TODO**: Provide plaintext comparison utilities for tests
- [ ] **TODO**: Document testing best practices

## Documentation TODO

- [ ] **TODO**: Add usage examples for each supported framework
- [ ] **TODO**: Document the "foot-guns" (intentional access via `.value`)
- [ ] **TODO**: Create migration guide from plain strings
- [ ] **TODO**: Add security considerations section
- [ ] **TODO**: Document performance characteristics

## Package Management

- [ ] **TODO**: Create `pyproject.toml` or `setup.py`
- [ ] **TODO**: Determine Python version support (3.8+? 3.10+?)
- [ ] **TODO**: Set up type stubs or py.typed marker
- [ ] **TODO**: Choose license (MIT to match TypeScript/Go versions?)
- [ ] **TODO**: Set up PyPI publishing

## Implementation Notes

### What's Intentionally NOT Protected

This library prevents **accidental** exposure. It does NOT prevent:

- Intentional access via `.value` or `.get_value()` - this is the intended escape hatch
- Memory dumps or debugger inspection
- Reflection/introspection attacks (e.g., `object.__getattribute__(obj, '_value')`)
- Code that explicitly extracts `__dict__` or `__slots__`

### Design Philosophy

Following the pattern from the TypeScript and Go implementations:

1. **Accidental exposure protection** - Make the default behavior safe
2. **Intentional access available** - Provide explicit methods to get plaintext when needed
3. **Framework integration** - Work with popular frameworks (even if not automatic)
4. **Consistent hashing** - Always show `sha256:<hex>` format for debugging
5. **Immutable** - SensitiveStrings should not be modifiable after creation

## Current Status

**Phase 1: Core Implementation** ✅
- Basic `SensitiveString` class with `__str__` and `__repr__`
- Hash-based string representation
- Explicit value access via `.value` and `.get_value()`
- Helper methods: `is_sensitive_string()`, `extract_value()`, etc.

**Phase 2: Serialization** 🚧 (TODO - see above)

**Phase 3: Framework Integration** 🚧 (TODO - see above)

**Phase 4: Testing & Distribution** 🚧 (TODO - see above)

