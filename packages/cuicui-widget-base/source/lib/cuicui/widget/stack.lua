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

local flagger = require("flagger")
local const   = require("cuicui.const")

--- Stack widget - overlays child widgets on top of each other.
---
--- A container that places all children in the same position, stacking them in layers.
--- Children are drawn in order, so later children appear on top of earlier ones.
--- Each child fills the entire stack area.
---
--- **Properties:**
--- - `color` (number, optional): Background color for the container area
--- - `align` (number): Alignment flags using `const.ALIGN` constants (default: LEFT + TOP)
---   - Horizontal: `ALIGN.LEFT`, `ALIGN.CENTER`, `ALIGN.RIGHT`
---   - Vertical: `ALIGN.TOP`, `ALIGN.HORIZON` (center), `ALIGN.BOTTOM`
---   - Combine with `+` operator (e.g., `const.ALIGN.CENTER + const.ALIGN.HORIZON`)
---
--- Children can use `h_expand` and `v_expand` properties to control whether they fill
--- the entire stack area or use their natural size.
---
--- **Example:**
--- ```lua
--- ui.stack(function(ui)
---     ui.align = const.ALIGN.CENTER + const.ALIGN.HORIZON
---     ui.color = colors.black
---
---     -- Background layer
---     ui.box(function(ui)
---         ui.color = colors.blue
---         ui.h_expand = true
---         ui.v_expand = true
---     end)
---     -- Foreground label
---     ui.label(function(ui)
---         ui.text = "Overlay text"
---         ui.color = colors.white
---     end)
--- end)
--- ```

--- @export
local widget  = {}

widget.PROPS  = {
    color = { "number", "nil" },
    align = { "number" },
}

function widget.populate_default_props(props, old_props)
    props.align = const.ALIGN.LEFT + const.ALIGN.TOP
end

function widget.accept_child(props_tree, id, child_props)
    return nil
end

function widget.compose(props, ui)
end

function widget.compute_natural_size(props_tree, id)
    local data = props_tree[id]

    -- Set default width and height
    data.natural_width = 0
    data.natural_height = 0

    -- Iterate over children to compute the size (take the maximum of all children)
    for _, child_id in ipairs(data.children) do
        local child_data = props_tree[child_id]

        -- Update width and height to the maximum
        data.natural_width = math.max(data.natural_width, child_data.natural_width)
        data.natural_height = math.max(data.natural_height, child_data.natural_height)
    end
end

function widget.compute_children_layout(props_tree, id)
    local data = props_tree[id]

    -- All children are positioned at the same location, stacked on top of each other
    for _, child_id in ipairs(data.children) do
        local child_data = props_tree[child_id]

        -- Compute child size based on expand flags
        if child_data.h_expand then
            child_data.width = data.width
        else
            child_data.width = child_data.natural_width
        end

        if child_data.v_expand then
            child_data.height = data.height
        else
            child_data.height = child_data.natural_height
        end

        -- Horizontal alignment
        if flagger.test(data.align, const.ALIGN.CENTER) then
            child_data.x = 1 + math.floor((data.width - child_data.width) / 2)
        elseif flagger.test(data.align, const.ALIGN.RIGHT) then
            child_data.x = 1 + data.width - child_data.width
        else
            child_data.x = 1
        end

        -- Vertical alignment
        if flagger.test(data.align, const.ALIGN.HORIZON) then
            child_data.y = 1 + math.floor((data.height - child_data.height) / 2)
        elseif flagger.test(data.align, const.ALIGN.BOTTOM) then
            child_data.y = 1 + data.height - child_data.height
        else
            child_data.y = 1
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
