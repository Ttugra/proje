--!strict
-- Central tunables. Models are stored in integer CELL units and only converted
-- to Roblox studs at render time, so changing SCALE never breaks saved data.
--
-- Cell axes: x, y = studs on the ground plane, z = plates upward.
-- Roblox world axes: X = x, Y (up) = z, Z = y.

local Config = {}

-- LDraw-style integer units (LDU): 1 stud pitch = 20, plate = 8, brick = 24.
Config.STUD_LDU = 20
Config.PLATE_LDU = 8
Config.BRICK_PLATES = 3

-- Roblox studs per LDU. 0.01 => one brick stud pitch is 0.2 Roblox studs.
-- Tune this in Studio by eye; everything else follows.
Config.SCALE = 0.01

-- Build platform (in cells). Starts small, grows with upgrades.
Config.PLATFORM_START = { x = 12, y = 12 }
Config.PLATFORM_STEPS = { 12, 16, 24, 32, 48 }

-- Build height limit in plates (16 bricks to start).
Config.HEIGHT_START_PLATES = 16 * Config.BRICK_PLATES

-- Per-model piece limit; raised by upgrades.
Config.PIECE_LIMIT_START = 300

-- Players per server; keep equal to the number of plots.
Config.MAX_PLAYERS = 8

-- Convert a cell coordinate (its minimum corner) to Roblox world studs
-- relative to the build platform origin.
function Config.cellToWorld(x: number, y: number, z: number): (number, number, number)
	local s = Config.SCALE
	return x * Config.STUD_LDU * s, z * Config.PLATE_LDU * s, y * Config.STUD_LDU * s
end

-- Size of a footprint (w, d in studs, h in plates) in Roblox studs: (X, Y, Z).
function Config.footprintToWorldSize(w: number, d: number, h: number): (number, number, number)
	local s = Config.SCALE
	return w * Config.STUD_LDU * s, h * Config.PLATE_LDU * s, d * Config.STUD_LDU * s
end

return Config
