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

local flagger       = require("flagger")
local const         = require("cuicui.const")

--- @export
local widget        = {}

widget.PROPS        = {
    spacing = { "number" },
    color = { "number" },
    fill = { "boolean" },
    align = { "number" },
}

widget.IS_CONTAINER = true

function widget.populate_default_props(props)
    props.spacing = props.spacing or 0
    props.fill = props.fill or false
    props.align = props.align or const.ALIGN.LEFT + const.ALIGN.TOP
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

        -- Update height
        data.natural_height = math.max(data.natural_height, child_data.natural_height)

        -- Update width (if first, don't add spacing)
        if first then
            data.natural_width = child_data.natural_width
            first = false
        else
            data.natural_width = data.natural_width + child_data.natural_width + data.spacing
        end
    end
end

function widget.compute_children_layout(props_tree, id)
    local data = props_tree[id]
    local expand_number = 0

    -- Iterate over children to compute the expand number
    for _, child_id in ipairs(data.children) do
        local child_data = props_tree[child_id]

        if child_data.h_expand then
            expand_number = expand_number + 1
        end
    end

    local remaining_width = data.width - data.natural_width
    local expand_width = math.floor(remaining_width / expand_number) -- Size of each expandable child
    local first = true
    local offset = 1

    -- If there are no expandable children, align the children horizontally
    if expand_number == 0 then
        if flagger.test(data.align, const.ALIGN.CENTER) then
            offset = math.floor(remaining_width / 2)
        elseif flagger.test(data.align, const.ALIGN.RIGHT) then
            offset = remaining_width
        end
    end

    -- Iterate over children to compute the layout
    for _, child_id in ipairs(data.children) do
        local child_data = props_tree[child_id]

        if child_data.v_expand then
            child_data.height = data.height
        else
            child_data.height = child_data.natural_height
        end

        if child_data.h_expand then
            child_data.width = child_data.natural_width + expand_width
        else
            child_data.width = child_data.natural_width
        end

        -- Set default y position
        child_data.y = 1

        if flagger.test(data.align, const.ALIGN.HORIZON) then
            child_data.y = 1 + math.floor((data.height - child_data.height) / 2)
        elseif flagger.test(data.align, const.ALIGN.BOTTOM) then
            child_data.y = 1 + data.height - child_data.height
        end

        if first then
            child_data.x = offset
            first = false
        else
            child_data.x = offset + data.spacing
        end

        offset = child_data.x + child_data.width
    end
end

function widget.draw(props_tree, id, term)
    local data = props_tree[id]

    if data.color then
        term.setBackgroundColor(data.color)
        term.clear()
    end
end

function widget.handle_click(props_tree, id, x, y, button)
end

function widget.handle_click_up(props_tree, id, x, y, button)
end

function widget.handle_key(props_tree, id, key, held)
end

function widget.handle_key_up(props_tree, id, key)
end

function widget.handle_lost_focus(props_tree, id)
end

return widget
