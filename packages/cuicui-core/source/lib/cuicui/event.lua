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
local event = {}

local click_timers = {}
local timers = {}

local function make_sch(render_tree, id)
    function index(self, key)
        if key ~= "start_timer" and key ~= "stop_timer" then
            error("attempt to call field '" .. key .. "' (a nil value)")
        end

        return function(arg)

        end
    end

    return setmetatable({}, { __index = index })
end

--- Fire lost focus event recursively
local function fire_lost_focus_recursive(props_tree, render_tree, widgets, id, x, y)
    local props = props_tree[id]

    for _, child_id in ipairs(props.children) do
        local child_props = props_tree[child_id]

        if child_props.x > x or x >= child_props.x + child_props.width and
            child_props.y > y or y >= child_props.y + child_props.height then
            fire_lost_focus_recursive(
                props_tree,
                render_tree,
                widgets,
                child_id,
                x - child_props.x,
                y - child_props.y
            )
        end
    end

    widgets[props.type].handle_event(props_tree, id, make_sch(render_tree, id), { "lost_focus" })
end

--- Fire mouse click event recursively
local function fire_mouse_click_recursive(props_tree, render_tree, widgets, id, x, y, click)
    local props = props_tree[id]
    local consumed = false

    for _, child_id in ipairs(props.children) do
        local child_props = props_tree[child_id]
        if child_props.x <= x and x < child_props.x + child_props.width and
            child_props.y <= y and y < child_props.y + child_props.height then
            if fire_mouse_click_recursive(
                    props_tree,
                    render_tree,
                    widgets,
                    child_id,
                    x - child_props.x,
                    y - child_props.y,
                    click
                ) then
                consumed = true
                break
            end
        else
            fire_lost_focus_recursive(
                props_tree,
                render_tree,
                widgets,
                child_id,
                x - child_props.x,
                y - child_props.y
            )
        end
    end

    if consumed then
        -- If consumed but clicked
        if props.click then
            local evnt = {
                "mouse_up",
                props.click,
                props.cursor[1],
                props.cursor[2]
            }

            props.click = nil
            props.cursor = nil

            widgets[props.type].handle_event(props_tree, id, make_sch(render_tree, id), evnt)
        end
        return true
    else
        local evnt = {
            "mouse_click",
            click,
            x, y
        }

        props.click = click
        props.cursor = { x, y }

        return widgets[props.type].handle_event(props_tree, id, make_sch(render_tree, id), evnt)
    end
end

--- Fire mouse up event recursively.
local function fire_mouse_up_recursive(props_tree, render_tree, widgets, id)
    local props = props_tree[id]

    for _, child_id in ipairs(props.children) do
        fire_mouse_up_recursive(props_tree, render_tree, widgets, child_id)
    end

    if props.click then
        local evnt = {
            "mouse_up",
            props.click,
            props.cursor[1],
            props.cursor[2]
        }

        props.click = nil
        props.cursor = nil

        widgets[props.type].handle_event(props_tree, id, make_sch(render_tree, id), evnt)
    end
end

--- Fire mouse drag event recursively
local function fire_mouse_drag_recursive(props_tree, render_tree, widgets, id, x, y, click)
    local props = props_tree[id]
    local consumed = false

    for _, child_id in ipairs(props.children) do
        local child_props = props_tree[child_id]
        if child_props.x <= x and x < child_props.x + child_props.width and
            child_props.y <= y and y < child_props.y + child_props.height then
            if fire_mouse_drag_recursive(
                    props_tree,
                    render_tree,
                    widgets,
                    child_id,
                    x - child_props.x,
                    y - child_props.y,
                    click
                ) then
                consumed = true
                break
            end
        else
            fire_mouse_up_recursive(
                props_tree,
                render_tree,
                widgets,
                child_id
            )
        end
    end

    if consumed then
        -- If consumed but clicked
        if props.click then
            local evnt = {
                "mouse_up",
                props.click,
                props.cursor[1],
                props.cursor[2]
            }

            props.click = nil
            props.cursor = nil

            widgets[props.type].handle_event(props_tree, id, make_sch(render_tree, id), evnt)
        end
        return true
    else
        local evnt = {}

        -- Change if the widget is clicked
        if props.click then
            evnt = {
                "mouse_drag",
                click,
                x, y
            }
        else
            evnt = {
                "mouse_click",
                click,
                x, y
            }
        end

        props.click = click
        props.cursor = { x, y }

        return widgets[props.type].handle_event(props_tree, id, make_sch(render_tree, id), evnt)
    end
end

--- Process events until the UI needs to be updated.
--- @param props_tree table: The properties tree of the UI
--- @param render_tree table: The render tree of the UI
--- @param widgets table: The widgets table of the UI
--- @param root_props table: The root widget properties of the UI
--- @param monitor_name string | nil: The name of the monitor to listen for touch events
--- @return boolean: True if the program should continue running, false if it should terminate
function event.process(props_tree, render_tree, widgets, root_props, monitor_name)
    while true do
        local evnt = { os.pullEventRaw() }

        if evnt[1] == "terminate" then
            return false
        elseif evnt[1] == "timer" then
            if click_timers[evnt[2]] then
                click_timers[evnt[2]] = nil
                fire_mouse_up_recursive(props_tree, render_tree, widgets, root_props.id)
                return true
            end
        elseif evnt[1] == "monitor_touch" and evnt[2] == monitor_name then
            click_timers[os.startTimer(0.5)] = true
            fire_mouse_click_recursive(props_tree, render_tree, widgets, root_props.id, evnt[3], evnt[4], 1)
            return true
        elseif evnt[1] == "mouse_click" then
            fire_mouse_click_recursive(props_tree, render_tree, widgets, root_props.id, evnt[3], evnt[4], evnt[2])
            return true
        elseif evnt[1] == "mouse_up" then
            fire_mouse_up_recursive(props_tree, render_tree, widgets, root_props.id)
            return true
        elseif evnt[1] == "mouse_drag" then
            fire_mouse_drag_recursive(props_tree, render_tree, widgets, root_props.id, evnt[3], evnt[4], evnt[2])
            return true
        elseif evnt[1] == "key" then
            return true
        elseif evnt[1] == "key_up" then
            return true
        end
    end
end

return event
