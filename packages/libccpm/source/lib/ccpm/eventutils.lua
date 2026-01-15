--[[
    libccpm - Library for CCPM
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

local ctextutils = require("commons.ctextutils")

--- @export
local eventutils = {}

--- Dispatch an event to the event queue.
--- @param ... any: The arguments to pass to the event handler.
function eventutils.dispatch(...)
    os.queueEvent(...)
    coroutine.yield()
end

--- Process transaction events into printed progress messages.
function eventutils.process_transaction_events()
    local download_total = 1 / 0
    local download_count = 0
    local download_current = nil
    local download_progress = eventutils.make_progress("Downloading packages")

    local uninstall_total = 1 / 0
    local uninstall_count = 0
    local uninstall_current = nil
    local uninstall_progress = eventutils.make_progress("Uninstalling packages")

    local install_total = 1 / 0
    local install_count = 0
    local install_current = nil
    local install_progress = eventutils.make_progress("Installing packages")

    while true do
        local event = { os.pullEvent() }

        if event[1] == "ccpm_transaction_checking" then
            print("Checking transaction")
        elseif event[1] == "ccpm_transaction_downloading" then
            download_total = event[2]
            if download_total ~= 0 then
                download_progress(download_total, download_count, download_current)
            end
        elseif event[1] == "ccpm_package_downloading" then
            download_current = event[2]
            download_progress(download_total, download_count, download_current)
        elseif event[1] == "ccpm_package_downloaded" then
            download_count = download_count + 1
            download_progress(download_total, download_count, download_current)
        elseif event[1] == "ccpm_package_not_downloaded" then
            printError("Error while downloading " .. event[2] .. ": " .. event[3])
        elseif event[1] == "ccpm_transaction_uninstalling" then
            uninstall_total = event[2]
            if uninstall_total ~= 0 then
                uninstall_progress(uninstall_total, uninstall_count, uninstall_current)
            end
        elseif event[1] == "ccpm_package_uninstalling" then
            uninstall_current = event[2]
            uninstall_progress(uninstall_total, uninstall_count, uninstall_current)
        elseif event[1] == "ccpm_package_uninstalled" then
            uninstall_count = uninstall_count + 1
            uninstall_progress(uninstall_total, uninstall_count, uninstall_current)
        elseif event[1] == "ccpm_package_not_uninstalled" then
            printError("Error while uninstalling " .. event[2] .. ": " .. event[3])
        elseif event[1] == "ccpm_transaction_installing" then
            install_total = event[2]
            if install_total ~= 0 then
                install_progress(install_total, install_count, install_current)
            end
        elseif event[1] == "ccpm_package_installing" then
            install_current = event[2]
            install_progress(install_total, install_count, install_current)
        elseif event[1] == "ccpm_package_installed" then
            install_count = install_count + 1
            install_progress(install_total, install_count, install_current)
        elseif event[1] == "ccpm_package_not_installed" then
            printError("Error while installing " .. event[2] .. ": " .. event[3])
        elseif event[1] == "ccpm_transaction_completed" then
            print("Transaction completed.")
        elseif event[1] == "ccpm_transaction_failed" then
            printError("Transaction failed: " .. event[2])
        elseif event[1] == "ccpm_transaction_rolled_back" then
            print("Transaction rolled back.")
        elseif event[1] == "ccpm_file_conflict_storage" then
            printError("File conflict detected with local storage: " .. event[2] .. ": " .. event[3])
        elseif event[1] == "ccpm_file_conflict_package" then
            printError("File conflict detected with another package: " ..
                event[2] .. " and " .. event[3] .. ": " .. event[4])
        end
    end
end

--- Make a function to display progress.
--- @param message string: The message to display.
--- @param t? table | nil: The term to write to. Defaults to the current term.
--- @return function: A function that takes three arguments: total, count, and current.
function eventutils.make_progress(message, t)
    t = t or term

    return function(total, count, current)
        local percentage = tostring(math.floor((count / total) * 100))
        local last = total == count

        t.clearLine()

        if current and not last then
            t.write(ctextutils.pad("[", 4 - #percentage) .. percentage .. "%] " .. message .. " (" .. current .. ")")
        else
            t.write(ctextutils.pad("[", 4 - #percentage) .. percentage .. "%] " .. message)
        end

        t.setCursorPos(1, select(2, t.getCursorPos()))
        if last then
            print()
        end
    end
end

return eventutils
