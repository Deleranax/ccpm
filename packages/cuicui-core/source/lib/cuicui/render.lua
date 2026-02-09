--[[
    cuicui-core - Core package for cuicui
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

local framebuffer = require("cuicui.framebuffer")

--- @export
local render = {}

--- Time after which a window is discarded if not used.
render.WINDOW_TIMEOUT = 5

--- Update the layout of the UI tree.
--- @param tree table: The UI tree.
--- @param root_props table: The root properties.
--- @param widgets table: The widgets table.
--- @param term term.Redirect: The terminal to draw to.
function render.update_layout(tree, root_props, widgets, term)
    local width, height = term.getSize()
    tree.render[root_props.id] = {}
    local root_layout = tree.render[root_props.id]

    local function compute_children_max_size_recursive(props)
        local widget = widgets[props.type]

        -- Initialize render tree
        for _, child_id in ipairs(props.children) do
            tree.render[child_id] = {}
        end

        widget.compute_children_max_size(tree.props, tree.render, props.id)

        for _, child_id in ipairs(props.children) do
            local child_props = tree.props[child_id]
            compute_children_max_size_recursive(child_props)
        end
    end

    -- Set root widget max size to terminal size
    root_layout.max_width = width
    root_layout.max_height = height

    -- Call on the root widget
    compute_children_max_size_recursive(root_props)

    -- First part of the layout, compute the size "bottom up"
    local function compute_natural_size_recursive(props, old_layout)
        for _, child_id in ipairs(props.children) do
            local child_data = tree.props[child_id]
            local child_old_layout = tree.old_render[child_id]

            compute_natural_size_recursive(child_data, child_old_layout)
        end

        local widget = widgets[props.type]
        widget.compute_natural_size(tree.props, tree.render, props.id)

        local layout = tree.render[props.id]

        if type(layout.natural_width) ~= "number" then
            error(props.type .. " is not setting natural width properly: " .. tostring(layout.natural_width))
        elseif type(layout.natural_height) ~= "number" then
            error(props.type .. " is not setting natural height properly: " .. tostring(layout.natural_height))
        end

        -- Check if the widget changed size
        if old_layout then
            if old_layout.natural_width ~= layout.natural_width
                or old_layout.natural_height ~= layout.natural_height then
                tree.dirty[props.id] = true
            end
        end
    end

    -- Call on the root widget
    compute_natural_size_recursive(root_props, tree.old_render[root_props.id])

    -- Second part of the layout, compute the layout "top down"
    local function compute_children_layout_recursive(props)
        local widget = widgets[props.type]
        widget.compute_children_layout(tree.props, tree.render, props.id)

        for _, child_id in ipairs(props.children) do
            local child_data = tree.props[child_id]
            local child_layout = tree.render[child_id]
            local child_old_layout = tree.old_render[child_id]

            if child_old_layout then
                -- Check if size changed
                if child_layout.width ~= child_old_layout.width
                    or child_layout.height ~= child_old_layout.height then
                    tree.dirty[child_id] = true
                end

                if child_layout.x ~= child_old_layout.x
                    or child_layout.y ~= child_old_layout.y then
                    tree.dirty[props.id] = true
                end
            end

            if type(child_layout.width) ~= "number" then
                error(props.type .. " is not setting final width properly: " .. tostring(child_layout.width))
            elseif type(child_layout.height) ~= "number" then
                error(props.type .. " is not setting final height properly: " .. tostring(child_layout.height))
            elseif type(child_layout.x) ~= "number" then
                error(props.type .. " is not setting final x position properly: " .. tostring(child_layout.x))
            elseif type(child_layout.y) ~= "number" then
                error(props.type .. " is not setting final y position properly: " .. tostring(child_layout.y))
            elseif child_layout.view then
                if type(child_layout.view.x) ~= "number" then
                    error(props.type .. " is not setting view x position properly: " .. tostring(child_layout.view.x))
                elseif type(child_layout.view.y) ~= "number" then
                    error(props.type .. " is not setting view y position properly: " .. tostring(child_layout.view.y))
                elseif type(child_layout.view.width) ~= "number" then
                    error(props.type .. " is not setting view width properly: " .. tostring(child_layout.view.width))
                elseif type(child_layout.view.height) ~= "number" then
                    error(props.type .. " is not setting view height properly: " .. tostring(child_layout.view.height))
                end
            end

            compute_children_layout_recursive(child_data)
        end
    end

    -- Set the root widget's layout
    if root_props.h_expand then
        root_layout.width = width
    else
        root_layout.width = root_layout.natural_width
    end

    if root_props.v_expand then
        root_layout.height = height
    else
        root_layout.height = root_layout.natural_height
    end

    root_layout.x = 1
    root_layout.y = 1

    -- Set dirty flag if size changed
    local old_root_layout = tree.old_render[root_props.id]
    if old_root_layout then
        if root_layout.width ~= old_root_layout.width
            or root_layout.height ~= old_root_layout.height then
            tree.dirty[root_props.id] = true
        end
    else
        tree.dirty[root_props.id] = true
    end

    -- Call on the root widget
    compute_children_layout_recursive(root_props)
end

--- Draw the UI tree to the terminal.
--- @param tree table: The UI tree.
--- @param root_props table: The root properties.
--- @param widgets table: The widgets table.
--- @param term term.Redirect: The terminal to draw to.
--- @param debug boolean: Whether to draw debug information.
function render.draw(tree, root_props, widgets, term, debug)
    -- Decrease the time left for each widget buffer and clear expired buffers
    for widget_id, buffer_data in pairs(tree.buffer) do
        buffer_data.timeout = buffer_data.timeout - 1

        -- Discard buffer if time is up
        if buffer_data.timeout <= 0 then
            tree.buffer[widget_id] = nil
        end
    end

    -- Create root framebuffer
    local root_buffer = framebuffer.new(term.getSize())

    -- Calculate absolute position and size for a buffer
    local function calculate_absolute_position(child_layout, parent_layout, parent_buffer)
        local result = {}

        -- Calculate position (only modified by parent's viewport)
        if parent_layout and parent_layout.view then
            -- Parent has a view - child position is relative to parent's viewport
            result.x = (child_layout.x - parent_layout.view.x + 1) + parent_buffer.x - 1
            result.y = (child_layout.y - parent_layout.view.y + 1) + parent_buffer.y - 1
            -- Size is clipped by parent's viewport
            result.width = math.max(0, math.min(
                child_layout.width,
                parent_layout.view.x + parent_layout.view.width - child_layout.x
            ))
            result.height = math.max(0, math.min(
                child_layout.height,
                parent_layout.view.y + parent_layout.view.height - child_layout.y
            ))
        else
            -- No parent view - use standard position calculation
            result.x = child_layout.x + parent_buffer.x - 1
            result.y = child_layout.y + parent_buffer.y - 1

            -- Size depends on whether child has its own view
            if child_layout.view then
                result.width = math.min(child_layout.view.width, child_layout.width - child_layout.view.x + 1)
                result.height = math.min(child_layout.view.height, child_layout.height - child_layout.view.y + 1)
            else
                result.width = child_layout.width
                result.height = child_layout.height
            end
        end

        return result
    end

    -- Draw the UI tree to the terminal
    local function draw_recursive(term, props, layout, buffer_data)
        if tree.dirty[props.id] or buffer_data == nil then
            if debug then
                buffer_data.buffer.setBackgroundColor(colors.green)
                buffer_data.buffer.clear()
            else
                widgets[props.type].draw(tree.props, tree.render, props.id, buffer_data.buffer)
            end
        elseif debug then
            buffer_data.buffer.setBackgroundColor(colors.white)
            buffer_data.buffer.clear()
        end

        -- Init the output buffer
        local output_buffer = framebuffer.new(layout.width, layout.height)
        buffer_data.buffer.blit_onto(output_buffer, 1, 1, 1, 1, layout.width, layout.height)

        for _, child_id in ipairs(props.children) do
            local child_data = tree.props[child_id]
            local child_layout = tree.render[child_id]
            local child_buffer = tree.buffer[child_id]

            if child_buffer then
                local buffer_width, buffer_height = child_buffer.buffer.getSize()

                -- Check if buffer size needs update
                if child_layout.width ~= buffer_width
                    or child_layout.height ~= buffer_height then
                    child_buffer.buffer = framebuffer.new(child_layout.width, child_layout.height)
                    tree.dirty[child_id] = true
                end

                -- Calculate absolute position
                local pos = calculate_absolute_position(child_layout, layout, buffer_data)
                child_buffer.x = pos.x
                child_buffer.y = pos.y
                child_buffer.width = pos.width
                child_buffer.height = pos.height

                -- Reset timeout for actively used buffer
                child_buffer.timeout = render.WINDOW_TIMEOUT
            else
                child_buffer = {
                    buffer = framebuffer.new(child_layout.width, child_layout.height),
                    timeout = render.WINDOW_TIMEOUT
                }

                -- Calculate absolute position
                local pos = calculate_absolute_position(child_layout, layout, buffer_data)
                child_buffer.x = pos.x
                child_buffer.y = pos.y
                child_buffer.width = pos.width
                child_buffer.height = pos.height

                tree.buffer[child_id] = child_buffer
            end

            draw_recursive(output_buffer, child_data, child_layout, child_buffer)
        end

        -- Blit the buffers
        if props.visible then
            if layout.view then
                output_buffer.blit_onto(
                    term,
                    layout.x,
                    layout.y,
                    layout.view.x,
                    layout.view.y,
                    layout.view.width,
                    layout.view.height
                )
            else
                output_buffer.blit_onto(
                    term,
                    layout.x,
                    layout.y,
                    1, 1, buffer_data.buffer.getSize()
                )
            end
        end
    end

    -- Setup root widget buffer
    local root_layout = tree.render[root_props.id]
    local root_buffer_data = tree.buffer[root_props.id]

    if root_buffer_data then
        local buffer_width, buffer_height = root_buffer_data.buffer.getSize()

        if root_layout.width ~= buffer_width
            or root_layout.height ~= buffer_height then
            root_buffer_data.buffer = framebuffer.new(root_layout.width, root_layout.height)
            tree.dirty[root_props.id] = true
        end

        -- Calculate absolute position (root has no parent, so use dummy parent buffer)
        local pos = calculate_absolute_position(root_layout, nil, { x = 1, y = 1 })
        root_buffer_data.x = pos.x
        root_buffer_data.y = pos.y
        root_buffer_data.width = pos.width
        root_buffer_data.height = pos.height

        -- Reset timeout for actively used buffer
        root_buffer_data.timeout = render.WINDOW_TIMEOUT
    else
        root_buffer_data = {
            x = root_layout.x,
            y = root_layout.y,
            width = root_layout.width,
            height = root_layout.height,
            buffer = framebuffer.new(root_layout.width, root_layout.height),
            timeout = render.WINDOW_TIMEOUT
        }
        tree.buffer[root_props.id] = root_buffer_data
    end

    -- Call on the root widget to draw the UI tree
    draw_recursive(root_buffer, root_props, root_layout, root_buffer_data)

    -- Blit on screen
    root_buffer.blit_onto(term, 1, 1, 1, 1, term.getSize())
end

return render
