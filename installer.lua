-- CCPM Installer with online require

local CCPM_BASE_URL = "https://raw.githubusercontent.com/Deleranax/ccpm/refs/heads/main/"
local PACKAGES_URL = CCPM_BASE_URL .. "packages/"

local function get_url(name)
    name = name:gsub("%/", ".")

    local parts = {}
    for value in name:gmatch("([^.]+)") do
        table.insert(parts, value)
    end

    return PACKAGES_URL .. parts[1] .. "/source/" .. table.concat(parts, "/") ".lua"
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

-- Add online_require to package searchers
table.insert(package.searchers, online_require)

-- Begin install
local repo = require("ccpm.repository")

repo.add("ccpm.repository")
