"""
SensitiveString - A wrapper for sensitive string values that prevents accidental exposure.

This module provides a SensitiveString class that wraps sensitive values (like passwords,
API keys, tokens) and returns a SHA256 hash instead of the raw value when converted to
string, logged, or otherwise serialized.
"""

import hashlib
from typing import Optional, Union, Any


class SensitiveString:
    """
    A wrapper for sensitive string values that prevents accidental exposure by returning
    a SHA256 hash instead of the raw value in string contexts.
    
    The primary goal is to prevent ACCIDENTAL persistence or exposure of secrets through:
    - Logging (automatically uses __str__, which returns the hash)
    - String formatting (f-strings, format(), str())
    - Console output (print, repr)
    - JSON serialization (with appropriate encoder - see README for framework-specific details)
    
    Note: This does NOT prevent intentional access via the .value property or .get_value()
    method - those are the escape hatches for when you actually need the plaintext.
    
    Example:
        >>> password = SensitiveString("my-secret-password")
        >>> print(password)
        sha256:2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824
        >>> print(f"Password: {password}")
        Password: sha256:2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824
        >>> password.get_value()  # Intentional access
        'my-secret-password'
    """
    
    __slots__ = ('_value',)
    
    def __init__(self, value: str):
        """
        Create a new SensitiveString.
        
        Args:
            value: The sensitive string value to wrap
        """
        object.__setattr__(self, '_value', value)
    
    def __str__(self) -> str:
        """
        Returns the SHA256 hash of the value instead of the plaintext.
        
        This is called by:
        - print()
        - str()
        - f-strings: f"{password}"
        - format(): "{}".format(password)
        - Most logging frameworks
        
        Returns:
            A string in the format "sha256:<hex_digest>"
        """
        hash_obj = hashlib.sha256(self._value.encode('utf-8'))
        return f"sha256:{hash_obj.hexdigest()}"
    
    def __repr__(self) -> str:
        """
        Returns a representation showing it's a SensitiveString with the hash.
        
        This is called by:
        - repr()
        - Interactive console display
        - Some debugging tools
        - Logging with %r format
        
        Returns:
            A string in the format "SensitiveString(sha256:<hex_digest>)"
        """
        return f"SensitiveString({self.__str__()})"
    
    def __format__(self, format_spec: str) -> str:
        """
        Handles custom formatting (called by f-strings and format()).
        
        Args:
            format_spec: The format specification (e.g., ":<20" for left-align 20 chars)
        
        Returns:
            The formatted hash string
        """
        return format(str(self), format_spec)
    
    def get_value(self) -> str:
        """
        Explicitly retrieve the plaintext value.
        
        Use this only when you actually need access to the secret value,
        such as:
        - Authenticating with an external service
        - Comparing against user input for validation
        - Encrypting before storage
        
        Returns:
            The raw plaintext value
        """
        return self._value
    
    @property
    def value(self) -> str:
        """
        Property accessor for the plaintext value (alternative to get_value()).
        
        This is more Pythonic than get_value() but serves the same purpose.
        
        Returns:
            The raw plaintext value
        """
        return self._value
    
    def __len__(self) -> int:
        """
        Returns the length of the underlying value without exposing it.
        
        Returns:
            The length of the plaintext value
        """
        return len(self._value)
    
    def __eq__(self, other: Any) -> bool:
        """
        Compare two SensitiveStrings by their raw values.
        
        Args:
            other: Another object to compare against
        
        Returns:
            True if both are SensitiveStrings with equal values
        """
        if isinstance(other, SensitiveString):
            return self._value == other._value
        return False
    
    def __hash__(self) -> int:
        """
        Make SensitiveStrings hashable (so they can be used in sets/dicts as keys).
        
        Returns:
            Hash of the plaintext value
        """
        return hash(self._value)
    
    def __dir__(self):
        """
        Customize dir() output to hide internal _value attribute.
        
        This doesn't prevent access, but makes it less obvious in introspection.
        
        Returns:
            List of public attributes
        """
        return ['get_value', 'value']
    
    @staticmethod
    def is_sensitive_string(obj: Any) -> bool:
        """
        Check if an object is a SensitiveString.
        
        Args:
            obj: Object to check
        
        Returns:
            True if obj is a SensitiveString instance
        """
        return isinstance(obj, SensitiveString)
    
    @staticmethod
    def extract_value(obj: Union[str, 'SensitiveString', None]) -> Optional[str]:
        """
        Extract the plaintext value from a string or SensitiveString.
        
        This is useful when you have a parameter that could be either type
        and need to normalize it.
        
        Args:
            obj: A string, SensitiveString, or None
        
        Returns:
            The plaintext string value, or None if obj was None
        """
        if obj is None:
            return None
        if isinstance(obj, SensitiveString):
            return obj.get_value()
        if isinstance(obj, str):
            return obj
        return None
    
    @staticmethod
    def extract_required_value(obj: Union[str, 'SensitiveString', None]) -> str:
        """
        Extract the plaintext value from a string or SensitiveString, or raise an error.
        
        Args:
            obj: A string or SensitiveString
        
        Returns:
            The plaintext string value
        
        Raises:
            ValueError: If obj is None or not a string/SensitiveString
        """
        result = SensitiveString.extract_value(obj)
        if result is None:
            raise ValueError("Expected string or SensitiveString, got None")
        return result
    
    @staticmethod
    def sensitive(obj: Any) -> Optional['SensitiveString']:
        """
        Convert an object to a SensitiveString if it isn't already.
        
        Args:
            obj: Object to convert (will be stringified if not already a string)
        
        Returns:
            A SensitiveString, or None if obj was None
        """
        if obj is None:
            return None
        if isinstance(obj, SensitiveString):
            return obj
        return SensitiveString(str(obj))

