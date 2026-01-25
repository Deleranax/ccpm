# cuicui - Modular Immediate Mode GUI Library

A lightweight, modular immediate mode GUI library for ComputerCraft with lazy-loaded widgets.

---

## Table of Contents

### Part 1: Using cuicui (UI Designers)
- [Getting Started](#getting-started)
- [Basic Usage](#basic-usage)
- [Widget Invocation](#widget-invocation)
- [Common Patterns](#common-patterns)
- [Installing Widget Packages](#installing-widget-packages)

### Part 2: Creating Widgets (Widget Developers)
- [Widget Development Overview](#widget-development-overview)
- [Widget Structure](#widget-structure)
- [Widget Lifecycle](#widget-lifecycle)
- [Publishing Widget Packages](#publishing-widget-packages)
- [Tips and Best Practices](#tips-and-best-practices)

---

# Part 1: Using cuicui (UI Designers)

This section explains how to use cuicui to build user interfaces.

## Getting Started

### Installation

```bash
ccpm install cuicui
```

### Basic Example

```lua
local cuicui = require("cuicui")

-- Create a simple UI
cuicui.vertical(term.current(), function(ui)
    ui.color = colors.black
    ui.h_expand = true
    
    ui.label(function(ui)
        ui.text = "Hello, World!"
        ui.color = colors.white
        ui.id = "greeting"
    end)
end)
```

---

## Basic Usage

### The Immediate Mode Pattern

cuicui uses an immediate mode approach where you describe your UI every frame:

```lua
local cuicui = require("cuicui")

local counter = 0

while true do
    counter = counter + 1
    
    cuicui.vertical(term.current(), function(ui)
        ui.label(function(ui)
            ui.text = "Counter: " .. counter
            -- No id needed - line number is unique
        end)
    end)
    
    os.sleep(1)
end
```

### Widget IDs

Widget IDs are **automatically generated** from the line number of the invocation, providing stable unique identifiers across UI rebuilds.

**You only need to manually set `ui.id` when creating widgets in loops**, where multiple widgets share the same line number:

```lua
-- NO ID NEEDED - line number provides unique ID
ui.label(function(ui)
    ui.text = "Static Label"
end)

-- ID REQUIRED - multiple widgets on same line
for i = 1, 10 do
    ui.label(function(ui)
        ui.text = "Item " .. i
        ui.id = "item_" .. i  -- Required: distinguishes loop iterations
    end)
end
```

**Important:** Always set explicit IDs for widgets created in loops to ensure proper tracking and state management.

---

## Widget Invocation

### Root Widget vs Child Widget

There are two ways to create widgets:

#### Root Widget (Top-Level)

Use `cuicui.widgetname(term, callback)` to create the root widget:

```lua
local cuicui = require("cuicui")

cuicui.vertical(term.current(), function(ui)
    -- Configure root widget properties
    ui.color = colors.black
    ui.h_expand = true
    
    -- Add children here...
end)
```

The first argument is always a terminal/monitor/window object.

#### Child Widget (Inside Container)

Use `ui.widgetname(callback)` to create child widgets:

```lua
cuicui.vertical(term.current(), function(ui)
    -- This is a child widget (no id needed - unique line)
    ui.label(function(ui)
        ui.text = "I'm a child"
    end)
    
    -- Another child widget (no id needed - different line)
    ui.label(function(ui)
        ui.text = "I'm also a child"
    end)
end)
```

### Nested Containers

You can nest container widgets:

```lua
cuicui.vertical(term.current(), function(ui)
    ui.color = colors.black
    
    -- Nested horizontal container
    ui.horizontal(function(ui)
        ui.spacing = 2
        ui.id = "row1"
        
        ui.label(function(ui)
            ui.text = "Left"
        end)
        
        ui.label(function(ui)
            ui.text = "Right"
        end)
    end)
end)
```

---

## Common Patterns

### Expansion and Alignment

```lua
cuicui.vertical(term.current(), function(ui)
    ui.label(function(ui)
        ui.text = "I expand to fill width"
        ui.h_expand = true  -- Horizontal expansion
    end)
    
    ui.label(function(ui)
        ui.text = "I expand to fill height"
        ui.v_expand = true  -- Vertical expansion
    end)
end)
```

### Conditional Rendering

```lua
local show_error = true

cuicui.vertical(term.current(), function(ui)
    ui.label(function(ui)
        ui.text = "Welcome"
    end)
    
    if show_error then
        ui.label(function(ui)
            ui.text = "Error occurred!"
            ui.color = colors.red
        end)
    end
end)
```

### Dynamic Lists

```lua
local items = {"Apple", "Banana", "Cherry"}

cuicui.vertical(term.current(), function(ui)
    for i, item in ipairs(items) do
        ui.label(function(ui)
            ui.text = item
            ui.id = "item_" .. i  -- ID REQUIRED in loops
        end)
    end
end)
```

---

## Installing Widget Packages

The cuicui ecosystem includes third-party widget packages:

```bash
# Install a widget package
ccpm install cuicui-widget-button

# Use it in your code
cuicui.vertical(term.current(), function(ui)
    ui.button(function(ui)
        ui.text = "Click Me"
        -- No id needed - unique line number
    end)
end)
```

Widget packages follow the naming convention: `cuicui-widget-<name>`

---

## Debugging

Enable debug mode to inspect the widget tree:

```lua
local cuicui = require("cuicui")
cuicui.DEBUG = true  -- Outputs to cuicui_debug_tree.json
```

---

# Part 2: Creating Widgets (Widget Developers)

This section explains how to create custom widgets for cuicui.

## Widget Development Overview

### How Widget Loading Works

Widgets are loaded **lazily** when first invoked:

1. User calls `ui.mywidget()` or `cuicui.mywidget()`
2. System loads `/lib/cuicui/widget/mywidget.lua`
3. Widget module is validated against `WIDGET_MODULE_STRUCT`
4. If validation fails, the program crashes with an error
5. If validation succeeds, the widget is registered and used

### Key Requirements

- Widget files must be named after their invocation method
- Widgets must export a table matching `WIDGET_MODULE_STRUCT`
- All functions must be deterministic (same inputs → same outputs)
- No side effects (I/O, timers, global state) allowed

---

## Widget Structure

All widgets must conform to `WIDGET_MODULE_STRUCT`. Here's the complete structure:

```lua
--- @export
local widget = {}

-- Public properties users can set
widget.PROPS = {
    text = { "string" },
    color = { "number", "nil" }  -- Multiple types: optional property
}

-- Is this a container widget?
widget.IS_CONTAINER = false  -- or true

-- Populate default values
function widget.populate_default_props(props)
    props.text = props.text or "Default"
    props.color = props.color or colors.white
end

-- FIRST PASS: Compute natural size (bottom-up)
function widget.compute_natural_size(props_tree, id)
    local data = props_tree[id]
    data.natural_width = #data.text
    data.natural_height = 1
end

-- SECOND PASS: Layout children (top-down)
function widget.compute_children_layout(props_tree, id)
    -- Empty for non-containers
    -- Implement layout logic for containers
end

-- Render the widget
function widget.draw(props_tree, id, term)
    local data = props_tree[id]
    term.setTextColor(data.color)
    term.write(data.text)
end

-- Handle mouse click
function widget.handle_click(props_tree, id, x, y, button)
    local data = props_tree[id]
    if button == 1 then
        data.focus = true
    end
end

-- Handle mouse release
function widget.handle_click_up(props_tree, id, x, y, button)
    -- Optional: implement if needed
end

-- Handle key press
function widget.handle_key(props_tree, id, key)
    local data = props_tree[id]
    if not data.focus then return end
    -- Handle key...
end

-- Handle key release
function widget.handle_key_up(props_tree, id, key)
    -- Optional: implement if needed
end

-- Handle lost focus
function widget.handle_lost_focus(props_tree, id)
    local data = props_tree[id]
    data.show_cursor = false
end

return widget
```

---

## Widget Lifecycle

Understanding the lifecycle is crucial for correct implementation:

### 1. Creation Phase
- User calls `ui.mywidget(function(ui) ... end)`
- Properties are set via the callback
- `populate_default_props(props)` fills in missing values

### 2. Layout Phase

#### First Pass (Bottom-Up)
- `compute_natural_size(props_tree, id)` is called
- Children are processed first, then parents
- Store preferred size in `natural_width` and `natural_height`

#### Second Pass (Top-Down)
- `compute_children_layout(props_tree, id)` is called
- Parents are processed first, then children
- Set children's final `width`, `height`, `x`, `y`
- Honor `h_expand` and `v_expand` properties

### 3. Rendering Phase
- `draw(props_tree, id, term)` renders the widget
- Children are drawn automatically by the framework

### 4. Event Handling Phase
- `handle_click(props_tree, id, x, y, button)` on mouse down
- `handle_click_up(props_tree, id, x, y, button)` on mouse up
- `handle_key(props_tree, id, key)` on key press
- `handle_key_up(props_tree, id, key)` on key release
- `handle_lost_focus(props_tree, id)` when focus is lost

---

## Detailed Member Reference

### `PROPS` (table)

Defines public properties users can set.

**Format:** `property_name = { "type1", "type2", ... }`

**Supported types:** `"string"`, `"number"`, `"boolean"`, `"table"`, `"function"`, `"nil"`

**Example:**
```lua
widget.PROPS = {
    text = { "string" },                    -- Required string
    color = { "number", "nil" },            -- Optional number
    callback = { "function", "nil" },       -- Optional function
    data = { "table" }                      -- Required table
}
```

---

### `IS_CONTAINER` (boolean)

Indicates whether this widget can contain children.

**Example:**
```lua
widget.IS_CONTAINER = false  -- Leaf widget (label, button, input)
widget.IS_CONTAINER = true   -- Container widget (vertical, horizontal, grid)
```

---

### `populate_default_props(props)` (function)

Sets default values for properties not provided by the user.

**Parameters:**
- `props` (table): Widget properties with user-set values

**Returns:** Nothing (modifies `props` in-place)

**Must be deterministic**

**Example:**
```lua
function widget.populate_default_props(props)
    props.text = props.text or ("Widget #" .. props.id)
    props.color = props.color or colors.white
    props.spacing = props.spacing or 0
    props.align = props.align or "left"
end
```

**Note:** You only have access to this widget's properties, not the props_tree.

---

### `compute_natural_size(props_tree, id)` (function)

**FIRST PASS** - Computes the widget's preferred size (bottom-up).

**Parameters:**
- `props_tree` (table): Map of widget IDs to their properties
- `id` (any): The ID key for this widget

**Returns:** Nothing (modifies `props_tree[id]`)

**Must be deterministic**

**Called:** After all children have computed their sizes

**Implementation:**
- Access this widget's properties: `props_tree[id]`
- Access children's sizes: `props_tree[child_id].natural_width` and `.natural_height`
- Store results: `props_tree[id].natural_width` and `.natural_height`

**Example (Non-Container):**
```lua
function widget.compute_natural_size(props_tree, id)
    local data = props_tree[id]
    data.natural_width = #data.text
    data.natural_height = 1
end
```

**Example (Container):**
```lua
function widget.compute_natural_size(props_tree, id)
    local data = props_tree[id]
    data.natural_width = 0
    data.natural_height = 0
    
    for _, child_id in ipairs(data.children) do
        local child = props_tree[child_id]
        data.natural_width = math.max(data.natural_width, child.natural_width)
        data.natural_height = data.natural_height + child.natural_height
    end
end
```

---

### `compute_children_layout(props_tree, id)` (function)

**SECOND PASS** - Computes final size and position of children (top-down).

**Parameters:**
- `props_tree` (table): Map of widget IDs to their properties
- `id` (any): The ID key for this widget

**Returns:** Nothing (modifies `props_tree`)

**Must be deterministic**

**Called:** Before children are laid out

**Implementation:**
- Access this widget's final size: `props_tree[id].width` and `.height`
- Access children's natural sizes: `props_tree[child_id].natural_width` and `.natural_height`
- Check expansion: `props_tree[child_id].h_expand` and `.v_expand`
- Set children's final properties: `width`, `height`, `x`, `y`

**For non-containers:** Leave empty

**Example (Container - Vertical Layout):**
```lua
function widget.compute_children_layout(props_tree, id)
    local data = props_tree[id]
    local y_offset = 1
    
    for _, child_id in ipairs(data.children) do
        local child = props_tree[child_id]
        
        -- Set position
        child.x = 1
        child.y = y_offset
        
        -- Set size (expand if needed)
        child.width = child.h_expand and data.width or child.natural_width
        child.height = child.v_expand and data.height or child.natural_height
        
        -- Update offset
        y_offset = y_offset + child.height + (data.spacing or 0)
    end
end
```

---

### `draw(props_tree, id, term)` (function)

Renders the widget to the screen.

**Parameters:**
- `props_tree` (table): Map of widget IDs to their properties
- `id` (any): The ID key for this widget
- `term` (table): ComputerCraft Redirect object (terminal, monitor, window)

**Returns:** Nothing

**Must be deterministic**

**Implementation:**
- Access widget properties: `props_tree[id]`
- Drawing origin is (1, 1) relative to this widget
- Use `term` methods: `setCursorPos()`, `setTextColor()`, `setBackgroundColor()`, `write()`, `clear()`
- Do NOT draw children manually (handled by framework)

**Example:**
```lua
function widget.draw(props_tree, id, term)
    local data = props_tree[id]
    
    -- Draw background
    if data.background_color then
        term.setBackgroundColor(data.background_color)
        term.clear()
    end
    
    -- Draw text
    term.setCursorPos(1, 1)
    term.setTextColor(data.color or colors.white)
    term.write(data.text)
end
```

---

### `handle_click(props_tree, id, x, y, button)` (function)

Handles mouse button press events.

**Parameters:**
- `props_tree` (table): Map of widget IDs to their properties
- `id` (any): The ID key for this widget
- `x` (number): X-coordinate relative to widget (1-based)
- `y` (number): Y-coordinate relative to widget (1-based)
- `button` (number): Mouse button (1=left, 2=right, 3=middle; always 1 for monitors)

**Returns:** Nothing

**Must be deterministic**

**Implementation:**
- Coordinates are relative to widget's top-left corner (1, 1)
- Set `props_tree[id].focus = true` to gain focus
- Modify widget state as needed

**Example:**
```lua
function widget.handle_click(props_tree, id, x, y, button)
    local data = props_tree[id]
    
    if button == 1 then
        -- Gain focus on left-click
        data.focus = true
        data.selected = not data.selected
    elseif button == 2 then
        -- Show context menu on right-click
        data.show_context_menu = true
    end
end
```

---

### `handle_click_up(props_tree, id, x, y, button)` (function)

Handles mouse button release events.

**Parameters:**
- `props_tree` (table): Map of widget IDs to their properties
- `id` (any): The ID key for this widget
- `x` (number): X-coordinate relative to widget (1-based)
- `y` (number): Y-coordinate relative to widget (1-based)
- `button` (number): Mouse button (1=left, 2=right, 3=middle; always 1 for monitors)

**Returns:** Nothing

**Must be deterministic**

**Important:** For monitors, this is simulated 0.5s after click (no native event)

**Example:**
```lua
function widget.handle_click_up(props_tree, id, x, y, button)
    local data = props_tree[id]
    
    if data.dragging then
        data.dragging = false
        data.drag_end_x = x
        data.drag_end_y = y
    end
    
    data.button_pressed = false
end
```

---

### `handle_key(props_tree, id, key)` (function)

Handles key press events.

**Parameters:**
- `props_tree` (table): Map of widget IDs to their properties
- `id` (any): The ID key for this widget
- `key` (number): Key code from OS event

**Returns:** Nothing

**Must be deterministic**

**Important:** Fired for ALL widgets regardless of focus. Check `props_tree[id].focus` if needed.

**Example:**
```lua
function widget.handle_key(props_tree, id, key)
    local data = props_tree[id]
    
    -- Only respond when focused
    if not data.focus then return end
    
    if key == keys.enter then
        data.submitted = true
    elseif key == keys.up then
        data.selected_index = math.max(1, data.selected_index - 1)
    elseif key == keys.down then
        data.selected_index = math.min(#data.items, data.selected_index + 1)
    end
end
```

---

### `handle_key_up(props_tree, id, key)` (function)

Handles key release events.

**Parameters:**
- `props_tree` (table): Map of widget IDs to their properties
- `id` (any): The ID key for this widget
- `key` (number): Key code from OS event

**Returns:** Nothing

**Must be deterministic**

**Important:** Fired for ALL widgets regardless of focus. Check `props_tree[id].focus` if needed.

**Example:**
```lua
function widget.handle_key_up(props_tree, id, key)
    local data = props_tree[id]
    
    if not data.focus then return end
    
    if key == keys.space then
        data.space_held = false
        data.hold_duration = os.clock() - data.press_time
    end
end
```

---

### `handle_lost_focus(props_tree, id)` (function)

Called when the widget loses focus.

**Parameters:**
- `props_tree` (table): Map of widget IDs to their properties
- `id` (any): The ID key for this widget

**Returns:** Nothing

**Must be deterministic**

**Use cases:** Cleanup, saving state, resetting visual indicators

**Example:**
```lua
function widget.handle_lost_focus(props_tree, id)
    local data = props_tree[id]
    
    -- Save pending input
    if data.text and #data.text > 0 then
        data.committed_text = data.text
    end
    
    -- Reset visual state
    data.show_cursor = false
    data.pending_input = nil
end
```

---

## Publishing Widget Packages

### Package Structure

Create a package named `cuicui-widget-<name>`:

```
cuicui-widget-mybutton/
├── manifest.json
└── source/
    └── lib/
        └── cuicui/
            └── widget/
                └── mybutton.lua
```

### Manifest Example

```json
{
  "description": "A custom button widget for cuicui",
  "license": "GPL-3.0-or-later",
  "authors": ["Your Name <your.email@example.com>"],
  "maintainers": ["Your Name <your.email@example.com>"],
  "version": "1.0.0",
  "dependencies": ["cuicui"]
}
```

**Important:** Always declare `cuicui` in the `dependencies` array.

### Publishing

1. Create your package structure
2. Test thoroughly
3. Publish to your package repository
4. Users install with: `ccpm install cuicui-widget-mybutton`

### Usage After Installation

```lua
local cuicui = require("cuicui")

-- Use as root widget
cuicui.mybutton(term.current(), function(ui)
    ui.text = "Root Button"
end)

-- Or as child widget
cuicui.vertical(term.current(), function(ui)
    ui.mybutton(function(ui)
        ui.text = "Child Button"
    end)
end)
```

---

## Tips and Best Practices

### General

1. **Start simple**: Create a non-container widget first before attempting containers
2. **Test on monitors**: Remember monitors have different click behavior (0.5s delay for click_up)
3. **Validate inputs**: Check property types and ranges in `populate_default_props()`
4. **Document properties**: Add comments explaining what each property does
5. **Set IDs in loops only**: Set explicit `ui.id` for widgets created in loops (line numbers handle other cases)

### Determinism

All functions must be deterministic:
- ✅ **DO**: Use input parameters and widget properties
- ❌ **DON'T**: Use `os.time()`, `math.random()`, global variables, or I/O

### Focus Management

- Only check `focus` in `handle_key` and `handle_key_up` when necessary
- Set `props_tree[id].focus = true` in `handle_click` to gain focus
- Clean up in `handle_lost_focus`

### Layout

- Respect `h_expand` and `v_expand` in `compute_children_layout()`
- Always set `x`, `y`, `width`, `height` for children
- Use `natural_width` and `natural_height` as starting points

### Drawing

- Draw relative to (1, 1)
- Clear background if needed
- Don't draw outside widget bounds
- Don't draw children manually

---

## Examples

### Built-in Widgets

- **label**: `/lib/cuicui/widget/label.lua` - Simple non-container widget
- **vertical**: `/lib/cuicui/widget/vertical.lua` - Container widget with vertical layout

### Complete Program

See `/bin/cuicui-world.lua` for a complete example showing:
- Root widget creation with `cuicui.vertical()`
- Child widget creation with `ui.label()`
- Dynamic widget creation in loops
- Proper ID assignment

---

## Debugging

### Enable Debug Mode

```lua
local cuicui = require("cuicui")
cuicui.DEBUG = true
```

This outputs the widget tree to `cuicui_debug_tree.json`.

### Common Issues

**Widget not loading:**
- Check file name matches invocation: `ui.mywidget()` → `mywidget.lua`
- Verify file is in `/lib/cuicui/widget/`

**Validation errors:**
- Ensure all required functions are implemented
- Check function signatures match `WIDGET_MODULE_STRUCT`
- Verify `PROPS` and `IS_CONTAINER` are present

**Layout issues:**
- Check `compute_natural_size()` sets `natural_width` and `natural_height`
- Verify `compute_children_layout()` sets `width`, `height`, `x`, `y` for all children
- Ensure coordinates are 1-based, not 0-based

---

## Reference

### Key Concepts

- **Props Tree**: Map of widget IDs to their properties (forms a tree via parent/child references)
- **Natural Size**: Widget's preferred size before layout constraints
- **Final Size**: Widget's actual size after layout (may differ due to expansion)
- **Expansion**: `h_expand` and `v_expand` allow widgets to fill available space
- **Focus**: Only one widget has focus at a time for keyboard input

### Important Properties

Every widget has these properties automatically:
- `id`: Unique identifier (auto-generated from line number, or user-specified in loops)
- `children`: Array of child widget IDs (containers only)
- `parent`: Parent widget ID
- `focus`: Boolean indicating focus state
- `h_expand`: Boolean for horizontal expansion
- `v_expand`: Boolean for vertical expansion
- `natural_width`, `natural_height`: Computed in first pass
- `width`, `height`, `x`, `y`: Set in second pass

---

## License

cuicui is licensed under the GNU General Public License v3.0 or later.
See <https://www.gnu.org/licenses/> for details.
