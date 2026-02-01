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

local schematics = require("schematics")

--- @export
local schema = {}

schema.PackageBase = {
    description = { "string" },
    license = { "string" },
    authors = { "array<string>" },
    maintainers = { "array<string>" },
}

schema.PackageManifest = {
    __inherits = { "PackageBase" },
    version = { "string" },
    dependencies = { "array<string>" },
}

schema.RepositoryManifest = {
    name = { "string" },
    url = { "string" },
    priority = { "number" }
}

schema.IndexVersion = {
    digest = { "string" },
    dependencies = { "array<string>" },
}

schema.IndexPackage = {
    __inherits = { "PackageBase" },
    versions = { "map<string, IndexVersion>" },
    latest_version = { "string" },
}

schema.RepositoryIndex = { "map<string, IndexPackage>" }

schema.PackageFile = {
    content = { "string" },
    digest = { "string" },
}

schema.package = {
    __inherits = { "PackageManifest" },
    files = { "map<string, PackageFile>" },
}

schema.validate = schematics.compile(schema)

return schema
