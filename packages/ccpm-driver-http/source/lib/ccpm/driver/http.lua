--[[
    ccpm-driver-http - HTTP driver for CCPM
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
local httpd = {}

--- Check if the given URL is compatible with the HTTP driver.
--- @param url string: The URL to check.
--- @return boolean: True if the URL is compatible, false otherwise.
function httpd.can_handle(url)
    expect(1, url, "string")

    return url:match("^https?://") ~= nil
end

--- Retrieve the manifest from the given URL.
--- @param url string: The URL to retrieve the manifest from.
--- @return table | nil, nil | string: A table representing the manifest or an error message.
function httpd.get_manifest(url)
    if not httpd.can_handle(url) then
        return nil, "URL is not compatible with the HTTP driver"
    end

    -- Remove the trailing slash if the URL end with one
    if url:sub(-1) == "/" then
        url = url:sub(1, -2)
    end

    local response = http.get(url .. "/manifest.json")
    if not response then
        return nil, "failed to retrieve manifest"
    elseif response.getResponseCode() ~= 200 then
        return nil, "failed to retrieve manifest: " .. response.getResponseCode()
    end

    local manifest, err = textutils.unserializeJSON(response.readAll())
    if not manifest then
        return nil, "failed to parse manifest: " .. err
    end

    return manifest, nil
end

--- Retrieve the packages index with the given repository manifest.
--- @param manifest table: The manifest table.
--- @return table | nil, nil | string: A table representing the packages index or an error message.
function httpd.get_packages_index(manifest)
    expect(1, manifest, "table")

    local response = http.get(manifest.url .. "/pool/index.json")
    if not response then
        return nil, "failed to retrieve index"
    elseif response.getResponseCode() ~= 200 then
        return nil, "failed to retrieve index: " .. response.getResponseCode()
    end

    local index, err = textutils.unserializeJSON(response.readAll())
    if not index then
        return nil, "failed to parse index: " .. err
    end

    return index, nil
end

--- Download a package from an HTTP repository.
--- @param manifest table The repository manifest.
--- @param name string The name of the package to download.
--- @param version string The version of the package to download.
--- @param path string The directory path where the package file should be downloaded.
--- @return nil | string Error message or nil if successful.
function httpd.download_package(manifest, name, version, path)
    expect(1, manifest, "table")
    expect(2, name, "string")
    expect(3, version, "string")
    expect(4, path, "string")

    local filename = name .. "." .. version .. ".ccp"

    local response = http.get(manifest.url .. "/pool/" .. filename)
    if not response then
        return "failed to retrieve file " .. filename
    elseif response.getResponseCode() ~= 200 then
        return "failed to retrieve file " .. filename .. ": " .. response.getResponseCode()
    end

    local content = response.readAll()
    local file = fs.open(path .. "/" .. filename, "w")
    if not file then
        return "failed to open file for writing"
    end
    file.write(content)
    file.close()
end

return httpd
