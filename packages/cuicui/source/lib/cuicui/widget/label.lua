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
    text = { "string" },
    color = { "number" },
    background_color = { "number" }
}

widget.IS_CONTAINER = false

function widget.populate_default_props(props)
    props.text = props.text or ("Label #" .. props.id)
    props.color = props.color or colors.white
end

function widget.compute_natural_size(props_tree, id)
    local data = props_tree[id]

    data.natural_width = #data.text
    data.natural_height = 1
end

function widget.compute_children_layout(props_tree, id)
    -- Only used for containers
end

function widget.draw(props_tree, id, term)
    local data = props_tree[id]

    if data.background_color then
        term.setBackgroundColour(data.background_color)
        term.clear()
    end

    term.setCursorPos(1, 1)
    term.setTextColor(data.color)
    term.write(data.text)
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
