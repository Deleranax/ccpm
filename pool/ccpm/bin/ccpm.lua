-- ComputerCraft Package Manager
-- Copyright (C) 2025 Deleranax
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <https://www.gnu.org/licenses/>.

local cli = {}

cli["register"] = {
    usage = "<repositories>"
}

local function printUsage()
    print("Usage:")

    for label, cmd in pairs(cli) do
        print("ccpm "..label.." "..cmd.usage)
    end
    --print("ccpm unregister <repositories>")
    --print("ccpm refresh")
    --print("ccpm install <packages>")
    --print("ccpm uninstall <packages>")
    --print("ccpm upgrade [packages]")
end

local args = { ... }

if #args < 1 then
    printUsage()
    return
end

