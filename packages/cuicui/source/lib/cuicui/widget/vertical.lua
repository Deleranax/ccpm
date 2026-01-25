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
local widget = {}

widget.PROPS = {
    spacing = { "number" },
    color = { "number" },
    fill = { "boolean" },
    align = { "string" },
}

widget.IS_CONTAINER = true

function widget.populate_default_props(props)
    props.spacing = props.spacing or 0
    props.fill = props.fill or false
    props.align = props.align or "left"
end

function widget.compute_natural_size(props_tree, id)
    local data = props_tree[id]
    local first = true

    -- Set default width and height
    data.natural_width = 0
    data.natural_height = 0

    -- Iterate over children to compute the size
    for _, child_id in ipairs(data.children) do
        -- Get child data
        local child_data = props_tree[child_id]

        -- Update width
        data.natural_width = math.max(data.natural_width, child_data.natural_width)

        -- Update height (if first, don't add spacing)
        if first then
            data.natural_height = child_data.natural_height
            first = false
        else
            data.natural_height = data.natural_height + child_data.natural_height + data.spacing
        end
    end
end

function widget.compute_children_layout(props_tree, id)
    local data = props_tree[id]
    local expand_number = 0

    -- Iterate over children to compute the expand number
    for _, child_id in ipairs(data.children) do
        local child_data = props_tree[child_id]

        if child_data.v_expand then
            expand_number = expand_number + 1
        end
    end

    -- The expand height is the final height minus the current height plus one, divided by the expand number
    -- It is the free space available for expansion divided by the number of expandable children
    local expand_height = math.floor((data.height - data.natural_height + 1) / expand_number)
    local first = true
    local offset = 0

    -- Iterate over children to compute the layout
    for _, child_id in ipairs(data.children) do
        local child_data = props_tree[child_id]

        if child_data.h_expand then
            child_data.width = data.width
        else
            child_data.width = child_data.natural_width
        end

        if child_data.v_expand then
            child_data.height = expand_height
        else
            child_data.height = child_data.natural_height
        end

        -- Set default x position
        child_data.x = 1

        if data.align == "center" then
            child_data.x = 1 + math.floor((data.width - child_data.width) / 2)
        elseif data.align == "right" then
            child_data.x = 1 + data.width - child_data.width
        end

        if first then
            child_data.y = 1
            first = false
        else
            child_data.y = offset + data.spacing
        end

        offset = child_data.y + child_data.height
    end
end

function widget.draw(props_tree, id, term)
    local data = props_tree[id]

    if data.color then
        term.setBackgroundColor(data.color)
        term.clear()
    end
end

function widget.handle_click(props_tree, id, x, y)
end

function widget.handle_key(props_tree, id, key)
end

function widget.handle_key_up(props_tree, id, key)
end

function widget.handle_focus_lost(props_tree, id)
end

return widget
