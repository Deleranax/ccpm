--[[
    libccpm - Library for CCPM
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
local expect = require("cc.expect")
local event = require("ccpm.eventutils")

--- @export
local repository = {}

--- Get the driver for the repository
--- @param url string | table: Repository URL or manifest.
--- @return table | nil, nil | string: A table representing the driver or nil and an error message.
function repository.get_driver(url)
    expect.expect(1, url, "string", "table")

    if type(url) == "table" then
        url = url.url
    end

    local driver = require("ccpm.driver." .. url:match("^([^/]+)://"))
    if not driver then
        return nil, "driver not found"
    elseif not driver.can_handle(url) then
        return nil, "driver cannot handle URL"
    end

    return driver, nil
end

--- Add a new repository.
--- @param url string: Repository URL (any).
--- @return nil | string: Nil or an error message.
function repository.add(url)
    expect.expect(1, url, "string")

    local driver, err = repository.get_driver(url)
    if not driver then
        return err
    end

    local manifest, err = driver.get_manifest(url)
    if type(manifest) ~= "table" then
        return "failed to get manifest: " .. err
    end
    if type(manifest.url) ~= "string" then
        return "incorrect manifest: missing URL"
    end
    if type(manifest.name) ~= "string" then
        return "incorrect manifest: missing name"
    end
    if type(manifest.priority) ~= "number" then
        return "incorrect manifest: missing priority"
    end

    local id, err = database.add_repository(manifest)
    if not id then
        return "failed to add repository: " .. err
    end

    return nil
end

--- Update the index of all repositories.
--- @return nil | string: Nil or an error message.
function repository.update_index()
    local repositories_index = {}
    local repositories, count = database.get_repositories()

    -- Download individual repositories packages index
    event.dispatch("ccpm_index_update_start", count)
    for id, repo in pairs(repositories) do
        event.dispatch("ccpm_index_updating", id)

        local driver, err = repository.get_driver(repo)
        if not driver then
            err = "failed to get driver for repository: " .. err
            event.dispatch("ccpm_index_not_updated", id, err)
            return err
        end

        local index, err = driver.get_packages_index(repo)
        if not index then
            err = "failed to get packages index for repository: " .. err
            event.dispatch("ccpm_index_not_updated", id, err)
            return err
        end

        repositories_index[id] = index
        event.dispatch("ccpm_index_updated", id)
    end
    event.dispatch("ccpm_index_update_end", #repositories)

    local new_index = {}

    -- Merge repositories index according to priority
    for id, index in pairs(repositories_index) do
        for name, manifest in pairs(index) do
            if not new_index[name] or new_index[name].priority > repositories[id].priority then
                new_index[name] = manifest
                new_index[name].repository = id
            end
        end
    end

    -- Save merged index to database
    database.set_packages_index(new_index)

    return nil
end

return repository
