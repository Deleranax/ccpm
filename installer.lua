-- CCPM Installer with online require

local CCPM_BASE_URL = "https://raw.githubusercontent.com/Deleranax/ccpm/refs/heads/main/"
local PACKAGES_URL = CCPM_BASE_URL .. "packages/"
local PACKAGES_OVERRIDE = {
    ["ccpm.driver.http"] = "ccpm-driver-http",
    ["ccpm.driver.https"] = "ccpm-driver-http",
    ["ccpm.repository"] = "libccpm",
    ["ccpm.database"] = "libccpm",
    ["ccpm.package"] = "libccpm"
}

local function get_url(name)
    name = name:gsub("%/", ".")

    local parts = {}
    for value in name:gmatch("([^.]+)") do
        table.insert(parts, value)
    end

    local package = parts[1]
    local path = table.concat(parts, ".")
    if PACKAGES_OVERRIDE[path] then
        package = PACKAGES_OVERRIDE[path]
    end

    return PACKAGES_URL .. package .. "/source/" .. table.concat(parts, "/") .. ".lua"
end

local function online_require(name)
    local url = get_url(name)
    local response = http.get(url)
    if response then
        local code = response.readAll()
        response.close()
        local chunk = load(code, "=" .. name)
        if chunk then
            return chunk, nil
        end
    end
    return nil, "no file at '" .. url .. "'"
end

-- Add online_require to package loaders
table.insert(package.loaders, online_require)

-- Begin install
local repo = require("ccpm.repository")

repo.add_repository(CCPM_BASE_URL)
