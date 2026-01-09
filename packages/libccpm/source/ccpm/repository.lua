local database = require("ccpm.database")

local repository = {}

--- Get the driver for the repository
--- @param url string: Repository URL (any).
--- @return table | nil, nil | string: A table representing the driver or nil and an error message.
function repository.get_driver(url)
    local driver = require("ccpm.driver." + url:match("^([^/]+)://"))
    if not driver then
        return nil, "Driver not found"
    else if not driver.can_handle(url) then
        return nil, "Driver cannot handle URL"
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

    local id = database.add_repository(url)
    if not id then
        return "Failed to add repository"
    end

    return nil
end

--- Remove a repository.
--- @param url string: Repository URL (canonical or any).
function repository.remove(url)

end

return repository
