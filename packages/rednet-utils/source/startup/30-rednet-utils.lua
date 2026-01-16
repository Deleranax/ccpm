--[[
    rednet-utils - Utilities for Rednet
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

-- Some part of this code is inspired/copied from CraftOS sources (rednet API)
-- Copyright (C) 2017 Daniel Ratcliffe
-- https://github.com/cc-tweaked/CC-Tweaked/blob/mc-1.20.x/projects/core/src/main/resources/data/computercraft/lua/rom/apis/rednet.lua

local old_open = rednet.open

-- Overload the rednet.open function to automatically send a greet message to all routers
function rednet.open(modem)
    old_open(modem)

    -- Create the message
    local reply_channel = os.getComputerID() % rednet.MAX_ID_CHANNELS
    local message_wrapper = {
        nMessageID = math.random(1, 2147483647),
        nRecipient = rednet.CHANNEL_REPEAT,
        nSender = os.getComputerID(),
        sProtocol = "greet",
    }

    peripheral.call(modem, "transmit", rednet.CHANNEL_REPEAT, reply_channel, message_wrapper)
end
