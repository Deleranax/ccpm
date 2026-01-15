# Package `uuid`

A lightweight Lua library for generating pseudo-random UUIDs (Universally Unique Identifiers) version 4, following RFC 4122 standards.

## Features

- **UUIDv4 Generation**: Generates pseudo-random UUIDs using Lua's `math.random`
- **RFC 4122 Compliant**: Properly sets version and variant bits
- **Validation Utilities**: Includes functions to validate UUID format
- **Zero Dependencies**: Pure Lua implementation with no external dependencies
- **Lightweight**: Simple and efficient implementation

## Installation

This package is part of the CCPM package manager ecosystem.

## Usage

### Basic Usage

```lua
local uuid = require("uuid")

-- Initialize random seed (important for randomness!)
math.randomseed(os.time())

-- Generate a UUIDv4
local id = uuid.v4()
print(id)  -- Output: e.g., "f47ac10b-58cc-4372-a567-0e02b2c3d479"

-- Alternative method
local id2 = uuid.generate()
```

### Validation

```lua
local uuid = require("uuid")

local id = "f47ac10b-58cc-4372-a567-0e02b2c3d479"

-- Validate UUID format
if uuid.validate(id) then
    print("Valid UUID format")
end

-- Check if it's specifically a UUIDv4
if uuid.is_v4(id) then
    print("Valid UUIDv4")
end
```

## API Reference

### `uuid.v4()`

Generates a new pseudo-random UUIDv4.

**Returns:** `string` - A UUIDv4 in the format `xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx`

**Example:**
```lua
local id = uuid.v4()
-- Returns: "550e8400-e29b-41d4-a716-446655440000"
```

### `uuid.generate()`

Alias for `uuid.v4()`. Generates a new pseudo-random UUIDv4.

**Returns:** `string` - A UUIDv4

### `uuid.validate(str)`

Validates whether a string matches the UUIDv4 format.

**Parameters:**
- `str` (string): The string to validate

**Returns:** `boolean` - `true` if valid UUIDv4 format, `false` otherwise

**Example:**
```lua
uuid.validate("550e8400-e29b-41d4-a716-446655440000")  -- true
uuid.validate("not-a-uuid")  -- false
```

### `uuid.is_v4(str)`

Checks if a string is a valid UUIDv4 (stricter validation than `validate`).

**Parameters:**
- `str` (string): The string to check

**Returns:** `boolean` - `true` if valid UUIDv4, `false` otherwise

## UUID Format

UUIDv4 follows this format: `xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx`

- `x`: Any hexadecimal digit (0-9, a-f)
- `4`: Version number (always 4 for UUIDv4)
- `y`: One of 8, 9, a, or b (variant bits set to 10xx in binary)

Example: `f47ac10b-58cc-4372-a567-0e02b2c3d479`

## Important Notes

### Random Seed Initialization

**You must initialize Lua's random seed before generating UUIDs** to ensure proper randomness:

```lua
math.randomseed(os.time())
-- Or for better randomness in some systems:
math.randomseed(os.time() + os.clock() * 1000000)
```

Without proper seed initialization, generated UUIDs may not be sufficiently random.

### Cryptographic Security

This implementation uses Lua's `math.random()`, which is **NOT cryptographically secure**. Do not use this library for:
- Security tokens
- Cryptographic keys
- Password reset tokens
- Any security-sensitive applications

For such use cases, use a cryptographically secure random number generator.

### Collision Probability

While UUIDv4 has a very low collision probability, it's not zero. The probability of generating duplicate UUIDs is approximately:

- 1 in 2.71 quintillion (2.71 × 10^18) for 1 billion UUIDs

## Standards Compliance

This implementation follows RFC 4122 (ISO/IEC 9834-8:2005):
- Version field is set to 4 (bits 12-15 of time_hi_and_version)
- Variant field is set to 10xx binary (bits 6-7 of clock_seq_hi_and_reserved)

## License

MIT License

## Authors

- Alexandre Leconte <aleconte@dwightstudio.fr>

## Version

1.0.0
