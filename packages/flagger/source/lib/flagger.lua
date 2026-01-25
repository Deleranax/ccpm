--[[
    flagger - A simple flag utility library
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
local flagger = {}

--- Get the component at a specific power of base
--- @param value number The value to extract from
--- @param exp number The exponent (power of base)
--- @param base number The base to use
--- @return number The component value at that position
function flagger.get(value, exp, base)
    local power = base ^ exp
    return math.floor(value / power) % base
end

--- Set the component at a specific power of base
--- @param value number The original value
--- @param exp number The exponent (power of base)
--- @param component number The component value to set
--- @param base number The base to use
--- @return number The new value with the component set
function flagger.set(value, exp, component, base)
    local power = base ^ exp
    local current = flagger.get(value, exp, base)
    return value - (current * power) + (component * power)
end

--- Create a flag table from component lists
--- @param orders table List of component groups, each containing flag names
--- @return table A table with flag names as keys and their numeric values
function flagger.make_flag(orders)
    local flags = {}
    local base = #orders[1]

    -- Calculate the maximum number of components per position
    for _, order in ipairs(orders) do
        if #order > base then
            base = #order
        end
    end

    -- Generate flag values
    for exp, order in ipairs(orders) do
        for component, name in ipairs(order) do
            if exp == 1 then
                -- First position: component index starting at 0
                flags[name] = component - 1
            else
                -- Other positions: component * base^(exp-1)
                flags[name] = component * (base ^ (exp - 1))
            end
        end
    end

    return flags
end

return flagger
