# SensitiveString - Erlang Implementation

An Erlang implementation of SensitiveString for wrapping sensitive values (passwords, API keys, tokens) to prevent accidental exposure in logs, console output, and serialization.

## Features

- 🔒 **Automatic hash display** - Via `to_string/1` for logging
- 📝 **Logging safe** - Shows hash in all string contexts
- 🎨 **JSON integration** - Via `to_json/1` for JSON libraries
- ⚡ **Functional** - Immutable by design (like all Erlang data)
- 🧪 **EUnit tests** - Comprehensive test suite included
- 🎯 **Pattern matching** - Works naturally with Erlang patterns

## Installation

Add to your `rebar.config`:

```erlang
{deps, [
    {sensitive_string, {git, "https://github.com/earlye/sensitive-strings", {branch, "main"}}}
]}.
```

### Requirements

- Erlang/OTP >= 21

## Basic Usage

```erlang
-include_lib("sensitive_string/include/sensitive_string.hrl").

%% Create a sensitive string
Password = sensitive_string:new(<<"my-secret-password">>),

%% Safe operations - these show the hash
String = sensitive_string:to_string(Password),
%% => <<"sha256:2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824">>

%% Log it safely
logger:info("Password: ~s", [sensitive_string:to_string(Password)]),
%% Shows hash in logs

%% Intentional access when you need the plaintext
Plaintext = sensitive_string:get_value(Password),
%% => <<"my-secret-password">>
```

## Logging

Works with all Erlang logging:

```erlang
Password = sensitive_string:new(<<"secret123">>),

%% logger (OTP 21+)
logger:info("Password: ~s", [sensitive_string:to_string(Password)]),
%% Shows: Password: sha256:...

%% io:format
io:format("Password: ~s~n", [sensitive_string:to_string(Password)]),
%% Shows: Password: sha256:...

%% error_logger
error_logger:info_msg("Password: ~s", [sensitive_string:to_string(Password)]),
%% Shows: Password: sha256:...
```

## JSON Serialization

### With jsx

```erlang
Credentials = #{
    username => <<"user@example.com">>,
    password => sensitive_string:to_json(sensitive_string:new(<<"secret123">>))
},

JSON = jsx:encode(Credentials),
%% => <<"{\"username\":\"user@example.com\",\"password\":\"sha256:...\"}">>
```

### With jiffy

```erlang
Credentials = {[
    {<<"username">>, <<"user@example.com">>},
    {<<"password">>, sensitive_string:to_json(sensitive_string:new(<<"secret123">>))}
]},

JSON = jiffy:encode(Credentials),
%% => <<"{\"username\":\"user@example.com\",\"password\":\"sha256:...\"}">>
```

## API Reference

### Creating a SensitiveString

```erlang
%% From binary
SS = sensitive_string:new(<<"my-secret">>),

%% From list
SS = sensitive_string:new("my-secret"),

%% Using helper
SS = sensitive_string:sensitive(<<"my-secret">>),
SS = sensitive_string:sensitive(AnotherSS),  %% Returns same if already sensitive
```

### Accessing the Plaintext

```erlang
SS = sensitive_string:new(<<"password">>),

%% Get value
Plaintext = sensitive_string:get_value(SS),
%% => <<"password">>
```

### Formatting

```erlang
SS = sensitive_string:new(<<"secret">>),

%% Get hash string
HashString = sensitive_string:to_string(SS),
%% => <<"sha256:2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824">>

%% Get hash hex (without prefix)
Hash = sensitive_string:hash_hex(<<"secret">>),
%% => <<"2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824">>
```

### Helper Functions

```erlang
%% Type checking
true = sensitive_string:is_sensitive_string(SS),
false = sensitive_string:is_sensitive_string(<<"plain">>),

%% Extract value
<<"secret">> = sensitive_string:extract_value(SS),
<<"plain">> = sensitive_string:extract_value(<<"plain">>),
undefined = sensitive_string:extract_value(undefined),

%% Extract value or error
<<"secret">> = sensitive_string:extract_required_value(SS),
%% sensitive_string:extract_required_value(undefined) -> error(badarg)
```

## Pattern Matching

Works naturally with Erlang pattern matching:

```erlang
-record(sensitive_string, {value :: binary()}).

handle_password(#sensitive_string{} = Password) ->
    %% You have a SensitiveString
    logger:info("Got password: ~s", [sensitive_string:to_string(Password)]),
    %% Use it...
    ok;
handle_password(Password) when is_binary(Password) ->
    %% Convert to SensitiveString
    handle_password(sensitive_string:new(Password)).
```

## Testing

Run the test suite with rebar3:

```bash
rebar3 eunit
```

Run with verbose output:

```bash
rebar3 eunit --verbose
```

## Design Philosophy

Following the pattern from other language implementations:

1. **Accidental exposure protection** - Make the default behavior safe
2. **Intentional access available** - Provide explicit functions for plaintext
3. **Functional paradigm** - Immutable data, pure functions
4. **Consistent hashing** - Always show `sha256:<hex>` format
5. **Pattern matching** - Works naturally with Erlang idioms

## What's Intentionally NOT Protected

This library prevents **accidental** exposure. It does NOT prevent:

- Intentional access via `get_value/1` - this is the intended escape hatch
- Process dictionary inspection
- Crash dumps or debugger inspection
- Side-channel attacks or timing attacks

The goal is to prevent secrets from accidentally ending up in logs, error messages, or serialized output - not to provide cryptographic security.

## Comparison with Other Languages

| Feature | This Library |
|---------|-------------|
| String formatting | ✅ Via `to_string/1` |
| JSON serialization | ✅ Via `to_json/1` |
| Logging | ✅ Manual formatting |
| Immutable | ✅ Yes (like all Erlang) |
| Pattern matching | ✅ Yes |
| Type safety | ✅ Via specs |

## Examples

### Web Handler

```erlang
handle_login(#{username := Username, password := Password} = Params) ->
    %% Convert to SensitiveString
    SS = sensitive_string:new(Password),
    
    %% Log safely
    logger:info("Login attempt for ~s", [Username]),
    %% Password is NOT in the log
    
    %% Authenticate
    case authenticate(Username, sensitive_string:get_value(SS)) of
        ok -> {ok, create_session(Username)};
        error -> {error, invalid_credentials}
    end.
```

### JSON API Response

```erlang
user_to_json(User) ->
    #{
        id => User#user.id,
        username => User#user.username,
        %% Password shows as hash in JSON
        password => sensitive_string:to_json(User#user.password)
    }.
```

## License

MIT License - See LICENSE.md for details

## Contributing

Contributions are welcome! Please see the main repository for guidelines.

