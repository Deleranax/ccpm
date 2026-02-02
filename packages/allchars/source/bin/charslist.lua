--[[
    allchars - A small utility to print all characters
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

local ctextutils = require("commons.textutils")

local width, height = term.getSize()
local x = 1
local y = 1

term.setCursorPos(1, 1)
term.clear()


for i = 0, 255 do
    -- Go to next line if needed
    if x + 4 > width then
        term.setCursorPos(1, y + 2)
        x = 1
        y = y + 3

        if y + 3 > height then
            term.setCursorPos(1, height)
            term.write("\25 Press key to continue \25")
            os.pullEvent("key")

            term.setCursorPos(1, 1)
            term.clear()
            y = 1
        end
    end

    local str = tostring(i)
    str = string.rep("0", 3 - #str) .. str

    term.setCursorPos(x + 1, y)
    term.write(string.char(i))
    term.setCursorPos(x, y + 1)
    term.write(str)

    x = x + 4
end
