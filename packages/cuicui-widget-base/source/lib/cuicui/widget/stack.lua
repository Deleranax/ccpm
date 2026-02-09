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
    background_color = { "number" },
    align = { "number" },
}

function widget.populate_default_props(props, old_props, event)
    props.background_color = colors.black
    props.align = const.ALIGN.LEFT + const.ALIGN.TOP
end

function widget.accept_child(parent_props, child_props)
    return nil
end

function widget.compute_children_max_size(props_tree, render_tree, id)
    local props = props_tree[id]
    local layout = render_tree[id]

    -- Pass through max size to all children
    for _, child_id in ipairs(props.children) do
        local child_layout = render_tree[child_id]
        child_layout.max_width = layout.max_width
        child_layout.max_height = layout.max_height
    end
end

function widget.compose(props, ui)
end

function widget.compute_natural_size(props_tree, render_tree, id)
    local props = props_tree[id]
    local layout = render_tree[id]

    -- Set default width and height
    local natural_width = 0
    local natural_height = 0

    -- Iterate over children to compute the size (take the maximum of all children)
    for _, child_id in ipairs(props.children) do
        local child_layout = render_tree[child_id]

        -- Update width and height to the maximum
        natural_width = math.max(natural_width, child_layout.natural_width)
        natural_height = math.max(natural_height, child_layout.natural_height)
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

    -- All children are positioned at the same location, stacked on top of each other
    for _, child_id in ipairs(props.children) do
        local child_props = props_tree[child_id]
        local child_layout = render_tree[child_id]

        -- Compute child size based on expand flags
        if child_props.h_expand then
            child_layout.width = layout.width
        else
            child_layout.width = child_layout.natural_width
        end

        if child_props.v_expand then
            child_layout.height = layout.height
        else
            child_layout.height = child_layout.natural_height
        end

        -- Horizontal alignment
        if flagger.test(props.align, const.ALIGN.CENTER) then
            child_layout.x = 1 + math.floor((layout.width - child_layout.width) / 2)
        elseif flagger.test(props.align, const.ALIGN.RIGHT) then
            child_layout.x = 1 + layout.width - child_layout.width
        else
            child_layout.x = 1
        end

        -- Vertical alignment
        if flagger.test(props.align, const.ALIGN.HORIZON) then
            child_layout.y = 1 + math.floor((layout.height - child_layout.height) / 2)
        elseif flagger.test(props.align, const.ALIGN.BOTTOM) then
            child_layout.y = 1 + layout.height - child_layout.height
        else
            child_layout.y = 1
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
