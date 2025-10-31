# SensitiveString - PHP Implementation

A PHP implementation of SensitiveString for wrapping sensitive values (passwords, API keys, tokens) to prevent accidental exposure in logs, console output, and serialization.

## Features

- 🔒 **Automatic hash display** - Via `__toString()` magic method
- 📝 **Logging safe** - Works with all PHP logging
- 🎨 **JSON integration** - Via `JsonSerializable` interface (actually works!)
- 💎 **Magic methods** - Uses PHP's magic methods properly
- 🧪 **PHPUnit tests** - Comprehensive test suite
- ✨ **Modern PHP** - Typed properties, strict types, PHP 7.4+

## Installation

### Via Composer

```bash
composer require earlye/sensitive-string
```

### Requirements

- PHP >= 7.4

## Basic Usage

```php
<?php
use SensitiveString\SensitiveString;

// Create a sensitive string
$password = new SensitiveString("my-secret-password");

// Safe operations - these show the hash
echo $password;  // sha256:2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824
(string)$password;  // sha256:...
"Password: $password"  // Password: sha256:...

// Intentional access when you need the plaintext
$password->getValue();  // "my-secret-password"
$password->value;  // "my-secret-password" (property access)
```

## Logging

Works automatically with all PHP logging:

```php
<?php
$password = new SensitiveString("secret123");

// echo/print
echo "Password: $password\n";  // Shows hash ✅

// error_log
error_log("Password: $password");  // Shows hash ✅

// Monolog
$logger->info("Password: {password}", ['password' => $password]);  // Shows hash ✅

// var_dump (for debugging)
var_dump($password);  // Shows hash ✅
```

## JSON Serialization

PHP's `JsonSerializable` interface **actually works** (unlike Python)! 🎉

```php
<?php
$credentials = [
    'username' => 'user@example.com',
    'password' => new SensitiveString('secret123')
];

$json = json_encode($credentials);
// {"username":"user@example.com","password":"sha256:..."}

echo json_encode(new SensitiveString('secret'));
// "sha256:..."
```

## Framework Integration

### Laravel

```php
<?php
namespace App\Models;

use SensitiveString\SensitiveString;

class User extends Model
{
    protected $casts = [
        'password' => 'string',
    ];
    
    public function setPasswordAttribute($value)
    {
        $this->attributes['password'] = bcrypt($value);
    }
    
    public function getPasswordAttribute($value)
    {
        return new SensitiveString($value);
    }
}

// Now User password is always a SensitiveString
$user = User::find(1);
Log::info($user);  // Password shows as hash ✅
response()->json($user);  // Password shows as hash ✅
```

### Symfony

```php
<?php
use SensitiveString\SensitiveString;
use Psr\Log\LoggerInterface;

class AuthController
{
    public function login(Request $request, LoggerInterface $logger)
    {
        $password = new SensitiveString($request->get('password'));
        
        $logger->info('Login attempt', [
            'username' => $request->get('username'),
            'password' => $password  // Shows hash in logs ✅
        ]);
        
        // Use plaintext for authentication
        $authenticated = $this->auth->check($username, $password->getValue());
    }
}
```

## API Reference

### Creating a SensitiveString

```php
<?php
// Constructor
$secret = new SensitiveString("my-secret");

// Using helper
$secret = SensitiveString::sensitive("my-secret");
$secret = SensitiveString::sensitive($anotherSensitive);  // Returns same object
```

### Accessing the Plaintext

```php
<?php
$secret = new SensitiveString("password");

// Method call
$plaintext = $secret->getValue();  // "password"

// Property access (magic __get)
$plaintext = $secret->value;  // "password"
```

### Utility Methods

```php
<?php
$secret = new SensitiveString("12345");

$secret->length();  // 5
$secret->isEmpty();  // false

// Helper methods
SensitiveString::isSensitiveString($secret);  // true
SensitiveString::isSensitiveString("plain");  // false

SensitiveString::extractValue($secret);  // "12345"
SensitiveString::extractValue("plain");  // "plain"
SensitiveString::extractValue(null);  // null

SensitiveString::extractRequiredValue($secret);  // "12345"
SensitiveString::extractRequiredValue(null);  // throws InvalidArgumentException
```

## Testing

Run the test suite:

```bash
composer install
composer test
```

Or with PHPUnit directly:

```bash
vendor/bin/phpunit
```

Run with coverage:

```bash
vendor/bin/phpunit --coverage-html coverage
```

## Design Philosophy

Following the pattern from other language implementations:

1. **Accidental exposure protection** - Make the default behavior safe
2. **Intentional access available** - Provide explicit methods for plaintext
3. **PHP conventions** - Use magic methods (`__toString`, `JsonSerializable`)
4. **Consistent hashing** - Always show `sha256:<hex>` format
5. **Modern PHP** - Strict types, typed properties, PHP 7.4+

## What's Intentionally NOT Protected

This library prevents **accidental** exposure. It does NOT prevent:

- Intentional access via `->getValue()` or `->value` - this is the intended escape hatch
- Reflection API access
- Serialization with `serialize()` (use JSON instead)
- Memory dumps or debugger inspection
- Side-channel attacks or timing attacks

The goal is to prevent secrets from accidentally ending up in logs, error messages, or JSON output - not to provide cryptographic security.

## PHP's Surprising Advantages

Unlike Python, PHP actually handles this pattern quite well:

| Feature | Python | **PHP** |
|---------|--------|---------|
| String conversion | `__str__()` ✅ | **`__toString()` ✅** |
| JSON hook | ❌ No | **`JsonSerializable` ✅** |
| Works automatically | ❌ No | **✅ Yes!** |
| Magic methods | ⚠️ Some | **✅ Many** |
| Type hints | ✅ Yes | **✅ Yes (7.4+)** |

PHP's magic methods and `JsonSerializable` interface make this **easier** than Python!

## Examples

### Web API

```php
<?php
header('Content-Type: application/json');

$user = [
    'id' => 123,
    'username' => 'john@example.com',
    'password' => new SensitiveString(getenv('DB_PASSWORD'))
];

echo json_encode($user);
// {"id":123,"username":"john@example.com","password":"sha256:..."}
```

### Error Logging

```php
<?php
try {
    $db = new PDO(
        'mysql:host=localhost',
        'user',
        new SensitiveString('secret')
    );
} catch (PDOException $e) {
    // Even if exception message contains connection string
    error_log($e->getMessage());  // Password shows as hash if logged
}
```

## License

MIT License - See LICENSE.md for details

## Contributing

Contributions are welcome! Please see the main repository for guidelines.

