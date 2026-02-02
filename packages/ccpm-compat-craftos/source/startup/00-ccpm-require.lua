--[[
    ccpm-compat-craftos - CCPM compatibility package for CraftOS
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

-- Exit if already loaded
if os.isCCPM then
    return
end

--- Restart the shell to continue normal execution
local function continue_execution()
    term.clear()
    term.setCursorPos(1, 1)

    local sShell
    if term.isColour() and settings.get("bios.use_multishell") then
        sShell = "rom/programs/advanced/multishell.lua"
    else
        sShell = "rom/programs/shell.lua"
    end
    os.run({}, sShell)
    os.run({}, "rom/programs/shutdown.lua")
end

--- Confirm the presence of CCPM
local function replace_version()
    -- Replace the version string
    local oldversion = os.version
    os.version = function()
        return oldversion() .. " (with CCPM)"
    end

    -- Add custom flag
    os.isCCPM = true
end

local CUSTOM_PACKAGE_PATH = "/lib/?;/lib/?.lua;/lib/?/init.lua;"

-- Exit the shell at the end of the program.
shell.exit()

-- Replace the default shell.run to skip the other startup
shell.run = function(...) end

-- Replace the default os.run function to inject the new paths
local oldrun = os.run
os.run = function(...)
    os.run = oldrun
    package.path = CUSTOM_PACKAGE_PATH .. package.path

    -- Patch flag
    local patched = false

    -- Verify if we can do it the "right way"
    if _HOST then
        if string.match(_HOST, "CraftOS%-PC") then
            -- Modify the package path
            settings.set(
                "shell.package_path",
                package.path
            )

            patched = true
        end
    end

    -- If not, let hack our way into CraftOS
    if not patched then
        -- Replace the defaults functions here
        local oldloadfile = loadfile
        _G.loadfile = function(filename, mode, env)
            if filename:find("cc/require%.lua$") then
                local content = ""

                -- Load the original file
                do
                    local file = fs.open(filename, "r")
                    content = file.readAll()
                    file.close()
                end

                -- Inject new paths
                content = content:gsub("package%.path = \"", "package.path = \"" .. CUSTOM_PACKAGE_PATH)

                local fun, err = loadstring(content, "@/" .. filename)
                if not fun then
                    error(err)
                end
                setfenv(fun, env)

                return fun
            else
                return oldloadfile(filename, mode, env)
            end
        end
    end

    replace_version()
    continue_execution()
end
