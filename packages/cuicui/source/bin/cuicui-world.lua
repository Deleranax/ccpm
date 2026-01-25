--[[
    cuicui - Modular immediate mode GUI library
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

local cuicui = require("cuicui")

-- Set the debug mode
cuicui.DEBUG = true

local counter = 1

cuicui.vertical(term.current(), function(ui)
    ui.color = colors.black
    ui.align = "center"
    ui.h_expand = true

    counter = counter + 1

    for i = 1, (counter % 10) do
        ui.label(function(ui)
            ui.text = "Cuicui, World!"
            ui.id = "l" .. i -- Important for repeating creation
            if i == 5 then
                ui.v_expand = true
                ui.h_expand = true
                ui.background_color = colors.red
            end
        end)
    end
end)
