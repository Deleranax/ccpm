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

local expect = require("cc.expect")

--- @export
local event = {}

local click_timers = {}
local timers = {}
local alarms = {}

local function make_sch(id)
    function index(_, key)
        return function(arg)
            expect(1, arg, "number")
            if key == "start_timer" then
                local timer_id = os.startTimer(arg)
                timers[timer_id] = id
                return timer_id
            elseif key == "cancel_timer" then
                if timers[arg] then
                    timers[arg] = nil
                    os.cancelTimer(arg)
                end
            elseif key == "set_alarm" then
                local alarm_id = os.setAlarm(arg)
                alarms[alarm_id] = id
                return alarm_id
            elseif key == "cancel_alarm" then
                if alarms[arg] then
                    alarms[arg] = nil
                    os.cancelAlarm(arg)
                end
            else
                error("Unknown scheduler method: " .. key, 2)
            end
        end
    end

    return setmetatable({}, { __index = index })
end

--- Fire lost focus event recursively
local function fire_lost_focus_recursive(tree, widgets, id, x, y)
    local props = tree.props[id]

    for _, child_id in ipairs(props.children) do
        local child_buffer = tree.buffer[child_id]

        if child_buffer.x > x or x >= child_buffer.x + child_buffer.width or
            child_buffer.y > y or y >= child_buffer.y + child_buffer.height then
            fire_lost_focus_recursive(
                tree,
                widgets,
                child_id,
                x,
                y
            )
        end
    end

    widgets[props.type].handle_event(tree.props, tree.render, tree.event, id, make_sch(id), { "lost_focus" })
end

--- Fire mouse click event recursively
local function fire_mouse_click_recursive(tree, widgets, id, buffer, x, y, click)
    local props = tree.props[id]
    local event_data = tree.event[id]
    local consumed = false
    local rel_x = x - buffer.x + 1
    local rel_y = y - buffer.y + 1

    for _, child_id in ipairs(props.children) do
        local child_buffer = tree.buffer[child_id]

        if child_buffer.x <= x and x < child_buffer.x + child_buffer.width and
            child_buffer.y <= y and y < child_buffer.y + child_buffer.height and
            not consumed then
            if fire_mouse_click_recursive(
                    tree,
                    widgets,
                    child_id,
                    child_buffer,
                    x,
                    y,
                    click
                ) then
                consumed = true
            end
        else
            fire_lost_focus_recursive(
                tree,
                widgets,
                child_id,
                x,
                y
            )
        end
    end

    if consumed then
        -- If consumed but clicked
        if event_data.click then
            local evnt = {
                "mouse_up",
                event_data.click,
                event_data.cursor[1],
                event_data.cursor[2]
            }

            event_data.click = nil
            event_data.cursor = nil

            widgets[props.type].handle_event(tree.props, tree.render, tree.event, id, make_sch(id), evnt)
        else
            tree.event[id] = {}
            widgets[props.type].handle_event(tree.props, tree.render, tree.event, id, make_sch(id), { "lost_focus" })
        end
        return true
    else
        local evnt = {
            "mouse_click",
            click,
            rel_x, rel_y
        }

        event_data.click = click
        event_data.cursor = { rel_x, rel_y }
        tree.event[id] = event_data

        return widgets[props.type].handle_event(tree.props, tree.render, tree.event, id, make_sch(id), evnt)
    end
end

--- Fire mouse up event recursively.
local function fire_mouse_up_recursive(tree, widgets, id)
    local props = tree.props[id]
    local event_data = tree.event[id]

    for _, child_id in ipairs(props.children) do
        fire_mouse_up_recursive(tree, widgets, child_id)
    end

    if event_data.click then
        local evnt = {
            "mouse_up",
            event_data.click,
            event_data.cursor[1],
            event_data.cursor[2]
        }

        event_data.click = nil
        event_data.cursor = nil

        widgets[props.type].handle_event(tree.props, tree.render, tree.event, id, make_sch(id), evnt)
    end
end

local function fire_mouse_scroll_recursive(tree, widgets, id, buffer, x, y, direction)
    local props = tree.props[id]
    local consumed = false
    local rel_x = x - buffer.x + 1
    local rel_y = y - buffer.y + 1

    for _, child_id in ipairs(props.children) do
        local child_buffer = tree.buffer[child_id]
        if child_buffer.x <= x and x < child_buffer.x + child_buffer.width and
            child_buffer.y <= y and y < child_buffer.y + child_buffer.height and
            not consumed then
            if fire_mouse_scroll_recursive(
                    tree,
                    widgets,
                    child_id,
                    child_buffer,
                    x,
                    y,
                    direction
                ) then
                consumed = true
            end
        end
    end

    if not consumed then
        local evnt = {
            "mouse_scroll",
            direction,
            rel_x, rel_y
        }

        return widgets[props.type].handle_event(tree.props, tree.render, tree.event, id, make_sch(id), evnt)
    else
        return true
    end
end

--- Fire mouse drag event recursively
local function fire_mouse_drag_recursive(tree, widgets, id, buffer, x, y, click)
    local props = tree.props[id]
    local event_data = tree.event[id]
    local consumed = false
    local rel_x = x - buffer.x + 1
    local rel_y = y - buffer.y + 1

    for _, child_id in ipairs(props.children) do
        local child_buffer = tree.buffer[child_id]
        if child_buffer.x <= x and x < child_buffer.x + child_buffer.width and
            child_buffer.y <= y and y < child_buffer.y + child_buffer.height and
            not consumed then
            if fire_mouse_drag_recursive(
                    tree,
                    widgets,
                    child_id,
                    child_buffer,
                    x,
                    y,
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
        if event_data.click then
            local rel_x = event_data.cursor[1] - buffer.x + 1
            local rel_y = event_data.cursor[2] - buffer.y + 1
            local evnt = {
                "mouse_up",
                event_data.click,
                rel_x,
                rel_y
            }

            event_data.click = nil
            event_data.cursor = nil

            widgets[props.type].handle_event(tree.props, tree.render, tree.event, id, make_sch(id), evnt)
        end
        return true
    else
        local evnt = {}

        -- Change if the widget is clicked
        if event_data.click then
            local dx = rel_x - event_data.cursor[1]
            local dy = rel_y - event_data.cursor[2]

            evnt = {
                "mouse_drag",
                click,
                x, y,
                dx, dy
            }
        else
            evnt = {
                "mouse_click",
                click,
                x, y
            }
        end

        event_data.click = click
        event_data.cursor = { rel_x, rel_y }

        return widgets[props.type].handle_event(tree.props, tree.render, tree.event, id, make_sch(id), evnt)
    end
end

local function fire_key_recursive(tree, widgets, id, key, held)
    local props = tree.props[id]
    local event_data = tree.event[id]
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
        if event_data.keys and event_data.keys[key] then
            local evnt = {
                "key_up",
                key
            }

            event_data.keys[key] = nil

            widgets[props.type].handle_event(tree.props, tree.render, tree.event, id, make_sch(id), evnt)
        end
        return true
    else
        local evnt = {
            "key",
            key,
            held
        }

        event_data.keys = event_data.keys or {}
        event_data.keys[key] = true

        return widgets[props.type].handle_event(tree.props, tree.render, tree.event, id, make_sch(id), evnt)
    end
end

local function fire_key_up_recursive(tree, widgets, id, key)
    local props = tree.props[id]
    local event_data = tree.event[id]

    for _, child_id in ipairs(props.children) do
        fire_key_up_recursive(tree, widgets, child_id, key)
    end

    if event_data.keys and event_data.keys[key] then
        local evnt = {
            "key_up",
            key
        }

        event_data.keys[key] = nil

        widgets[props.type].handle_event(tree.props, tree.render, tree.event, id, make_sch(id), evnt)
    end
end

local function fire_char_recursive(tree, widgets, id, character)
    local props = tree.props[id]
    local consumed = false

    for _, child_id in ipairs(props.children) do
        if fire_char_recursive(
                tree,
                widgets,
                child_id,
                character
            ) then
            consumed = true
            break
        end
    end

    if not consumed then
        local evnt = {
            "char",
            character
        }

        return widgets[props.type].handle_event(tree.props, tree.render, tree.event, id, make_sch(id), evnt)
    else
        return true
    end
end

--- Process events until the UI needs to be updated.
--- @param tree table: The UI tree.
--- @param widgets table: The widgets table.
--- @param root_props table: The root widget properties.
--- @param monitor_name string | nil: The name of the monitor to listen for touch events
--- @param event_handler function | nil: A custom event handler function.
--- @return boolean: True if the program should continue running, false if it should terminate
function event.process(tree, widgets, root_props, monitor_name, event_handler)
    while true do
        local evnt = { os.pullEventRaw() }

        if evnt[1] == "terminate" then
            return false
        elseif evnt[1] == "timer" then
            if click_timers[evnt[2]] then
                click_timers[evnt[2]] = nil
                fire_mouse_up_recursive(tree, widgets, root_props.id)
                return true
            elseif timers[evnt[2]] then
                local props = tree.props[timers[evnt[2]]]
                timers[evnt[2]] = nil
                if props then
                    widgets[props.type].handle_event(
                        tree.props,
                        tree.render,
                        tree.event,
                        props.id,
                        make_sch(props.id),
                        { "timer", evnt[2] }
                    )
                    return true
                end
            elseif alarms[evnt[2]] then
                local props = tree.props[alarms[evnt[2]]]
                alarms[evnt[2]] = nil
                if props then
                    widgets[props.type].handle_event(
                        tree.props,
                        tree.render,
                        tree.event,
                        props.id,
                        make_sch(props.id),
                        { "alarm", evnt[2] }
                    )
                    return true
                end
            end
        elseif evnt[1] == "monitor_touch" and evnt[2] == monitor_name then
            click_timers[os.startTimer(0.5)] = true
            fire_mouse_click_recursive(
                tree,
                widgets,
                root_props.id,
                tree.render[root_props.id],
                evnt[3], evnt[4], 1
            )
            return true
        elseif evnt[1] == "mouse_scroll" then
            fire_mouse_scroll_recursive(
                tree,
                widgets,
                root_props.id,
                tree.render[root_props.id],
                evnt[3], evnt[4], evnt[2]
            )
            return true
        elseif evnt[1] == "mouse_click" then
            fire_mouse_click_recursive(
                tree,
                widgets,
                root_props.id,
                tree.render[root_props.id],
                evnt[3], evnt[4], evnt[2]
            )
            return true
        elseif evnt[1] == "mouse_up" then
            fire_mouse_up_recursive(tree, widgets, root_props.id)
            return true
        elseif evnt[1] == "mouse_drag" then
            fire_mouse_drag_recursive(
                tree,
                widgets,
                root_props.id,
                tree.render[root_props.id],
                evnt[3], evnt[4], evnt[2])
            return true
        elseif evnt[1] == "key" then
            fire_key_recursive(
                tree,
                widgets,
                root_props.id,
                evnt[2], evnt[3]
            )
            return true
        elseif evnt[1] == "key_up" then
            fire_key_up_recursive(
                tree,
                widgets,
                root_props.id,
                evnt[2]
            )
            return true
        elseif evnt[1] == "char" then
            fire_char_recursive(
                tree,
                widgets,
                root_props.id,
                evnt[2]
            )
            return true
        else
            if event_handler then
                if event_handler(evnt) then
                    return true
                end
            end
        end
    end
end

return event
