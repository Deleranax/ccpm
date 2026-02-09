--[[
    cuicui-widget-base - Base widget pack for cuicui
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
cuicui.DEBUG  = 1

local mode    = 1
local init    = true
local counter = 0

cuicui.vertical(term.current(), function(ui)
    ui.background_color = colors.lightGray
    ui.align = const.ALIGN.CENTER + const.ALIGN.HORIZON
    ui.h_expand = true
    ui.v_expand = true

    if ui.keys then
        if ui.keys[keys.left] and mode > 1 then
            mode = mode - 1
            init = true
        elseif ui.keys[keys.right] and mode < 5 then
            mode = mode + 1
            init = true
        end
    end

    if mode == 1 then
        ui.label(function(ui2)
            ui2.text = "*click*"
            ui2.visible = ui.click ~= nil
        end)

        ui.progress(function(ui)
            ui.current = counter
            ui.vertical = false
            ui.width = 10
            ui.height = 3
            ui.target = 20
            ui.on_click(function(ui)
                counter = counter + 1
            end)
        end, false)

        for i = 1, 10 do
            ui.button(function(ui)
                ui.text = "Cuicui, world! (" .. i .. ")"
                ui.activated_background_color = colors.red
                ui.background_color = colors.blue
                if ui.active then
                    ui.v_expand = true
                    ui.h_expand = true
                end
            end, true, "l" .. i) -- Important for repeating creation
        end
    elseif mode == 2 then
        ui.toggle(function(ui)
            if init then ui.active = true end
            ui.group = "group1"
            ui.align_right = false
        end)
        ui.toggle(function(ui)
            ui.group = "group1"
            ui.align_right = true
        end)
    elseif mode == 3 then
        ui.box(function(ui)
            ui.padding = 3
            ui.background_color = colors.red
            ui.text(function(ui)
                ui.text =
                "Completement dingo ce truc vous trouvez pas? by the way, il fait beau aujourd'hui d'apres ma carte interractive ahah je marque n'importe quoi \n\n\n hello le monde"
                ui.background_color = colors.blue
            end)
        end)
    elseif mode == 4 then
        ui.scroll(function(ui)
            ui.vertical(function(ui)
                ui.background_color = colors.red
                for i = 1, 50 do
                    ui.button(function(ui)
                        ui.activated_background_color = colors.blue
                        ui.text = "Cuicui, world! (" .. i .. ")"
                    end, true, "l" .. i)
                end
            end)
        end)
    elseif mode == 5 then
        ui.input(function(ui)
            ui.placeholder = "Type something..."
            ui.width = 20
            ui.background_color = colors.blue
            ui.placeholder_color = colors.lightBlue
        end)
    end

    init = false
end)
