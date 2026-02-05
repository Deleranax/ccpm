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

local function make_sch(tree, id)
    function index(self, key)
        if key ~= "start_timer" and key ~= "stop_timer" then
            error("attempt to call field '" .. key .. "' (a nil value)")
        end

        return function(arg)
            -- Make the scheduler
        end
    end

    return setmetatable({}, { __index = index })
end

--- Fire lost focus event recursively
local function fire_lost_focus_recursive(tree, widgets, id, x, y)
    local props = tree.props[id]

    for _, child_id in ipairs(props.children) do
        local child_props = tree.props[child_id]

        if child_props.x > x or x >= child_props.x + child_props.width or
            child_props.y > y or y >= child_props.y + child_props.height then
            fire_lost_focus_recursive(
                tree,
                widgets,
                child_id,
                x - child_props.x,
                y - child_props.y
            )
        end
    end

    widgets[props.type].handle_event(tree.props, id, make_sch(tree, id), { "lost_focus" })
end

--- Fire mouse click event recursively
local function fire_mouse_click_recursive(tree, widgets, id, x, y, click)
    local props = tree.props[id]
    local consumed = false

    for _, child_id in ipairs(props.children) do
        local child_props = tree.props[child_id]
        if child_props.x <= x and x < child_props.x + child_props.width and
            child_props.y <= y and y < child_props.y + child_props.height and
            not consumed then
            if fire_mouse_click_recursive(
                    tree,
                    widgets,
                    child_id,
                    x - child_props.x,
                    y - child_props.y,
                    click
                ) then
                consumed = true
            end
        else
            fire_lost_focus_recursive(
                tree,
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

            widgets[props.type].handle_event(tree.props, id, make_sch(tree, id), evnt)
        else
            widgets[props.type].handle_event(tree.props, id, make_sch(tree, id), { "lost_focus" })
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

        return widgets[props.type].handle_event(tree.props, id, make_sch(tree, id), evnt)
    end
end

--- Fire mouse up event recursively.
local function fire_mouse_up_recursive(tree, widgets, id)
    local props = tree.props[id]

    for _, child_id in ipairs(props.children) do
        fire_mouse_up_recursive(tree, widgets, child_id)
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

        widgets[props.type].handle_event(tree.props, id, make_sch(tree, id), evnt)
    end
end

--- Fire mouse drag event recursively
local function fire_mouse_drag_recursive(tree, widgets, id, x, y, click)
    local props = tree.props[id]
    local consumed = false

    for _, child_id in ipairs(props.children) do
        local child_props = tree.props[child_id]
        if child_props.x <= x and x < child_props.x + child_props.width and
            child_props.y <= y and y < child_props.y + child_props.height and
            not consumed then
            if fire_mouse_drag_recursive(
                    tree,
                    widgets,
                    child_id,
                    x - child_props.x,
                    y - child_props.y,
                    click
                ) then
                consumed = true
            end
        else
            fire_mouse_up_recursive(
                tree,
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

            widgets[props.type].handle_event(tree.props, id, make_sch(tree, id), evnt)
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

        return widgets[props.type].handle_event(tree.props, id, make_sch(tree, id), evnt)
    end
end

local function fire_key_recursive(tree, widgets, id, key, held)
    local props = tree.props[id]
    local consumed = false

    for _, child_id in ipairs(props.children) do
        if fire_key_recursive(
                tree,
                widgets,
                child_id,
                key,
                held
            ) then
            consumed = true
            break
        end
    end

    if consumed then
        -- If consumed but pressed
        if props.keys and props.keys[key] then
            local evnt = {
                "key_up",
                key
            }

            props.keys[key] = nil

            widgets[props.type].handle_event(tree.props, id, make_sch(tree, id), evnt)
        end
        return true
    else
        local evnt = {
            "key",
            key,
            held
        }

        props.keys = props.keys or {}
        props.keys[key] = true

        return widgets[props.type].handle_event(tree.props, id, make_sch(tree, id), evnt)
    end
end

local function fire_key_up_recursive(tree, widgets, id, key)
    local props = tree.props[id]

    for _, child_id in ipairs(props.children) do
        fire_key_up_recursive(tree, widgets, child_id, key)
    end

    if props.keys and props.keys[key] then
        local evnt = {
            "key_up",
            key
        }

        props.keys[key] = nil

        widgets[props.type].handle_event(tree.props, id, make_sch(tree, id), evnt)
    end
end

--- Process events until the UI needs to be updated.
--- @param tree table: The UI tree.
--- @param widgets table: The widgets table.
--- @param root_props table: The root widget properties.
--- @param monitor_name string | nil: The name of the monitor to listen for touch events
--- @return boolean: True if the program should continue running, false if it should terminate
function event.process(tree, widgets, root_props, monitor_name)
    while true do
        local evnt = { os.pullEventRaw() }

        if evnt[1] == "terminate" then
            return false
        elseif evnt[1] == "timer" then
            if click_timers[evnt[2]] then
                click_timers[evnt[2]] = nil
                fire_mouse_up_recursive(tree, widgets, root_props.id)
                return true
            end
        elseif evnt[1] == "monitor_touch" and evnt[2] == monitor_name then
            click_timers[os.startTimer(0.5)] = true
            fire_mouse_click_recursive(tree, widgets, root_props.id, evnt[3], evnt[4], 1)
            return true
        elseif evnt[1] == "mouse_click" then
            fire_mouse_click_recursive(tree, widgets, root_props.id, evnt[3], evnt[4], evnt[2])
            return true
        elseif evnt[1] == "mouse_up" then
            fire_mouse_up_recursive(tree, widgets, root_props.id)
            return true
        elseif evnt[1] == "mouse_drag" then
            fire_mouse_drag_recursive(tree, widgets, root_props.id, evnt[3], evnt[4], evnt[2])
            return true
        elseif evnt[1] == "key" then
            fire_key_recursive(tree, widgets, root_props.id, evnt[2], evnt[3])
            return true
        elseif evnt[1] == "key_up" then
            fire_key_up_recursive(tree, widgets, root_props.id, evnt[2])
            return true
        end
    end
end

return event
