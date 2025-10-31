<?php

declare(strict_types=1);

require_once __DIR__ . '/../src/SensitiveString.php';

use SensitiveString\SensitiveString;

echo "=== SensitiveString PHP Examples ===\n\n";

// Basic usage
echo "1. Basic Creation and Display:\n";
$password = new SensitiveString("my-secret-password");
echo "Password: $password\n";
echo "Type: " . get_class($password) . "\n\n";

// Explicit access
echo "2. Explicit Access:\n";
echo "getValue(): " . $password->getValue() . "\n";
echo "value property: {$password->value}\n\n";

// JSON serialization (THE PHP ADVANTAGE!)
echo "3. JSON Serialization (JsonSerializable works!):\n";
$credentials = [
    'username' => 'john@example.com',
    'password' => new SensitiveString('secret123')
];
echo json_encode($credentials, JSON_PRETTY_PRINT) . "\n\n";

// String interpolation
echo "4. String Interpolation:\n";
$apiKey = new SensitiveString("ABC123-SECRET-KEY");
echo "API Key: $apiKey\n";
echo "Full message: Connecting with key: $apiKey\n\n";

// Array of secrets
echo "5. Array of Secrets:\n";
$secrets = [
    'db_password' => new SensitiveString('db-secret'),
    'api_key' => new SensitiveString('api-secret'),
    'oauth_token' => new SensitiveString('token-secret')
];
echo json_encode($secrets, JSON_PRETTY_PRINT) . "\n\n";

// Helper methods
echo "6. Helper Methods:\n";
$secret = new SensitiveString("12345");
echo "Length: " . $secret->length() . "\n";
echo "Is empty: " . ($secret->isEmpty() ? 'true' : 'false') . "\n";
echo "Is SensitiveString: " . (SensitiveString::isSensitiveString($secret) ? 'true' : 'false') . "\n\n";

// Extract value
echo "7. Extract Value:\n";
$mixed = [
    new SensitiveString("secret1"),
    "plain-string",
    new SensitiveString("secret2")
];
foreach ($mixed as $i => $value) {
    $extracted = SensitiveString::extractValue($value);
    $type = SensitiveString::isSensitiveString($value) ? 'SensitiveString' : 'plain string';
    echo "Item $i: $extracted ($type)\n";
}
echo "\n";

// Consistent hashing
echo "8. Consistent Hashing:\n";
$secret1 = new SensitiveString("same-value");
$secret2 = new SensitiveString("same-value");
$secret3 = new SensitiveString("different-value");
echo "Secret 1: $secret1\n";
echo "Secret 2: $secret2\n";
echo "Secret 3: $secret3\n";
echo "1 == 2: " . ((string)$secret1 === (string)$secret2 ? 'true' : 'false') . "\n";
echo "1 == 3: " . ((string)$secret1 === (string)$secret3 ? 'true' : 'false') . "\n\n";

// Error logging simulation
echo "9. Logging (safe for production logs):\n";
$dbPassword = new SensitiveString("production-db-password");
error_log("Database connection with password: $dbPassword");
echo "Logged to error_log: Database connection with password: $dbPassword\n\n";

// var_dump (debug info)
echo "10. var_dump() Debug Info:\n";
var_dump($password);
echo "\n";

echo "✨ All examples complete!\n";

