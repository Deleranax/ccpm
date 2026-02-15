--[[
    scada-core - SCADA Core Library
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
local schematics = require("schematics")
local Stream = require("lockbox.util.stream")
local HMAC = require("lockbox.mac.hmac")
local tree = require("scada.tree")

--- @export
local message = {}

--- The message schema
message.schema = setmetatable({}, { __index = tree.schema })

message.schema.Wrapper = {
    type = { "table" },
    content = { "table", "string" }
}

message.schema.AuthenticatedWrapper = {
    __inherits = { "Wrapper" },
    content = { "string" },
    hmac = { "string" }
}

message.schema.SubscribeChallengeMessage = {
    nonce_a = { "number" },
    nonce_b = { "number" }
}

message.schema.SubscribeResponseMessage = {
    sum = { "number" }
}

message.schema.AckMessage = {
    timestamp = { "number" }
}

message.schema.UpdateMessage = {
    tree = { "Tree" },
    timestamp = { "number" }
}

message.schema.validate = schematics.compile(message.schema)

-- Local Message Authentication Code instance
local mac = HMAC()

--- Add authentication on a message.
--- @param msg table: The message to authenticate
--- @param key table: The key (byte array)
--- @return table: The authenticated message
function message.auth(msg, key)
    expect(1, msg, "table")
    expect(2, key, "table")

    if msg.content then
        msg.content = textutils.serialize(msg.content)
        msg.hmac = mac.init()
            .setKey(key)
            .update(msg.content)
            .finalize()
            .asHex()
    end

    return msg
end

--- Verify authentication on a message.
--- @param msg table: The message to verify
--- @param key table: The key (byte array)
--- @return table: The verified message or nil if verification failed
function message.verify(msg, key)
    expect(1, msg, "table")
    expect(2, key, "table")

    if msg.hmac then
        local hmac = mac.init()
            .setKey(key)
            .update(msg.content)
            .finalize()
            .asHex()

        if msg.hmac == hmac then
            msg.content = textutils.unserialize(msg.content)
            msg.hmac = nil

            return msg
        end
    end

    return nil
end

return message
