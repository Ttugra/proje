--!nonstrict
-- Plain-Luau tests for the pure logic modules (no Roblox APIs needed).
-- Run from the repo root with the Luau CLI:  luau roblox/tests/run.luau

local PartDefs = require("../src/shared/PartDefs")
local OccupancyGrid = require("../src/shared/OccupancyGrid")
local History = require("../src/shared/History")
local Config = require("../src/shared/Config")

local passed, failed = 0, 0

local function check(name: string, condition: boolean)
	if condition then
		passed += 1
	else
		failed += 1
		print("FAIL: " .. name)
	end
end

local function newGrid()
	return OccupancyGrid.new(PartDefs, 12, 12, 48)
end

local function piece(id, part, rot, x, y, z)
	return { id = id, part = part, rot = rot, x = x, y = y, z = z, color = 1 }
end

-- PartDefs ------------------------------------------------------------------
do
	local w, d, h = PartDefs.footprint("brick_2x4", 0)
	check("brick_2x4 rot0 footprint", w == 2 and d == 4 and h == 3)
	w, d, h = PartDefs.footprint("brick_2x4", 1)
	check("brick_2x4 rot1 swaps w/d", w == 4 and d == 2 and h == 3)
	check("plate is 1 plate high", select(3, PartDefs.footprint("plate_2x2", 0)) == 1)
	check("unknown part -> nil", PartDefs.footprint("nope", 0) == nil)
	check("bad rotation -> nil", PartDefs.footprint("brick_1x1", 4) == nil)
	check("tile has no studs", PartDefs.get("tile_2x2").studs == false)
end

-- Placement & collision -----------------------------------------------------
do
	local g = newGrid()
	check("place brick", g:place(piece(1, "brick_2x4", 0, 0, 0, 0)))
	check("overlap rejected", g:canPlace("brick_1x1", 0, 1, 3, 0) == false)
	check("adjacent ok", g:canPlace("brick_1x1", 0, 2, 0, 0) == true)
	check("on top ok", g:canPlace("brick_2x4", 0, 0, 0, 3) == true)
	check("inside body rejected (z=2)", g:canPlace("plate_1x1", 0, 0, 0, 2) == false)
	check("out of bounds x", g:canPlace("brick_2x4", 0, 11, 0, 0) == false)
	check("out of bounds z", g:canPlace("brick_1x1", 0, 0, 0, 48) == false)
	check("non-integer rejected", g:canPlace("brick_1x1", 0, 0.5, 0, 0) == false)
	check("duplicate id rejected", g:place(piece(1, "brick_1x1", 0, 5, 5, 0)) == false)
	check("count", g.count == 1)
	check("pieceAt hit", g:pieceAt(1, 3, 2).id == 1)
	check("pieceAt miss", g:pieceAt(5, 5, 0) == nil)
	check("remove returns piece", g:remove(1).id == 1)
	check("cells freed", g:canPlace("brick_2x4", 0, 0, 0, 0) == true)
	check("count after remove", g.count == 0)
end

-- Rotation keeps the min-corner origin -------------------------------------
do
	local g = newGrid()
	check("rotated 2x4 placed", g:place(piece(1, "brick_2x4", 1, 0, 0, 0)))
	check("rotated occupies x0..3", g:pieceAt(3, 1, 0) ~= nil)
	check("rotated does not occupy y2", g:pieceAt(0, 2, 0) == nil)
end

-- Support / floating --------------------------------------------------------
do
	local g = newGrid()
	g:place(piece(1, "brick_2x4", 0, 0, 0, 0))
	g:place(piece(2, "brick_2x2", 0, 0, 0, 3)) -- sits on 1
	g:place(piece(3, "brick_1x1", 0, 8, 8, 6)) -- hovering in air
	local floating = g:floatingPieces()
	check("only the hovering piece floats", #floating == 1 and floating[1] == 3)

	-- a piece placed on a tile is NOT connected (tiles have no studs)
	local g2 = newGrid()
	g2:place(piece(1, "tile_2x2", 0, 0, 0, 0))
	g2:place(piece(2, "brick_2x2", 0, 0, 0, 1))
	local f2 = g2:floatingPieces()
	check("piece on tile floats", #f2 == 1 and f2[1] == 2)

	-- hanging underneath a grounded piece's overhang is connected via its studs
	local g3 = newGrid()
	g3:place(piece(1, "brick_1x1", 0, 0, 0, 0))
	g3:place(piece(2, "plate_2x2", 0, 0, 0, 3))
	g3:place(piece(3, "plate_1x1", 0, 1, 1, 3 + 1)) -- on top of plate 2, which is supported
	check("stacked supported chain", #g3:floatingPieces() == 0)
end

-- Serialization -------------------------------------------------------------
do
	local g = newGrid()
	g:place(piece(2, "brick_2x2", 0, 4, 4, 0))
	g:place(piece(1, "plate_1x2", 1, 0, 0, 0))
	local data = g:serialize()
	check("serialize ordered by id", data[1].id == 1 and data[2].id == 2)
	local g2, reason = OccupancyGrid.load(PartDefs, 12, 12, 48, data)
	check("load ok", g2 ~= nil and reason == nil)
	check("roundtrip count", g2 ~= nil and g2.count == 2)

	local bad = { piece(1, "brick_2x2", 0, 0, 0, 0), piece(2, "brick_2x2", 0, 1, 1, 0) }
	local g3 = OccupancyGrid.load(PartDefs, 12, 12, 48, bad)
	check("overlapping data rejected", g3 == nil)
end

-- History -------------------------------------------------------------------
do
	local value = 0
	local function add(n, mergeKey)
		return {
			description = "add " .. n,
			mergeKey = mergeKey,
			apply = function() value += n end,
			revert = function() value -= n end,
		}
	end

	local h = History.new()
	h:execute(add(1))
	h:execute(add(10))
	check("applied", value == 11)
	check("undo", h:undo() and value == 1)
	check("redo", h:redo() and value == 11)
	h:undo()
	h:execute(add(100)) -- new action clears redo
	check("redo cleared", h:canRedo() == false)

	local h2 = History.new()
	value = 0
	h2:execute(add(1, "nudge"))
	h2:execute(add(1, "nudge"))
	h2:execute(add(1, "nudge"))
	check("merged applied", value == 3)
	h2:undo()
	check("merged undo is one step", value == 0 and h2:canUndo() == false)
	h2:redo()
	check("merged redo", value == 3)
end

-- Config --------------------------------------------------------------------
do
	local x, y, z = Config.cellToWorld(1, 2, 3)
	check("cellToWorld x", math.abs(x - 1 * 20 * Config.SCALE) < 1e-9)
	check("cellToWorld up = plates", math.abs(y - 3 * 8 * Config.SCALE) < 1e-9)
	check("cellToWorld z = cell y", math.abs(z - 2 * 20 * Config.SCALE) < 1e-9)
end

print(`{passed} passed, {failed} failed`)
if failed > 0 then
	error("tests failed")
end
