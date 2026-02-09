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

local utils   = require("cuicui.utils")
local flagger = require("flagger")
local const   = require("cuicui.const")

--- Box widget - a container for a single child with padding and optional fixed size.
---
--- Useful for adding spacing around widgets or enforcing specific dimensions. The box can only
--- contain one child widget. Use `padding` to add space inside the box (between the border and
--- the child).
---
--- **Properties:**
--- - `width` (number, optional): Fixed width for the box. If not set, size adapts to child + padding
--- - `height` (number, optional): Fixed height for the box. If not set, size adapts to child + padding
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
    width = { "number", "nil" },
    height = { "number", "nil" },
    padding = { "number", "table" },
    align = { "number" },
    background_color = { "number" }
}

function widget.populate_default_props(props, old_props, event)
    props.padding = 0
    props.background_color = colors.black
    props.align = const.ALIGN.LEFT + const.ALIGN.TOP
end

function widget.accept_child(parent_props, child_props)
    if #parent_props.children > 0 then
        return "Box can only have a single child"
    end
end

function widget.compute_children_max_size(props_tree, render_tree, id)
    local props = props_tree[id]
    local layout = render_tree[id]

    -- If we have a child, set its max size based on our max size minus padding
    if #props.children > 0 then
        local child_layout = render_tree[props.children[1]]

        -- Calculate available space after padding
        if layout.max_width then
            child_layout.max_width = math.max(0, layout.max_width - props.padding.left - props.padding.right)
        end

        if layout.max_height then
            child_layout.max_height = math.max(0, layout.max_height - props.padding.top - props.padding.bottom)
        end
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
    local natural_width
    if props.width then
        natural_width = props.width
    else
        natural_width = props.padding.left + child_width + props.padding.right
    end

    -- Compute the box's natural height
    local natural_height
    if props.height then
        natural_height = props.height
    else
        natural_height = props.padding.top + child_height + props.padding.bottom
    end

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
    local props = props_tree[id]
    local layout = render_tree[id]

    if #props.children > 0 then
        local child_props = props_tree[props.children[1]]
        local child_layout = render_tree[props.children[1]]

        -- Compute the child's size (can only increase from natural size)
        local available_width = layout.width - props.padding.left - props.padding.right
        local available_height = layout.height - props.padding.top - props.padding.bottom

        -- Use natural size as minimum, can expand to available space if h_expand/v_expand
        if child_props.h_expand then
            child_layout.width = math.max(child_layout.natural_width, available_width)
        else
            child_layout.width = child_layout.natural_width
        end

        if child_props.v_expand then
            child_layout.height = math.max(child_layout.natural_height, available_height)
        else
            child_layout.height = child_layout.natural_height
        end

        -- Compute the child's position with alignment
        -- Horizontal alignment
        if flagger.test(props.align, const.ALIGN.CENTER) then
            child_layout.x = 1 + props.padding.left + math.floor((available_width - child_layout.width) / 2) + 1
        elseif flagger.test(props.align, const.ALIGN.RIGHT) then
            child_layout.x = 1 + props.padding.left + available_width - child_layout.width + 1
        else
            child_layout.x = 1 + props.padding.left
        end

        -- Vertical alignment
        if flagger.test(props.align, const.ALIGN.HORIZON) then
            child_layout.y = 1 + props.padding.top + math.floor((available_height - child_layout.height) / 2)
        elseif flagger.test(props.align, const.ALIGN.BOTTOM) then
            child_layout.y = 1 + props.padding.top + available_height - child_layout.height
        else
            child_layout.y = 1 + props.padding.top
        end
    end
end

function widget.draw(props_tree, render_tree, id, term)
    local props = props_tree[id]

    term.setBackgroundColor(props.background_color)
    term.clear()
end

function widget.handle_event(props_tree, render_tree, event_tree, id, sch, event)
end

return widget
