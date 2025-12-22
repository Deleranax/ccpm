local libdeflate = require("libdeflate")
local base64 = require("lockbox.util.base64")
local expect = require("cc.expect")

local package = {}

--- Unpack a CCPM package (.ccp).
-- @param package_path string: Pathname for the package file.
-- @param output string: Pathname for the output directory.
-- @return table or (nil, string): A table representing the manifest or nil and an error message.
function package.unpack(package_path, output)
    expect.expect(1, package_path, "string")
    expect.expect(2, output, "string")

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

    for path, pkg_file in pairs(data.files) do
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

    data.files = nil
    return data
end

return package
