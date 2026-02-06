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

    -- First part of the layout, compute the size "bottom up"
    local function compute_natural_size_recursive(props, old_layout)
        -- data is tree.props[id]
        -- old_layout is tree.old_render[id]
        local needs_recompute = tree.dirty[props.id] ~= nil or old_layout == nil

        for _, child_id in ipairs(props.children) do
            local child_data = tree.props[child_id]
            local child_old_layout = tree.old_render[child_id]

            if compute_natural_size_recursive(child_data, child_old_layout) then
                -- If the child changed size, we need to recompute our own size
                needs_recompute = true
            end
        end

        -- Initialize render tree
        tree.render[props.id] = {}

        if needs_recompute then
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
                    return true
                end
            else
                return true
            end
        else
            -- Copy from old layout
            tree.render[props.id] = {}
            tree.render[props.id].natural_width = old_layout.natural_width
            tree.render[props.id].natural_height = old_layout.natural_height
        end

        return false
    end

    -- Call on the root widget
    compute_natural_size_recursive(root_props, tree.old_render[root_props.id])

    -- Second part of the layout, compute the layout "top down"
    local function compute_children_layout_recursive(data)
        -- data is tree.props[id]
        local need_recompute = tree.dirty[data.id] ~= nil

        -- Check children dirtiness (skip if not needed)
        if not need_recompute then
            for _, child_id in ipairs(data.children) do
                local child_data = tree.props[child_id]
                local child_old_data = tree.old_props[child_id]
                local child_layout = tree.render[child_id]
                local child_old_layout = tree.old_render[child_id]

                if child_old_layout and child_old_data then
                    -- If the child changed size or expand properties
                    if child_layout.width ~= child_old_layout.width
                        or child_layout.height ~= child_old_layout.height
                        or child_data.h_expand ~= child_old_data.h_expand
                        or child_data.v_expand ~= child_old_data.v_expand then
                        need_recompute = true
                        break
                    end
                else
                    need_recompute = true
                    break
                end
            end
        end

        if need_recompute then
            local widget = widgets[data.type]
            widget.compute_children_layout(tree.props, tree.render, data.id)
        end

        for _, child_id in ipairs(data.children) do
            local child_data = tree.props[child_id]
            local child_layout = tree.render[child_id]
            local child_old_layout = tree.old_render[child_id]

            if not need_recompute then
                -- Copy from old layout
                child_layout.width = child_old_layout.width
                child_layout.height = child_old_layout.height
                child_layout.x = child_old_layout.x
                child_layout.y = child_old_layout.y
            elseif child_old_layout then
                -- Check if size changed
                if child_layout.width ~= child_old_layout.width
                    or child_layout.height ~= child_old_layout.height then
                    tree.dirty[child_id] = true
                end
            end

            if type(child_layout.width) ~= "number" then
                error(data.type .. " is not setting final width properly: " .. tostring(child_layout.width))
            elseif type(child_layout.height) ~= "number" then
                error(data.type .. " is not setting final height properly: " .. tostring(child_layout.height))
            elseif type(child_layout.x) ~= "number" then
                error(data.type .. " is not setting final x position properly: " .. tostring(child_layout.x))
            elseif type(child_layout.y) ~= "number" then
                error(data.type .. " is not setting final y position properly: " .. tostring(child_layout.y))
            end

            compute_children_layout_recursive(child_data)
        end
    end

    -- Fetch root layout
    local root_layout = tree.render[root_props.id]

    -- Set the root widget's layout
    if root_props.h_expand then
        root_layout.width = width
    else
        root_layout.width = math.min(width, root_layout.natural_width)
    end

    if root_props.v_expand then
        root_layout.height = height
    else
        root_layout.height = math.min(height, root_layout.natural_height)
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

    -- Draw the UI tree to the terminal
    local function draw_recursive(data, layout, buffer_data)
        -- data = tree.props[id]
        -- layout = tree.render[id] (layout properties)
        -- buffer_data = tree.buffer[id] (buffer state)

        if tree.dirty[data.id] or buffer_data == nil then
            if debug then
                buffer_data.buffer.setBackgroundColor(colors.green)
                buffer_data.buffer.clear()
            else
                widgets[data.type].draw(tree.props, tree.render, data.id, buffer_data.buffer)
            end
        elseif debug then
            buffer_data.buffer.setBackgroundColor(colors.green)
            buffer_data.buffer.clear()
        end

        if data.visible then
            buffer_data.buffer.blit_onto(
                root_buffer,
                buffer_data.x,
                buffer_data.y,
                1, 1, buffer_data.buffer.getSize()
            )
        end

        if data.children then
            for _, child_id in ipairs(data.children) do
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
                    local abs_x = child_layout.x + buffer_data.x - 1
                    local abs_y = child_layout.y + buffer_data.y - 1

                    -- Check if position changed
                    if abs_x ~= child_buffer.x or abs_y ~= child_buffer.y then
                        child_buffer.x = abs_x
                        child_buffer.y = abs_y
                    end

                    -- Reset timeout for actively used buffer
                    child_buffer.timeout = render.WINDOW_TIMEOUT
                else
                    -- Create new buffer
                    local abs_x = child_layout.x + buffer_data.x - 1
                    local abs_y = child_layout.y + buffer_data.y - 1

                    child_buffer = {
                        x = abs_x,
                        y = abs_y,
                        buffer = framebuffer.new(child_layout.width, child_layout.height),
                        timeout = render.WINDOW_TIMEOUT
                    }
                    tree.buffer[child_id] = child_buffer
                end

                draw_recursive(child_data, child_layout, child_buffer)
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

        if root_layout.x ~= root_buffer_data.x
            or root_layout.y ~= root_buffer_data.y then
            root_buffer_data.x = root_layout.x
            root_buffer_data.y = root_layout.y
        end

        -- Reset timeout for actively used buffer
        root_buffer_data.timeout = render.WINDOW_TIMEOUT
    else
        root_buffer_data = {
            x = root_layout.x,
            y = root_layout.y,
            buffer = framebuffer.new(root_layout.width, root_layout.height),
            timeout = render.WINDOW_TIMEOUT
        }
        tree.buffer[root_props.id] = root_buffer_data
    end

    -- Call on the root widget to draw the UI tree
    draw_recursive(root_props, root_layout, root_buffer_data)

    -- Blit on screen
    root_buffer.blit_onto(term, 1, 1, 1, 1, term.getSize())
end

return render
