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

local expect = require("cc.expect")
local render = require("cuicui.render")
local event = require("cuicui.event")
local ctable = require("commons.table")

--- @export
local cuicui = {}

-- TODO: Continue refactoring new tree structure (strict separation from props, render, dirty, buffer)

--- Debug
cuicui.DEBUG = 0
cuicui.DEBUG_LOG_FILE = "cuicui_debug.tree"

--- Structure of a widget module. Modules that fail to match this structure won't be loaded.
--- All functions should be deterministic, meaning they should always return the same result
--- given the same input. Failure to do so can lead to unexpected behavior.
cuicui.WIDGET_MODULE_STRUCT = {
    --- Defines the public properties that users can set for this widget.
    ---
    --- This table declares which properties are exposed to users when they create instances
    --- of this widget. Each property is defined using the same validation format as
    --- WIDGET_MODULE_STRUCT (e.g., `{ "string" }`, `{ "number" }`, `{ "boolean" }`).
    ---
    --- **Multiple types:** A property can accept multiple types by listing them in the table.
    --- For example, `{ "string", "nil" }` allows a property to be either a string or nil.
    ---
    --- **Important:** Only list PUBLIC properties here. Internal/private properties used
    --- by the widget implementation should NOT be listed.
    ---
    --- **Example:**
    --- ```
    --- PROPS = {
    ---     text = { "string" },
    ---     color = { "number" },
    ---     background_color = { "number", "nil" },  -- Optional property
    ---     spacing = { "number" },
    ---     align = { "string" }
    --- }
    --- ```
    PROPS = { "table" },

    --- Populates default values and propagates state from the previous render.
    ---
    --- This function is called BEFORE the user's configuration function is executed.
    --- It should set sensible default values for all widget properties, then propagate
    --- state properties from the previous render that need to persist across re-renders.
    --- The user's configuration function will then override any properties they explicitly set.
    ---
    --- **Implementation guidelines:**
    --- - Modify the `props` table in-place (do NOT return anything)
    --- - First, set default values for all properties (use pattern: `props.x = default_value`)
    --- - Then, propagate state properties from `old_props` if it exists
    --- - Then, apply any event-driven state changes from `event` if it exists
    --- - Only propagate state properties (e.g., `checked`, `selected`, `scroll_offset`)
    --- - Do NOT propagate user-configurable properties (e.g., `text`, `color`, `spacing`)
    --- - The `old_props` parameter can be `nil` on the first render (check before accessing)
    --- - The `event` parameter can be `nil` if no events modified this widget's state
    --- - The `event` table contains state changes made by event handlers between frames
    --- - You only have access to this widget's properties, not the props_tree
    --- - This function must be deterministic (same inputs → same outputs)
    --- - You can use `props.id` to generate unique defaults if needed
    ---
    --- **Example:**
    --- ```
    --- function widget.populate_default_props(props, old_props, event)
    ---     -- Set default values
    ---     props.text = "Checkbox #" .. props.id
    ---     props.color = colors.white
    ---     props.checked = false
    ---
    ---     -- Propagate state from previous render
    ---     if old_props then
    ---         props.checked = old_props.checked
    ---     end
    ---
    ---     -- Apply event-driven state changes
    ---     if event and event.checked ~= nil then
    ---         props.checked = event.checked
    ---     end
    --- end
    --- ```
    ---
    --- @param props table: Widget properties table to populate with default values
    --- @param old_props table|nil: Previous widget properties for state propagation (nil on first render)
    --- @param event table|nil: Event-driven state changes for this widget (nil if no events occurred)
    populate_default_props = { "function" },

    --- Composes child elements after the user has set property values.
    ---
    --- This function is called AFTER the user's configuration function has executed.
    --- It allows the widget to dynamically create child elements based on the properties
    --- set by the user. Use the `ui` table (similar to the user-facing API) to create
    --- child widgets programmatically.
    ---
    --- **Implementation guidelines:**
    --- - Use `ui.widget_name(function(child_ui) ... end)` to create child widgets
    --- - Access this widget's user-set properties via the `props` parameter
    --- - The `ui` table provides methods for all registered widgets
    --- - Child widgets are created in the order you call them
    --- - **IMPORTANT:** Child widgets MUST have their `id` explicitly set to remain unique
    --- - **Best practice:** Use parent ID as prefix for child IDs (e.g., `props.id .. "-1"`)
    --- - This function must be deterministic (same inputs → same outputs)
    --- - This function returns nothing
    --- - **Container widgets:** Typically implement this to create dynamic children
    --- - **Non-container widgets:** Implement as an empty function (required but does nothing)
    ---
    --- **Example:**
    --- ```
    --- function widget.compose(props, ui)
    ---     -- Create checkbox indicator and label
    ---     ui.label(function(child_ui)
    ---         child_ui.text = props.checked and "[X]" or "[ ]"
    ---     end, true, props.id .. "-indicator")
    ---     ui.label(function(child_ui)
    ---         child_ui.text = props.label or "Checkbox"
    ---     end, true, props.id .. "-label")
    --- end
    --- ```
    ---
    --- @param props table: Widget properties with user-set values already populated
    --- @param ui table: UI builder table for creating child widgets
    compose = { "function" },

    --- Validates whether this widget accepts a particular child widget.
    ---
    --- This function is called when a child widget is being added to this widget (before
    --- the child is added to the tree). It should return `nil` if the child is accepted,
    --- or an error message string if the child is rejected. This allows widgets to control
    --- what types of children they accept (e.g., a label might reject all children, while
    --- a container might accept any child).
    ---
    --- **Implementation guidelines:**
    --- - Return `nil` if the child is accepted
    --- - Return a string error message if the child is rejected
    --- - Access this widget's properties via: `parent_props`
    --- - Access the child's properties via: `child_props` (child is not in tree yet)
    --- - Access the child's widget type via: `child_props.type`
    --- - You can inspect other properties to make decisions
    --- - You can modify properties in `parent_props` or `child_props` to adjust behavior (but remain deterministic)
    --- - This function must be deterministic (same inputs → same outputs)
    --- - **Container widgets:** Return `nil` to accept children (or check specific types)
    --- - **Non-container widgets:** Return an error message to reject all children
    ---
    --- **Example (container that accepts all children):**
    --- ```
    --- function widget.accept_child(parent_props, child_props)
    ---     return nil  -- Accept any child
    --- end
    --- ```
    ---
    --- **Example (non-container widget):**
    --- ```
    --- function widget.accept_child(parent_props, child_props)
    ---     return "Label widgets cannot have children"
    --- end
    --- ```
    ---
    --- **Example (selective container):**
    --- ```
    --- function widget.accept_child(parent_props, child_props)
    ---     if child_props.type == "label" or child_props.type == "button" then
    ---         return nil  -- Accept labels and buttons
    ---     else
    ---         return "This container only accepts label and button widgets"
    ---     end
    --- end
    --- ```
    ---
    --- @param parent_props table: The parent widget's properties
    --- @param child_props table: The child widget's properties (child is not in tree yet)
    --- @return nil|string: `nil` if child is accepted, or error message string if rejected
    accept_child = { "function" },

    --- Computes and stores the maximum allowed size for this widget's children.
    ---
    --- This function is called during the FIRST PASS of the layout algorithm in a "top-down"
    --- traversal, meaning parents are processed before their children. Container widgets use
    --- this function to set constraints on how large their children can be by setting the
    --- `max_width` and `max_height` fields in the render_tree for each child.
    ---
    --- **Important:** This is the FIRST PASS, so natural sizes and allocated sizes are not
    --- yet available. You can use this widget's properties from `props_tree[id]` and this
    --- widget's max size from `render_tree[id]` (if set by parent) to compute children's max sizes.
    ---
    --- **Important:** Setting `max_width` and `max_height` is OPTIONAL. However, if you do NOT
    --- set a maximum size here, you CANNOT reduce the child's size during `compute_children_layout`.
    --- In the third pass, sizes can only be increased, never reduced.
    ---
    --- **Implementation guidelines:**
    --- - Access this widget's properties via: `props_tree[id]`
    --- - Access this widget's max size via: `render_tree[id].max_width` and `.max_height` (set by parent, may be nil)
    --- - Store results by setting: `render_tree[child_id].max_width` and `render_tree[child_id].max_height` (optional)
    --- - Use this widget's properties and max size to determine appropriate max sizes for children
    --- - This function must be deterministic (same inputs → same outputs)
    --- - This function returns nothing; it only mutates the render_tree
    --- - **Container widgets:** Set max size constraints for children based on own properties and max size (or leave unset)
    --- - **Non-container widgets:** Implement as an empty function (required but does nothing)
    --- - The props_tree contains user/widget-set properties; the render_tree contains layout properties
    ---
    --- @param props_tree table: Map of widget IDs to their properties (forms a tree via parent/child references)
    --- @param render_tree table: Map of widget IDs to their layout properties (generated by layout algorithm)
    --- @param id string: The ID key for this widget in the props_tree and render_tree
    compute_children_max_size = { "function" },

    --- Computes and stores the natural size (preferred width and height) of this widget.
    ---
    --- This function is called during the SECOND PASS of the layout algorithm in a "bottom-up"
    --- traversal, meaning children are processed before their parents. When this function is
    --- called for a widget, all of its children have already had their natural sizes computed.
    ---
    --- **Important:** If `max_width` and/or `max_height` are set (from the first pass), the natural
    --- size MUST respect these constraints. The natural size represents the preferred size within
    --- the allowed maximum. The actual final size will be set in the third pass and may be greater
    --- than the natural size (but will never exceed the max size if one was set).
    ---
    --- **Implementation guidelines:**
    --- - Access this widget's properties via: `props_tree[id]`
    --- - Access this widget's max size constraints via: `render_tree[id].max_width` and `.max_height` (set in first pass)
    --- - Access children's natural sizes via: `render_tree[child_id].natural_width` and `.natural_height`
    --- - Store results by setting: `render_tree[id].natural_width` and `render_tree[id].natural_height`
    --- - The natural size MUST NOT exceed max_width/max_height if they are set
    --- - This function must be deterministic (same inputs → same outputs)
    --- - This function returns nothing; it only mutates the render_tree
    --- - The props_tree contains user/widget-set properties; the render_tree contains layout properties
    --- - You can store temporary data in render_tree[id] to share with compute_children_layout, draw, and handle_event
    ---
    --- @param props_tree table: Map of widget IDs to their properties (forms a tree via parent/child references)
    --- @param render_tree table: Map of widget IDs to their layout properties (generated by layout algorithm)
    --- @param id string: The ID key for this widget in the props_tree and render_tree
    compute_natural_size = { "function" },

    --- Computes and stores the final layout (size and position) of this widget's children.
    ---
    --- This function is called during the THIRD PASS of the layout algorithm in a "top-down"
    --- traversal, meaning parents are processed before their children. When this function is
    --- called, the parent already has its final size allocated, and this function must decide
    --- how to distribute that space among the children.
    ---
    --- **Important:** Child sizes can ONLY be increased from their natural size, never reduced.
    --- If you need to reduce a child's size, you must set `max_width`/`max_height` during the
    --- first pass (`compute_children_max_size`). Sizes set here must be >= natural_size (or <= max_size if set).
    ---
    --- **Implementation guidelines:**
    --- - Access this widget's final size via: `render_tree[id].width` and `.height`
    --- - Access children's natural sizes via: `render_tree[child_id].natural_width` and `.natural_height`
    --- - Check if children expand via: `props_tree[child_id].h_expand` and `.v_expand`
    --- - Store results by setting: `render_tree[child_id].width`, `.height`, `.x`, and `.y`
    --- - Child sizes must be >= natural size (can only increase)
    --- - Optionally store: `render_tree[child_id].view` (a table with `width`, `height`, `x`, `y` fields)
    --- - This function must be deterministic (same inputs → same outputs)
    --- - This function returns nothing; it only mutates the render_tree
    --- - **Container widgets:** Implement logic to distribute space among children
    --- - **Non-container widgets:** Implement as an empty function (required but does nothing)
    --- - The props_tree contains user/widget-set properties; the render_tree contains layout properties
    --- - Only layout properties (natural_width, natural_height, width, height, x, y, view) go in render_tree
    --- - You can store temporary data in render_tree[id] to share with compute_natural_size, draw, and handle_event
    ---
    --- **Optional view parameter:**
    --- The `view` field in `render_tree[child_id]` is an optional table that defines what portion
    --- of the widget buffer should be rendered. Unlike width, height, x, and y which are mandatory,
    --- `view` is optional (by default, the renderer blits the whole widget buffer).
    ---
    --- When set, `view` must be a table containing:
    --- - `width`: The width of the view
    --- - `height`: The height of the view
    --- - `x`: The x coordinate of the view in the widget buffer
    --- - `y`: The y coordinate of the view in the widget buffer
    ---
    --- The `view` parameter is used to control what portion of a widget's buffer is visible,
    --- enabling features like scrolling. For example, scrollboxes use `view` to show only
    --- a portion of their content at a time.
    ---
    --- @param props_tree table: Map of widget IDs to their properties (forms a tree via parent/child references)
    --- @param render_tree table: Map of widget IDs to their layout properties (generated by layout algorithm)
    --- @param id string: The ID key for this widget in the props_tree and render_tree
    compute_children_layout = { "function" },

    --- Renders the visual representation of this widget to a terminal/display object.
    ---
    --- This function is called during the rendering phase after layout has been computed.
    --- It should draw the widget's content to the provided terminal object. Child widgets
    --- are drawn automatically by the framework; you only need to draw this widget's content.
    ---
    --- **Implementation guidelines:**
    --- - Access this widget's properties via: `props_tree[id]`
    --- - Access this widget's layout via: `render_tree[id]`
    --- - The drawing area is positioned at (1, 1) relative to this widget
    --- - Use `render_tree[id].width` and `.height` for the allocated drawing area
    --- - The `term` object is a ComputerCraft Redirect (terminal, monitor, window, etc.)
    --- - Available methods: `setCursorPos()`, `setTextColor()`, `setBackgroundColor()`, `write()`, `clear()`, etc.
    --- - This function must be deterministic (same inputs → same outputs)
    --- - This function returns nothing
    --- - Do NOT draw children; the framework handles that automatically
    --- - You can access temporary data from render_tree[id] that was stored in compute_natural_size or compute_children_layout
    ---
    --- **Example:**
    --- ```
    --- function widget.draw(props_tree, render_tree, id, term)
    ---     local props = props_tree[id]
    ---     local layout = render_tree[id]
    ---     if props.background_color then
    ---         term.setBackgroundColor(props.background_color)
    ---         term.clear()
    ---     end
    ---     term.setCursorPos(1, 1)
    ---     term.setTextColor(props.color)
    ---     term.write(props.text)
    --- end
    --- ```
    ---
    --- @param props_tree table: Map of widget IDs to their properties (forms a tree via parent/child references)
    --- @param render_tree table: Map of widget IDs to their layout properties (generated by layout algorithm)
    --- @param id string: The ID key for this widget in the props_tree and render_tree
    --- @param term term.Redirect: ComputerCraft Redirect object (terminal, monitor, or window) to draw on
    draw = { "function" },

    --- Handles OS events that occur on this widget.
    ---
    --- This function is called when an event occurs on this widget. Events are processed
    --- in a bottom-up manner (children first, then parents). The function can return `true`
    --- to consume the event and prevent it from propagating to parent widgets.
    ---
    --- **Event types:**
    --- - `mouse_click`: User clicked inside the widget (can be consumed)
    --- - `mouse_drag`: User is dragging while holding a mouse button inside the widget (can be consumed)
    --- - `mouse_scroll`: User scrolled the mouse wheel inside the widget (can be consumed)
    --- - `mouse_up`: User released a mouse button inside the widget OR moved cursor out of widget bounds
    --- - `key`: User pressed a key (fires repeatedly while held) (can be consumed)
    --- - `key_up`: User released a key
    --- - `char`: User typed a character (can be consumed)
    --- - `timer`: A timer finished
    --- - `alarm`: An alarm triggered
    --- - `lost_focus`: Fired when a click event was not handled by this widget (consumed by child or outside bounds)
    ---
    --- **Important notes about events:**
    --- - **Local events:** All mouse events (except `lost_focus`) are local, meaning they only fire
    ---   when the action occurs inside the widget. For example, `mouse_up` fires when the user
    ---   released the button inside this widget OR moved the cursor out of the widget bounds while holding.
    --- - **Monitor adaptations:** On monitors, `mouse_up` is simulated a fixed time after `mouse_click`
    ---   since monitors don't natively support button release events.
    --- - **Focus management:** The `lost_focus` event is always fired when a click event is not
    ---   handled by the widget itself (either consumed by a child widget or outside of the widget bounds).
    ---   Widgets can track their own focus state in their properties if needed.
    ---
    --- **Event table structure:**
    --- The `event` table structure is identical to native CC:Tweaked events, with one exception:
    --- the `mouse_drag` event has delta coordinates (dx, dy) appended to the event table.
    --- Mouse events have coordinates relative to the widget origin (1-based).
    --- Refer to the official CC:Tweaked documentation for complete event field details.
    ---
    --- **Implementation guidelines:**
    --- - Access this widget's properties via: `props_tree[id]` (READ ONLY - for current state)
    --- - Access this widget's layout and temporary data via: `render_tree[id]` (READ/WRITE - for layout and inter-function data)
    --- - Store event-driven state changes in: `event_tree[id]` (WRITE - for state modifications)
    --- - **IMPORTANT:** Do NOT modify `props_tree[id]` - it will be ignored and lost
    --- - Initialize `event_tree[id]` table if needed: `event_tree[id] = event_tree[id] or {}`
    --- - State changes in `event_tree[id]` will be applied in the next frame via `populate_default_props`
    --- - Use `render_tree[id]` to store temporary data shared between compute_natural_size, compute_children_layout, draw, and handle_event
    --- - Check `event[1]` to determine which event occurred
    --- - Return `true` to consume the event (stop propagation to parents)
    --- - Return `nil` or `false` to allow the event to propagate to parents
    --- - **Note:** Only `mouse_click`, `mouse_drag`, `mouse_scroll`, `key`, and `char` events can be consumed
    --- - Use `sch.start_timer(time)` to schedule a timer (returns timer ID)
    --- - Use `sch.set_alarm(time)` to schedule an alarm (returns alarm ID)
    --- - Use `sch.cancel_timer(id)` to cancel a timer
    --- - Use `sch.cancel_alarm(id)` to cancel an alarm
    --- - This function should be deterministic (same inputs → same outputs)
    --- - Events are processed bottom-up (children before parents)
    ---
    --- **Example:**
    --- ```
    --- function widget.handle_event(props_tree, render_tree, event_tree, id, sch, event)
    ---     local props = props_tree[id]
    ---
    ---     if event[1] == "mouse_click" then
    ---         local button = event[2]
    ---         local x = event[3]
    ---         local y = event[4]
    ---         -- Gain focus and toggle checked state
    ---         if button == 1 then
    ---             -- Store state changes in event_tree
    ---             event_tree[id] = event_tree[id] or {}
    ---             event_tree[id].focus = true
    ---             event_tree[id].checked = not props.checked
    ---             -- Schedule a timer to auto-uncheck after 2 seconds
    ---             event_tree[id].timer_id = sch.start_timer(2)
    ---             return true  -- Consume the event
    ---         end
    ---     elseif event[1] == "key" and props.focus then
    ---         local key = event[2]
    ---         local held = event[3]
    ---         -- Toggle with space key when focused
    ---         if key == keys.space and not held then
    ---             event_tree[id] = event_tree[id] or {}
    ---             event_tree[id].checked = not props.checked
    ---             return true  -- Consume the event
    ---         end
    ---     elseif event[1] == "mouse_scroll" then
    ---         local direction = event[2]
    ---         -- Scroll content
    ---         event_tree[id] = event_tree[id] or {}
    ---         event_tree[id].scroll_offset = props.scroll_offset + direction
    ---         return true  -- Consume the event
    ---     elseif event[1] == "timer" then
    ---         local timer_id = event[2]
    ---         -- Check if this is our timer
    ---         if timer_id == props.timer_id then
    ---             event_tree[id] = event_tree[id] or {}
    ---             event_tree[id].checked = false
    ---             event_tree[id].timer_id = nil
    ---         end
    ---         -- Timer events cannot be consumed
    ---     elseif event[1] == "lost_focus" then
    ---         -- Clean up when losing focus
    ---         event_tree[id] = event_tree[id] or {}
    ---         event_tree[id].focus = false
    ---         event_tree[id].show_cursor = false
    ---         -- Cancel any pending timer
    ---         if props.timer_id then
    ---             sch.cancel_timer(props.timer_id)
    ---             event_tree[id].timer_id = nil
    ---         end
    ---     end
    ---
    ---     return false  -- Don't consume, let parent handle it
    --- end
    --- ```
    ---
    --- @param props_tree table: Map of widget IDs to their properties (READ ONLY - forms a tree via parent/child references)
    --- @param render_tree table: Map of widget IDs to their layout properties (READ/WRITE - for layout and temporary data shared across functions)
    --- @param event_tree table: Map of widget IDs to event-driven state changes (WRITE - changes applied next frame)
    --- @param id string: The ID key for this widget in the props_tree, render_tree, and event_tree
    --- @param sch table: Scheduler for managing timers and alarms (start_timer, set_alarm, cancel_timer, cancel_alarm)
    --- @param event table: Event data with type and type-specific fields (see structure above)
    --- @return boolean|nil: `true` to consume event (stop propagation), `nil`/`false` to propagate to parents (only mouse_click/mouse_drag/mouse_scroll/key can be consumed)
    handle_event = { "function" },
}

--- List of properties readable/writable in the widget function.
cuicui.COMMON_PROPS = {
    -- Unique identifier for the widget. Defaults to stable unique ID generated by the library (the line)
    -- numbers. SHOULD BE SET BY THE USER WHEN CREATING WIDGETS IN LOOPS (as the line will be the same).
    id = { "string", "number" },
    -- Boolean value describing whether the widget is horizontally expanded.
    h_expand = { "boolean" },
    -- Boolean value describing whether the widget is vertically expanded.
    v_expand = { "boolean" },
    -- Boolean value describing whether the widget is visible.
    visible = { "boolean" }
}

--- List of event states readable in the widget function.
cuicui.EVENT_STATES = {
    -- Number: Button number when widget is clicked or nil.
    click = true,
    -- Table: Cursor position (x: [1], y: [2]) when the widget is clicked or nil.
    cursor = true,
    -- Table: List of keys pressed ([key] = true or nil).
    keys = true,
}

--- List of hooks executed in the widget function.
cuicui.HOOKS = {
    -- Hook executed when the widget is clicked (mouse_click event).
    on_click = true,
    -- Hook executed when the widget is released (mouse_up event).
    on_release = true,
}

--- Index widgets table
--- @param self table: The widgets table.
--- @param key string: The name of the widget.
local function index_widgets(self, key)
    expect(2, key, "string")

    local status, widget = pcall(require, "cuicui.widget." .. key)

    if status then
        for name, types in pairs(cuicui.WIDGET_MODULE_STRUCT) do
            local ok = false
            for _, typ in ipairs(types) do
                if type(widget[name]) == typ then
                    ok = true
                    break
                end
            end

            if not ok then
                error("Invalid type for widget '" .. key .. "' field '" .. name .. "'", 3)
            end
        end
    else
        error("Invalid widget '" .. key .. "': " .. widget, 3)
    end

    self[key] = widget
    return widget
end

local widgets = setmetatable({}, {
    __index = index_widgets
})

--- Generate a stable unique ID based on the source file and line number of the caller.
local function gen_stable_id()
    local d = debug.getinfo(3)
    return d.source .. "-" .. tostring(d.currentline)
end

--- Create the base properties of a widget
---
--- @param tree table: The UI tree.
--- @param key string: The name of the widget.
--- @param parent_id string: The parent ID of the widget.
--- @param widget table: The widget table.
--- @return table: The widget properties.
local function make_props(tree, key, child_id, parent_id, widget)
    local props = {
        type = key,
        parent = parent_id,
        id = child_id,
        visible = true,
        h_expand = false,
        v_expand = false,
        children = {}
    }
    local old_props = tree.old_props[child_id];

    -- Set the default properties if they are not already set
    widget.populate_default_props(props, old_props, tree.event[child_id])

    return props
end

--- Check if the properties have changed
--- @param tree table: The UI tree.
--- @param props table: The new properties.
local function check_dirtiness(tree, props)
    local old_props = tree.old_props[props.id]

    -- New widget is always dirty
    if old_props == nil then
        tree.dirty[props.id] = true
        return
    end

    -- Helper function to recursively compare values
    local function values_equal(v1, v2)
        if type(v1) ~= type(v2) then
            return false
        end

        if type(v1) == "table" then
            -- Check all keys match
            for k, val in pairs(v1) do
                if not values_equal(val, v2[k]) then
                    return false
                end
            end
            for k in pairs(v2) do
                if v1[k] == nil then
                    return false
                end
            end
            return true
        else
            return v1 == v2
        end
    end

    -- Check if any property changed
    tree.dirty[props.id] = not values_equal(props, old_props)
end

--- Make a new UI table
--- @param tree table: The UI tree.
--- @param parent_props table: The parent ID of the widget.
local function make_ui(tree, parent_props)
    local parent_widget = widgets[parent_props.type]

    local function index(self, key)
        -- If the parent exists and the key exists in the parent's table
        -- It allows user to access the widget properties
        if cuicui.COMMON_PROPS[key] then
            return parent_props[key]
        elseif parent_widget.PROPS[key] then
            return parent_props[key]
        elseif cuicui.EVENT_STATES[key] then
            if tree.event[parent_props.id] then
                return tree.event[parent_props.id][key]
            else
                return nil
            end
        elseif cuicui.HOOKS[key] then
            local current_event = tree.event[parent_props.id]
            local old_event = tree.old_event[parent_props.id]

            return function(fn)
                expect(1, fn, "function", "nil")

                if current_event and fn then
                    if key == "on_click" then
                        if current_event.click and (not old_event or not old_event.click) then
                            fn(self)
                        end
                    elseif key == "on_release" then
                        if (not current_event.click) and (old_event and old_event.click) then
                            fn(self)
                        end
                    end
                end
            end
        end

        -- Fetch the widget from the widgets table
        local widget = widgets[key]

        -- Return the function that creates the widget
        return function(fn, inherit, user_id)
            expect(1, fn, "function", "nil")

            -- Generate an id
            local child_id
            if user_id then
                child_id = tostring(user_id)
            else
                child_id = gen_stable_id()
            end

            -- Create the widget properties
            local props = make_props(tree, key, child_id, parent_props.id, widget)

            -- Inherit properties from parent
            if inherit == nil or inherit then
                for name in pairs(widget.PROPS) do
                    if parent_props[name] ~= nil then
                        props[name] = parent_props[name]
                    end
                end
            end

            -- Create the UI table
            local ui = make_ui(tree, props)

            -- Call the function with a new UI table
            if fn then
                fn(ui)
            end

            -- Compose the widget
            widget.compose(props, ui)

            -- Accept the widget in the parent
            local err = parent_widget.accept_child(parent_props, props)
            if err then
                error(err, 2)
            end

            -- Check dirtiness
            check_dirtiness(tree, props)

            -- Add the widget to the tree
            tree.props[child_id] = props
            tree.event[child_id] = tree.event[child_id] or {}

            -- Add to the parent's children list
            table.insert(parent_props.children, child_id)
        end
    end

    local function newindex(_, key, value)
        -- Assign the value to the widget table
        if cuicui.COMMON_PROPS[key] then
            expect(1, value, table.unpack(cuicui.COMMON_PROPS[key]))

            if key == "id" then
                error("The 'id' property is read-only and cannot be modified after widget creation.", 2)
            end

            parent_props[key] = value
        elseif parent_widget.PROPS[key] then
            expect(1, value, table.unpack(parent_widget.PROPS[key]))
            parent_props[key] = value
        else
            error("Unknown property: " .. key, 2)
        end
    end

    local ui = setmetatable({}, {
        __index = index,
        __newindex = newindex
    })

    return ui
end

--- Entry point for the library
local function index_cuicui(_, key)
    -- Return the function that run the application
    return function(term, fn, event_handler)
        -- Get the peripheral side
        local monitor_name = nil
        if getmetatable(term) then
            local mt = getmetatable(term)

            if mt.__name == "peripheral" then
                monitor_name = mt.name
            end
        end

        -- Tree
        local tree = {
            props = {},
            old_props = {},
            old_event = {},
            event = {},
            render = {},
            old_render = {},
            dirty = {},
            buffer = {}
        }

        -- Fetch the widget from the widgets table
        local root_widget = widgets[key]

        -- Run the UI loop
        while true do
            -- Make props for the root widget
            local root_id = gen_stable_id()
            local root_props = make_props(tree, key, root_id, 0, root_widget)

            -- Make UI for the root widget
            local root_ui = make_ui(tree, root_props)

            -- Compute the tree
            fn(root_ui)

            -- Compose the widget
            root_widget.compose(root_props, root_ui)

            -- Check dirtiness of the root widget
            check_dirtiness(tree, root_props)

            -- Add the widget to the tree
            tree.props[root_id] = root_props
            tree.event[root_id] = tree.event[root_id] or {}

            -- Render the UI
            render.update_layout(tree, root_props, widgets, term)
            render.draw(tree, root_props, widgets, term, cuicui.DEBUG > 1)

            -- Set the cursor position to the top-left corner of the terminal
            -- For debugging purposes
            if cuicui.DEBUG > 0 then
                term.setCursorPos(1, 1)
                term.setTextColor(colors.white)
                term.setBackgroundColor(colors.black)

                -- Extract buffer data
                local buffer = {}
                for key, buf in pairs(tree.buffer) do
                    buffer[key] = {
                        width = buf.width,
                        height = buf.height,
                        x = buf.x,
                        y = buf.y,
                    }
                end

                local file = fs.open(cuicui.DEBUG_LOG_FILE, "w")
                file.write(textutils.serialize({
                    props = tree.props,
                    event = tree.event,
                    render = tree.render,
                    buffer = buffer,
                    dirty = tree.dirty
                }))
                file.close()
            end

            -- Clear the event tree
            tree.old_event = tree.event
            tree.event = ctable.copy(tree.old_event)

            -- Wait and process events until the UI needs to be updated
            if not event.process(tree, widgets, root_props, monitor_name, event_handler) then
                term.setCursorPos(1, 1)
                term.clear()
                return
            end

            -- Clear the tree
            tree.old_props = tree.props
            tree.old_render = tree.render
            tree.props = {}
            tree.render = {}
            tree.dirty = {}
            -- tree.buffer is NOT cleared here - managed by renderer with timeout
        end
    end
end

return setmetatable(cuicui, {
    __index = index_cuicui
})
