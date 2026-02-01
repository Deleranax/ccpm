--[[
    rednet-router - Router for Rednet packets
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

local ctextutils = require("commons.textutils")
local cfileutils = require("commons.fileutils")

local LOOKUP_TABLE_FILE = "/.data/rednet-router/lookup_table.json"
local REDNET_MESSAGE_STRUCT = {
    nMessageID = "number",
    nRecipient = "number",
    nSender = "number"
}

local load, save = cfileutils.make_store(LOOKUP_TABLE_FILE)

local modems = {}
local lookup_table = load()
local received_messages = {}
local messages_timeout = {}

--- Get the channel ID for a given ID
local function id_as_channel(id)
    return (id or os.getComputerID()) % rednet.MAX_ID_CHANNELS
end

--- Handle modem messages
local function modem_handler(modem, channel, reply_channel, message)
    -- Verify rednet message structure
    if type(message) ~= "table" then
        return
    end
    for key, typ in pairs(REDNET_MESSAGE_STRUCT) do
        if typ ~= type(message[key]) then
            return
        end
    end

    -- Prevent floading
    if message.nSender == rednet.CHANNEL_REPEAT or message.nSender == rednet.CHANNEL_BROADCAST then
        return
    end

    -- Prevent doubles
    if received_messages[message.nMessageID] then
        return
    end

    -- Update lookup table
    lookup_table[message.nSender] = modem
    save(lookup_table)

    if channel == rednet.CHANNEL_REPEAT then
        -- Add message to history and start timeout
        received_messages[message.nMessageID] = true
        messages_timeout[os.startTimer(30)] = message.nMessageID

        local send_channel = message.nRecipient
        if send_channel ~= rednet.CHANNEL_BROADCAST and send_channel ~= rednet.CHANNEL_REPEAT then
            send_channel = id_as_channel(message.nRecipient)
        end

        -- Find recipient side from lookup table
        local saved_side = lookup_table[message.nRecipient]

        if saved_side then
            -- Check if the side is valid
            if modems[saved_side] then
                if saved_side ~= modem then
                    print("[" .. ctextutils.pad(message.nSender, 5) .. "] " .. ctextutils.pad(modem, 6) ..
                        " --> " .. ctextutils.pad(saved_side, 6) .. " [" .. ctextutils.pad(message.nRecipient, 5) .. "]")

                    -- Check if it is a greet message
                    if send_channel ~= rednet.CHANNEL_REPEAT then
                        modems[saved_side].transmit(send_channel, reply_channel, message)
                    end
                    modems[saved_side].transmit(rednet.CHANNEL_REPEAT, reply_channel, message)
                end
                return
            else
                lookup_table[message.nRecipient] = nil
                save(LOOKUP_TABLE_FILE, lookup_table)
            end
        end

        print("[" .. ctextutils.pad(message.nSender, 5) .. "] " .. ctextutils.pad(modem, 6) ..
            " --> all   [" .. ctextutils.pad(message.nRecipient, 5) .. "]")
        for side, mod in pairs(modems) do
            if side ~= modem then
                if send_channel ~= rednet.CHANNEL_REPEAT then
                    mod.transmit(send_channel, reply_channel, message)
                end
                mod.transmit(rednet.CHANNEL_REPEAT, reply_channel, message)
            end
        end
    end
end

local function timer_handler(timer)
    local message_id = messages_timeout[timer]
    -- Clear message history
    if message_id then
        messages_timeout[timer] = nil
        received_messages[message_id] = nil
    end
end

-- Find all modems
peripheral.find("modem", function(side, modem)
    modems[side] = modem
end)

-- Open all modems
for side, modem in pairs(modems) do
    print("Opening modem " .. side)
    modem.open(rednet.CHANNEL_REPEAT)
end

while true do
    local event, a1, a2, a3, a4 = os.pullEventRaw()
    if event == "modem_message" then
        modem_handler(a1, a2, a3, a4)
    elseif event == "timer" then
        timer_handler(a1)
    elseif event == "terminate" then
        break
    end
end

-- Close all modems
for side, modem in pairs(modems) do
    print("Closing modem " .. side)
    modem.close(rednet.CHANNEL_REPEAT)
    modem.close(rednet.CHANNEL_BROADCAST)
end
