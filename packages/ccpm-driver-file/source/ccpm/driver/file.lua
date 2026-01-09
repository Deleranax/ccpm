local expect = require("cc.expect")

local file = {}

--- Check if the given URL is compatible with the file driver.
--- @param url string: The URL to check.
--- @return boolean: True if the URL is compatible, false otherwise.
function file.can_handle(url)
    expect.expect(1, url, "string")

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
    expect.expect(1, manifest, "table")

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

--- Retrieve the package file with the given name with the given repository manifest.
--- @param manifest table: The manifest table.
--- @param filename string: The name of the package file.
--- @return string | nil, nil | string: The package content or an error message.
function file.get_package(manifest, filename)
    expect.expect(1, manifest, "table")
    expect.expect(2, filename, "string")

    -- Extract the file path from the URL (remove "file://")
    local path = manifest.url:sub(8)

    -- Remove the trailing slash if the path ends with one
    if path:sub(-1) == "/" then
        path = path:sub(1, -2)
    end

    local package_path = path .. "/pool/" .. filename .. ".ccp"

    if not fs.exists(package_path) then
        return nil, "package file not found: " .. package_path
    end

    if fs.isDir(package_path) then
        return nil, "package path is a directory: " .. package_path
    end

    local handle, err = fs.open(package_path, "r")
    if not handle then
        return nil, "failed to open package: " .. tostring(err)
    end

    local content = handle.readAll()
    handle.close()

    return content, nil
end

return file
