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

--- @export
local event = {}

local click_timers = {}

--- Fire the "click", "lost_focus" events.
local function fire_click_events(props_tree, render_tree, widgets, x, y, button)
    for id, data in pairs(props_tree) do
        local render = render_tree[id]
        local widget = widgets[data.type]

        if render.x <= x and x < render.x + render.width and
            render.y <= y and y < render.y + render.height then
            data.click = button
            widget.handle_click(props_tree, id, x - render.x + 1, y - render.y + 1, button)
        elseif data.focus then
            data.focus = nil
            widget.handle_lost_focus(props_tree, id)
        end
    end
end

local function fire_click_up_events(props_tree, render_tree, widgets, x, y, button)
    for id, data in pairs(props_tree) do
        local render = render_tree[id]
        local widget = widgets[data.type]

        if render.x <= x and x < render.x + render.width and
            render.y <= y and y < render.y + render.height then
            data.click = nil
            widget.handle_click_up(props_tree, id, x - render.x + 1, y - render.y + 1, button)
        elseif data.click then
            data.click = nil
            widget.handle_click_up(props_tree, id, 0, 0, button)
        end
    end
end

local function fire_key_events(props_tree, widgets, key, held)
    for id, props in pairs(props_tree) do
        local widget = widgets[props.type]

        widget.handle_key(props_tree, id, key, held)
    end
end

local function fire_key_up_events(props_tree, widgets, key)
    for id, props in pairs(props_tree) do
        local widget = widgets[props.type]

        widget.handle_key_up(props_tree, id, key)
    end
end

--- Process events until the UI needs to be updated.
--- @param props_tree table: The properties tree of the UI
--- @param render_tree table: The render tree of the UI
--- @param widgets table: The widgets table of the UI
--- @param monitor_name string | nil: The name of the monitor to listen for touch events
--- @return boolean: True if the program should continue running, false if it should terminate
function event.process(props_tree, render_tree, widgets, monitor_name)
    while true do
        local event = { os.pullEventRaw() }

        if event[1] == "terminate" then
            return false
        elseif event[1] == "timer" then
            local coords = click_timers[event[2]]
            if coords then
                click_timers[event[2]] = nil
                fire_click_up_events(props_tree, render_tree, widgets, coords.x, coords.y, 1)
                return true
            end
        elseif event[1] == "monitor_touch" and event[2] == monitor_name then
            click_timers[os.startTimer(0.5)] = { x = event[3], y = event[4] }
            fire_click_events(props_tree, render_tree, widgets, event[3], event[4], 1)
            return true
        elseif event[1] == "mouse_click" then
            fire_click_events(props_tree, render_tree, widgets, event[3], event[4], event[2])
            return true
        elseif event[1] == "mouse_up" then
            fire_click_up_events(props_tree, render_tree, widgets, event[3], event[4], event[2])
            return true
        elseif event[1] == "key" then
            fire_key_events(props_tree, widgets, event[2], event[3])
            return true
        elseif event[1] == "key_up" then
            fire_key_up_events(props_tree, widgets, event[2])
            return true
        end
    end
end

return event
