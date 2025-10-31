"""
Basic tests for SensitiveString to verify core functionality.
"""

from sensitive_string import SensitiveString


def test_str_shows_hash():
    """Test that str() returns a hash, not the plaintext"""
    secret = SensitiveString("my-secret-value")
    result = str(secret)
    
    assert result.startswith("sha256:"), f"Expected hash format, got: {result}"
    assert "my-secret-value" not in result, "Plaintext leaked in str()"
    assert len(result) == 71  # "sha256:" (7) + 64 hex chars


def test_repr_shows_hash():
    """Test that repr() returns a hash, not the plaintext"""
    secret = SensitiveString("my-secret-value")
    result = repr(secret)
    
    assert result.startswith("SensitiveString(sha256:"), f"Expected repr format, got: {result}"
    assert "my-secret-value" not in result, "Plaintext leaked in repr()"


def test_format_shows_hash():
    """Test that format strings use the hash"""
    secret = SensitiveString("my-secret-value")
    result = f"Password: {secret}"
    
    assert "sha256:" in result, f"Expected hash in format string, got: {result}"
    assert "my-secret-value" not in result, "Plaintext leaked in format string"


def test_get_value_returns_plaintext():
    """Test that get_value() returns the actual secret"""
    secret = SensitiveString("my-secret-value")
    assert secret.get_value() == "my-secret-value"


def test_value_property_returns_plaintext():
    """Test that .value property returns the actual secret"""
    secret = SensitiveString("my-secret-value")
    assert secret.value == "my-secret-value"


def test_len():
    """Test that len() returns the length of the plaintext"""
    secret = SensitiveString("12345")
    assert len(secret) == 5


def test_equality():
    """Test that two SensitiveStrings with same value are equal"""
    secret1 = SensitiveString("same-value")
    secret2 = SensitiveString("same-value")
    secret3 = SensitiveString("different-value")
    
    assert secret1 == secret2
    assert secret1 != secret3
    assert secret1 != "same-value"  # Not equal to plain string


def test_hashable():
    """Test that SensitiveStrings can be used in sets/dicts"""
    secret1 = SensitiveString("value1")
    secret2 = SensitiveString("value2")
    secret3 = SensitiveString("value1")  # Same as secret1
    
    # Can be added to a set
    secret_set = {secret1, secret2}
    assert len(secret_set) == 2
    
    # Same value should not add duplicate
    secret_set.add(secret3)
    assert len(secret_set) == 2


def test_consistent_hash():
    """Test that the same value produces the same hash string"""
    secret1 = SensitiveString("consistent-value")
    secret2 = SensitiveString("consistent-value")
    
    assert str(secret1) == str(secret2)


def test_is_sensitive_string():
    """Test the type checking helper"""
    secret = SensitiveString("value")
    
    assert SensitiveString.is_sensitive_string(secret)
    assert not SensitiveString.is_sensitive_string("plain string")
    assert not SensitiveString.is_sensitive_string(None)
    assert not SensitiveString.is_sensitive_string(123)


def test_extract_value():
    """Test extracting values from strings or SensitiveStrings"""
    secret = SensitiveString("secret")
    plain = "plain"
    
    assert SensitiveString.extract_value(secret) == "secret"
    assert SensitiveString.extract_value(plain) == "plain"
    assert SensitiveString.extract_value(None) is None


def test_extract_required_value():
    """Test extracting values with error on None"""
    secret = SensitiveString("secret")
    plain = "plain"
    
    assert SensitiveString.extract_required_value(secret) == "secret"
    assert SensitiveString.extract_required_value(plain) == "plain"
    
    try:
        SensitiveString.extract_required_value(None)
        assert False, "Should have raised ValueError"
    except ValueError as e:
        assert "Expected string or SensitiveString" in str(e)


def test_sensitive():
    """Test the conversion helper"""
    secret = SensitiveString("original")
    
    # Already sensitive - returns same object
    result = SensitiveString.sensitive(secret)
    assert result is secret
    
    # Convert string
    result = SensitiveString.sensitive("plain")
    assert isinstance(result, SensitiveString)
    assert result.value == "plain"
    
    # None stays None
    assert SensitiveString.sensitive(None) is None
    
    # Other types get stringified
    result = SensitiveString.sensitive(123)
    assert result.value == "123"


if __name__ == "__main__":
    # Run all tests
    import sys
    
    test_functions = [
        test_str_shows_hash,
        test_repr_shows_hash,
        test_format_shows_hash,
        test_get_value_returns_plaintext,
        test_value_property_returns_plaintext,
        test_len,
        test_equality,
        test_hashable,
        test_consistent_hash,
        test_is_sensitive_string,
        test_extract_value,
        test_extract_required_value,
        test_sensitive,
    ]
    
    passed = 0
    failed = 0
    
    for test_func in test_functions:
        try:
            test_func()
            print(f"✅ {test_func.__name__}")
            passed += 1
        except Exception as e:
            print(f"❌ {test_func.__name__}: {e}")
            failed += 1
    
    print(f"\n{passed} passed, {failed} failed")
    sys.exit(0 if failed == 0 else 1)

