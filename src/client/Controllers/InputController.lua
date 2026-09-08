--!strict

local UserInputService = game:GetService("UserInputService")

export type PointerFamily = "mouse" | "touch"
export type PointerPhase = "start" | "move" | "end" | "cancel"

export type PointerEvent = {
	phase: PointerPhase,
	family: PointerFamily,
	pointerId: number,
	position: Vector2,
}

export type InputController = {
	Bind: (self: InputController, target: GuiObject) -> (),
	Unbind: (self: InputController) -> (),
	Connect: (self: InputController, callback: (event: PointerEvent) -> ()) -> RBXScriptConnection,
	IsPointerActive: (self: InputController) -> boolean,
	Destroy: (self: InputController) -> (),
}

type PrivateInputController = InputController & {
	_event: BindableEvent,
	_connections: { RBXScriptConnection },
	_target: GuiObject?,
	_targetWasActive: boolean?,
	_activeFamily: PointerFamily?,
	_activeInput: InputObject?,
	_activePointerId: number?,
	_pointerSequence: number,
	_lastPosition: Vector2,
}

local InputController = {}
InputController.__index = InputController

local function screenPosition(input: InputObject): Vector2
	return Vector2.new(input.Position.X, input.Position.Y)
end

local function fireEvent(self: PrivateInputController, phase: PointerPhase, position: Vector2)
	local family = self._activeFamily
	local pointerId = self._activePointerId
	if family == nil or pointerId == nil then
		return
	end

	self._lastPosition = position
	self._event:Fire({
		phase = phase,
		family = family,
		pointerId = pointerId,
		position = position,
	} :: PointerEvent)
end

local function clearActivePointer(self: PrivateInputController)
	self._activeFamily = nil
	self._activeInput = nil
	self._activePointerId = nil
end

local function finishPointer(self: PrivateInputController, phase: "end" | "cancel", position: Vector2?)
	if self._activeFamily == nil then
		return
	end

	fireEvent(self, phase, position or self._lastPosition)
	clearActivePointer(self)
end

local function beginPointer(self: PrivateInputController, family: PointerFamily, input: InputObject)
	-- One stroke owns one primary pointer. Extra touches/mouse presses are ignored
	-- until that pointer ends or is cancelled.
	if self._activeFamily ~= nil then
		return
	end

	self._pointerSequence += 1
	self._activeFamily = family
	self._activeInput = input
	self._activePointerId = self._pointerSequence
	self._lastPosition = screenPosition(input)
	fireEvent(self, "start", self._lastPosition)
end

function InputController.new(): InputController
	local self: PrivateInputController = setmetatable({
		_event = Instance.new("BindableEvent"),
		_connections = {},
		_target = nil,
		_targetWasActive = nil,
		_activeFamily = nil,
		_activeInput = nil,
		_activePointerId = nil,
		_pointerSequence = 0,
		_lastPosition = Vector2.zero,
	}, InputController) :: any

	return self
end

function InputController:Connect(callback: (event: PointerEvent) -> ()): RBXScriptConnection
	local selfPrivate = self :: any :: PrivateInputController
	return selfPrivate._event.Event:Connect(callback)
end

function InputController:IsPointerActive(): boolean
	local selfPrivate = self :: any :: PrivateInputController
	return selfPrivate._activeFamily ~= nil
end

function InputController:Bind(target: GuiObject)
	local selfPrivate = self :: any :: PrivateInputController
	selfPrivate:Unbind()

	selfPrivate._target = target
	selfPrivate._targetWasActive = target.Active

	-- Active GuiObjects sink the drawing pointer before it reaches world/camera
	-- gestures. B01 owns only pointer normalization; camera behavior itself stays
	-- with RaceCameraController in its later task.
	target.Active = true

	table.insert(selfPrivate._connections, target.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			beginPointer(selfPrivate, "mouse", input)
		elseif input.UserInputType == Enum.UserInputType.Touch then
			beginPointer(selfPrivate, "touch", input)
		end
	end))

	table.insert(selfPrivate._connections, UserInputService.InputChanged:Connect(function(input: InputObject)
		local family = selfPrivate._activeFamily
		if family == nil then
			return
		end

		if family == "touch" then
			if input ~= selfPrivate._activeInput then
				return
		end
			if input.UserInputState == Enum.UserInputState.Cancel then
				finishPointer(selfPrivate, "cancel", screenPosition(input))
			else
				fireEvent(selfPrivate, "move", screenPosition(input))
			end
		elseif input.UserInputType == Enum.UserInputType.MouseMovement then
			if input.UserInputState == Enum.UserInputState.Cancel then
				finishPointer(selfPrivate, "cancel", screenPosition(input))
			else
				fireEvent(selfPrivate, "move", screenPosition(input))
			end
		end
	end))

	table.insert(selfPrivate._connections, UserInputService.InputEnded:Connect(function(input: InputObject)
		local family = selfPrivate._activeFamily
		if family == "touch" and input == selfPrivate._activeInput then
			local phase: "end" | "cancel" = if input.UserInputState == Enum.UserInputState.Cancel then "cancel" else "end"
			finishPointer(selfPrivate, phase, screenPosition(input))
		elseif family == "mouse" and input.UserInputType == Enum.UserInputType.MouseButton1 then
			local phase: "end" | "cancel" = if input.UserInputState == Enum.UserInputState.Cancel then "cancel" else "end"
			finishPointer(selfPrivate, phase, screenPosition(input))
		end
	end))

	table.insert(selfPrivate._connections, UserInputService.WindowFocusReleased:Connect(function()
		finishPointer(selfPrivate, "cancel", nil)
	end))

	table.insert(selfPrivate._connections, target.AncestryChanged:Connect(function(_, parent)
		if parent == nil then
			finishPointer(selfPrivate, "cancel", nil)
		end
	end))
end

function InputController:Unbind()
	local selfPrivate = self :: any :: PrivateInputController
	finishPointer(selfPrivate, "cancel", nil)

	for _, connection in selfPrivate._connections do
		connection:Disconnect()
	end
	table.clear(selfPrivate._connections)

	if selfPrivate._target ~= nil and selfPrivate._targetWasActive ~= nil then
		selfPrivate._target.Active = selfPrivate._targetWasActive
	end

	selfPrivate._target = nil
	selfPrivate._targetWasActive = nil
end

function InputController:Destroy()
	local selfPrivate = self :: any :: PrivateInputController
	selfPrivate:Unbind()
	selfPrivate._event:Destroy()
end

return InputController
