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

-- TODO: Add the toggle group system

--- @export
local widget = {}

widget.PROPS = {
    active = { "boolean" },
    deactivated_color = { "number" },
    activated_color = { "number" },
    background_color = { "number" },
    align_right = { "boolean" }
}

function widget.populate_default_props(props, old_props)
    props.active = false
    props.deactivated_color = colors.gray
    props.activated_color = colors.lightBlue
    props.background_color = colors.lightGray
    props.align_right = false

    if old_props then
        props.active = old_props.active
    end
end

function widget.accept_child(props_tree, id, child_props)
    return "Toggles cannot have children"
end

function widget.compose(props, ui)
end

function widget.compute_natural_size(props_tree, id)
    local data = props_tree[id]

    data.natural_width = 2
    data.natural_height = 1
end

function widget.compute_children_layout(props_tree, id)
    -- Only used for containers
end

local function draw_left(term, circle_color, dot_color, background_color)
    term.setBackgroundColor(circle_color)
    term.setTextColor(dot_color)
    term.write("\136")
    term.setBackgroundColor(background_color)
    term.setTextColor(circle_color)
    term.write("\149")
end

local function draw_right(term, circle_color, dot_color, background_color)
    term.setBackgroundColor(circle_color)
    term.setTextColor(background_color)
    term.write("\149")
    term.setBackgroundColor(circle_color)
    term.setTextColor(dot_color)
    term.write("\132")
end

function widget.draw(props_tree, id, term)
    local data = props_tree[id]

    -- Compute the color based on the activation state
    term.setCursorPos(1, 1)
    if data.active then
        if data.align_right then
            draw_right(term, data.activated_color, data.deactivated_color, data.background_color)
        else
            draw_left(term, data.activated_color, data.deactivated_color, data.background_color)
        end
    else
        if data.align_right then
            draw_right(term, data.deactivated_color, data.background_color, data.background_color)
        else
            draw_left(term, data.deactivated_color, data.background_color, data.background_color)
        end
    end
end

function widget.handle_event(props_tree, id, sch, event)
    if event[1] == "mouse_click" then
        local data = props_tree[id]

        data.active = not data.active
    end
end

return widget
