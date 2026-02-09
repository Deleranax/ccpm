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

--- @export
local widget = {}

widget.PROPS = {
    text = { "string" },
    width = { "number" },
    focus = { "boolean" },
    placeholder = { "string" },
    color = { "number" },
    placeholder_color = { "number" },
    background_color = { "number" }
}

function widget.populate_default_props(props, old_props, event)
    props.text = ""
    props.width = 10
    props.focus = false
    props.placeholder = "placeholder"
    props.color = colors.white
    props.placeholder_color = colors.gray
    props.background_color = colors.black

    if old_props then
        props.text = old_props.text
        props.focus = old_props.focus
    end

    if event then
        if event.text then
            props.text = event.text
            event.text = nil
        end
        if event.focus ~= nil then
            props.focus = event.focus
            event.focus = nil
        end
    end
end

function widget.accept_child(parent_props, child_props)
    return "Input cannot have children"
end

function widget.compute_children_max_size(props_tree, render_tree, id)
    -- Only used for containers
end

function widget.compose(props, ui)
end

function widget.compute_natural_size(props_tree, render_tree, id)
    local props = props_tree[id]
    local layout = render_tree[id]

    local natural_width = props.width
    local natural_height = 1

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

local function get_visible_text(text, width)
    return string.sub(text, math.max(1, #text - width + 1), #text)
end

function widget.draw(props_tree, render_tree, id, term)
    local props = props_tree[id]

    term.setBackgroundColor(props.background_color)
    term.clear()

    term.setCursorPos(1, 1)
    if props.text == "" then
        if props.focus then
            term.setTextColor(props.color)
            term.write("_")
        else
            term.setTextColor(props.placeholder_color)
            term.write(props.placeholder)
        end
    else
        local visible_text = get_visible_text(props.text, props.width - 1)

        if props.focus then
            term.setTextColor(props.color)
            term.write(visible_text .. "_")
        else
            term.setTextColor(props.color)
            term.write(visible_text)
        end
    end
end

function widget.handle_event(props_tree, render_tree, event_tree, id, sch, event)
    if event[1] == "mouse_click" then
        event_tree[id].focus = true
        return true
    elseif event[1] == "lost_focus" then
        event_tree[id].focus = false
        return true
    elseif props_tree[id].focus then
        if event[1] == "key" then
            if event[2] == keys.backspace then
                event_tree[id].text = string.sub(props_tree[id].text, 1, -2)
            elseif event[2] == keys.enter then
                event_tree[id].focus = false
            end
            return true
        elseif event[1] == "key_up" then
            return true
        elseif event[1] == "char" then
            event_tree[id].text = props_tree[id].text .. event[2]
            return true
        end
    end
end

return widget
