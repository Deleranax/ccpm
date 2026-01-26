--[[
    flagger - A simple flag utility library
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

--- @export
local flagger = {}

--- Make a flag table from variations list.
--- @param ... string: List of variations names.
--- @return table: A table with flag names as keys and their numeric values
function flagger.make_flags(...)
    local flags = {}

    for i, name in ipairs({ ... }) do
        flags[name] = 2 ^ (i - 1)
    end

    return flags
end

--- Test if a flag is set in a value.
--- @param value number The value to test.
--- @param variation number The flag to test.
--- @return boolean True if the flag is set, false otherwise.
function flagger.test(value, variation)
    return bit.band(value, variation) == variation
end

return flagger
