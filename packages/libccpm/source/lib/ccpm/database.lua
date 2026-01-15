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

local uuid = require("uuid")
local ctable = require("commons.ctable")
local expect = require("cc.expect")
local event = require("ccpm.eventutils")

--- @export
local database = {}

database.STORAGE_DIR = "/.data/ccpm/"
database.REPOSITORIES_INDEX_FILE = database.STORAGE_DIR .. "repositories-index.json"
database.PACKAGES_INDEX_FILE = database.STORAGE_DIR .. "packages-index.json"
database.PACKAGES_DATABASE_FILE = database.STORAGE_DIR .. "packages-database.json"

local repositories_index = {}
local packages_index = {}
local packages_database = {}

--- Load or backup a file.
--- @param path string: The path to the file.
--- @param fallback table: The fallback data.
--- @return table: The loaded data.
local function load_or_backup(path, fallback)
    expect.expect(1, path, "string")
    expect.expect(1, fallback, "table", "nil")

    if fs.exists(path) then
        local file = fs.open(path, "r")
        if not file then
            return fallback
        end

        local data = file.readAll()
        if data == nil then
            error("could not read storage file: " .. path)
        end
        file.close()

        data = textutils.unserializeJSON(data)
        if data == nil then
            event.dispatch("ccpm_backup", path)

            local i = 0
            while fs.exists(path .. ".bak" .. i) do
                i = i + 1
            end

            fs.move(path, path .. ".bak" .. i)
            return fallback
        end

        return data
    else
        return fallback
    end
end

--- Save file.
--- @param path string: The path to the storage file.
--- @param value table: The data to save.
local function save(path, value)
    if value == nil then
        if fs.exists(path) then
            fs.delete(path)
        end
        return
    end

    local file, err = fs.open(path, "w")
    if not file then
        error("unable to serialize data: " .. err)
    end

    local data, err = textutils.serializeJSON(value)
    if data == nil then
        error("unable to serialize data: " .. err)
    end

    file.write(data)
    file.close()
end

local function make_pattern(query)
    query = query:gsub("%*", ".+")
    query = query:gsub("%-", "%%-")
    return "^" .. query .. "$"
end

--- Load local storage.
function database.load_all()
    repositories_index = load_or_backup(database.REPOSITORIES_INDEX_FILE, repositories_index)
    packages_index = load_or_backup(database.PACKAGES_INDEX_FILE, packages_index)
    packages_database = load_or_backup(database.PACKAGES_DATABASE_FILE, packages_database)
end

--- Save local storage.
function database.save_all()
    if not fs.exists(database.STORAGE_DIR) then
        fs.makeDir(database.STORAGE_DIR)
    end

    save(database.REPOSITORIES_INDEX_FILE, repositories_index)
    save(database.PACKAGES_INDEX_FILE, packages_index)
    save(database.PACKAGES_DATABASE_FILE, packages_database)
end

--- Get repository instance.
--- @param id string: The ID of the repository.
--- @return table | nil: A table representing the repository, or nil if not found.
function database.get_repository(id)
    return ctable.copy(repositories_index[id])
end

--- Add a new repository.
--- @param repository table: A table representing the repository.
--- @return string | nil, string | nil: The local ID of the repository, or nil and an error message if the repository already exists.
function database.add_repository(repository)
    expect.expect(1, repository, "table")

    -- Check if the repository already exists
    for id, repo in pairs(repositories_index) do
        if repo.url == repository.url then
            return nil, "repository already exists (" .. id .. ")"
        end
    end

    local id = uuid.v4()
    repositories_index[id] = ctable.copy(repository)

    save(database.REPOSITORIES_INDEX_FILE, repositories_index)
    return id, nil
end

--- Update an existing repository.
--- @param id string: The ID of the repository.
--- @param repository table: A table representing the repository.
--- @return string | nil: An error message or nil.
function database.update_repository(id, repository)
    if not repositories_index[id] then
        return "repository not found"
    end

    repositories_index[id] = ctable.copy(repository)

    save(database.REPOSITORIES_INDEX_FILE, repositories_index)
    return nil
end

--- Delete an existing repository.
--- @param id string: The ID of the repository.
--- @return string | nil: An error message or nil.
function database.remove_repository(id)
    if not repositories_index[id] then
        return "repository not found"
    end

    repositories_index[id] = nil

    save(database.REPOSITORIES_INDEX_FILE, repositories_index)
    return nil
end

--- List all repositories.
--- @return table, number: A table of repositories and the number of entries.
function database.get_repositories()
    return ctable.copy_count(repositories_index)
end

--- Search for repositories by URL.
--- @param query string: The search query.
--- @return table | nil, string | number: A table of repositories and the number of entries, or nil and an error message if the database cannot be loaded.
function database.search_repositories(query)
    expect.expect(1, query, "string")

    local pattern = make_pattern(query)
    local repositories = {}
    local count = 0

    for id, repository in pairs(repositories_index) do
        if string.find(repository.url, pattern) then
            repositories[id] = ctable.copy(repository)
            count = count + 1
        end
    end
    return repositories, count
end

--- Set the packages index.
--- @param index table: The packages index.
function database.set_packages_index(index)
    expect.expect(1, index, "table")

    packages_index = index

    save(database.PACKAGES_INDEX_FILE, packages_index)
end

--- Get a package.
--- @param name string: The package name.
--- @return table | nil, string | nil: A table of packages, or nil and an error message if package not found.
function database.get_package(name)
    expect.expect(1, name, "string")

    local package = packages_index[name]
    if package == nil then
        return nil, "package not found: " .. name
    end
    return ctable.copy(package)
end

--- Get all packages.
--- @return table, number: A table of packages and the number of entries.
function database.get_packages()
    return ctable.copy_count(packages_index)
end

--- Search for packages by name.
--- @param query string: The search query, with wildcard support.
--- @return table, number: A table of packages and the number of entries.
function database.search_packages(query)
    expect.expect(1, query, "string")

    local pattern = make_pattern(query)
    local packages = {}
    local count = 0

    for name, package in pairs(packages_index) do
        if string.find(name, pattern) then
            packages[name] = ctable.copy(package)
            count = count + 1
        end
    end
    return packages, count
end

--- Get installed packages.
--- @return table, number: A table of installed packages and the number of entries.
function database.get_installed_packages()
    return ctable.copy_count(packages_database)
end

--- Search for installed packages by name.
--- @param query string: The search query, with wildcard support.
--- @return table, number: A table of installed packages and the number of entries.
function database.search_installed_packages(query)
    expect.expect(1, query, "string")

    local pattern = make_pattern(query)
    local packages = {}
    local count = 0

    for name, package in pairs(packages_database) do
        if string.find(name, pattern) then
            packages[name] = ctable.copy(package)
            count = count + 1
        end
    end
    return packages, count
end

--- Get installed package by name.
--- @param name string: The package name.
--- @return table | nil, string | nil: The installed package or nil and an error message.
function database.get_installed_package(name)
    expect.expect(1, name, "string")

    local package = packages_database[name]
    if package == nil then
        return nil, "package not found: " .. name
    end
    return ctable.copy(package)
end

--- Set the packages database.
--- @param db table: The packages database.
function database.set_packages_database(db)
    expect.expect(1, db, "table")

    packages_database = db

    save(database.PACKAGES_DATABASE_FILE, packages_database)
end

-- Load database at require.
database.load_all()

return database
