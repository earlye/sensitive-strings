<?php

declare(strict_types=1);

namespace SensitiveString;

use JsonSerializable;

/**
 * SensitiveString wraps a string value and prevents accidental exposure
 * by returning a SHA256 hash instead of the raw value when formatted or serialized.
 *
 * The primary goal is to prevent ACCIDENTAL exposure. Intentional access
 * to the plaintext is available via the getValue() method or value property.
 *
 * Example:
 *   $password = new SensitiveString("my-secret");
 *   echo $password;  // sha256:2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824
 *   $password->getValue();  // "my-secret" (intentional access)
 */
class SensitiveString implements JsonSerializable
{
    private string $value;

    /**
     * Creates a new SensitiveString
     *
     * @param string $value The sensitive value to wrap
     */
    public function __construct(string $value)
    {
        $this->value = $value;
    }

    /**
     * Returns the SHA256 hash of the value instead of the plaintext.
     * This is called by echo, print, string concatenation, etc.
     *
     * @return string The SHA256 hash in format "sha256:hex"
     */
    public function __toString(): string
    {
        return 'sha256:' . hash('sha256', $this->value);
    }

    /**
     * Returns debug representation showing it's a SensitiveString with the hash.
     * This is called by var_dump(), var_export(), etc.
     *
     * @return array Debug information
     */
    public function __debugInfo(): array
    {
        return [
            'value' => (string)$this,
        ];
    }

    /**
     * Explicitly retrieves the plaintext value.
     * Use this only when you actually need access to the secret value.
     *
     * @return string The raw plaintext value
     */
    public function getValue(): string
    {
        return $this->value;
    }

    /**
     * Property accessor for the plaintext value (PHP 8.0+ style)
     *
     * @return string The raw plaintext value
     */
    public function __get(string $name): string
    {
        if ($name === 'value') {
            return $this->value;
        }
        throw new \Exception("Undefined property: $name");
    }

    /**
     * Returns the length of the underlying value without exposing it.
     *
     * @return int Length of the plaintext
     */
    public function length(): int
    {
        return strlen($this->value);
    }

    /**
     * Returns true if the underlying value is empty.
     *
     * @return bool True if empty
     */
    public function isEmpty(): bool
    {
        return empty($this->value);
    }

    /**
     * Returns the SHA256 hash for JSON serialization (JsonSerializable interface).
     * This is called automatically by json_encode().
     *
     * @return string The SHA256 hash
     */
    public function jsonSerialize(): mixed
    {
        return (string)$this;
    }

    /**
     * Checks if a value is a SensitiveString
     *
     * @param mixed $obj Object to check
     * @return bool True if obj is a SensitiveString
     */
    public static function isSensitiveString($obj): bool
    {
        return $obj instanceof self;
    }

    /**
     * Extracts the plaintext value from a string or SensitiveString
     *
     * @param mixed $obj Object to extract from
     * @return string|null The plaintext value or null
     */
    public static function extractValue($obj): ?string
    {
        if ($obj instanceof self) {
            return $obj->getValue();
        }
        if (is_string($obj)) {
            return $obj;
        }
        return null;
    }

    /**
     * Extracts the plaintext value or throws an exception
     *
     * @param mixed $obj Object to extract from
     * @return string The plaintext value
     * @throws \InvalidArgumentException If obj is not a string or SensitiveString
     */
    public static function extractRequiredValue($obj): string
    {
        $result = self::extractValue($obj);
        if ($result === null) {
            throw new \InvalidArgumentException('Expected string or SensitiveString');
        }
        return $result;
    }

    /**
     * Converts a value into a SensitiveString if it isn't already
     *
     * @param mixed $obj Object to convert
     * @return SensitiveString|null A SensitiveString or null if obj was null
     */
    public static function sensitive($obj): ?self
    {
        if ($obj === null) {
            return null;
        }
        if ($obj instanceof self) {
            return $obj;
        }
        return new self((string)$obj);
    }
}

