--[[
    scada-core - SCADA Core Library
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
local tree = {}

tree.schema = {}

tree.schema.WhiteList = { "array<number>" }

tree.schema.Interval = {
    min = { "number" },
    max = { "number" }
}

tree.schema.Measure = {
    description = { "string", "nil" },
    range = { "WhiteList", "Interval" },
    value = { "number" }
}

tree.schema.Command = {
    __inherits = { "Measure" },
    target = { "number" }
}

tree.schema.Tree = {
    read = { "map<string, Measure>" },
    write = { "map<string, Command>" }
}

return tree
