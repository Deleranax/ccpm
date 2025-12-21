local libdeflate = require("libdeflate")
local base64 = require("lockbox.util.base64")

local packages

--- Unpack a CCPM package (.ccp).
-- @param package_path string: Pathname for the package file.
-- @param output string: Pathname for the output directory.
-- @return table or (nil, string): A table representing the manifest or nil and an error message.
function packages:unpack(package_path, output)
    local file, error = fs.open(package_path, "r")
    if file == nil then
        return nil, "unable to open package: " .. error
    end

    local data = file.readAll()
    if data == nil then
        return nil, "unable to read package: " .. error
    end
    file.close()

    data, error = libdeflate.DecompressZlib(data)
    if data == nil then
        return nil, "unable to decompress package: " .. error
    end

    data, error = textutils.unserializeJSON(data)
    if data == nil then
        return nil, "unable to parse package: " .. error
    end

    for path, content in pairs(data.files) do
        file, error = fs.open(output .. "/" .. path, "w")
        if file == nil then
            return nil, "unable to write file: " .. error
        end

        file.write(content)
        file.close()
    end

    data.files = nil
    return data
end

return packages
