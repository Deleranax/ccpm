--[[
    cuicui-core - Core package for cuicui
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

--- @export
local utils = {}

--- Compute rectangle variables from a given value.
--- @param var number | table: The value to compute the rectangle variables from.
--- @return table: The computed rectangle variables (top, left, bottom, right).
function utils.compute_rect_vars(var)
    if type(var) == "number" then
        return {
            top = var,
            left = var,
            bottom = var,
            right = var
        }
    elseif type(var) == "table" then
        return {
            top = var.top or var.y or 0,
            left = var.left or var.x or 0,
            bottom = var.bottom or var.y or 0,
            right = var.right or var.x or 0
        }
    else
        return {
            top = 0,
            left = 0,
            bottom = 0,
            right = 0
        }
    end
end

return utils
