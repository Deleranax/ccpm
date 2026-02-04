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

-- TODO: Change event system to a single handle + top to bottom resolution

--- Debug
cuicui.DEBUG = false
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
    --- - Only propagate state properties (e.g., `checked`, `selected`, `scroll_offset`)
    --- - Do NOT propagate user-configurable properties (e.g., `text`, `color`, `spacing`)
    --- - The `old_props` parameter can be `nil` on the first render (check before accessing)
    --- - You only have access to this widget's properties, not the props_tree
    --- - This function must be deterministic (same inputs → same outputs)
    --- - You can use `props.id` to generate unique defaults if needed
    ---
    --- **Example:**
    --- ```
    --- function widget.populate_default_props(props, old_props)
    ---     -- Set default values
    ---     props.text = "Checkbox #" .. props.id
    ---     props.color = colors.white
    ---     props.checked = false
    ---
    ---     -- Propagate state from previous render
    ---     if old_props then
    ---         props.checked = old_props.checked
    ---     end
    --- end
    --- ```
    ---
    --- @param props table: Widget properties table to populate with default values
    --- @param old_props table|nil: Previous widget properties for state propagation (nil on first render)
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
    --- - **Best practice:** Use parent ID as prefix for child IDs (e.g., `tostring(props.id) .. "-1"`)
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
    ---         child_ui.id = tostring(props.id) .. "-indicator"
    ---         child_ui.text = props.checked and "[X]" or "[ ]"
    ---     end)
    ---     ui.label(function(child_ui)
    ---         child_ui.id = tostring(props.id) .. "-label"
    ---         child_ui.text = props.label or "Checkbox"
    ---     end)
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
    --- - Access this widget's properties via: `props_tree[id]`
    --- - Access the child's properties via: `child_props` (child is not in tree yet)
    --- - Access the child's widget type via: `child_props.type`
    --- - You can inspect other properties to make decisions
    --- - You can modify properties in `props_tree[id]` or `child_props` to adjust behavior (but remain deterministic)
    --- - This function must be deterministic (same inputs → same outputs)
    --- - **Container widgets:** Return `nil` to accept children (or check specific types)
    --- - **Non-container widgets:** Return an error message to reject all children
    ---
    --- **Example (container that accepts all children):**
    --- ```
    --- function widget.accept_child(props_tree, id, child_props)
    ---     return nil  -- Accept any child
    --- end
    --- ```
    ---
    --- **Example (non-container widget):**
    --- ```
    --- function widget.accept_child(props_tree, id, child_props)
    ---     return "Label widgets cannot have children"
    --- end
    --- ```
    ---
    --- **Example (selective container):**
    --- ```
    --- function widget.accept_child(props_tree, id, child_props)
    ---     if child_props.type == "label" or child_props.type == "button" then
    ---         return nil  -- Accept labels and buttons
    ---     else
    ---         return "This container only accepts label and button widgets"
    ---     end
    --- end
    --- ```
    ---
    --- @param props_tree table: Map of widget IDs to their properties (forms a tree via parent/child references)
    --- @param id any: The ID key for this widget in the props_tree
    --- @param child_props table: The child widget's properties (child is not in tree yet)
    --- @return nil|string: `nil` if child is accepted, or error message string if rejected
    accept_child = { "function" },

    --- Computes and stores the natural size (preferred width and height) of this widget.
    ---
    --- This function is called during the FIRST PASS of the layout algorithm in a "bottom-up"
    --- traversal, meaning children are processed before their parents. When this function is
    --- called for a widget, all of its children have already had their natural sizes computed.
    ---
    --- **Implementation guidelines:**
    --- - Access this widget's properties via: `props_tree[id]`
    --- - Access children's natural sizes via: `props_tree[child_id].natural_width` and `.natural_height`
    --- - Store results by setting: `props_tree[id].natural_width` and `props_tree[id].natural_height`
    --- - This function must be deterministic (same inputs → same outputs)
    --- - This function returns nothing; it only mutates the props_tree
    ---
    --- @param props_tree table: Map of widget IDs to their properties (forms a tree via parent/child references)
    --- @param id any: The ID key for this widget in the props_tree
    compute_natural_size = { "function" },

    --- Computes and stores the final layout (size and position) of this widget's children.
    ---
    --- This function is called during the SECOND PASS of the layout algorithm in a "top-down"
    --- traversal, meaning parents are processed before their children. When this function is
    --- called, the parent already has its final size allocated, and this function must decide
    --- how to distribute that space among the children.
    ---
    --- **Implementation guidelines:**
    --- - Access this widget's final size via: `props_tree[id].width` and `.height`
    --- - Access children's natural sizes via: `props_tree[child_id].natural_width` and `.natural_height`
    --- - Check if children expand via: `props_tree[child_id].h_expand` and `.v_expand`
    --- - Store results by setting: `props_tree[child_id].width`, `.height`, `.x`, and `.y`
    --- - This function must be deterministic (same inputs → same outputs)
    --- - This function returns nothing; it only mutates the props_tree
    --- - **Container widgets:** Implement logic to distribute space among children
    --- - **Non-container widgets:** Implement as an empty function (required but does nothing)
    ---
    --- @param props_tree table: Map of widget IDs to their properties (forms a tree via parent/child references)
    --- @param id any: The ID key for this widget in the props_tree
    compute_children_layout = { "function" },

    --- Renders the visual representation of this widget to a terminal/display object.
    ---
    --- This function is called during the rendering phase after layout has been computed.
    --- It should draw the widget's content to the provided terminal object. Child widgets
    --- are drawn automatically by the framework; you only need to draw this widget's content.
    ---
    --- **Implementation guidelines:**
    --- - Access this widget's properties via: `props_tree[id]`
    --- - The drawing area is positioned at (1, 1) relative to this widget
    --- - Use `props_tree[id].width` and `.height` for the allocated drawing area
    --- - The `term` object is a ComputerCraft Redirect (terminal, monitor, window, etc.)
    --- - Available methods: `setCursorPos()`, `setTextColor()`, `setBackgroundColor()`, `write()`, `clear()`, etc.
    --- - This function must be deterministic (same inputs → same outputs)
    --- - This function returns nothing
    --- - Do NOT draw children; the framework handles that automatically
    ---
    --- **Example:**
    --- ```
    --- function widget.draw(props_tree, id, term)
    ---     local data = props_tree[id]
    ---     if data.background_color then
    ---         term.setBackgroundColor(data.background_color)
    ---         term.clear()
    ---     end
    ---     term.setCursorPos(1, 1)
    ---     term.setTextColor(data.color)
    ---     term.write(data.text)
    --- end
    --- ```
    ---
    --- @param props_tree table: Map of widget IDs to their properties (forms a tree via parent/child references)
    --- @param id any: The ID key for this widget in the props_tree
    --- @param term table: ComputerCraft Redirect object (terminal, monitor, or window) to draw on
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
    --- The `event` table is a list where `event[1]` contains the event type (string), followed by
    --- additional parameters depending on the event type. Mouse events have coordinates relative to
    --- the widget origin (1-based). Refer to the official CC:Tweaked documentation for complete
    --- event field details.
    ---
    --- **Implementation guidelines:**
    --- - Access this widget's properties via: `props_tree[id]`
    --- - Check `event[1]` to determine which event occurred
    --- - Return `true` to consume the event (stop propagation to parents)
    --- - Return `nil` or `false` to allow the event to propagate to parents
    --- - **Note:** Only `mouse_click`, `mouse_drag`, `mouse_scroll`, and `key` events can be consumed
    --- - You can modify widget properties in `props_tree[id]` to change state
    --- - Use `sch.start_timer(time)` to schedule a timer (returns timer ID)
    --- - Use `sch.start_alarm(time)` to schedule an alarm (returns alarm ID)
    --- - Use `sch.cancel_timer(id)` to cancel a timer
    --- - Use `sch.cancel_alarm(id)` to cancel an alarm
    --- - This function should be deterministic (same inputs → same outputs)
    --- - Events are processed bottom-up (children before parents)
    ---
    --- **Example:**
    --- ```
    --- function widget.handle_event(props_tree, id, sch, event)
    ---     local data = props_tree[id]
    ---
    ---     if event[1] == "mouse_click" then
    ---         local button = event[2]
    ---         local x = event[3]
    ---         local y = event[4]
    ---         -- Gain focus and toggle checked state
    ---         if button == 1 then
    ---             data.focus = true  -- Request focus
    ---             data.checked = not data.checked
    ---             -- Schedule a timer to auto-uncheck after 2 seconds
    ---             data.timer_id = sch.start_timer(2)
    ---             return true  -- Consume the event
    ---         end
    ---     elseif event[1] == "key" and data.focus then
    ---         local key = event[2]
    ---         local held = event[3]
    ---         -- Toggle with space key when focused
    ---         if key == keys.space and not held then
    ---             data.checked = not data.checked
    ---             return true  -- Consume the event
    ---         end
    ---     elseif event[1] == "mouse_scroll" then
    ---         local direction = event[2]
    ---         -- Scroll content
    ---         data.scroll_offset = data.scroll_offset + direction
    ---         return true  -- Consume the event
    ---     elseif event[1] == "timer" then
    ---         local timer_id = event[2]
    ---         -- Check if this is our timer
    ---         if timer_id == data.timer_id then
    ---             data.checked = false
    ---             data.timer_id = nil
    ---         end
    ---         -- Timer events cannot be consumed
    ---     elseif event[1] == "lost_focus" then
    ---         -- Clean up when losing focus
    ---         data.focus = false
    ---         data.show_cursor = false
    ---         -- Cancel any pending timer
    ---         if data.timer_id then
    ---             sch.cancel_timer(data.timer_id)
    ---             data.timer_id = nil
    ---         end
    ---     end
    ---
    ---     return false  -- Don't consume, let parent handle it
    --- end
    --- ```
    ---
    --- @param props_tree table: Map of widget IDs to their properties (forms a tree via parent/child references)
    --- @param id any: The ID key for this widget in the props_tree
    --- @param sch table: Scheduler for managing timers and alarms (start_timer, start_alarm, cancel_timer, cancel_alarm)
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
    -- Number value when widget is clicked (which button) or nil.
    click = { "number", "nil" },
    -- Cursor position (x: [1], y: [2]) when the widget is clicked or nil.
    cursor = { "table", "nil" }
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
        error("Unknown widget '" .. key .. "'", 3)
    end

    self[key] = widget
    return widget
end

local widgets = setmetatable({}, {
    __index = index_widgets
})

--- Create the base properties of a widget
--- @param key string: The name of the widget.
--- @param parent_id any: The parent ID of the widget.
--- @param widget table: The widget table.
--- @param old_props_tree table: The old properties tree.
--- @return table: The widget properties.
local function make_props(key, parent_id, widget, old_props_tree)
    local props = {
        type = key,
        parent = parent_id,
        id = debug.getinfo(3).currentline,
        visible = true,
        h_expand = false,
        v_expand = false,
        children = {}
    }
    local old_props = old_props_tree[props.id];

    -- Propagate event states
    if old_props then
        for state in pairs(cuicui.EVENT_STATES) do
            props[state] = old_props[state]
        end
    end

    -- Set the default properties if they are not already set
    widget.populate_default_props(props, old_props)

    return props
end

--- Check if the properties have changed (outside render values)
--- @param props table: The new properties.
--- @param old_props table: The old properties.
local function set_dirtiness(props, old_props)
    if old_props == nil then
        props.dirty = true
        return
    end

    for key, value in pairs(props) do
        if not cuicui.EVENT_STATES[key] and old_props[key] ~= value then
            props.dirty = true
            return
        end
    end

    props.dirty = false
end

--- Make a new UI table
--- @param parent_props table: The parent ID of the widget.
--- @param old_props_tree table: The old properties tree.
--- @param props_tree table: The properties tree to populate.
local function make_ui(parent_props, old_props_tree, props_tree)
    local parent_widget = widgets[parent_props.type]

    local function index(_, key)
        -- If the parent exists and the key exists in the parent's table
        -- It allows user to access the widget properties
        if cuicui.COMMON_PROPS[key] then
            return parent_props[key]
        elseif parent_widget.PROPS[key] then
            return parent_props[key]
        else
            for state in pairs(cuicui.EVENT_STATES) do
                if key == state then
                    local old_parent_props = old_props_tree[parent_props.id]
                    if old_parent_props then
                        return old_parent_props[state]
                    else
                        return nil
                    end
                end
            end
        end

        -- Fetch the widget from the widgets table
        local widget = widgets[key]

        -- Return the function that creates the widget
        return function(fn)
            expect(1, fn, "function", "nil")

            -- Create the widget properties
            local props = make_props(key, parent_props.id, widget, old_props_tree)

            -- Create the UI table
            local ui = make_ui(props, old_props_tree, props_tree)

            -- Call the function with a new UI table
            if fn then
                fn(ui)
            end

            -- Compose the widget
            widget.compose(props, old_props, ui)

            -- Accept the widget in the parent
            local err = parent_widget.accept_child(props_tree, parent_props.id, props)
            if err then
                error(err, 2)
            end

            -- Check dirtiness
            set_dirtiness(props, old_props_tree[props.id])

            -- Add the widget to the tree
            props_tree[props.id] = props

            -- Add to the parent's children list
            table.insert(parent_props.children, props.id)
        end
    end

    local function newindex(_, key, value)
        -- Assign the value to the widget table
        if cuicui.COMMON_PROPS[key] then
            expect(1, value, table.unpack(cuicui.COMMON_PROPS[key]))

            if key == "id" and props_tree[key] then
                error("ID already exists: " .. key, 2)
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
    return function(term, fn)
        -- Get the peripheral side
        local monitor_name = nil
        if getmetatable(term) then
            local mt = getmetatable(term)

            if mt.__name == "peripheral" then
                monitor_name = mt.name
            end
        end

        -- Trees
        local props_tree = {}
        local old_props_tree = {}
        local render_tree = {}

        -- Fetch the widget from the widgets table
        local root_widget = widgets[key]

        local root_props = make_props(key, 0, root_widget, old_props_tree)

        -- Add the widget to the tree
        props_tree[root_props.id] = root_props

        -- Run the UI loop
        while true do
            -- Turn on visibility of root widget
            root_props.visible = true

            -- Compute the tree
            fn(make_ui(root_props, old_props_tree, props_tree))

            -- Compose the widget
            root_widget.compose(props, old_props, ui)

            -- Check dirtiness of the root widget
            local old_root_props = old_props_tree[root_props.id]
            set_dirtiness(root_props, old_root_props)

            -- Render the UI
            render.update_layout(props_tree, old_props_tree, term, root_props, old_root_props, widgets)
            render.draw(props_tree, render_tree, term, root_props, widgets)

            -- Wait and process events until the UI needs to be updated
            if not event.process(props_tree, render_tree, widgets, root_props, monitor_name) then
                term.setCursorPos(1, 1)
                term.clear()
                return
            end

            -- Log the tree to a file
            if cuicui.DEBUG then
                props_tree["_timestamp"] = os.time()
                local file = fs.open(cuicui.DEBUG_LOG_FILE, "w")
                file.write(textutils.serialize(props_tree))
                file.close()
                props_tree["_timestamp"] = nil
            end

            -- Clear the tree
            old_props_tree = ctable.copy(props_tree)
            props_tree = { [root_props.id] = root_props }
            root_props.children = {}
        end
    end
end

return setmetatable(cuicui, {
    __index = index_cuicui
})
