--!strict
-- Part definition table. Names match the meshes produced by
-- tools/blender/gen_bricks.py (brick_2x4, plate_1x2, tile_2x2 ...).
--
-- A part occupies w x d studs and h plates. Its position is stored as the
-- minimum corner cell of the (rotated) footprint, so rotating never shifts
-- the stored origin.

export type PartDef = {
	name: string,
	w: number, -- studs along x at rotation 0
	d: number, -- studs along y at rotation 0
	h: number, -- plates
	studs: boolean, -- true => something can be attached on top
}

local PartDefs = {}

local defs: { [string]: PartDef } = {}

local SIZES = { { 1, 1 }, { 1, 2 }, { 1, 3 }, { 1, 4 }, { 1, 6 }, { 2, 2 }, { 2, 3 }, { 2, 4 }, { 2, 6 } }

for _, size in SIZES do
	local w, d = size[1], size[2]
	local suffix = `{w}x{d}`
	defs["brick_" .. suffix] = { name = "brick_" .. suffix, w = w, d = d, h = 3, studs = true }
	defs["plate_" .. suffix] = { name = "plate_" .. suffix, w = w, d = d, h = 1, studs = true }
	defs["tile_" .. suffix] = { name = "tile_" .. suffix, w = w, d = d, h = 1, studs = false }
end

PartDefs.defs = defs

function PartDefs.get(name: string): PartDef?
	return defs[name]
end

function PartDefs.isValidRotation(rot: number): boolean
	return rot == 0 or rot == 1 or rot == 2 or rot == 3
end

-- Footprint (w, d, h) after rotating by rot * 90 degrees around the vertical axis.
function PartDefs.footprint(name: string, rot: number): (number, number, number)?
	local def = defs[name]
	if def == nil or not PartDefs.isValidRotation(rot) then
		return nil
	end
	if rot % 2 == 1 then
		return def.d, def.w, def.h
	end
	return def.w, def.d, def.h
end

return PartDefs
