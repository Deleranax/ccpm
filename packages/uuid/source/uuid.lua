local uuid = {}

local V4_TEMPLATE = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
local V4_PATTERN = "^%x%x%x%x%x%x%x%x%-%x%x%x%x%-4%x%x%x%-[89ab]%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$"

--- Helper function to generate a random hexadecimal character.
--- @return string: A random hexadecimal character.
local function random_hex()
    return string.format("%x", math.random(0, 15))
end

--- Helper function to generate a random byte (2 hex characters).
--- @return string: A random byte (2 hex characters).
local function random_byte()
    return string.format("%02x", math.random(0, 255))
end

--- Generate a UUIDv4
--- @return string: A UUIDv4 string.
function uuid.v4()
    local rtn = string.gsub(V4_TEMPLATE, "[xy]", function(c)
        local v
        if c == "x" then
            -- Random hex digit (0-15)
            v = math.random(0, 15)
        else
            -- For 'y', use values 8, 9, 10, or 11 (binary 10xx)
            -- This sets the variant to RFC 4122
            v = math.random(8, 11)
        end
        return string.format("%x", v)
    end)

    return rtn
end

--- Check if a string is a valid UUIDv4.
--- @param str string: The string to validate.
--- @return boolean: True if the string is a valid UUIDv4, false otherwise.
function uuid.is_v4(str)
    if type(str) ~= "string" then
        return false
    end

    return str:match(V4_PATTERN) ~= nil
end

return uuid
