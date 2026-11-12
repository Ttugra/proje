--!strict
-- Undo / redo as a command stack. Each command knows how to apply and revert
-- itself. Commands with the same mergeKey executed back to back collapse into
-- one undo step (e.g. holding an arrow key to nudge a piece).

export type Command = {
	description: string,
	apply: () -> (),
	revert: () -> (),
	mergeKey: string?,
}

local History = {}
History.__index = History

export type Stack = typeof(setmetatable(
	{} :: {
		undoStack: { Command },
		redoStack: { Command },
	},
	History
))

function History.new(): Stack
	return setmetatable({ undoStack = {}, redoStack = {} }, History)
end

function History.execute(self: Stack, command: Command)
	command.apply()
	self.redoStack = {}

	local top = self.undoStack[#self.undoStack]
	if top ~= nil and command.mergeKey ~= nil and top.mergeKey == command.mergeKey then
		local previous = top
		self.undoStack[#self.undoStack] = {
			description = previous.description,
			mergeKey = previous.mergeKey,
			apply = function()
				previous.apply()
				command.apply()
			end,
			revert = function()
				command.revert()
				previous.revert()
			end,
		}
	else
		table.insert(self.undoStack, command)
	end
end

function History.canUndo(self: Stack): boolean
	return #self.undoStack > 0
end

function History.canRedo(self: Stack): boolean
	return #self.redoStack > 0
end

function History.undo(self: Stack): boolean
	local command = table.remove(self.undoStack)
	if command == nil then
		return false
	end
	command.revert()
	table.insert(self.redoStack, command)
	return true
end

function History.redo(self: Stack): boolean
	local command = table.remove(self.redoStack)
	if command == nil then
		return false
	end
	command.apply()
	table.insert(self.undoStack, command)
	return true
end

function History.clear(self: Stack)
	self.undoStack = {}
	self.redoStack = {}
end

return History
