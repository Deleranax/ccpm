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

local utils   = require "cuicui.utils"
local flagger = require("flagger")
local const   = require("cuicui.const")

--- Box widget - a container for a single child with padding and optional fixed size.
---
--- Useful for adding spacing around widgets or enforcing specific dimensions. The box can only
--- contain one child widget. Use `padding` to add space inside the box (between the border and
--- the child).
---
--- **Properties:**
--- - `fixed_width` (number, optional): Fixed width for the box. If not set, size adapts to child + padding
--- - `fixed_height` (number, optional): Fixed height for the box. If not set, size adapts to child + padding
--- - `padding` (number or table): Space inside the box around the child. Can be a single number for all sides,
---   or a table with `{top, right, bottom, left}`, `{top=N, right=N, bottom=N, left=N}`, or `{x=N, y=N}`
--- - `align` (number): Alignment flags using `const.ALIGN` constants (default: LEFT + TOP)
---   - Horizontal: `ALIGN.LEFT`, `ALIGN.CENTER`, `ALIGN.RIGHT`
---   - Vertical: `ALIGN.TOP`, `ALIGN.HORIZON` (center), `ALIGN.BOTTOM`
---   - Combine with `+` operator (e.g., `const.ALIGN.CENTER + const.ALIGN.HORIZON`)
--- - `color` (number, optional): Background color for the box area
---
--- **Example:**
--- ```lua
--- ui.box(function(ui)
---     ui.padding = 2  -- 2 pixels padding on all sides
---     ui.align = const.ALIGN.CENTER + const.ALIGN.HORIZON
---     ui.color = colors.gray
---     ui.label(function(ui)
---         ui.text = "Padded label"
---     end)
--- end)
--- ```

--- @export
local widget  = {}

widget.PROPS  = {
    fixed_width = { "number", "nil" },
    fixed_height = { "number", "nil" },
    padding = { "number", "table" },
    align = { "number" },
    color = { "number", "nil" }
}

function widget.populate_default_props(props, old_props)
    props.padding = 0
    props.align = const.ALIGN.LEFT + const.ALIGN.TOP
end

function widget.accept_child(props_tree, id, child_props)
    local data = props_tree[id]

    if #data.children > 0 then
        return "Box can only have a single child"
    end
end

function widget.compose(props, old_props, ui)
    -- Flatten the rect vars
    props.padding = utils.compute_rect_vars(props.padding)
end

function widget.compute_natural_size(props_tree, id)
    local data = props_tree[id]

    local child_width = 0
    local child_height = 0

    -- If the child exists, get its natural size
    if #data.children > 0 then
        local child_data = props_tree[data.children[1]]

        child_width = child_data.natural_width
        child_height = child_data.natural_height
    end

    -- Compute the box's natural width
    if data.fixed_width then
        data.natural_width = data.fixed_width
    else
        data.natural_width = data.padding.left + child_width + data.padding.right
    end

    -- Compute the box's natural height
    if data.fixed_height then
        data.natural_height = data.fixed_height
    else
        data.natural_height = data.padding.top + child_height + data.padding.bottom
    end
end

function widget.compute_children_layout(props_tree, id)
    local data = props_tree[id]

    if #data.children > 0 then
        local child_data = props_tree[data.children[1]]

        -- Compute the child's size
        child_data.width = math.min(child_data.natural_width, data.width - data.padding.left - data.padding.right)
        child_data.height = math.min(child_data.natural_height, data.height - data.padding.top - data.padding.bottom)

        -- Compute the child's position with alignment
        local available_width = data.width - data.padding.left - data.padding.right
        local available_height = data.height - data.padding.top - data.padding.bottom

        -- Horizontal alignment
        if flagger.test(data.align, const.ALIGN.CENTER) then
            child_data.x = data.padding.left + math.floor((available_width - child_data.width) / 2)
        elseif flagger.test(data.align, const.ALIGN.RIGHT) then
            child_data.x = data.padding.left + available_width - child_data.width
        else
            child_data.x = data.padding.left
        end

        -- Vertical alignment
        if flagger.test(data.align, const.ALIGN.HORIZON) then
            child_data.y = data.padding.top + math.floor((available_height - child_data.height) / 2)
        elseif flagger.test(data.align, const.ALIGN.BOTTOM) then
            child_data.y = data.padding.top + available_height - child_data.height
        else
            child_data.y = data.padding.top
        end
    end
end

function widget.draw(props_tree, id, term)
    local data = props_tree[id]

    if data.color then
        term.setBackgroundColor(data.color)
        term.clear()
    end
end

function widget.handle_event(props_tree, id, sch, event)
end

return widget
