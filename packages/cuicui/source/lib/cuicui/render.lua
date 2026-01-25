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
local render = {}

--- Time after which a window is discarded if not used.
render.WINDOW_TIMEOUT = 5

--- Update the layout of the UI tree.
--- @param props_tree table: The properties tree.
--- @param render_tree table: The render tree.
--- @param term table: The terminal to draw to.
--- @param root_props table: The root properties.
--- @param widgets table: The widgets table.
function render.update_layout(props_tree, render_tree, term, root_props, widgets)
    local width, height = term.getSize()

    -- First part of the layout, compute the size "bottom up"
    local function compute_natural_size_recursive(data)
        if data.children then
            for _, child_id in ipairs(data.children) do
                local child_data = props_tree[child_id]

                compute_natural_size_recursive(child_data)
            end
        end

        local widget = widgets[data.type]
        widget.compute_natural_size(props_tree, data.id)

        if type(data.natural_width) ~= "number" then
            error(data.type .. " is not setting natural width properly: " .. tostring(data.natural_width))
        elseif type(data.natural_height) ~= "number" then
            error(data.type .. " is not setting natural height properly: " .. tostring(data.natural_height))
        end
    end

    -- Call on the root widget
    compute_natural_size_recursive(root_props)

    -- Second part of the layout, compute the layout "top down"
    local function compute_children_layout_recursive(data)
        local widget = widgets[data.type]
        widget.compute_children_layout(props_tree, data.id)

        if type(data.width) ~= "number" then
            error(data.type .. " is not setting final width properly: " .. tostring(data.width))
        elseif type(data.height) ~= "number" then
            error(data.type .. " is not setting final height properly: " .. tostring(data.height))
        end

        if data.children then
            for _, child_id in ipairs(data.children) do
                local child_data = props_tree[child_id]

                compute_children_layout_recursive(child_data)
            end
        end
    end

    -- Set the root widget's final size
    root_props.width = width
    root_props.height = height

    -- Call on the root widget
    compute_children_layout_recursive(root_props)
end

--- Draw the UI tree to the terminal.
--- @param props_tree table: The properties tree.
--- @param render_tree table: The render tree.
--- @param term table: The terminal to draw to.
--- @param root_props table: The root properties.
--- @param widgets table: The widgets table.
function render.draw(props_tree, render_tree, term, root_props, widgets)
    -- Decrease the time left for each widget
    for _, widget_id in ipairs(render_tree) do
        local render_data = render_tree[widget_id]
        render_data.timeout = render_data.timeout - 1

        -- Discard window if time is up
        if render_data.timeout <= 0 then
            render_tree[widget_id] = nil
        end
    end

    -- Draw the UI tree to the terminal
    local function draw_recursive(data, render_data)
        local widget = widgets[data.type]
        widget.draw(props_tree, data.id, render_data.term)

        if data.children then
            for _, child_id in ipairs(data.children) do
                local child_data = props_tree[child_id]
                local child_render_data = render_tree[child_id]

                if child_render_data then
                    if child_data.width ~= child_render_data.width
                        or child_data.height ~= child_render_data.height
                        or child_data.x + render_data.x - 1 ~= child_render_data.x
                        or child_data.y + render_data.y - 1 ~= child_render_data.y then
                        -- Update child render data
                        child_render_data.width = child_data.width
                        child_render_data.height = child_data.height
                        child_render_data.x = child_data.x + render_data.x - 1
                        child_render_data.y = child_data.y + render_data.y - 1
                        child_render_data.timeout = render.WINDOW_TIMEOUT

                        child_render_data.term.reposition(
                            child_data.x,
                            child_data.y,
                            child_render_data.width,
                            child_render_data.height
                        )
                    end
                else
                    child_render_data = {
                        width = child_data.width,
                        height = child_data.height,
                        x = child_data.x + render_data.x - 1,
                        y = child_data.y + render_data.y - 1,
                        term = window.create(
                            term,
                            child_data.x + render_data.x - 1,
                            child_data.y + render_data.y - 1,
                            child_data.width,
                            child_data.height
                        ),
                        timeout = render.WINDOW_TIMEOUT
                    }
                    render_tree[child_id] = child_render_data
                end

                -- Set the visibility of the child widget's terminal
                render_tree[child_id].term.setVisible(child_data.visible)

                draw_recursive(child_data, child_render_data)
            end
        end
    end

    -- Call on the root widget to draw the UI tree
    local render_data = {
        width = root_props.width,
        height = root_props.height,
        x = 1,
        y = 1,
        term = window.create(
            term,
            1,
            1,
            root_props.width,
            root_props.height
        )
    }
    draw_recursive(root_props, render_data)
end

return render
