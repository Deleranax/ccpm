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

function widget.populate_default_props(props, old_props, event)
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

function widget.compute_natural_size(props_tree, render_tree, id)
    local props = props_tree[id]
    local layout = render_tree[id]

    local child_width = 0
    local child_height = 0

    -- If the child exists, get its natural size
    if #props.children > 0 then
        local child_layout = render_tree[props.children[1]]

        child_width = child_layout.natural_width
        child_height = child_layout.natural_height
    end

    -- Compute the box's natural width
    if props.fixed_width then
        layout.natural_width = props.fixed_width
    else
        layout.natural_width = props.padding.left + child_width + props.padding.right
    end

    -- Compute the box's natural height
    if props.fixed_height then
        layout.natural_height = props.fixed_height
    else
        layout.natural_height = props.padding.top + child_height + props.padding.bottom
    end
end

function widget.compute_children_layout(props_tree, render_tree, id)
    local props = props_tree[id]
    local layout = render_tree[id]

    if #props.children > 0 then
        local child_props = props_tree[props.children[1]]
        local child_layout = render_tree[props.children[1]]

        -- Compute the child's size
        child_layout.width = math.min(child_layout.natural_width, layout.width - props.padding.left - props.padding
            .right)
        child_layout.height = math.min(child_layout.natural_height,
            layout.height - props.padding.top - props.padding.bottom)

        -- Compute the child's position with alignment
        local available_width = layout.width - props.padding.left - props.padding.right
        local available_height = layout.height - props.padding.top - props.padding.bottom

        -- Horizontal alignment
        if flagger.test(props.align, const.ALIGN.CENTER) then
            child_layout.x = props.padding.left + math.floor((available_width - child_layout.width) / 2)
        elseif flagger.test(props.align, const.ALIGN.RIGHT) then
            child_layout.x = props.padding.left + available_width - child_layout.width
        else
            child_layout.x = props.padding.left
        end

        -- Vertical alignment
        if flagger.test(props.align, const.ALIGN.HORIZON) then
            child_layout.y = props.padding.top + math.floor((available_height - child_layout.height) / 2)
        elseif flagger.test(props.align, const.ALIGN.BOTTOM) then
            child_layout.y = props.padding.top + available_height - child_layout.height
        else
            child_layout.y = props.padding.top
        end
    end
end

function widget.draw(props_tree, render_tree, id, term)
    local props = props_tree[id]

    if props.color then
        term.setBackgroundColor(props.color)
        term.clear()
    end
end

function widget.handle_event(props_tree, event_tree, id, sch, event)
end

return widget
