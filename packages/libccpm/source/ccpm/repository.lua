local database = require("ccpm.database")

local repository = {}

--- Get the driver for the repository
--- @param url string: Repository URL (any).
--- @return table | nil, nil | string: A table representing the driver or nil and an error message.
function repository.get_driver(url)
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
    local repositories = database.get_repositories()
    if not repositories then
        return "failed to get repositories"
    end

    for _, repository in ipairs(repositories) do
        local driver, err = repository.get_driver(repository.url)
        if not driver then
            return "failed to get driver for repository: " .. err
        end

        local manifest, err = driver.get_manifest(repository.url)
        if not manifest then
            return "failed to get manifest for repository: " .. err
        end

        local err = database.update_repository(repository.id, manifest)
        if err then
            return "failed to update repository: " .. err
        end
    end

    return nil
end

return repository
