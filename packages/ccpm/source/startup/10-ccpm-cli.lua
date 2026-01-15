--[[
    ccpm - ComputerCraft Package Manager
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

local database = require("ccpm.database")

-- Add bin to PATH
shell.setPath(shell.path() .. ":/bin")

-- Completion function
local function complete(sh, index, arg, args)
    database.load_all()
    table.remove(args, 1)

    local suggestion = {}

    if index == 1 then
        suggestion = { "install", "uninstall", "update", "upgrade", "recover", "repo", "list", "status", "help" }
    elseif index == 2 then
        if args[1] == "help" then
            suggestion = { "install", "uninstall", "update", "upgrade", "recover", "repo", "list", "status" }
        elseif args[1] == "install" then
            local packages = database.get_packages()
            for name, _ in pairs(packages) do
                table.insert(suggestion, name)
            end
        elseif args[1] == "uninstall" or args[2] == "upgrade" then
            local installed_packages = database.get_installed_packages()
            for name, _ in pairs(installed_packages) do
                table.insert(suggestion, name)
            end
        elseif args[1] == "list" then
            suggestion = { "available", "installed" }
        elseif args[1] == "repo" then
            suggestion = { "add", "remove", "list" }
        end
    end

    local rtn = {}

    -- Remove the prefix
    for _, str in ipairs(suggestion) do
        local query = arg:gsub("%-", "%%-")
        if str:match("^" .. query) then
            local s = str:gsub("^" .. query, "")
            table.insert(rtn, s)
        end
    end

    return rtn
end
shell.setCompletionFunction("bin/ccpm.lua", complete)
