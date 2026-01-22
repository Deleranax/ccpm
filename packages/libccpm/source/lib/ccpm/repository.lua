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

--- Convert a repository URL to a raw URL.
--- Note: Implemented using Claude Sonnet 4.5. It has been tested (see the test directory), but may incorrectly
--- handle certain services.
--- @param url string: Repository URL.
--- @return string: Raw URL.
function repository.extract_raw_url(url)
    expect.expect(1, url, "string")

    -- Remove trailing slashes
    url = url:gsub("/+$", "")

    -- GitHub: https://github.com/user/repo -> https://raw.githubusercontent.com/user/repo/refs/heads/dist/
    local user, repo = url:match("^https?://[www%.]*github%.com/([^/]+)/([^/]+)/?$")
    if user and repo then
        -- Remove .git suffix if present
        repo = repo:gsub("%.git$", "")
        return string.format("https://raw.githubusercontent.com/%s/%s/refs/heads/dist/", user, repo)
    end

    -- GitLab: https://gitlab.com/user/repo -> https://gitlab.com/user/repo/-/raw/dist/
    local gitlab_url = url:match("^(https?://[^/]*gitlab[^/]*/[^/]+/[^/]+)/?$")
    if gitlab_url then
        gitlab_url = gitlab_url:gsub("%.git$", "")
        return gitlab_url .. "/-/raw/dist/"
    end

    -- Bitbucket: https://bitbucket.org/user/repo -> https://bitbucket.org/user/repo/raw/dist/
    user, repo = url:match("^https?://[www%.]*bitbucket%.org/([^/]+)/([^/]+)/?$")
    if user and repo then
        repo = repo:gsub("%.git$", "")
        return string.format("https://bitbucket.org/%s/%s/raw/dist/", user, repo)
    end

    -- Codeberg: https://codeberg.org/user/repo -> https://codeberg.org/user/repo/raw/branch/dist/
    user, repo = url:match("^https?://[www%.]*codeberg%.org/([^/]+)/([^/]+)/?$")
    if user and repo then
        repo = repo:gsub("%.git$", "")
        return string.format("https://codeberg.org/%s/%s/raw/branch/dist/", user, repo)
    end

    -- SourceHut: https://git.sr.ht/~user/repo -> https://git.sr.ht/~user/repo/blob/dist/
    local srht_user, srht_repo = url:match("^https?://git%.sr%.ht/(~[^/]+)/([^/]+)/?$")
    if srht_user and srht_repo then
        srht_repo = srht_repo:gsub("%.git$", "")
        return string.format("https://git.sr.ht/%s/%s/blob/dist/", srht_user, srht_repo)
    end

    -- If no pattern matches, assume it's already a raw URL
    -- Ensure it ends with a slash for consistency
    if not url:match("/$") then
        url = url .. "/"
    end

    return url
end

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

--- Get the manifest for the repository
--- @param url string | table: Repository URL or manifest.
--- @return table | nil, nil | string: A table representing the manifest or nil and an error message.
function repository.fetch_manifest(url)
    expect.expect(1, url, "string", "table")

    if type(url) == "table" then
        url = url.url
    end

    local raw_url = repository.extract_raw_url(url)

    local driver, err = repository.get_driver(raw_url)
    if not driver then
        return nil, err
    end

    local manifest, err = driver.get_manifest(raw_url)
    if not manifest then
        return nil, err
    end

    return manifest, nil
end

--- Add a new repository.
--- @param url string: Repository URL (any).
--- @return nil | string: Nil or an error message.
function repository.add(url)
    local manifest, err = repository.fetch_manifest(url)
    if not manifest then
        return nil, err
    end

    local id, err = database.add_repository(manifest)
    if not id then
        return "failed to add repository: " .. err
    end

    return nil
end

--- Update the index and manifest of all repositories.
--- @return nil | string: Nil or an error message.
function repository.update()
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

        local manifest, err = repository.fetch_manifest(repo)
        if not manifest then
            err = "failed to get manifest for repository: " .. err
            event.dispatch("ccpm_index_not_updated", id, err)
            return err
        end
        if manifest.url ~= repo.url or
            manifest.name ~= repo.name or
            manifest.priority ~= repo.priority then
            database.update_repository(id, manifest)
        end

        local index, err = driver.get_packages_index(manifest)
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
