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

local expect = require("cc.expect")

--- @export
local cfileutils = {}

--- Creates a pair of load/save functions for persistent data storage
--- @param path string The path to the file where data will be stored
--- @return function, function The load and save functions. The load function takes no arguments and returns the loaded data. The save function takes the data to be saved as an argument.
function cfileutils.make_store(path)
    --- Save data to a file
    local function save(data)
        local file = fs.open(path, "w")
        file.write(textutils.serialize(data))
        file.close()
    end

    --- Load data from a file
    local function load()
        if fs.exists(path) then
            local file = fs.open(path, "r")
            local data = textutils.unserialize(file.readAll())
            file.close()
            return data
        else
            return {}
        end
    end

    return load, save
end

return cfileutils
