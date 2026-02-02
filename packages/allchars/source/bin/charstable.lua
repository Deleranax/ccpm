--[[
    allchars - A small utility to print all characters
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

local ctextutils = require("commons.textutils")

-- Create the table
local header = { "Character", "Decimal" }
local modes = { 9, 7 }
local rows = {}

for i = 0, 255 do
    local char = string.char(i)
    table.insert(rows, { char, tostring(i) })
end

-- Print the table
ctextutils.print_table(header, modes, rows)
