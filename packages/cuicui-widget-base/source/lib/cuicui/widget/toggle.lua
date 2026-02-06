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

function widget.populate_default_props(props, old_props, event)
    props.active = false
    props.deactivated_color = colors.gray
    props.activated_color = colors.lightBlue
    props.background_color = colors.lightGray
    props.align_right = false

    if old_props then
        props.active = old_props.active
    end

    -- Apply event-driven state changes
    if event and event.active ~= nil then
        props.active = event.active
    end
end

function widget.accept_child(props_tree, id, child_props)
    return "Toggles cannot have children"
end

function widget.compose(props, ui)
end

function widget.compute_natural_size(props_tree, render_tree, id)
    local layout = render_tree[id]

    layout.natural_width = 2
    layout.natural_height = 1
end

function widget.compute_children_layout(props_tree, render_tree, id)
    -- Only used for containers
end

local function draw_left(term, circle_color, dot_color, background_color)
    term.blit("\136\149", colors.toBlit(dot_color) .. colors.toBlit(circle_color),
        colors.toBlit(circle_color) .. colors.toBlit(background_color))
end

local function draw_right(term, circle_color, dot_color, background_color)
    term.blit("\149\132", colors.toBlit(background_color) .. colors.toBlit(dot_color),
        colors.toBlit(circle_color) .. colors.toBlit(circle_color))
end

function widget.draw(props_tree, render_tree, id, term)
    local props = props_tree[id]

    -- Compute the color based on the activation state
    term.setCursorPos(1, 1)
    if props.active then
        if props.align_right then
            draw_right(term, props.activated_color, props.deactivated_color, props.background_color)
        else
            draw_left(term, props.activated_color, props.deactivated_color, props.background_color)
        end
    else
        if props.align_right then
            draw_right(term, props.deactivated_color, props.background_color, props.background_color)
        else
            draw_left(term, props.deactivated_color, props.background_color, props.background_color)
        end
    end
end

function widget.handle_event(props_tree, event_tree, id, sch, event)
    if event[1] == "mouse_click" then
        local props = props_tree[id]

        event_tree[id].active = not props.active
        return true
    end
end

return widget
