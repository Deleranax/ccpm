local database = require("ccpm.database")
local expect = require("cc.expect")

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

--- Remove a repository.
--- @param url string: Repository URL (canonical or any).
function repository.remove(url)

end

--- Update the index of all repositories.
--- @return nil | string: Nil or an error message.
function repository.update_index()
    local repositories_index = {}
    local repositories = database.get_repositories()

    -- Download individual repositories packages index
    os.queueEvent("ccpm_index_update_start", #repositories)
    for id, repo in pairs(repositories) do
        os.queueEvent("ccpm_index_updating", id)

        local driver, err = repository.get_driver(repo)
        if not driver then
            err = "failed to get driver for repository: " .. err
            os.queueEvent("ccpm_index_not_updated", id, err)
            return err
        end

        local index, err = driver.get_packages_index(repo)
        if not index then
            err = "failed to get packages index for repository: " .. err
            os.queueEvent("ccpm_index_not_updated", id, err)
            return err
        end

        repositories_index[id] = index
        os.queueEvent("ccpm_index_updated", id)
    end
    os.queueEvent("ccpm_index_update_end")

    local new_index = {}

    -- Merge repositories index according to priority
    for id, index in pairs(repositories_index) do
        for name, manifest in pairs(index) do
            if not new_index[name] or repositories[id].priority > repositories[id].priority then
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
