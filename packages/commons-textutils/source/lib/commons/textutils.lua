--[[
    commons-textutils - A collection of common utilities: text manipulation
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

--- @export
local ctextutils = {}

--- Truncate text with ellipsis if it exceeds the specified width.
--- @param text string: The text to truncate.
--- @param width number: The maximum width for the text.
--- @return string: The truncated text with ellipsis if needed.
function ctextutils.truncate(text, width)
    text = tostring(text)
    if #text <= width then
        return text
    else
        if width <= 1 then
            return "\16"
        else
            return string.sub(text, 1, width - 1) .. "\187"
        end
    end
end

--- Pad text to a specified width with spaces, truncating if necessary.
--- @param text string: The text to pad.
--- @param width number: The target width for the text.
--- @return string: The padded or truncated text.
function ctextutils.pad(text, width)
    text = tostring(text)
    if #text >= width then
        return ctextutils.truncate(text, width)
    else
        return text .. string.rep(" ", width - #text)
    end
end

--- Write text and move to the next line, scrolling if necessary.
--- @param t table: The terminal to write to.
--- @param text string: The text to write.
function ctextutils.writeln(t, text)
    local _, height = t.getSize()
    t.write(text)
    local _, y = t.getCursorPos()
    if y >= height then
        t.scroll(1)
        t.setCursorPos(1, height)
    else
        t.setCursorPos(1, y + 1)
    end
end

--- Display a table with a header and rows.
--- @param header table: The header of the table (list of strings).
--- @param modes table: The modes of the columns (list of numbers).
---                     - Positive number: static width
---                     - Negative number: maximum width (content-based, capped at abs(mode))
---                     - Zero: fill remaining space
--- @param rows table: The rows of the table (list of lists of strings).
--- @param t table | nil: The terminal on which to display.
function ctextutils.print_table(header, modes, rows, t)
    expect(1, header, "table")
    expect(2, modes, "table")
    expect(3, rows, "table")
    expect(4, t, "table", "nil")

    -- Monitor or current terminal
    t = t or term

    local width, height = t.getSize()

    -- Calculate number of columns
    local num_cols = #header
    if num_cols == 0 then return end

    -- Calculate separator space: " | " between columns (3 chars each)
    local separator_space = (num_cols - 1) * 3
    local available_width = width - separator_space

    -- Step 1: Calculate content widths for all columns
    local content_widths = {}
    for i = 1, num_cols do
        content_widths[i] = #header[i]
        for _, row in ipairs(rows) do
            if row[i] then
                content_widths[i] = math.max(content_widths[i], #tostring(row[i]))
            end
        end
    end

    -- Step 2: Categorize columns by mode
    local static_cols = {}
    local max_cols = {}
    local fill_cols = {}

    for i = 1, num_cols do
        local mode = modes[i] or 0
        if mode > 0 then
            table.insert(static_cols, i)
        elseif mode < 0 then
            table.insert(max_cols, i)
        else
            table.insert(fill_cols, i)
        end
    end

    -- Step 3: Allocate widths
    local col_widths = {}
    local remaining_width = available_width

    -- Allocate static widths first
    for _, i in ipairs(static_cols) do
        col_widths[i] = math.max(1, modes[i])
        remaining_width = remaining_width - col_widths[i]
    end

    -- Allocate max widths (min of content and limit)
    for _, i in ipairs(max_cols) do
        local max_limit = math.abs(modes[i])
        col_widths[i] = math.max(1, math.min(content_widths[i], max_limit))
        remaining_width = remaining_width - col_widths[i]
    end

    -- Allocate fill columns
    if #fill_cols > 0 then
        -- Distribute remaining width equally among fill columns
        local fill_width = math.max(1, math.floor(remaining_width / #fill_cols))
        local extra = remaining_width - (fill_width * #fill_cols)

        for idx, i in ipairs(fill_cols) do
            if idx == #fill_cols then
                -- Last fill column gets remaining space (including rounding remainder)
                col_widths[i] = fill_width + extra
            else
                col_widths[i] = fill_width
            end
        end
    elseif remaining_width > 0 and #max_cols > 0 then
        -- No fill columns, but we have extra space - distribute among max columns
        -- that haven't reached their content width
        local expandable_cols = {}
        for _, i in ipairs(max_cols) do
            if col_widths[i] < content_widths[i] then
                table.insert(expandable_cols, i)
            end
        end

        if #expandable_cols > 0 then
            local extra_per_col = math.floor(remaining_width / #expandable_cols)
            local leftover = remaining_width - (extra_per_col * #expandable_cols)

            for idx, i in ipairs(expandable_cols) do
                local max_limit = math.abs(modes[i])
                local additional = extra_per_col
                if idx == #expandable_cols then
                    additional = additional + leftover
                end
                col_widths[i] = math.min(col_widths[i] + additional, max_limit)
            end
        end
    end

    -- Step 4: Print header
    local header_line = ""
    for i = 1, num_cols do
        header_line = header_line .. ctextutils.pad(header[i], col_widths[i])
        if i < num_cols then
            header_line = header_line .. " | "
        end
    end
    ctextutils.writeln(t, header_line)

    -- Step 5: Print separator line
    local separator = ""
    for i = 1, num_cols do
        separator = separator .. string.rep("-", col_widths[i])
        if i < num_cols then
            separator = separator .. "-+-"
        end
    end
    ctextutils.writeln(t, separator)

    -- Step 6: Print rows
    for _, row in ipairs(rows) do
        local row_line = ""
        for i = 1, num_cols do
            local cell = row[i] or ""
            row_line = row_line .. ctextutils.pad(cell, col_widths[i])
            if i < num_cols then
                row_line = row_line .. " | "
            end
        end
        ctextutils.writeln(t, row_line)
    end
end

return ctextutils
