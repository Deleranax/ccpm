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
    local function compute_natural_size_recursive(data, old_data)
        local needs_recompute = data.dirty or old_data == nil

        if data.children then
            for _, child_id in ipairs(data.children) do
                local child_data = tree.props[child_id]
                local child_old_data = tree.old_props[child_id]

                if compute_natural_size_recursive(child_data, child_old_data) then
                    -- If the child changed size, we need to recompute our own size
                    needs_recompute = true
                end
            end
        end

        if needs_recompute then
            local widget = widgets[data.type]
            widget.compute_natural_size(tree.props, data.id)

            if type(data.natural_width) ~= "number" then
                error(data.type .. " is not setting natural width properly: " .. tostring(data.natural_width))
            elseif type(data.natural_height) ~= "number" then
                error(data.type .. " is not setting natural height properly: " .. tostring(data.natural_height))
            end

            -- Check if the widget changed size
            if old_data then
                if old_data.natural_width ~= data.natural_width
                    or old_data.natural_height ~= data.natural_height then
                    data.dirty = true
                    return true
                end
            else
                return true
            end
        else
            -- Set the natural size from old data
            data.natural_width = old_data.natural_width
            data.natural_height = old_data.natural_height
        end

        return false
    end

    -- Call on the root widget
    compute_natural_size_recursive(root_props, tree.old_props[root_props.id])

    -- Second part of the layout, compute the layout "top down"
    local function compute_children_layout_recursive(data)
        local need_recompute = data.dirty

        -- Check children dirtiness (skip if not needed)
        if not need_recompute then
            for _, child_id in ipairs(data.children) do
                local child_data = tree.props[child_id]
                local child_old_data = tree.old_props[child_id]

                if child_old_data then
                    -- If the child changed size
                    if child_data.width ~= child_old_data.width
                        or child_data.height ~= child_old_data.height
                        or child_data.h_expand ~= child_old_data.h_expand
                        or child_data.v_expand ~= child_old_data.v_expand then
                        need_recompute = true
                    end
                else
                    need_recompute = true
                end
            end
        end

        if need_recompute then
            local widget = widgets[data.type]
            widget.compute_children_layout(tree.props, data.id)
        end

        for _, child_id in ipairs(data.children) do
            local child_data = tree.props[child_id]
            local child_old_data = tree.old_props[child_id]

            if not need_recompute then
                child_data.width = child_old_data.width
                child_data.height = child_old_data.height
                child_data.x = child_old_data.x
                child_data.y = child_old_data.y
            elseif child_old_data then
                if child_data.width ~= child_old_data.width
                    or child_data.height ~= child_old_data.height then
                    child_data.dirty = true
                end
            end

            if type(child_data.width) ~= "number" then
                error(data.type .. " is not setting final width properly: " .. tostring(child_data.width))
            elseif type(child_data.height) ~= "number" then
                error(data.type .. " is not setting final height properly: " .. tostring(child_data.height))
            elseif type(child_data.x) ~= "number" then
                error(data.type .. " is not setting final x position properly: " .. tostring(child_data.x))
            elseif type(child_data.y) ~= "number" then
                error(data.type .. " is not setting final y position properly: " .. tostring(child_data.y))
            end

            compute_children_layout_recursive(child_data)
        end
    end

    -- Set the root widget's layout
    if root_props.h_expand then
        root_props.width = width
    else
        root_props.width = math.min(width, root_props.natural_width)
    end

    if root_props.v_expand then
        root_props.height = height
    else
        root_props.height = math.min(height, root_props.natural_height)
    end

    root_props.x = 1
    root_props.y = 1

    -- Set dirty flag if size changed
    local old_root_props = tree.old_props[root_props.id]
    if old_root_props then
        if root_props.width ~= old_root_props.width
            or root_props.height ~= old_root_props.height then
            root_props.dirty = true
        end
    else
        root_props.dirty = true
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
    -- Decrease the time left for each widget
    for widget_id, render_data in pairs(tree.render) do
        render_data.timeout = render_data.timeout - 1

        -- Discard window if time is up
        if render_data.timeout <= 0 then
            tree.render[widget_id] = nil
        end
    end

    -- Create root framebuffer
    local root_buffer = framebuffer.new(term.getSize())

    -- Draw the UI tree to the terminal
    local function draw_recursive(data, render_data)
        if data.dirty or render_data == nil then
            if debug then
                render_data.buffer.setBackgroundColor(colors.green)
                render_data.buffer.clear()
            else
                widgets[data.type].draw(tree.props, data.id, render_data.buffer)
            end
        elseif debug then
            render_data.buffer.setBackgroundColor(colors.green)
            render_data.buffer.clear()
        end

        if data.visible then
            render_data.buffer.blit_onto(
                root_buffer,
                render_data.x,
                render_data.y,
                1, 1, render_data.buffer.getSize()
            )
        end

        if data.children then
            for _, child_id in ipairs(data.children) do
                local child_data = tree.props[child_id]
                local child_render_data = tree.render[child_id]

                if child_render_data then
                    local render_width, render_height = child_render_data.buffer.getSize()

                    if child_data.width ~= render_width
                        or child_data.height ~= render_height then
                        -- Update child render data
                        child_render_data.timeout = render.WINDOW_TIMEOUT

                        child_render_data.buffer = framebuffer.new(child_data.width, child_data.height)
                        child_data.dirty = true
                    end

                    if child_data.x + render_data.x - 1 ~= child_render_data.x
                        or child_data.y + render_data.y - 1 ~= child_render_data.y then
                        -- Update child render data
                        child_render_data.x = child_data.x + render_data.x - 1
                        child_render_data.y = child_data.y + render_data.y - 1
                        child_render_data.timeout = render.WINDOW_TIMEOUT
                    end
                else
                    child_render_data = {
                        x = child_data.x + render_data.x - 1,
                        y = child_data.y + render_data.y - 1,
                        buffer = framebuffer.new(child_data.width, child_data.height),
                        timeout = render.WINDOW_TIMEOUT
                    }
                    tree.render[child_id] = child_render_data
                end

                draw_recursive(child_data, child_render_data)
            end
        end
    end

    -- Setup root widget render data
    if tree.render[root_props.id] then
        local root_render_data = tree.render[root_props.id]
        local render_width, render_height = root_render_data.buffer.getSize()

        if root_props.width ~= render_width
            or root_props.height ~= render_height then
            -- Update child render data
            root_render_data.timeout = render.WINDOW_TIMEOUT

            root_render_data.buffer = framebuffer.new(root_props.width, root_props.height)
            root_props.dirty = true
        end

        if root_props.x ~= root_render_data.x
            or root_props.y ~= root_render_data.y then
            -- Update child render data
            root_render_data.x = root_props.x
            root_render_data.y = root_props.y
            root_render_data.timeout = render.WINDOW_TIMEOUT
        end
    else
        tree.render[root_props.id] = {
            x = root_props.x,
            y = root_props.y,
            buffer = framebuffer.new(
                root_props.width,
                root_props.height
            ),
            timeout = render.WINDOW_TIMEOUT
        }
    end

    -- Call on the root widget to draw the UI tree
    draw_recursive(root_props, tree.render[root_props.id])

    -- Blit on screen
    root_buffer.blit_onto(term, 1, 1, 1, 1, term.getSize())
end

return render
