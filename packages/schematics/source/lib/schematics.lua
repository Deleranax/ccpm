--[[
    schematics - Lua structure schema definition library
    Copyright (C) 2026  Alexandre Leconte <aleconte@dwightstudio.fr>

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses>.
--]]

local expect = require("cc.expect")

--- @export
local schematics = {}

--- Native types supported by Lua
schematics.NATIVE_TYPES = {
    ["string"] = true,
    ["number"] = true,
    ["boolean"] = true,
    ["table"] = true,
    ["function"] = true,
    ["userdata"] = true,
    ["thread"] = true,
    ["nil"] = true,
    ["any"] = true
}

--- Patterns for matching types and arrays/maps
schematics.TYPE_PATTERN = "%s*([a-zA-Z0-9_]+)%s*"
schematics.ARRAY_PATTERN = "^array%s*<" .. schematics.TYPE_PATTERN .. ">$"
schematics.MAP_PATTERN = "^map%s*<" .. schematics.TYPE_PATTERN .. "," .. schematics.TYPE_PATTERN .. ">$"

--- Determine if a table is list (approximate).
local function is_list(t)
    return next(t) == 1
end

--- Verify a schema recursively.
--- @param typ string: The type to verify.
--- @param types table: The types list to use.
--- @param path string: The path to the current type.
--- @param depth number: The depth of the current type.
local function verify_recursive(typ, types, path, depth)
    if type(typ) ~= "string" then
        error("invalid type at " .. path .. ": not a string", depth + 1)
    end

    if schematics.NATIVE_TYPES[typ] then
        return
    elseif types[typ] then
        return
    else
        -- Match the patterns
        local typ1 = typ:match(schematics.ARRAY_PATTERN)
        if typ1 then
            verify_recursive(typ1, types, path .. ".array.value", depth + 1)
            return
        end

        local typ1, typ2 = typ:match(schematics.MAP_PATTERN)
        if typ1 then
            verify_recursive(typ1, types, path .. ".map.key", depth + 1)
            verify_recursive(typ2, types, path .. ".map.value", depth + 1)
            return
        end

        error("Invalid type at " .. path, depth + 1)
    end
end

--- Verify a schema.
--- @param schema table: The schema to verify.
local function verify(schema)
    local types = {}

    -- Construct the types list
    for key in pairs(schema) do
        types[key] = true
    end

    -- Check each type
    for key, typ in pairs(schema) do
        if type(typ) ~= "table" then
            error("invalid type at " .. key .. ": not a table", 3)
        end

        if is_list(typ) then
            -- type = { "type1", "type2" }

            -- Verify each type
            for i, id in ipairs(typ) do
                verify_recursive(id, types, key .. "[" .. i .. "]", 3)
            end
        else
            -- type = { var1 = { "type1" }, var2 = { "type2" } }

            -- Check inherits
            if typ.__inherits then
                -- Verify each type
                for _, id in ipairs(typ.__inherits) do
                    verify_recursive(id, types, key .. ".__inherits", 3)
                end
            end

            -- Check fields
            for key2, typ2 in pairs(typ) do
                if key2 ~= "__inherits" then
                    if type(typ2) ~= "table" then
                        error("invalid type at " .. key .. "." .. key2 .. ": not a table", 3)
                    end

                    if is_list(typ2) then
                        -- Verify each type
                        for i, id in ipairs(typ2) do
                            verify_recursive(id, types, key .. "." .. key2 .. "[" .. i .. "]", 3)
                        end
                    else
                        error("invalid type at " .. key .. "." .. key2 .. ": not a list", 3)
                    end
                end
            end
        end
    end
end

--- Compile a schema into a validator function.
--- @param schema table: The schema to compile.
--- @return function: A validator function, accepting a variable (any) and a type to validate it against (table) and returning a boolean and an error message.
function schematics.compile(schema)
    expect(1, schema, "table")

    -- Verify the schema
    verify(schema)

    --- Validate a type recursively.
    local function validate_recursive(var, typ, path)
        if schematics.NATIVE_TYPES[typ] then
            if typ == "any" or type(var) == typ then
                return true, nil
            else
                return false, "at " .. path .. ": expected " .. typ .. ", got " .. type(var)
            end
        elseif schema[typ] then
            local schema = schema[typ]

            if is_list(schema) then
                -- type = { "type1", "type2" }

                local errors = {}

                for i, id in ipairs(schema) do
                    local valid, err = validate_recursive(var, id, path .. "<" .. i .. ":" .. id .. ">")
                    if not valid then
                        table.insert(errors, err)
                    else
                        return true, nil
                    end
                end

                return false, table.concat(errors, "\n")
            else
                -- type = { var1 = { "type1" }, var2 = { "type2" } }

                -- Validate inherits
                if schema.__inherits then
                    for _, id in ipairs(schema.__inherits) do
                        local valid, err = validate_recursive(var, id, path .. ".__inherits")
                        if not valid then
                            return false, err
                        end
                    end
                end

                -- Validate fields
                for key, typ in pairs(schema) do
                    if key ~= "__inherits" then
                        local errors = {}

                        for i, id in ipairs(typ) do
                            local valid, err = validate_recursive(var[key], id,
                                path .. "." .. key .. "<" .. i .. ":" .. id .. ">")
                            if not valid then
                                table.insert(errors, err)
                            else
                                errors = {}
                                break
                            end
                        end

                        if #errors > 0 then
                            return false, table.concat(errors, "\n")
                        end
                    end
                end

                return true, nil
            end
        else
            -- Match the patterns
            local typ1 = typ:match(schematics.ARRAY_PATTERN)
            if typ1 then
                for i, var in ipairs(var) do
                    local valid, err = validate_recursive(var, typ1, path .. "[" .. i .. "]")
                    if not valid then
                        return false, err
                    end
                end
                return true, nil
            end

            local typ1, typ2 = typ:match(schematics.MAP_PATTERN)
            if typ1 then
                for key, var in pairs(var) do
                    -- Key
                    local valid, err = validate_recursive(key, typ1, path .. "[" .. tostring(key) .. "].key")
                    if not valid then
                        return false, err
                    end

                    -- Value
                    valid, err = validate_recursive(var, typ2, path .. "[" .. tostring(key) .. "].value")
                    if not valid then
                        return false, err
                    end
                end
                return true, nil
            end

            return false, "at " .. path .. ": unknown type '" .. typ .. "'"
        end
    end

    -- Return the validator function
    return function(var, typ)
        expect(2, typ, "table")

        if is_list(typ) then
            local errors = {}

            for i, id in ipairs(typ) do
                if type(id) ~= "string" then
                    error("invalid type at <" .. i .. ">: not a string", 2)
                end

                local valid, err = validate_recursive(var, id, id)
                if not valid then
                    table.insert(errors, err)
                else
                    return true, nil
                end
            end

            return false, table.concat(errors, "\n")
        else
            error("invalid type: not a list", 2)
        end
    end
end

return schematics
