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
--- @param old_props_tree table: The old properties tree.
--- @param term table: The terminal to draw to.
--- @param root_props table: The root properties.
--- @param old_root_props table: The old root properties.
--- @param widgets table: The widgets table.
function render.update_layout(props_tree, old_props_tree, term, root_props, old_root_props, widgets)
    local width, height = term.getSize()

    -- First part of the layout, compute the size "bottom up"
    local function compute_natural_size_recursive(data, old_data)
        local needs_recompute = data.dirty or old_data == nil

        if data.children then
            for _, child_id in ipairs(data.children) do
                local child_data = props_tree[child_id]
                local child_old_data = old_props_tree[child_id]

                if compute_natural_size_recursive(child_data, child_old_data) then
                    -- If the child changed size, we need to recompute our own size
                    needs_recompute = true
                end
            end
        end

        if needs_recompute then
            local widget = widgets[data.type]
            widget.compute_natural_size(props_tree, data.id)

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
        end

        -- Set the natural size from old data
        data.natural_width = old_data.natural_width
        data.natural_height = old_data.natural_height

        return false
    end

    -- Call on the root widget
    compute_natural_size_recursive(root_props, old_root_props)

    -- Second part of the layout, compute the layout "top down"
    local function compute_children_layout_recursive(data)
        local need_recompute = data.dirty

        -- Check children dirtiness (skip if not needed)
        if data.children and need_recompute then
            for _, child_id in ipairs(data.children) do
                local child_data = props_tree[child_id]
                local child_old_data = old_props_tree[child_id]

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
            widget.compute_children_layout(props_tree, data.id)
        end

        if data.children then
            for _, child_id in ipairs(data.children) do
                local child_data = props_tree[child_id]
                local child_old_data = old_props_tree[child_id]

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
    end

    -- Set the root widget's final size
    root_props.width = width
    root_props.height = height

    -- Set dirty flag if size changed
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
    local function draw_recursive(data, render_data, needs_blit)
        if data.dirty or render_data == nil then
            local widget = widgets[data.type]
            widget.draw(props_tree, data.id, render_data.term)
        elseif needs_blit then
            render_data.term.redraw()
        end

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
                        child_data.dirty = true
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

                draw_recursive(child_data, child_render_data, needs_blit or data.dirty)
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
    render_tree[root_props.id] = render_data
    draw_recursive(root_props, render_data, false)
end

return render
