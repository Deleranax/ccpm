local database = {}

local STORAGE_DIR = "/.data/ccpm/"
local REPOSITORIES_INDEX_FILE = STORAGE_DIR .. "repository_index.db"
local PACKAGES_INDEX_FILE = STORAGE_DIR .. "packages_index.db"
local PACKAGES_DATABASE_FILE = STORAGE_DIR .. "packages_database.db"
local TRANSACTION_FILE = STORAGE_DIR .. "transaction.lock"

local repositories_index = {}
local packages_index = {}
local packages_database = {}
local transaction = nil

local function load_or_backup(path, fallback)
    if fs.exists(path) then
        local file = fs.open(path, "r")
        if not file then
            return fallback
        end

        local data = file.readAll()
        if data == nil then
            error("Could not read storage file: " .. path)
        end
        file.close()

        data = textutils.unserializeJSON(data)
        if data == nil then
            os.queueEvent("ccpm_backup", path)

            local i = 0
            while fs.exists(path .. ".bak" .. i) do
                i = i + 1
            end

            fs.move(path, path .. ".bak" .. i)
            return fallback
        end

        return data
    end
end

local function save(path, value)
    if value == nil then
        if fs.exists(path) then
            fs.delete(path)
        end
        return
    end

    local file = fs.open(path, "w")
    if not file then
        os.queueEvent("ccpm_not_saved", path)
        return
    end

    local data, err = textutils.serializeJSON(value)
    if data == nil then
        error("unable to serialize data: " .. err)
    end

    file.write(data)
    file.close()
end

--- Load local storage.
function database.load()
    os.queueEvent("ccpm_loading")

    repositories_index = load_or_backup(REPOSITORIES_INDEX_FILE, repositories_index)
    packages_index = load_or_backup(PACKAGES_INDEX_FILE, packages_index)
    packages_database = load_or_backup(PACKAGES_DATABASE_FILE, packages_database)
    transaction = load_or_backup(TRANSACTION_FILE, transaction)
end

--- Save local storage.
function database.save()
    os.queueEvent("ccpm_saving")

    if not fs.exists(STORAGE_DIR) then
        fs.makeDir(STORAGE_DIR)
    end

    save(REPOSITORIES_INDEX_FILE, repositories_index)
    save(PACKAGES_INDEX_FILE, packages_index)
    save(PACKAGES_DATABASE_FILE, packages_database)
    save(TRANSACTION_FILE, transaction)
end

--- Get repositories index instance.
-- @return table: A table representing the repositories index.
function database.get_repositories_index()
    return repositories_index
end

--- Get packages index instance.
-- @return table: A table representing the packages index.
function database.get_packages_index()
    return packages_index
end

--- Get packages database instance.
-- @return table: A table representing the packages database.
function database.get_packages_database()
    return packages_database
end

--- Get transaction instance.
-- @return table: A table representing the transaction.
function database.get_transaction_index()
    return transaction
end

-- Load database at startup.
database.load()

return database
