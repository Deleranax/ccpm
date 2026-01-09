local expect = require("cc.expect")

local httpd = {}

--- Check if the given URL is compatible with the HTTP driver.
--- @param url string: The URL to check.
--- @return boolean: True if the URL is compatible, false otherwise.
function httpd.can_handle(url)
    expect.expect(1, url, "string")

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
    if response.getResponseCode() ~= 200 then
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
    expect.expect(1, manifest, "table")

    local response = http.get(manifest.url .. "/pool/index.json")
    if response.getResponseCode() ~= 200 then
        return nil, "failed to retrieve index: " .. response.getResponseCode()
    end

    local index, err = textutils.unserializeJSON(response.readAll())
    if not index then
        return nil, "failed to parse index: " .. err
    end

    return index, nil
end

--- Retrieve the package file with the given name with the given repository manifest.
--- @param manifest table: The manifest table.
--- @param filename string: The name of the package file.
--- @return string | nil, nil | string: The package content or an error message.
function httpd.get_package(manifest, filename)
    expect.expect(1, manifest, "table")
    expect.expect(2, filename, "string")

    local response = http.get(manifest.url .. "/pool/" .. filename .. ".ccp")
    if response.getResponseCode() ~= 200 then
        return nil, "failed to retrieve package: " .. response.getResponseCode()
    end

    return response.readAll(), nil
end

return httpd
