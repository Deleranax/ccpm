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

--- @export
local fb = {}

--- Create a new framebuffer with the given width and height.
--- @param width number: The width of the framebuffer.
--- @param height number: The height of the framebuffer.
--- @param init_bg number | nil: The initial background color of the framebuffer.
--- @return table: The new framebuffer.
function fb.new(width, height, init_bg)
    expect(1, width, "number")
    expect(2, height, "number")
    expect(3, init_bg, "number", "nil")

    if width < 1 or height < 1 then
        error("Invalid dimensions: width and height must be positive integers", 2)
    end

    -- Private
    local text_buffer = {}
    local text_color_buffer = {}
    local background_color_buffer = {}
    local x = 1
    local y = 1
    local current_text_color = colors.toBlit(colors.white)
    local current_background_color = init_bg and colors.toBlit(init_bg) or colors.toBlit(colors.black)

    --- Blit to the framebuffer
    local function blit(text, text_color, background_color)
        if x > width or y > height or x < 1 or y < 1 then
            return
        end

        if #text ~= #text_color or #text ~= #background_color then
            error("Invalid input: length mismatch", 2)
        end

        -- Blit text in bounds
        for i = 1, math.min(#text, width - x + 1) do
            text_buffer[y][x] = text:sub(i, i)
            text_color_buffer[y][x] = text_color:sub(i, i)
            background_color_buffer[y][x] = background_color:sub(i, i)

            -- Increment x position
            x = x + 1
        end
    end

    local function clear_line(y)
        if y > height or y < 1 then
            return
        end

        if not text_buffer[y] then
            text_buffer[y] = {}
            text_color_buffer[y] = {}
            background_color_buffer[y] = {}
        end

        for i = 1, width do
            text_buffer[y][i] = " "
            text_color_buffer[y][i] = current_text_color
            background_color_buffer[y][i] = current_background_color
        end
    end

    local function clear()
        for i = 1, height do
            clear_line(i)
        end
    end

    -- Initialization
    clear()

    -- Public
    local framebuffer = {}

    -- FrameBuffer Specific functions

    --- Blit a rectangular region of the FrameBuffer onto a terminal.
    ---
    --- This efficiently transfers a portion of the FrameBuffer's contents to the specified
    --- terminal at the given coordinates, useful for partial screen updates.
    ---
    --- @param term term.Redirect The target terminal to blit onto.
    --- @param term_x number X coordinate on the terminal where the region will be placed (1-based).
    --- @param term_y number Y coordinate on the terminal where the region will be placed (1-based).
    --- @param fb_x number X coordinate of the top-left corner of the source region in the FrameBuffer (1-based).
    --- @param fb_y number Y coordinate of the top-left corner of the source region in the FrameBuffer (1-based).
    --- @param fb_width number Width of the region to copy from the FrameBuffer.
    --- @param fb_height number Height of the region to copy from the FrameBuffer.
    function framebuffer.blit_onto(term, term_x, term_y, fb_x, fb_y, fb_width, fb_height)
        local term_width, term_height = term.getSize()

        -- Clip
        if fb_y < 1 then
            fb_height = fb_height + fb_y - 1
            fb_y = 1
        end
        if fb_x < 1 then
            fb_width = fb_width + fb_x - 1
            fb_x = 1
        end

        -- Rectify input
        fb_width = math.min(width - fb_x + 1, fb_width)
        fb_height = math.min(height - fb_y + 1, fb_height)

        -- Clip
        if term_x < 1 then
            fb_x = fb_x - term_x + 1
            fb_width = fb_width + term_x - 1
            term_x = 1
        end
        if term_y < 1 then
            fb_y = fb_y - term_y + 1
            fb_height = fb_height + term_y - 1
            term_y = 1
        end
        if fb_width + term_x > term_width then
            fb_width = term_width - term_x + 1
        end
        if fb_height + term_y > term_height then
            fb_height = term_height - term_y + 1
        end

        -- Optimize
        if fb_width < 1 or fb_height < 1 then
            return
        end

        for i = 0, fb_height - 1 do
            local start = fb_x
            local stop = fb_x + fb_width - 1
            term.setCursorPos(term_x, term_y + i)
            term.blit(
                table.concat(text_buffer[fb_y + i], "", start, stop),
                table.concat(text_color_buffer[fb_y + i], "", start, stop),
                table.concat(background_color_buffer[fb_y + i], "", start, stop)
            )
        end
    end

    -- Type term.Redirect functions

    function framebuffer.write(text)
        blit(text, string.rep(current_text_color, #text), string.rep(current_background_color, #text))
    end

    function framebuffer.scroll(y)
        if y == 0 then return end

        local start = 1
        local stop = height
        local step = 1

        if y < 0 then
            start = height
            stop = 1
            step = -1
        end

        for i = start, stop, step do
            local from = i + y

            if from < 1 or from > height then
                for j = 1, width do
                    text_buffer[i][j] = " "
                    text_color_buffer[i][j] = current_text_color
                    background_color_buffer[i][j] = current_background_color
                end
            else
                text_buffer[i] = text_buffer[from]
                text_color_buffer[i] = text_color_buffer[from]
                background_color_buffer[i] = background_color_buffer[from]
            end
        end
    end

    function framebuffer.getCursorPos()
        return x, y
    end

    function framebuffer.setCursorPos(new_x, new_y)
        x = new_x
        y = new_y
    end

    function framebuffer.getCursorBlink()
        -- Not applicable
        return false
    end

    function framebuffer.setCursorBlink(...)
        -- Not applicable
    end

    function framebuffer.getSize()
        return width, height
    end

    function framebuffer.clear()
        clear()
    end

    function framebuffer.clearLine()
        clear_line(y)
    end

    function framebuffer.getTextColor()
        return colors.fromBlit(current_text_color)
    end

    framebuffer.getTextColour = framebuffer.getTextColor

    function framebuffer.setTextColor(color)
        current_text_color = colors.toBlit(color)
    end

    framebuffer.setTextColour = framebuffer.setTextColor

    function framebuffer.getBackgroundColor()
        return colors.fromBlit(current_background_color)
    end

    framebuffer.getBackgroundColour = framebuffer.getBackgroundColor

    function framebuffer.setBackgroundColor(color)
        current_background_color = colors.toBlit(color)
    end

    framebuffer.setBackgroundColour = framebuffer.setBackgroundColor

    function framebuffer.isColor()
        return true
    end

    framebuffer.isColour = framebuffer.isColor

    function framebuffer.blit(text, textColor, backgroundColor)
        if #text ~= #textColor or #text ~= #backgroundColor then
            error("Invalid input: length mismatch", 2)
        end

        blit(text, textColor, backgroundColor)
    end

    function framebuffer.setPaletteColor(...)
        -- Not applicable
    end

    framebuffer.setPaletteColour = framebuffer.setPaletteColor

    function framebuffer.getPaletteColor(...)
        -- Not applicable
        return 0, 0, 0
    end

    framebuffer.getPaletteColour = framebuffer.getPaletteColor

    return framebuffer
end

return fb
