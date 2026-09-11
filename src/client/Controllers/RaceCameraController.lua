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
local VERTICAL_DEAD_ZONE = 0.50
local VERTICAL_DAMPING_TIME = 0.22
local ORBIT_YAW_LIMIT = 40
local ORBIT_PITCH_LIMIT = 18
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
		_previousCameraType = nil :: Enum.CameraType?,
		_previousFieldOfView = nil :: number?,
		_smoothedPosition = nil :: Vector3?,
		_smoothedLookTarget = nil :: Vector3?,
		_orbitYaw = 0,
		_orbitPitch = 0,
		_mouseOrbitHeld = false,
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

function RaceCameraController:_captureCamera(camera: Camera)
	if self._ownsCamera then
		return
	end
	self._previousCameraType = camera.CameraType
	self._previousFieldOfView = camera.FieldOfView
	self._ownsCamera = true
end

function RaceCameraController:_releaseCamera()
	if not self._ownsCamera then
		return
	end
	local camera = Workspace.CurrentCamera
	if camera ~= nil then
		if self._previousCameraType ~= nil then
			camera.CameraType = self._previousCameraType
		end
		if self._previousFieldOfView ~= nil then
			camera.FieldOfView = self._previousFieldOfView
		end
	end
	self._ownsCamera = false
	self._previousCameraType = nil
	self._previousFieldOfView = nil
	self._smoothedPosition = nil
	self._smoothedLookTarget = nil
end

function RaceCameraController:_applyOrbitDelta(delta: Vector2)
	local yaw = self._orbitYaw - delta.X * ORBIT_DEGREES_PER_PIXEL
	local pitch = self._orbitPitch - delta.Y * ORBIT_DEGREES_PER_PIXEL
	self._orbitYaw, self._orbitPitch = CameraMath.ClampOrbit(
		yaw,
		pitch,
		ORBIT_YAW_LIMIT,
		ORBIT_PITCH_LIMIT
	)
end

function RaceCameraController:_step(dt: number)
	local body = findLocalRacerBody()
	if body == nil then
		self:_releaseCamera()
		return
	end

	local camera = Workspace.CurrentCamera
	if camera == nil then
		return
	end
	self:_captureCamera(camera)

	local rawPosition = body.Position
	if self._smoothedPosition == nil then
		self._smoothedPosition = rawPosition
	else
		local current = self._smoothedPosition
		local nextX = CameraMath.SmoothNumber(current.X, rawPosition.X, dt, POSITION_DAMPING_TIME)
		local nextY = CameraMath.StepVerticalDeadZone(
			current.Y,
			rawPosition.Y,
			VERTICAL_DEAD_ZONE,
			dt,
			VERTICAL_DAMPING_TIME
		)
		local nextZ = CameraMath.SmoothNumber(current.Z, rawPosition.Z, dt, POSITION_DAMPING_TIME)
		self._smoothedPosition = Vector3.new(nextX, nextY, nextZ)
	end

	if not self._mouseOrbitHeld and self._touchOrbitInput == nil then
		self._orbitYaw = CameraMath.SmoothNumber(self._orbitYaw, 0, dt, ORBIT_RETURN_TIME)
		self._orbitPitch = CameraMath.SmoothNumber(self._orbitPitch, 0, dt, ORBIT_RETURN_TIME)
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
		if gameProcessed then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			local mousePosition = UserInputService:GetMouseLocation()
			if not self:_pointOwnedByUI(mousePosition) then
				self._mouseOrbitHeld = true
			end
		elseif input.UserInputType == Enum.UserInputType.Touch then
			local position = Vector2.new(input.Position.X, input.Position.Y)
			if self._touchOrbitInput == nil and not self:_pointOwnedByUI(position) then
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
			self._mouseOrbitHeld = false
		elseif input == self._touchOrbitInput then
			self._touchOrbitInput = nil
		end
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
	disconnectAll(self._connections)
	self._mouseOrbitHeld = false
	self._touchOrbitInput = nil
	self:_releaseCamera()
end

return RaceCameraController
