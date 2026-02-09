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

--- Scroll widget - a container with a vertical scrollbar for scrolling through content.
---
--- Wraps a single child widget and provides vertical scrolling when the child's natural height
--- exceeds the available space. A scrollbar appears on the right side with up/down arrows and
--- a draggable cursor. The widget automatically reserves 1 column for the scrollbar.
---
--- **Properties:**
--- - `scroll` (number): Current scroll position (0 = top, default: 0)
--- - `color` (number): Color for the scrollbar arrows and cursor (default: white)
--- - `background_color` (number): Background color for the arrow areas (default: black)
--- - `bar_background_color` (number): Background color for the scrollbar track (default: gray)
---
--- **Interaction:**
--- - Mouse scroll: Scroll up/down by 1
--- - Click up arrow: Scroll up by 1
--- - Click down arrow: Scroll down by 1
---
--- **Example:**
--- ```lua
--- ui.scroll(function(ui)
---     ui.color = colors.lightBlue
---     ui.background_color = colors.black
---     ui.bar_background_color = colors.gray
---
---     ui.vertical(function(ui)
---         -- Add many items here that exceed the visible height
---         for i = 1, 20 do
---             ui.label(function(ui)
---                 ui.text = "Item " .. i
---             end)
---         end
---     end)
--- end)
--- ```

--- @export
local widget = {}

widget.PROPS = {
    scroll = { "number" },
    color = { "number" },
    background_color = { "number" },
    bar_background_color = { "number" },
}

function widget.populate_default_props(props, old_props, event)
    props.scroll = 0
    props.color = colors.white
    props.bar_background_color = colors.gray
    props.background_color = colors.black

    if old_props then
        props.scroll = old_props.scroll
    end

    if event and event.scroll then
        props.scroll = props.scroll + event.scroll
        event.scroll = nil
    end
end

function widget.accept_child(parent_props, child_props)
    if #parent_props.children > 0 then
        return "Scrolls can only have a single child"
    end
end

function widget.compute_children_max_size(props_tree, render_tree, id)
    local props = props_tree[id]
    local layout = render_tree[id]

    -- If we have a child, set its max size
    if #props.children > 0 then
        local child_layout = render_tree[props.children[1]]

        -- Max size is reduced by 1 to account for the scrollbar
        if layout.max_width then
            child_layout.max_width = layout.max_width - 1
        end
    end
end

function widget.compose(props, ui)
end

function widget.compute_natural_size(props_tree, render_tree, id)
    local props = props_tree[id]
    local layout = render_tree[id]

    local natural_width = 1
    local natural_height = 1

    if #props.children > 0 then
        local child_layout = render_tree[props.children[1]]

        natural_width = child_layout.natural_width + 1
        natural_height = child_layout.natural_height
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

local function compute_cursor_from_scroll(view_size, child_size, scroll)
    local scroll_max = child_size - view_size
    local cursor_size = math.max(1, math.floor((view_size / scroll_max) * (view_size - 2)))
    local cursor_pos = math.floor((scroll / scroll_max) * (view_size - 2 - cursor_size))

    return scroll_max, cursor_pos, cursor_size
end

function widget.compute_children_layout(props_tree, render_tree, id)
    local props = props_tree[id]
    local layout = render_tree[id]

    if #props.children > 0 then
        local child_layout = render_tree[props.children[1]]

        child_layout.x = 1
        child_layout.y = 1
        child_layout.width = layout.width - 1
        child_layout.height = child_layout.natural_height
        child_layout.view = {
            x = 1,
            y = 1 + props.scroll,
            width = layout.width - 1,
            height = layout.height,
        }

        -- Compute the cursor properties
        layout.scroll_max, layout.cursor_pos, layout.cursor_size = compute_cursor_from_scroll(
            layout.height,
            child_layout.natural_height,
            props.scroll
        )
    end
end

function widget.draw(props_tree, render_tree, id, term)
    local props = props_tree[id]
    local layout = render_tree[id]

    if #props.children > 0 then
        local child_layout = render_tree[props.children[1]]

        -- Blit up arrow
        term.setCursorPos(layout.width, 1)
        term.blit(
            "\30",
            colors.toBlit(props.color),
            colors.toBlit(props.background_color)
        )

        -- Blit the space before the cursor
        if layout.cursor_pos > 0 then
            for i = 2, 2 + layout.cursor_pos do
                term.setCursorPos(layout.width, i)
                term.blit(
                    "\127",
                    colors.toBlit(props.color),
                    colors.toBlit(props.bar_background_color)
                )
            end
        end

        -- Blit the cursor
        for i = 2 + layout.cursor_pos, 2 + layout.cursor_pos + layout.cursor_size - 1 do
            term.setCursorPos(layout.width, i)
            term.blit(
                " ",
                colors.toBlit(colors.black),
                colors.toBlit(props.color)
            )
        end

        -- Blit the space after the cursor
        for i = 2 + layout.cursor_pos + layout.cursor_size, layout.height - 1 do
            term.setCursorPos(layout.width, i)
            term.blit(
                "\127",
                colors.toBlit(props.color),
                colors.toBlit(props.bar_background_color)
            )
        end

        -- Blit down arrow
        term.setCursorPos(layout.width, layout.height)
        term.blit(
            "\31",
            colors.toBlit(props.color),
            colors.toBlit(props.background_color)
        )
    end
end

local function compute_scroll_from_cursor(size, cursor)
end

function widget.handle_event(props_tree, render_tree, event_tree, id, sch, event)
    if event[1] == "mouse_click" or event[1] == "mouse_drag" or event[1] == "mouse_scroll" then
        local props = props_tree[id]
        local layout = render_tree[id]

        if #props.children > 0 then
            if event[1] == "mouse_scroll" then
                if event[2] < 0 then
                    if props.scroll > 0 then
                        event_tree[id].scroll = -1
                    end
                elseif event[2] > 0 then
                    if props.scroll < layout.scroll_max then
                        event_tree[id].scroll = 1
                    end
                end
            elseif event[1] == "mouse_click" then
                if event[3] == layout.width then
                    if event[4] == 1 then
                        if props.scroll > 0 then
                            event_tree[id].scroll = -1
                        end
                    elseif event[4] == layout.height then
                        if props.scroll < layout.scroll_max then
                            event_tree[id].scroll = 1
                        end
                    end
                end
            end
        end

        return true
    end
end

return widget
