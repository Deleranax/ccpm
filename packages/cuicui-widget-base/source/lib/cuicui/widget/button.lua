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

local label = require("cuicui.widget.label")

-- DOC HERE

--- @export
local widget = {}

widget.PROPS = {
    active = { "boolean" },
    text = { "string" },
    color = { "number" },
    background_color = { "number" },
    activated_color = { "number", "nil" },
    activated_background_color = { "number", "nil" }
}

function widget.populate_default_props(props, old_props, event)
    props.active = false
    props.text = "Button #" .. props.id
    props.color = colors.white

    if old_props then
        props.active = old_props.active
    end

    if event and event.active ~= nil then
        props.active = event.active
        event.active = nil
    end
end

function widget.accept_child(parent_props, child_props)
    return "Buttons cannot have children"
end

function widget.compute_children_max_size(props_tree, render_tree, id)
    -- Only used for containers
end

function widget.compose(props, ui)
end

function widget.compute_natural_size(props_tree, render_tree, id)
    local props = props_tree[id]
    local layout = render_tree[id]

    local natural_width = #props.text
    local natural_height = 1

    -- Respect max size constraints if set
    if layout.max_width then
        natural_width = math.min(natural_width, layout.max_width)
    end
    if layout.max_height then
        natural_height = math.min(natural_height, layout.max_height)
    end

    layout.natural_width = natural_width
    layout.natural_height = natural_height
end

function widget.compute_children_layout(props_tree, render_tree, id)
    -- Only used for containers
end

function widget.draw(props_tree, render_tree, id, term)
    local props = props_tree[id]

    if props.active then
        term.setBackgroundColor(props.activated_background_color or props.background_color)
        term.clear()

        term.setCursorPos(1, 1)
        term.setTextColor(props.activated_color or props.color)
        term.write(props.text)
    else
        term.setBackgroundColor(props.background_color)
        term.clear()

        term.setCursorPos(1, 1)
        term.setTextColor(props.color)
        term.write(props.text)
    end
end

function widget.handle_event(props_tree, render_tree, event_tree, id, sch, event)
    if event[1] == "mouse_click" then
        event_tree[id].active = true
        return true
    elseif event[1] == "mouse_up" then
        event_tree[id].active = false
        return true
    elseif event[1] == "mouse_drag" then
        return true
    end
end

return widget
