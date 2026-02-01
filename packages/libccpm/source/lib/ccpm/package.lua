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

local libdeflate = require("libdeflate")
local base64     = require("lockbox.util.base64")
local Digest     = require("lockbox.digest.sha2_256")
local Stream     = require("lockbox.util.stream")
local expect     = require("cc.expect")
local repository = require("ccpm.repository")
local database   = require("ccpm.database")
local event      = require("ccpm.eventutils")
local schema     = require("ccpm.schema")

--- @export
local package    = {}

--- Unpack a CCPM package (.ccp).
--- @param package_path string: Pathname for the package file.
--- @param output string: Pathname for the output directory.
--- @return table | nil, nil | string: A table representing the manifest or nil and an error message.
function package.unpack(package_path, output)
    expect(1, package_path, "string")
    expect(2, output, "string")

    if not fs.exists(output) then
        fs.makeDir(output)
    end

    if not fs.isDir(output) then
        return nil, "invalid output: not a directory"
    end

    if fs.isReadOnly(output) then
        return nil, "invalid output: read only"
    end

    local file, err = fs.open(package_path, "r")
    if file == nil then
        return nil, "unable to open package: " .. err
    end

    local data = file.readAll()
    if data == nil then
        return nil, "unable to read package"
    end
    file.close()

    data = base64.toString(data)
    if data == nil then
        return nil, "unable to decode package"
    end

    data, err = libdeflate:DecompressZlib(data)
    if data == nil then
        return nil, "unable to decompress package: " .. err
    end

    data, err = textutils.unserializeJSON(data)
    if data == nil then
        return nil, "unable to parse package: " .. err
    end

    local valid, err = schema.validate(data, { "Package" })
    if not valid then
        return nil, "invalid package: " .. err
    end

    for path, pkg_file in pairs(data.files) do
        local digest = Digest()
            .init()
            .update(Stream.fromString(pkg_file.content))
            .finish()
            .asHex()

        if digest ~= pkg_file.digest then
            return nil, "checksum mismatch for file: " .. path
        end

        if fs.exists(output .. "/" .. path) then
            return nil, "conflicting file: " .. path
        end

        file, err = fs.open(output .. "/" .. path, "w")
        if file == nil then
            return nil, "unable to write file: " .. err
        end

        file.write(pkg_file.content)
        file.close()
    end

    return data
end

--- Download a package.
--- @param name string The name of the package to download.
--- @param version string The version of the package to download.
--- @param path string The directory path where the package file should be downloaded.
--- @return nil | string: Nil and an error message.
function package.download(name, version, path)
    expect(1, name, "string")
    expect(2, version, "string", nil)
    expect(3, path, "string")

    local manifest, err = database.get_package(name)
    if manifest == nil then
        return err
    end

    if version == nil then
        version = manifest["latest_version"]
    else
        if not manifest["versions"][version] then
            return "invalid version: " .. version
        end
    end

    local repo = database.get_repository(manifest.repository)
    if repo == nil then
        return "invalid repository: " .. manifest.repository
    end

    local driver = repository.get_driver(repo)
    if driver == nil then
        return "couldn't find driver: " .. manifest.repository
    end

    event.dispatch("ccpm_package_downloading", name, version)
    local err = driver.download_package(repo, name, version, path)
    if err ~= nil then
        err = "unable to download package: " .. err
        event.dispatch("ccpm_package_download_failed", name, version, err)
        return err
    end

    event.dispatch("ccpm_package_downloaded", name, version)
end

return package
