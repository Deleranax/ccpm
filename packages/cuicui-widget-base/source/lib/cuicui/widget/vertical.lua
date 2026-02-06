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

--- Vertical widget - arranges child widgets in a vertical stack.
---
--- A container that organizes its children vertically from top to bottom. You can control
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
--- ui.vertical(function(ui)
---     ui.spacing = 1
---     ui.align = const.ALIGN.CENTER + const.ALIGN.TOP
---     ui.color = colors.black
---
---     ui.label(function(ui)
---         ui.text = "First item"
---     end)
---     ui.label(function(ui)
---         ui.text = "Second item"
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

        -- Update width
        layout.natural_width = math.max(layout.natural_width, child_layout.natural_width)

        -- Update height (if first, don't add spacing)
        if first then
            layout.natural_height = child_layout.natural_height
            first = false
        else
            layout.natural_height = layout.natural_height + child_layout.natural_height + props.spacing
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

        if child_props.v_expand then
            expand_number = expand_number + 1
        end
    end

    local remaining_height = layout.height - layout.natural_height
    local expand_height = math.floor(remaining_height / expand_number) -- Size of each expandable child
    local first = true
    local offset = 1

    -- If there are no expandable children, align the children vertically
    if expand_number == 0 then
        if flagger.test(props.align, const.ALIGN.HORIZON) then
            offset = math.floor(remaining_height / 2)
        elseif flagger.test(props.align, const.ALIGN.BOTTOM) then
            offset = remaining_height
        end
    end

    -- Iterate over children to compute the layout
    for _, child_id in ipairs(props.children) do
        local child_props = props_tree[child_id]
        local child_layout = render_tree[child_id]

        if child_props.h_expand then
            child_layout.width = layout.width
        else
            child_layout.width = child_layout.natural_width
        end

        if child_props.v_expand then
            child_layout.height = child_layout.natural_height + expand_height
        else
            child_layout.height = child_layout.natural_height
        end

        -- Set default x position
        child_layout.x = 1

        if flagger.test(props.align, const.ALIGN.CENTER) then
            child_layout.x = 1 + math.floor((layout.width - child_layout.width) / 2)
        elseif flagger.test(props.align, const.ALIGN.RIGHT) then
            child_layout.x = 1 + layout.width - child_layout.width
        end

        if first then
            child_layout.y = offset
            first = false
        else
            child_layout.y = offset + props.spacing
        end

        offset = child_layout.y + child_layout.height
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
