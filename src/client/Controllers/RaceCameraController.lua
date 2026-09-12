--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local CameraMath = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Math"):WaitForChild("CameraMath")
)

local FIELD_OF_VIEW = 60
local LOCAL_RACER_SCREEN_ANCHOR = 0.38
local LOOK_AHEAD = 11
local CAMERA_HEIGHT = 10
local SIDE_DISTANCE = 23
local POSITION_DAMPING_TIME = 0.16
local LOOK_TARGET_DAMPING_TIME = 0.12
-- Reference-feel starting hypothesis. The stable anchor does not move while the
-- racer stays inside these world-space bands; Studio evidence may tune the
-- widths later without changing the ownership model.
local HORIZONTAL_DEAD_ZONE = 2.50
local VERTICAL_DEAD_ZONE = 1.25
local VERTICAL_DAMPING_TIME = 0.22
local ORBIT_PITCH_LIMIT = 70
local ORBIT_INPUT_DAMPING_TIME = 0.08
local ORBIT_RETURN_TIME = 0.40
local ORBIT_DEGREES_PER_PIXEL = 0.25
local FALLBACK_ASPECT_RATIO = 16 / 9

local RaceCameraController = {}
RaceCameraController.__index = RaceCameraController

type ConnectionList = { RBXScriptConnection }

local function disconnectAll(connections: ConnectionList)
	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)
end

local function findLocalRacerBody(): BasePart?
	local runtime = Workspace:FindFirstChild("Runtime")
	local racers = runtime and runtime:FindFirstChild("Racers")
	if racers == nil then
		return nil
	end

	for _, candidate in racers:GetChildren() do
		if candidate:IsA("Model") then
			local ownerUserId = candidate:GetAttribute("OwnerUserId")
			if type(ownerUserId) == "number" and ownerUserId == Players.LocalPlayer.UserId then
				local body = candidate:FindFirstChild("BodyCollider")
				if body and body:IsA("BasePart") then
					return body
				end
			end
		end
	end
	return nil
end

local function belongsToDrawInputRect(guiObject: Instance): boolean
	local current: Instance? = guiObject
	while current ~= nil do
		if current.Name == "DrawInputRect" then
			return true
		end
		current = current.Parent
	end
	return false
end

function RaceCameraController.new(playerGui: PlayerGui)
	local self = setmetatable({
		_playerGui = playerGui,
		_connections = {} :: ConnectionList,
		_started = false,
		_ownsCamera = false,
		_ownedCamera = nil :: Camera?,
		_previousCameraType = nil :: Enum.CameraType?,
		_previousFieldOfView = nil :: number?,
		_deadZoneAnchor = nil :: Vector3?,
		_smoothedPosition = nil :: Vector3?,
		_smoothedLookTarget = nil :: Vector3?,
		_targetOrbitYaw = 0,
		_targetOrbitPitch = 0,
		_orbitYaw = 0,
		_orbitPitch = 0,
		_mouseOrbitHeld = false,
		_previousMouseBehavior = nil :: Enum.MouseBehavior?,
		_touchOrbitInput = nil :: InputObject?,
	}, RaceCameraController)
	return self
end

function RaceCameraController:_pointOwnedByUI(position: Vector2): boolean
	local guiObjects = self._playerGui:GetGuiObjectsAtPosition(math.floor(position.X), math.floor(position.Y))
	for _, guiObject in guiObjects do
		if belongsToDrawInputRect(guiObject) then
			return true
		end
		if guiObject.Visible and (guiObject:IsA("GuiButton") or guiObject.Active) then
			return true
		end
	end
	return false
end

function RaceCameraController:_worldCameraInputAllowed(position: Vector2): boolean
	if UserInputService:GetFocusedTextBox() ~= nil then
		return false
	end
	return not self:_pointOwnedByUI(position)
end

function RaceCameraController:_beginMouseOrbit()
	if self._mouseOrbitHeld then
		return
	end
	if self._touchOrbitInput == nil then
		self._targetOrbitYaw = self._orbitYaw
		self._targetOrbitPitch = self._orbitPitch
	end
	self._previousMouseBehavior = UserInputService.MouseBehavior
	self._mouseOrbitHeld = true
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
end

function RaceCameraController:_endMouseOrbit()
	if not self._mouseOrbitHeld and self._previousMouseBehavior == nil then
		return
	end
	self._mouseOrbitHeld = false
	local previousMouseBehavior = self._previousMouseBehavior
	self._previousMouseBehavior = nil
	if previousMouseBehavior ~= nil then
		UserInputService.MouseBehavior = previousMouseBehavior
	end
end

function RaceCameraController:_captureCamera(camera: Camera)
	if self._ownsCamera and self._ownedCamera == camera then
		return
	end
	if self._ownsCamera then
		self:_releaseCamera()
	end
	self._ownedCamera = camera
	self._previousCameraType = camera.CameraType
	self._previousFieldOfView = camera.FieldOfView
	self._ownsCamera = true
end

function RaceCameraController:_releaseCamera()
	if not self._ownsCamera then
		return
	end
	local camera = self._ownedCamera
	if camera ~= nil and camera.Parent ~= nil then
		if self._previousCameraType ~= nil then
			camera.CameraType = self._previousCameraType
		end
		if self._previousFieldOfView ~= nil then
			camera.FieldOfView = self._previousFieldOfView
		end
	end
	self._ownsCamera = false
	self._ownedCamera = nil
	self._previousCameraType = nil
	self._previousFieldOfView = nil
	self._deadZoneAnchor = nil
	self._smoothedPosition = nil
	self._smoothedLookTarget = nil
	self._targetOrbitYaw = 0
	self._targetOrbitPitch = 0
	self._orbitYaw = 0
	self._orbitPitch = 0
end

function RaceCameraController:_applyOrbitDelta(delta: Vector2)
	-- R17.9: yaw is intentionally unbounded so RMB can orbit the racer through
	-- full 360-degree turns. Only pitch is clamped to prevent camera inversion.
	self._targetOrbitYaw -= delta.X * ORBIT_DEGREES_PER_PIXEL
	self._targetOrbitPitch = CameraMath.ClampPitch(
		self._targetOrbitPitch - delta.Y * ORBIT_DEGREES_PER_PIXEL,
		ORBIT_PITCH_LIMIT
	)
end

function RaceCameraController:_step(dt: number)
	local orbitInputActive = self._mouseOrbitHeld or self._touchOrbitInput ~= nil
	if not orbitInputActive then
		self._targetOrbitYaw = 0
		self._targetOrbitPitch = 0
	end

	local orbitDampingTime = if orbitInputActive then ORBIT_INPUT_DAMPING_TIME else ORBIT_RETURN_TIME
	if orbitInputActive then
		-- The target yaw is intentionally unbounded while dragging. Smooth it as a
		-- linear accumulated angle so a target beyond +/-180 degrees cannot make
		-- shortest-angle wrapping reverse the user's drag direction.
		self._orbitYaw = CameraMath.SmoothNumber(self._orbitYaw, self._targetOrbitYaw, dt, orbitDampingTime)
	else
		-- Once input is released, 360-degree-equivalent angles may return by the
		-- shortest path to canonical side framing.
		self._orbitYaw = CameraMath.SmoothAngleDegrees(self._orbitYaw, self._targetOrbitYaw, dt, orbitDampingTime)
	end
	self._orbitPitch = CameraMath.SmoothNumber(self._orbitPitch, self._targetOrbitPitch, dt, orbitDampingTime)

	local body = findLocalRacerBody()
	if body == nil then
		if self._mouseOrbitHeld then
			self:_endMouseOrbit()
		end
		self:_releaseCamera()
		return
	end

	local camera = Workspace.CurrentCamera
	if camera == nil and self._mouseOrbitHeld then
		self:_endMouseOrbit()
	end
	if camera == nil then
		self:_releaseCamera()
		return
	end
	self:_captureCamera(camera)

	local rawPosition = body.Position
	if self._deadZoneAnchor == nil then
		self._deadZoneAnchor = rawPosition
		self._smoothedPosition = rawPosition
	else
		local anchor = self._deadZoneAnchor
		local nextAnchorX = CameraMath.StepDeadZoneAnchor(anchor.X, rawPosition.X, HORIZONTAL_DEAD_ZONE)
		local nextAnchorY = CameraMath.StepDeadZoneAnchor(anchor.Y, rawPosition.Y, VERTICAL_DEAD_ZONE)
		-- Lane Z is mechanically constrained. Keep the camera's side anchor stable
		-- instead of feeding tiny solver Z errors back into presentation.
		self._deadZoneAnchor = Vector3.new(nextAnchorX, nextAnchorY, anchor.Z)

		local current = self._smoothedPosition or self._deadZoneAnchor
		local nextPosition = CameraMath.SmoothVector(
			current,
			self._deadZoneAnchor,
			dt,
			POSITION_DAMPING_TIME
		)
		local nextY = CameraMath.SmoothNumber(
			current.Y,
			self._deadZoneAnchor.Y,
			dt,
			VERTICAL_DAMPING_TIME
		)
		self._smoothedPosition = Vector3.new(nextPosition.X, nextY, nextPosition.Z)
	end

	local smoothedPosition = self._smoothedPosition :: Vector3
	local desiredLookTarget = smoothedPosition + Vector3.new(LOOK_AHEAD, 0, 0)
	if self._smoothedLookTarget == nil then
		self._smoothedLookTarget = desiredLookTarget
	else
		self._smoothedLookTarget = CameraMath.SmoothVector(
			self._smoothedLookTarget,
			desiredLookTarget,
			dt,
			LOOK_TARGET_DAMPING_TIME
		)
	end

	local viewportSize = camera.ViewportSize
	local aspectRatio = if viewportSize.Y > 0 then viewportSize.X / viewportSize.Y else FALLBACK_ASPECT_RATIO
	local canonicalCameraX = CameraMath.ScreenAnchorCameraX(
		LOOK_AHEAD,
		CAMERA_HEIGHT,
		SIDE_DISTANCE,
		FIELD_OF_VIEW,
		aspectRatio,
		LOCAL_RACER_SCREEN_ANCHOR
	)
	local orbitRotation = CFrame.Angles(math.rad(self._orbitPitch), math.rad(self._orbitYaw), 0)
	local baseOffset = Vector3.new(canonicalCameraX, CAMERA_HEIGHT, SIDE_DISTANCE)
	local cameraOffset = orbitRotation:VectorToWorldSpace(baseOffset)
	local cameraPosition = smoothedPosition + cameraOffset

	camera.CameraType = Enum.CameraType.Scriptable
	camera.FieldOfView = FIELD_OF_VIEW
	camera.CFrame = CFrame.lookAt(cameraPosition, self._smoothedLookTarget :: Vector3, Vector3.yAxis)
end

function RaceCameraController:Start()
	if self._started then
		return
	end
	self._started = true

	table.insert(self._connections, UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
		if findLocalRacerBody() == nil then
			return
		end

		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			local mousePosition = UserInputService:GetMouseLocation()
			if self:_worldCameraInputAllowed(mousePosition) then
				self:_beginMouseOrbit()
			end
			return
		end

		if gameProcessed then
			return
		end
		if input.UserInputType == Enum.UserInputType.Touch then
			local position = Vector2.new(input.Position.X, input.Position.Y)
			if self._touchOrbitInput == nil and not self:_pointOwnedByUI(position) then
				if not self._mouseOrbitHeld then
					self._targetOrbitYaw = self._orbitYaw
					self._targetOrbitPitch = self._orbitPitch
				end
				self._touchOrbitInput = input
			end
		end
	end))

	table.insert(self._connections, UserInputService.InputChanged:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseMovement and self._mouseOrbitHeld then
			self:_applyOrbitDelta(Vector2.new(input.Delta.X, input.Delta.Y))
		elseif input == self._touchOrbitInput then
			self:_applyOrbitDelta(Vector2.new(input.Delta.X, input.Delta.Y))
		end
	end))

	table.insert(self._connections, UserInputService.InputEnded:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			self:_endMouseOrbit()
		elseif input == self._touchOrbitInput then
			self._touchOrbitInput = nil
		end
	end))

	table.insert(self._connections, UserInputService.WindowFocusReleased:Connect(function()
		self:_endMouseOrbit()
		self._touchOrbitInput = nil
	end))

	table.insert(self._connections, RunService.RenderStepped:Connect(function(dt: number)
		self:_step(dt)
	end))

	self:_step(0)
end

function RaceCameraController:Destroy()
	if not self._started then
		return
	end
	self._started = false
	self:_endMouseOrbit()
	disconnectAll(self._connections)
	self._touchOrbitInput = nil
	self:_releaseCamera()
end

return RaceCameraController
