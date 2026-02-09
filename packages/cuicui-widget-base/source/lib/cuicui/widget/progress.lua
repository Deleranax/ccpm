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

--- Progress widget - displays a progress bar showing completion ratio.
---
--- A visual indicator that shows progress based on current and target values.
--- The progress bar can be displayed horizontally or vertically with customizable colors.
--- Progress bars cannot contain child widgets.
---
--- **Properties:**
--- - `current` (number): Current progress value (default: 0)
--- - `target` (number): Target value for completion (default: 100)
--- - `color` (number): Color of the filled portion of the bar (default: colors.green)
--- - `background_color` (number): Color of the unfilled portion (default: colors.gray)
--- - `vertical` (boolean): If true, displays the bar vertically instead of horizontally (default: false)
--- - `width` (number, optional): Fixed width for the progress bar. If not set, adapts to container
--- - `height` (number, optional): Fixed height for the progress bar. If not set, adapts to container
---
--- **Example:**
--- ```lua
--- ui.progress(function(ui)
---     ui.current = 65
---     ui.target = 100
---     ui.color = colors.lime
---     ui.background_color = colors.lightGray
--- end)
---
--- -- Vertical progress bar
--- ui.progress(function(ui)
---     ui.current = 33
---     ui.target = 100
---     ui.vertical = true
---     ui.height = 10
--- end)
---
--- -- With fixed size
--- ui.progress(function(ui)
---     ui.current = 50
---     ui.target = 200
---     ui.width = 20
---     ui.height = 1
--- end)
--- ```

--- @export
local widget = {}

widget.PROPS = {
    current = { "number" },
    target = { "number" },
    color = { "number" },
    background_color = { "number" },
    vertical = { "boolean" },
    width = { "number", "nil" },
    height = { "number", "nil" }
}

function widget.populate_default_props(props, old_props, event)
    props.current = 0
    props.target = 100
    props.color = colors.green
    props.background_color = colors.gray
    props.vertical = false

    if old_props then
        props.current = old_props.current
        props.target = old_props.target
    end

    -- Apply event-driven state changes
    if event then
        if event.current ~= nil then
            props.current = event.current
        end
        if event.target ~= nil then
            props.target = event.target
        end
    end
end

function widget.compose(props, ui)
end

function widget.accept_child(parent_props, child_props)
    return "Progress bars cannot have children"
end

function widget.compute_children_max_size(props_tree, render_tree, id)
    -- Only used for containers
end

function widget.compute_natural_size(props_tree, render_tree, id)
    local props = props_tree[id]
    local layout = render_tree[id]

    local natural_width, natural_height
    if props.vertical then
        natural_width = props.width or 1
        natural_height = props.height or 10
    else
        natural_width = props.width or 10
        natural_height = props.height or 1
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
    -- Only used for containers
end

function widget.draw(props_tree, render_tree, id, term)
    local props = props_tree[id]
    local layout = render_tree[id]

    -- Calculate progress ratio (handle division by zero and clamp between 0 and 1)
    local progress
    if props.target <= 0 then
        progress = 0
    else
        progress = math.max(0, math.min(1, props.current / props.target))
    end

    if props.vertical then
        -- Vertical progress bar (fills from bottom to top)
        local unfilled = math.floor(layout.height * (1 - progress) * 3)
        local whole_chars = math.floor(unfilled / 3)
        local partial_chars = unfilled % 3

        -- Fill with color
        term.setBackgroundColor(props.color)
        term.clear()

        for x = 1, layout.width do
            for y = 1, whole_chars do
                term.setCursorPos(x, y)
                term.blit(
                    " ",
                    colors.toBlit(colors.black),
                    colors.toBlit(props.background_color)
                )
            end

            if partial_chars == 1 then
                term.setCursorPos(x, whole_chars + 1)
                term.blit(
                    "\131",
                    colors.toBlit(props.background_color),
                    colors.toBlit(props.color)
                )
            elseif partial_chars == 2 then
                term.setCursorPos(x, whole_chars + 1)
                term.blit(
                    "\143",
                    colors.toBlit(props.background_color),
                    colors.toBlit(props.color)
                )
            end
        end
    else
        -- Horizontal progress bar (fills from left to right)
        local filled = math.floor(layout.width * progress * 2)
        local whole_chars = math.floor(filled / 2)
        local partial_chars = filled % 2

        -- Fill with background color
        term.setBackgroundColor(props.background_color)
        term.clear()

        for y = 1, layout.height do
            term.setCursorPos(1, y)
            term.blit(
                string.rep(" ", whole_chars),
                string.rep(colors.toBlit(colors.black), whole_chars),
                string.rep(colors.toBlit(props.color), whole_chars)
            )

            if partial_chars == 1 then
                term.blit(
                    "\149",
                    colors.toBlit(props.color),
                    colors.toBlit(props.background_color)
                )
            end
        end
    end
end

function widget.handle_event(props_tree, render_tree, event_tree, id, sch, event)
end

return widget
