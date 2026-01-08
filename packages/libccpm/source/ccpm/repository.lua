local database = require("ccpm.database")

local repository = {}

--- Get the driver for the repository
--- @param url string: Repository URL (any).
--- @return table | nil, nil | string: A table representing the driver or nil and an error message.
function repository.get_driver(url)

end

--- Add a new repository.
--- @param url string: Repository URL (any).
--- @return nil | string: Nil or an error message.
function repository.add(url)

end

--- Remove a repository.
--- @param url string: Repository URL (canonical or any).
function repository.remove(url)

end

return repository
