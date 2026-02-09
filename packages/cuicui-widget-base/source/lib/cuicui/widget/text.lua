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

local const = require("cuicui.const")
local strings = require("cc.strings")
local flagger = require("flagger")

--- @export
local widget = {}

widget.PROPS = {
    text = { "string" },
    align = { "number" },
    color = { "number" },
    background_color = { "number" }
}

function widget.populate_default_props(props, old_props, event)
    props.text = "Text #" .. props.id
    props.align = const.ALIGN.LEFT
    props.color = colors.white
    props.background_color = colors.black
end

function widget.accept_child(parent_props, child_props)
    return "Texts cannot have children"
end

function widget.compute_children_max_size(props_tree, render_tree, id)
    -- Only used for containers
end

function widget.compose(props, ui)
end

local function compute_lines(text, max_width)
    local lines = {}

    for _, part in ipairs(strings.split(text, "\n", true)) do
        if max_width then
            for _, line in ipairs(strings.wrap(part, max_width)) do
                table.insert(lines, line)
            end
        else
            table.insert(lines, part)
        end
    end

    return lines
end

function widget.compute_natural_size(props_tree, render_tree, id)
    local props = props_tree[id]
    local layout = render_tree[id]

    -- Use max_width constraint when computing lines if available
    local lines = compute_lines(props.text, layout.max_width)
    local max = 0
    for _, line in ipairs(lines) do
        max = math.max(max, #line)
    end

    local natural_width = max
    local natural_height = #lines

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
    -- Only used for containers
end

function widget.draw(props_tree, render_tree, id, term)
    local props = props_tree[id]
    local layout = render_tree[id]

    term.setBackgroundColor(props.background_color)
    term.clear()

    term.setCursorPos(1, 1)
    term.setTextColor(props.color)

    local align_right = flagger.test(props.align, const.ALIGN.RIGHT)
    local align_center = flagger.test(props.align, const.ALIGN.CENTER)

    local lines = compute_lines(props.text, layout.width)
    for i, line in ipairs(lines) do
        local padding = 0

        if align_right then
            padding = layout.width - #line
        elseif align_center then
            padding = math.floor((layout.width - #line) / 2)
        end

        term.setCursorPos(1 + padding, i)
        term.write(line)
    end
end

function widget.handle_event(props_tree, render_tree, event_tree, id, sch, event)
end

return widget
