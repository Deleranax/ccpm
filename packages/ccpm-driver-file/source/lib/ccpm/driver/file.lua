--[[
    ccpm-driver-file - File driver for CCPM
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

local expect = require("cc.expect")

--- @export
local file = {}

--- Check if the given URL is compatible with the file driver.
--- @param url string: The URL to check.
--- @return boolean: True if the URL is compatible, false otherwise.
function file.can_handle(url)
    expect(1, url, "string")

    return url:match("^file://") ~= nil
end

--- Retrieve the manifest from the given URL.
--- @param url string: The URL to retrieve the manifest from.
--- @return table | nil, nil | string: A table representing the manifest or an error message.
function file.get_manifest(url)
    if not file.can_handle(url) then
        return nil, "URL is not compatible with the file driver"
    end

    -- Extract the file path from the URL (remove "file://")
    local path = url:sub(8)

    -- Remove the trailing slash if the path ends with one
    if path:sub(-1) == "/" then
        path = path:sub(1, -2)
    end

    local manifest_path = path .. "/manifest.json"

    if not fs.exists(manifest_path) then
        return nil, "manifest file not found: " .. manifest_path
    end

    if fs.isDir(manifest_path) then
        return nil, "manifest path is a directory: " .. manifest_path
    end

    local handle, err = fs.open(manifest_path, "r")
    if not handle then
        return nil, "failed to open manifest: " .. err
    end

    local content = handle.readAll()
    handle.close()

    local manifest, parse_err = textutils.unserializeJSON(content)
    if not manifest then
        return nil, "failed to parse manifest: " .. parse_err
    end

    return manifest, nil
end

--- Retrieve the packages index with the given repository manifest.
--- @param manifest table: The manifest table.
--- @return table | nil, nil | string: A table representing the packages index or an error message.
function file.get_packages_index(manifest)
    expect(1, manifest, "table")

    -- Extract the file path from the URL (remove "file://")
    local path = manifest.url:sub(8)

    -- Remove the trailing slash if the path ends with one
    if path:sub(-1) == "/" then
        path = path:sub(1, -2)
    end

    local index_path = path .. "/pool/index.json"

    if not fs.exists(index_path) then
        return nil, "index file not found: " .. index_path
    end

    if fs.isDir(index_path) then
        return nil, "index path is a directory: " .. index_path
    end

    local handle, err = fs.open(index_path, "r")
    if not handle then
        return nil, "failed to open index: " .. tostring(err)
    end

    local content = handle.readAll()
    handle.close()

    local index, parse_err = textutils.unserializeJSON(content)
    if not index then
        return nil, "failed to parse index: " .. tostring(parse_err)
    end

    return index, nil
end

--- Download a package from a file repository.
--- @param manifest table The repository manifest.
--- @param name string The name of the package to download.
--- @param version string The version of the package to download.
--- @param path string The directory path where the package file should be downloaded.
--- @return nil | string Error message or nil if successful.
function file.download_package(manifest, name, version, path)
    expect(1, manifest, "table")
    expect(2, name, "string")
    expect(3, version, "string")
    expect(4, path, "string")

    local filename = name .. "." .. version .. ".ccp"

    -- Extract the file path from the URL (remove "file://")
    local repo_path = manifest.url:sub(8)

    -- Remove the trailing slash if the path ends with one
    if repo_path:sub(-1) == "/" then
        repo_path = repo_path:sub(1, -2)
    end

    local package_path = repo_path .. "/pool/" .. filename

    if not fs.exists(package_path) then
        return "package file not found: " .. package_path
    end

    if fs.isDir(package_path) then
        return "package path is a directory: " .. package_path
    end

    fs.copy(package_path, path .. "/" .. filename)
end

return file
