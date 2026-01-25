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

--- Check if two tables are equal.
--- @param tab1 table: The first table.
--- @param tab2 table: The second table.
--- @param ignore_mt boolean: Whether to ignore metatables, defaults to false.
--- @return boolean: True if the tables are equal, false otherwise.
function ctable.equals(tab1, tab2, ignore_mt)
    if tab1 == tab2 then
        return true
    end

    local type_tab1 = type(tab1)
    local type_tab2 = type(tab2)

    if type_tab1 ~= type_tab2 then
        return false
    end

    if type_tab1 ~= 'table' then
        return false
    end

    if not ignore_mt then
        local mt_tab1 = getmetatable(tab1)
        if mt_tab1 and mt_tab1.__eq then
            --compare using built in method
            return tab1 == tab2
        end
    end

    local keys = {}

    for key1, value1 in pairs(tab1) do
        local value2 = tab2[key1]
        if value2 == nil or ctable.equals(value1, value2, ignore_mt) == false then
            return false
        end
        keys[key1] = true
    end

    for key2, _ in pairs(tab2) do
        if not keys[key2] then
            return false
        end
    end
    return true
end

return ctable
