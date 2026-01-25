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
local event = {}

--- Process events until the UI needs to be updated.
--- @param tree table: The properties tree of the UI
--- @param monitor_name string | nil: The name of the monitor to listen for touch events
--- @param event_handler function | nil: The event handler function to call when an event is received
--- @return boolean: True if the program should continue running, false if it should terminate
function event.process(tree, monitor_name, event_handler)
    while true do
        local event = { os.pullEventRaw() }

        if event[1] == "terminate" then
            return false
        elseif event[1] == "monitor_touch" and event[2] == monitor_name then
            break
        elseif event[1] == "mouse_click" then
            break
        elseif event_handler then
            if event_handler(event) then
                break
            end
        end
    end

    return true
end

return event
