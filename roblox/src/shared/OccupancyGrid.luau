--!strict
-- Source of truth for a build: which cell is held by which piece.
-- Collision, support (floating) checks, analysis and saving all derive from
-- this table. Pure logic, no Roblox APIs, so the server can validate client
-- requests with it and it can run in plain Luau tests.

export type Piece = {
	id: number,
	part: string,
	rot: number, -- 0..3 (quarter turns)
	x: number, -- minimum corner cell of the rotated footprint
	y: number,
	z: number, -- in plates
	color: number, -- palette index
}

-- The part table is injected (see PartDefs) so this module has no requires.
export type Defs = {
	footprint: (name: string, rot: number) -> (number, number, number)?,
	get: (name: string) -> { studs: boolean }?,
}

local OccupancyGrid = {}
OccupancyGrid.__index = OccupancyGrid

export type Grid = typeof(setmetatable(
	{} :: {
		defs: Defs,
		sizeX: number,
		sizeY: number,
		sizeZ: number,
		cells: { [number]: number },
		pieces: { [number]: Piece },
		count: number,
		nextId: number,
	},
	OccupancyGrid
))

function OccupancyGrid.new(defs: Defs, sizeX: number, sizeY: number, sizeZ: number): Grid
	return setmetatable({
		defs = defs,
		sizeX = sizeX,
		sizeY = sizeY,
		sizeZ = sizeZ,
		cells = {},
		pieces = {},
		count = 0,
		nextId = 1,
	}, OccupancyGrid)
end

local function key(self: Grid, x: number, y: number, z: number): number
	return x + self.sizeX * (y + self.sizeY * z)
end

local function inBounds(self: Grid, x: number, y: number, z: number): boolean
	return x >= 0 and y >= 0 and z >= 0 and x < self.sizeX and y < self.sizeY and z < self.sizeZ
end

function OccupancyGrid.newId(self: Grid): number
	local id = self.nextId
	self.nextId += 1
	return id
end

function OccupancyGrid.pieceAt(self: Grid, x: number, y: number, z: number): Piece?
	if not inBounds(self, x, y, z) then
		return nil
	end
	local id = self.cells[key(self, x, y, z)]
	if id == nil then
		return nil
	end
	return self.pieces[id]
end

-- Returns (true) or (false, reason). Does not modify the grid.
function OccupancyGrid.canPlace(self: Grid, part: string, rot: number, x: number, y: number, z: number): (boolean, string?)
	local w, d, h = self.defs.footprint(part, rot)
	if w == nil or d == nil or h == nil then
		return false, "unknown part or rotation"
	end
	if x ~= math.floor(x) or y ~= math.floor(y) or z ~= math.floor(z) then
		return false, "position must be integer cells"
	end
	if not inBounds(self, x, y, z) or not inBounds(self, x + w - 1, y + d - 1, z + h - 1) then
		return false, "out of bounds"
	end
	for cz = z, z + h - 1 do
		for cy = y, y + d - 1 do
			for cx = x, x + w - 1 do
				if self.cells[key(self, cx, cy, cz)] ~= nil then
					return false, "cell occupied"
				end
			end
		end
	end
	return true, nil
end

function OccupancyGrid.place(self: Grid, piece: Piece): (boolean, string?)
	if self.pieces[piece.id] ~= nil then
		return false, "duplicate id"
	end
	local ok, reason = self:canPlace(piece.part, piece.rot, piece.x, piece.y, piece.z)
	if not ok then
		return false, reason
	end
	local w, d, h = self.defs.footprint(piece.part, piece.rot)
	assert(w ~= nil and d ~= nil and h ~= nil)
	for cz = piece.z, piece.z + h - 1 do
		for cy = piece.y, piece.y + d - 1 do
			for cx = piece.x, piece.x + w - 1 do
				self.cells[key(self, cx, cy, cz)] = piece.id
			end
		end
	end
	self.pieces[piece.id] = piece
	self.count += 1
	if piece.id >= self.nextId then
		self.nextId = piece.id + 1
	end
	return true, nil
end

function OccupancyGrid.remove(self: Grid, id: number): Piece?
	local piece = self.pieces[id]
	if piece == nil then
		return nil
	end
	local w, d, h = self.defs.footprint(piece.part, piece.rot)
	assert(w ~= nil and d ~= nil and h ~= nil)
	for cz = piece.z, piece.z + h - 1 do
		for cy = piece.y, piece.y + d - 1 do
			for cx = piece.x, piece.x + w - 1 do
				self.cells[key(self, cx, cy, cz)] = nil
			end
		end
	end
	self.pieces[id] = nil
	self.count -= 1
	return piece
end

-- Pieces connected to `piece` through studs: a piece above sits on this one's
-- studs, or this one sits on a lower piece's studs. Tiles have no studs, so
-- nothing attaches on top of them.
local function neighbours(self: Grid, piece: Piece): { number }
	local result: { number } = {}
	local seen: { [number]: boolean } = {}
	local w, d, h = self.defs.footprint(piece.part, piece.rot)
	assert(w ~= nil and d ~= nil and h ~= nil)
	local thisStuds = (self.defs.get(piece.part) :: { studs: boolean }).studs

	for cy = piece.y, piece.y + d - 1 do
		for cx = piece.x, piece.x + w - 1 do
			if thisStuds then
				local above = self:pieceAt(cx, cy, piece.z + h)
				if above ~= nil and not seen[above.id] then
					seen[above.id] = true
					table.insert(result, above.id)
				end
			end
			local below = self:pieceAt(cx, cy, piece.z - 1)
			if below ~= nil and not seen[below.id] then
				local belowDef = self.defs.get(below.part) :: { studs: boolean }
				if belowDef.studs then
					seen[below.id] = true
					table.insert(result, below.id)
				end
			end
		end
	end
	return result
end

-- Ids of pieces that are not connected (through studs) to the ground plate.
function OccupancyGrid.floatingPieces(self: Grid): { number }
	local grounded: { [number]: boolean } = {}
	local queue: { number } = {}
	for id, piece in self.pieces do
		if piece.z == 0 then
			grounded[id] = true
			table.insert(queue, id)
		end
	end

	local head = 1
	while head <= #queue do
		local piece = self.pieces[queue[head]]
		head += 1
		for _, otherId in neighbours(self, piece) do
			if not grounded[otherId] then
				grounded[otherId] = true
				table.insert(queue, otherId)
			end
		end
	end

	local floating: { number } = {}
	for id in self.pieces do
		if not grounded[id] then
			table.insert(floating, id)
		end
	end
	table.sort(floating)
	return floating
end

-- Plain-data snapshot, ordered by id, ready for DataStore / remote transfer.
function OccupancyGrid.serialize(self: Grid): { Piece }
	local list: { Piece } = {}
	for _, piece in self.pieces do
		table.insert(list, {
			id = piece.id,
			part = piece.part,
			rot = piece.rot,
			x = piece.x,
			y = piece.y,
			z = piece.z,
			color = piece.color,
		})
	end
	table.sort(list, function(a, b)
		return a.id < b.id
	end)
	return list
end

-- Rebuilds a grid from serialized data. Returns nil plus a reason if any
-- piece is invalid (never trust loaded or client-supplied data).
function OccupancyGrid.load(defs: Defs, sizeX: number, sizeY: number, sizeZ: number, list: { Piece }): (Grid?, string?)
	local grid = OccupancyGrid.new(defs, sizeX, sizeY, sizeZ)
	for _, piece in list do
		local ok, reason = grid:place(piece)
		if not ok then
			return nil, `piece {piece.id}: {reason}`
		end
	end
	return grid, nil
end

return OccupancyGrid
