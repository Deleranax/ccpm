--[[
    commons - A collection of common utilities
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
local ctable = {}

--- Copy a table recursively.
--- @param tab table: The table to copy.
--- @return table: A deep copy of the table.
function ctable.copy(tab)
    local new_table = {}
    for k, v in pairs(tab) do
        if type(v) == "table" then
            v = ctable.copy(v)
        end

        new_table[k] = v
    end
    return new_table
end

--- Copy a table recursively.
--- @param tab table: The table to copy.
--- @return table, number: A deep copy of the table, the number of entries.
function ctable.copy_count(tab)
    local new_table = {}
    local count = 0
    for k, v in pairs(tab) do
        if type(v) == "table" then
            v = ctable.copy(v)
        end

        new_table[k] = v
        count = count + 1
    end
    return new_table, count
end

--- Collect values from an iterator into a table.
--- @param iter function: An iterator function.
--- @return table: A table containing the collected values.
function ctable.collect(iter)
    local result = {}
    for value in iter do
        table.insert(result, value)
    end
    return result
end

--- Slice a table.
--- @param tab table: The table to slice.
--- @param start number: The start index.
--- @param finish? number | nil: The finish index which can be negative.
--- @return table: A table containing the sliced values.
function ctable.slice(tab, start, finish)
    if finish and finish < 0 then
        finish = #tab + finish + 1
    end

    local result = {}
    for i = start or 1, finish or #tab do
        table.insert(result, tab[i])
    end
    return result
end

return ctable
