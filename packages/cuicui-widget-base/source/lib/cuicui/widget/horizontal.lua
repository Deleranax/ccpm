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

--- Horizontal widget - arranges child widgets in a horizontal row.
---
--- A container that organizes its children horizontally from left to right. You can control
--- spacing between children, alignment, and how children expand to fill available space.
---
--- **Properties:**
--- - `spacing` (number): Gap in pixels between each child widget (default: 0)
--- - `color` (number, optional): Background color for the container area
--- - `fill` (boolean): Currently unused (default: false)
--- - `align` (number): Alignment flags using `const.ALIGN` constants (default: LEFT + TOP)
---   - Horizontal: `ALIGN.LEFT`, `ALIGN.CENTER`, `ALIGN.RIGHT`
---   - Vertical: `ALIGN.TOP`, `ALIGN.HORIZON` (center), `ALIGN.BOTTOM`
---   - Combine with `+` operator (e.g., `const.ALIGN.CENTER + const.ALIGN.HORIZON`)
---
--- Children can use `h_expand` and `v_expand` properties to grow and fill available space.
---
--- **Example:**
--- ```lua
--- ui.horizontal(function(ui)
---     ui.spacing = 2
---     ui.align = const.ALIGN.LEFT + const.ALIGN.HORIZON
---     ui.color = colors.black
---
---     ui.label(function(ui)
---         ui.text = "Item 1"
---     end)
---     ui.label(function(ui)
---         ui.text = "Item 2"
---     end)
--- end)
--- ```

--- @export
local widget  = {}

widget.PROPS  = {
    spacing = { "number" },
    color = { "number" },
    fill = { "boolean" },
    align = { "number" },
}

function widget.populate_default_props(props, old_props, event)
    props.spacing = 0
    props.fill = false
    props.align = const.ALIGN.LEFT + const.ALIGN.TOP
end

function widget.accept_child(props_tree, id, child_props)
    return nil
end

function widget.compose(props, ui)
end

function widget.compute_natural_size(props_tree, render_tree, id)
    local props = props_tree[id]
    local layout = render_tree[id]
    local first = true

    -- Set default width and height
    layout.natural_width = 0
    layout.natural_height = 0

    -- Iterate over children to compute the size
    for _, child_id in ipairs(props.children) do
        -- Get child layout
        local child_layout = render_tree[child_id]

        -- Update height
        layout.natural_height = math.max(layout.natural_height, child_layout.natural_height)

        -- Update width (if first, don't add spacing)
        if first then
            layout.natural_width = child_layout.natural_width
            first = false
        else
            layout.natural_width = layout.natural_width + child_layout.natural_width + props.spacing
        end
    end
end

function widget.compute_children_layout(props_tree, render_tree, id)
    local props = props_tree[id]
    local layout = render_tree[id]
    local expand_number = 0

    -- Iterate over children to compute the expand number
    for _, child_id in ipairs(props.children) do
        local child_props = props_tree[child_id]

        if child_props.h_expand then
            expand_number = expand_number + 1
        end
    end

    local remaining_width = layout.width - layout.natural_width
    local expand_width = math.floor(remaining_width / expand_number) -- Size of each expandable child
    local first = true
    local offset = 1

    -- If there are no expandable children, align the children horizontally
    if expand_number == 0 then
        if flagger.test(props.align, const.ALIGN.CENTER) then
            offset = math.floor(remaining_width / 2)
        elseif flagger.test(props.align, const.ALIGN.RIGHT) then
            offset = remaining_width
        end
    end

    -- Iterate over children to compute the layout
    for _, child_id in ipairs(props.children) do
        local child_props = props_tree[child_id]
        local child_layout = render_tree[child_id]

        if child_props.v_expand then
            child_layout.height = layout.height
        else
            child_layout.height = child_layout.natural_height
        end

        if child_props.h_expand then
            child_layout.width = child_layout.natural_width + expand_width
        else
            child_layout.width = child_layout.natural_width
        end

        -- Set default y position
        child_layout.y = 1

        if flagger.test(props.align, const.ALIGN.HORIZON) then
            child_layout.y = 1 + math.floor((layout.height - child_layout.height) / 2)
        elseif flagger.test(props.align, const.ALIGN.BOTTOM) then
            child_layout.y = 1 + layout.height - child_layout.height
        end

        if first then
            child_layout.x = offset
            first = false
        else
            child_layout.x = offset + props.spacing
        end

        offset = child_layout.x + child_layout.width
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
