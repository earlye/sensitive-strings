# SensitiveString - Ruby Implementation

A Ruby implementation of SensitiveString for wrapping sensitive values (passwords, API keys, tokens) to prevent accidental exposure in logs, console output, and serialization.

## Features

- 🔒 **Automatic hash display** - Via `to_s` for puts, string interpolation
- 📝 **Logging safe** - Works with all Ruby logging frameworks
- 🎨 **JSON integration** - Via `to_json` for json gem and `as_json` for Rails
- 💎 **Idiomatic Ruby** - Uses Ruby conventions (to_s, inspect, etc.)
- 🧊 **Immutable** - Values are frozen on creation
- ✨ **Clean syntax** - Beautiful to read and write

## Installation

Add to your `Gemfile`:

```ruby
gem 'sensitive-string'
```

Or install directly:

```bash
gem install sensitive-string
```

### Requirements

- Ruby >= 2.7.0

## Basic Usage

```ruby
require 'sensitive_string'

# Create a sensitive string
password = SensitiveString.new("my-secret-password")

# Safe operations - these show the hash
puts password  # => sha256:2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824
password.to_s  # => "sha256:..."
"Password: #{password}"  # => "Password: sha256:..."

# Intentional access when you need the plaintext
password.value  # => "my-secret-password"
```

## Logging

Works automatically with all Ruby logging:

```ruby
require 'logger'

logger = Logger.new($stdout)
password = SensitiveString.new("secret123")

logger.info "Password: #{password}"  # Shows hash ✅
logger.debug { password }  # Shows hash ✅
puts password  # Shows hash ✅
p password  # Shows SensitiveString(...sha256:...) ✅
```

## JSON Serialization

### With JSON gem

```ruby
require 'json'

credentials = {
  username: "user@example.com",
  password: SensitiveString.new("secret123")
}

JSON.generate(credentials)
# => {"username":"user@example.com","password":"sha256:..."}
```

### With Rails/ActiveSupport

```ruby
credentials = {
  username: "user",
  password: SensitiveString.new("secret123")
}

credentials.to_json
# => {"username":"user","password":"sha256:..."}
```

## Rails Integration

Works seamlessly with Rails:

```ruby
class User < ApplicationRecord
  def password=(value)
    @password = SensitiveString.new(value)
  end
  
  def password
    @password
  end
end

user = User.new(password: "secret")
user.to_json  # Password shows as hash ✅
logger.info(user)  # Password shows as hash ✅
```

## API Reference

### Creating a SensitiveString

```ruby
# From string
secret = SensitiveString.new("my-secret")

# Using helper
secret = SensitiveString.sensitive("my-secret")
secret = SensitiveString.sensitive(another_sensitive)  # Returns same object
```

### Accessing the Plaintext

```ruby
secret = SensitiveString.new("password")

# Property access
plaintext = secret.value  # => "password"
```

### Utility Methods

```ruby
secret = SensitiveString.new("12345")

secret.length  # => 5
secret.size    # => 5
secret.empty?  # => false

# Equality
secret2 = SensitiveString.new("12345")
secret == secret2  # => true

# Hashable - can use as hash keys
hash = {}
hash[secret] = "metadata"
```

### Helper Methods

```ruby
# Type checking
SensitiveString.sensitive_string?(secret)  # => true
SensitiveString.sensitive_string?("plain") # => false

# Extract value
SensitiveString.extract_value(secret)  # => "password"
SensitiveString.extract_value("plain") # => "plain"
SensitiveString.extract_value(nil)     # => nil

# Extract value or raise
SensitiveString.extract_required_value(secret)  # => "password"
SensitiveString.extract_required_value(nil)     # raises ArgumentError
```

## Testing

Run the test suite:

```bash
bundle install
bundle exec rspec
```

Run with documentation format:

```bash
bundle exec rspec --format documentation
```

## Design Philosophy

Following the pattern from other language implementations:

1. **Accidental exposure protection** - Make the default behavior safe
2. **Intentional access available** - Provide explicit methods for plaintext
3. **Ruby conventions** - Use idiomatic Ruby methods (to_s, to_json, etc.)
4. **Consistent hashing** - Always show `sha256:<hex>` format
5. **Immutable** - Values frozen on creation

## What's Intentionally NOT Protected

This library prevents **accidental** exposure. It does NOT prevent:

- Intentional access via `.value` - this is the intended escape hatch
- Memory dumps or debugger inspection  
- Reading instance variables directly
- Side-channel attacks or timing attacks

The goal is to prevent secrets from accidentally ending up in logs, error messages, or serialized output - not to provide cryptographic security.

## Comparison with Other Languages

| Feature | This Gem |
|---------|----------|
| String formatting | ✅ Via `to_s` |
| Debug printing | ✅ Via `inspect` |
| JSON (json gem) | ✅ Via `to_json` |
| Rails/ActiveSupport | ✅ Via `as_json` |
| Logging | ✅ Automatic |
| Conventions | ✅ Idiomatic Ruby |
| Immutable | ✅ Yes |

## Examples

```ruby
# String interpolation
password = SensitiveString.new("secret")
puts "Your password is #{password}"
# => Your password is sha256:...

# Logging
require 'logger'
logger = Logger.new($stdout)
logger.info("Credentials") { { password: password } }
# Shows hash in logs

# JSON API responses (Rails)
class UserSerializer
  def as_json
    {
      username: user.username,
      password: user.password  # SensitiveString - shows hash
    }
  end
end

# Comparison
if user.password == SensitiveString.new(params[:password])
  # Authentication logic
end
```

## License

MIT License - See LICENSE.md for details

## Contributing

Contributions are welcome! Please see the main repository for guidelines.

