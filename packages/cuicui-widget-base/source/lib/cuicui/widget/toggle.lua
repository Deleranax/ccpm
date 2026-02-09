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

--- Toggle widget - an interactive switch that can be clicked to toggle between active/inactive states.
---
--- A clickable toggle switch with visual feedback. Toggles can work independently or be grouped together
--- to create radio button behavior where only one toggle in a group can be active at a time.
--- When clicked, an active toggle in a group cannot be deactivated directly.
---
--- **Properties:**
--- - `active` (boolean): Whether the toggle is currently active (default: false)
--- - `group` (string, optional): Group name for radio button behavior. Toggles with the same group name
---   will be mutually exclusive - activating one deactivates others in the group
--- - `deactivated_color` (number): Color when toggle is inactive (default: colors.gray)
--- - `activated_color` (number): Color when toggle is active (default: colors.lightBlue)
--- - `background_color` (number): Background color for the inactive side (default: colors.lightGray)
--- - `align_right` (boolean): If true, the active indicator appears on the right side (default: false)
---
--- The toggle has a fixed size of 2x1 characters and cannot contain child widgets.
---
--- **Example:**
--- ```lua
--- ui.toggle(function(ui)
---     ui.active = true
---     ui.activated_color = colors.green
---     ui.deactivated_color = colors.red
---     ui.align_right = false
--- end)
---
--- -- Radio button group example
--- ui.toggle(function(ui)
---     ui.group = "options"
---     if init then ui.active = true end
--- end)
--- ui.toggle(function(ui)
---     ui.group = "options"
--- end)
--- ```

--- @export
local widget = {}

widget.PROPS = {
    active = { "boolean" },
    group = { "string", "nil" },
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
        event.active = nil
    end
end

function widget.compose(props, ui)
end

function widget.accept_child(parent_props, child_props)
    return "Toggles cannot have children"
end

function widget.compute_children_max_size(props_tree, render_tree, id)
    -- Only used for containers
end

function widget.compute_natural_size(props_tree, render_tree, id)
    local layout = render_tree[id]

    local natural_width = 2
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

function widget.handle_event(props_tree, render_tree, event_tree, id, sch, event)
    if event[1] == "mouse_click" then
        local props = props_tree[id]

        if props.active then
            if not props.group then
                event_tree[id].active = false
            end
        else
            if props.group then
                for other_id, other_props in pairs(props_tree) do
                    if other_props.type == "toggle" then
                        if other_props.group == props.group then
                            event_tree[other_id].active = false
                        end
                    end
                end
            end

            event_tree[id].active = true
        end
        return true
    elseif event[1] == "mouse_up" then
        return true
    elseif event[1] == "mouse_drag" then
        return true
    end
end

return widget
