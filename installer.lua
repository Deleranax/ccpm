--[[
    installer - ComputerCraft Package Manager installer
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

local CCPM_BASE_URL = "https://raw.githubusercontent.com/Deleranax/ccpm/refs/heads/"
local CCPM_REPO_URL = CCPM_BASE_URL .. "dist/"
local PACKAGES_URL = CCPM_BASE_URL .. "main/packages/"
local PACKAGES_OVERRIDE = {
    ["ccpm.driver.http"] = "ccpm-driver-http",
    ["ccpm.driver.https"] = "ccpm-driver-http",
    ["ccpm.repository"] = "libccpm",
    ["ccpm.database"] = "libccpm",
    ["ccpm.eventutils"] = "libccpm",
    ["ccpm.transaction"] = "libccpm",
    ["ccpm.package"] = "libccpm",
    ["ccpm.schema"] = "libccpm",
}

--- Get the download URL for a module.
--- @param name string The name of the module.
--- @return string The download URL for the module.
local function get_url(name)
    name = name:gsub("%/", ".")
    name = name:gsub("^lib%.", "")

    local parts = {}
    for value in name:gmatch("([^.]+)") do
        table.insert(parts, value)
    end

    local package = parts[1]
    local path = table.concat(parts, ".")
    if PACKAGES_OVERRIDE[path] then
        package = PACKAGES_OVERRIDE[path]
    end

    return PACKAGES_URL .. package .. "/source/lib/" .. table.concat(parts, "/") .. ".lua"
end

--- Load a module from the internet.
--- @param name string The name of the module.
--- @return function|nil The loaded module or nil if the module could not be loaded.
--- @return string|nil The error message if the module could not be loaded.
local function online_require(name)
    local url = get_url(name)
    local response = http.get(url)
    if response then
        local code = response.readAll()
        response.close()
        local chunk = load(code, "=" .. name, "t", _ENV)
        if chunk then
            return chunk, nil
        end
    end
    return nil, "no file at '" .. url .. "'"
end

-- Add online_require to package loaders
table.insert(package.loaders, online_require)

function monitor()
    while true do
        local event = { os.pullEvent() }
        if event[1]:sub(1, 4) == "ccpm" then
            print(textutils.serializeJSON(event))
        end
    end
end

print("Loading live CCPM dependencies")

local repo = require("ccpm.repository")
local trans = require("ccpm.transaction")
local eventutils = require("ccpm.eventutils")

parallel.waitForAny(
    function()
        print("Adding CCPM repository")
        local err = repo.add(CCPM_REPO_URL)
        if err then
            printError(err)
            return
        end

        print("Updating index and manifests")
        err = repo.update()
        if err then
            printError(err)
            return
        end

        print("Installing CCPM")
        err = trans.begin()
        if err then
            return
        end

        err = trans.install("ccpm")
        if err then
            return
        end

        err = trans.resolve_dependencies()
        if err then
            return
        end

        err = trans.commit()
        if err then
            return
        end

        sleep(1)

        print("CCPM installed successfully")

        sleep(1)

        term.setTextColor(colors.yellow)
        print("Press any key to reboot")
        os.pullEvent("key")
        os.reboot()
    end,
    eventutils.process_transaction_events
)
