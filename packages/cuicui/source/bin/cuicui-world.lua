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

--! preserve-lines

local cuicui  = require("cuicui")
local const   = require("cuicui.const")

-- Set the debug mode
cuicui.DEBUG  = false

local counter = 1

cuicui.vertical(term.current(), function(ui)
    ui.color = colors.black
    ui.align = const.ALIGN.CENTER + const.ALIGN.HORIZON
    ui.h_expand = true

    ui.label(function(ui2)
        ui2.text = "*click*"
        ui2.visible = ui.click ~= nil
    end)

    if ui.click then
        counter = counter + 1
    end

    for i = 1, (counter % 10) do
        ui.label(function(ui)
            ui.text = "Cuicui, world! (" .. i .. ")"
            ui.id = "l" .. i -- Important for repeating creation
            if i == 5 then
                ui.v_expand = true
                ui.h_expand = true
                ui.background_color = colors.red
            end
        end)
    end
end)
