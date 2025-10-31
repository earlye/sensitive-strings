<?php

declare(strict_types=1);

require_once __DIR__ . '/src/SensitiveString.php';

use SensitiveString\SensitiveString;

echo "=== PHP SensitiveString Tests ===\n\n";

// Test 1: __toString shows hash
$password = new SensitiveString('my-secret-password');
$result = (string)$password;
assert(str_starts_with($result, 'sha256:'), "Expected hash format");
assert(!str_contains($result, 'my-secret-password'), "Leaked plaintext!");
echo "✅ Test 1: __toString shows hash\n";

// Test 2: getValue returns plaintext
assert($password->getValue() === 'my-secret-password', "getValue() failed");
echo "✅ Test 2: getValue returns plaintext\n";

// Test 3: value property returns plaintext
assert($password->value === 'my-secret-password', "value property failed");
echo "✅ Test 3: value property returns plaintext\n";

// Test 4: String interpolation
$message = "Password: $password";
assert(!str_contains($message, 'my-secret-password'), "Leaked in interpolation!");
echo "✅ Test 4: String interpolation shows hash\n";

// Test 5: JSON
$data = ['password' => $password];
$json = json_encode($data);
assert(!str_contains($json, 'my-secret-password'), "JSON leaked!");
assert(str_contains($json, 'sha256:'), "JSON doesn't show hash!");
echo "✅ Test 5: JSON serialization shows hash\n";

// Test 6: Helper methods
assert(SensitiveString::extractValue($password) === 'my-secret-password', "extract_value failed");
assert(SensitiveString::extractValue('plain') === 'plain', "extract_value failed");
echo "✅ Test 6: Helper methods work\n";

// Test 7: Consistent hash
$password2 = new SensitiveString('my-secret-password');
assert((string)$password === (string)$password2, "Hash inconsistent");
echo "✅ Test 7: Consistent hash for same value\n";

// Test 8: echo
ob_start();
echo $password;
$output = ob_get_clean();
assert(!str_contains($output, 'my-secret-password'), "echo leaked!");
echo "✅ Test 8: echo shows hash\n";

echo "\n✨ All tests passed!\n";

