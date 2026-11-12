--!strict
-- Server entry point. Placeholder: plot assignment, authoritative placement
-- validation (OccupancyGrid), saving and NPC customers will live here.
-- Set Game Settings > Players > Maximum Players to Config.MAX_PLAYERS.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)

print(`[cikcik] server started, max players {Config.MAX_PLAYERS}`)
