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

    --- Boolean constant indicating whether this widget can contain child widgets.
    ---
    --- Set to `true` for container widgets (e.g., layout containers like vertical, horizontal, grid).
    --- Set to `false` for leaf widgets (e.g., labels, buttons, text inputs).
    ---
    --- **Impact on implementation:**
    --- - Container widgets must implement child layout logic in `compute_children_layout()`
    --- - Non-container widgets should leave `compute_children_layout()` as an empty function
    ---
    --- **Example:**
    --- ```
    --- IS_CONTAINER = true  -- For a vertical layout container
    --- IS_CONTAINER = false -- For a label widget
    --- ```
    IS_CONTAINER = { "boolean" },

    --- Populates default values for properties that were not set by the user.
    ---
    --- This function is called after the user has created a widget instance with their
    --- chosen properties. It should fill in sensible defaults for any properties that
    --- the user did not explicitly set.
    ---
    --- **Implementation guidelines:**
    --- - Modify the `props` table in-place (do NOT return anything)
    --- - Only set properties that are `nil` (use pattern: `props.x = props.x or default_value`)
    --- - You only have access to this widget's properties, not the props_tree
    --- - This function must be deterministic (same inputs → same outputs)
    --- - You can use `props.id` to generate unique defaults if needed
    ---
    --- **Example:**
    --- ```
    --- function widget.populate_default_props(props)
    ---     props.text = props.text or ("Label #" .. props.id)
    ---     props.color = props.color or colors.white
    ---     props.spacing = props.spacing or 0
    --- end
    --- ```
    ---
    --- @param props table: Widget properties with user-set values already populated
    populate_default_props = { "function" },

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

    --- Handles mouse click events that occur on this widget.
    ---
    --- This function is called when the user clicks on this widget. The coordinates are
    --- relative to the widget's origin (top-left corner at 1, 1). You can use this to
    --- implement interactive behavior like buttons, toggles, or selections.
    ---
    --- **Implementation guidelines:**
    --- - Access this widget's properties via: `props_tree[id]`
    --- - Coordinates `x` and `y` are relative to the widget (top-left = 1, 1)
    --- - The `button` parameter is a number from the OS event (1 = left, 2 = right, 3 = middle)
    --- - **Note:** For monitors, `button` is always 1 (left) as they only support one button
    --- - You can modify widget properties in `props_tree[id]` to change state
    --- - **Focus management:** Set `props_tree[id].focus = true` if the widget should gain focus
    --- - This function returns nothing
    --- - Click propagation to children is handled automatically by the framework
    --- - This function should be deterministic (same inputs → same outputs)
    ---
    --- **Example:**
    --- ```
    --- function widget.handle_click(props_tree, id, x, y, button)
    ---     local data = props_tree[id]
    ---     -- Gain focus when left-clicked
    ---     if button == 1 then
    ---         data.focus = true
    ---         data.selected = not data.selected
    ---     -- Handle right-click for context menu
    ---     elseif button == 2 then
    ---         data.show_context_menu = true
    ---     end
    ---     -- Track click position
    ---     data.last_click_x = x
    ---     data.last_click_y = y
    --- end
    --- ```
    ---
    --- @param props_tree table: Map of widget IDs to their properties (forms a tree via parent/child references)
    --- @param id any: The ID key for this widget in the props_tree
    --- @param x number: X-coordinate of the click relative to widget origin (1-based)
    --- @param y number: Y-coordinate of the click relative to widget origin (1-based)
    --- @param button number: Mouse button number from OS event (1=left, 2=right, 3=middle; always 1 for monitors)
    handle_click = { "function" },

    --- Handles mouse button release events that occur on this widget.
    ---
    --- This function is called when the user releases a mouse button on this widget. The
    --- coordinates are relative to the widget's origin (top-left corner at 1, 1).
    ---
    --- **Important:** For monitors, this event is simulated 0.5 seconds after the click
    --- because monitors don't have a native click-up event in ComputerCraft.
    ---
    --- **Event propagation when release happens outside the widget:**
    --- - If the mouse button is released outside this widget, `x` and `y` will be `0, 0`
    --- - The event will be fired to any widget the mouse is in when the release happens
    --- - The event will also be fired to every widget it was in when the click began
    --- - If a widget is in both sets, it only receives the event once (no duplicates)
    ---
    --- **Implementation guidelines:**
    --- - Access this widget's properties via: `props_tree[id]`
    --- - Coordinates `x` and `y` are relative to the widget (top-left = 1, 1)
    --- - **When `x == 0` and `y == 0`, the release happened outside this widget**
    --- - The `button` parameter is a number from the OS event (1 = left, 2 = right, 3 = middle)
    --- - **Note:** For monitors, `button` is always 1 (left) and fires 0.5s after click
    --- - You can modify widget properties in `props_tree[id]` to change state
    --- - This function returns nothing
    --- - This function should be deterministic (same inputs → same outputs)
    ---
    --- **Example:**
    --- ```
    --- function widget.handle_click_up(props_tree, id, x, y, button)
    ---     local data = props_tree[id]
    ---     -- Complete a drag operation
    ---     if button == 1 and data.dragging then
    ---         data.dragging = false
    ---         data.drag_end_x = x
    ---         data.drag_end_y = y
    ---     end
    ---     -- Reset button pressed state
    ---     data.button_pressed = false
    --- end
    --- ```
    ---
    --- @param props_tree table: Map of widget IDs to their properties (forms a tree via parent/child references)
    --- @param id any: The ID key for this widget in the props_tree
    --- @param x number: X-coordinate of the release relative to widget origin (1-based), or 0 if release happened outside widget
    --- @param y number: Y-coordinate of the release relative to widget origin (1-based), or 0 if release happened outside widget
    --- @param button number: Mouse button number from OS event (1=left, 2=right, 3=middle; always 1 for monitors)
    handle_click_up = { "function" },

    --- Handles key press events when the user presses a key.
    ---
    --- This function is called when a key is pressed down. The key code is provided as a
    --- number from the OS event system. You can use this to implement keyboard navigation,
    --- text input, shortcuts, or other keyboard-driven interactions.
    ---
    --- The `held` parameter indicates whether this is a repeat event from holding the key
    --- down (`true`) or the initial key press (`false`).
    ---
    --- **Important:** This function is fired regardless of whether the widget has focus.
    --- If your widget should only respond to keys when focused, check `props_tree[id].focus`
    --- at the beginning of your implementation.
    ---
    --- **Implementation guidelines:**
    --- - Access this widget's properties via: `props_tree[id]`
    --- - The `key` parameter is a number representing the key code from the OS
    --- - The `held` parameter is `true` for repeat events (holding key), `false` for initial press
    --- - Check `props_tree[id].focus` if the widget should only respond when focused
    --- - You can modify widget properties in `props_tree[id]` to change state
    --- - This function returns nothing
    --- - This function should be deterministic (same inputs → same outputs)
    ---
    --- **Example:**
    --- ```
    --- function widget.handle_key(props_tree, id, key, held)
    ---     local data = props_tree[id]
    ---     -- Only respond to keys when focused
    ---     if not data.focus then return end
    ---     -- Ignore repeat events for certain keys
    ---     if held and key == keys.enter then return end
    ---     -- Check for Enter key (keys.enter)
    ---     if key == keys.enter then
    ---         data.submitted = true
    ---     -- Check for arrow keys for navigation (allow repeats)
    ---     elseif key == keys.up then
    ---         data.selected_index = math.max(1, data.selected_index - 1)
    ---     end
    --- end
    --- ```
    ---
    --- @param props_tree table: Map of widget IDs to their properties (forms a tree via parent/child references)
    --- @param id any: The ID key for this widget in the props_tree
    --- @param key number: Key code from the OS event representing which key was pressed
    --- @param held boolean: True if this is a repeat event from holding the key down, false for initial press
    handle_key = { "function" },

    --- Handles key release events when the user releases a key.
    ---
    --- This function is called when a key is released after being pressed. The key code is
    --- provided as a number from the OS event system. This is useful for implementing actions
    --- that should occur when a key is released rather than pressed, or for tracking key
    --- hold durations.
    ---
    --- **Important:** This function is fired regardless of whether the widget has focus.
    --- If your widget should only respond to keys when focused, check `props_tree[id].focus`
    --- at the beginning of your implementation.
    ---
    --- **Implementation guidelines:**
    --- - Access this widget's properties via: `props_tree[id]`
    --- - The `key` parameter is a number representing the key code from the OS
    --- - Check `props_tree[id].focus` if the widget should only respond when focused
    --- - You can modify widget properties in `props_tree[id]` to change state
    --- - This function returns nothing
    --- - This function should be deterministic (same inputs → same outputs)
    ---
    --- **Example:**
    --- ```
    --- function widget.handle_key_up(props_tree, id, key)
    ---     local data = props_tree[id]
    ---     -- Only respond to keys when focused
    ---     if not data.focus then return end
    ---     -- Track key release for hold duration calculation
    ---     if key == keys.space then
    ---         data.space_held = false
    ---         data.hold_duration = os.clock() - data.press_time
    ---     end
    --- end
    --- ```
    ---
    --- @param props_tree table: Map of widget IDs to their properties (forms a tree via parent/child references)
    --- @param id any: The ID key for this widget in the props_tree
    --- @param key number: Key code from the OS event representing which key was released
    handle_key_up = { "function" },

    --- Handles the event when this widget loses focus.
    ---
    --- This function is called when the widget that previously had focus loses it (either
    --- because another widget gained focus or focus was cleared entirely). This is useful
    --- for cleanup operations, saving state, or resetting visual indicators.
    ---
    --- **Implementation guidelines:**
    --- - Access this widget's properties via: `props_tree[id]`
    --- - You can modify widget properties in `props_tree[id]` to change state
    --- - This function returns nothing
    --- - This function should be deterministic (same inputs → same outputs)
    --- - Common use cases: clear selections, save input, reset visual state
    ---
    --- **Example:**
    --- ```
    --- function widget.handle_lost_focus(props_tree, id)
    ---     local data = props_tree[id]
    ---     -- Save any pending changes
    ---     data.pending_input = nil
    ---     -- Reset visual state
    ---     data.show_cursor = false
    ---     -- Validate and commit input
    ---     if data.text and #data.text > 0 then
    ---         data.committed_text = data.text
    ---     end
    --- end
    --- ```
    ---
    --- @param props_tree table: Map of widget IDs to their properties (forms a tree via parent/child references)
    --- @param id any: The ID key for this widget in the props_tree
    handle_lost_focus = { "function" }
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
    -- Boolean value describing whether the widget has focus.
    focus = { "boolean", "nil" },
    -- Number value wehen widget is clicked (which button) or nil.
    click = { "number", "nil" }
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
--- @param old_props table | nil: The old properties.
--- @return table: The widget properties.
local function make_props(key, parent_id, widget, old_props)
    local props = {
        type = key,
        parent = parent_id,
        id = debug.getinfo(3).currentline,
        visible = true,
        h_expand = false,
        v_expand = false,
    }

    -- If the widget is a container, add an empty children table
    if widget.IS_CONTAINER then
        props.children = {}
    end

    -- Set the default properties if they are not already set
    widget.populate_default_props(props)

    -- If old properties exist, copy them to the new properties
    if old_props then
        for state in pairs(cuicui.EVENT_STATES) do
            props[state] = old_props[state]
        end
    end

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
                    return parent_props[state]
                end
            end
        end

        -- Fetch the widget from the widgets table
        local widget = widgets[key]

        -- Return the function that creates the widget
        return function(fn)
            expect(1, fn, "function", "nil")

            -- Create the widget properties
            local props = make_props(key, parent_props.id, widget, old_props_tree[key])

            -- Call the function with a new UI table
            if fn then
                fn(make_ui(props, old_props_tree, props_tree))
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

        -- Check that the widget is a container
        if not root_widget.IS_CONTAINER then
            error("Root widget must be a container", 2)
        end

        local root_props = make_props(key, 0, root_widget, nil)

        -- Add the widget to the tree
        props_tree[root_props.id] = root_props

        -- Run the UI loop
        while true do
            -- Turn on visibility of root widget
            root_props.visible = true

            -- Compute the tree
            fn(make_ui(root_props, old_props_tree, props_tree))

            -- Check dirtiness of the root widget
            local old_root_props = old_props_tree[root_props.id]
            set_dirtiness(root_props, old_root_props)

            -- Render the UI
            render.update_layout(props_tree, old_props_tree, term, root_props, old_root_props, widgets)
            render.draw(props_tree, render_tree, term, root_props, widgets)

            -- Wait and process events until the UI needs to be updated
            if not event.process(props_tree, render_tree, widgets, monitor_name) then
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
