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

--- Label widget - displays a single line of text.
---
--- A simple text display widget that shows a string with configurable colors.
--- Labels cannot contain child widgets.
---
--- **Properties:**
--- - `text` (string): The text content to display
--- - `color` (number): Text color (use ComputerCraft color constants)
--- - `background_color` (number, optional): Background color for the label area
---
--- **Example:**
--- ```lua
--- ui.label(function(ui)
---     ui.text = "Hello, world!"
---     ui.color = colors.white
---     ui.background_color = colors.blue
--- end)
--- ```

--- @export
local widget = {}

widget.PROPS = {
    text = { "string" },
    color = { "number" },
    background_color = { "number", "nil" }
}

function widget.populate_default_props(props, old_props, event)
    props.text = "Label #" .. props.id
    props.color = colors.white
end

function widget.accept_child(props_tree, id, child_props)
    return "Labels cannot have children"
end

function widget.compose(props, ui)
end

function widget.compute_natural_size(props_tree, render_tree, id)
    local props = props_tree[id]
    local layout = render_tree[id]

    layout.natural_width = #props.text
    layout.natural_height = 1
end

function widget.compute_children_layout(props_tree, render_tree, id)
    -- Only used for containers
end

function widget.draw(props_tree, render_tree, id, term)
    local props = props_tree[id]

    if props.background_color then
        term.setBackgroundColor(props.background_color)
        term.clear()
    end

    term.setCursorPos(1, 1)
    term.setTextColor(props.color)
    term.write(props.text)
end

function widget.handle_event(props_tree, event_tree, id, sch, event)
end

return widget
