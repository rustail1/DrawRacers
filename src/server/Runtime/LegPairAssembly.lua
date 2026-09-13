--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local PhysicsConfig = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("PhysicsConfig")
)
local LegDriveMath = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Math"):WaitForChild("LegDriveMath")
)
local StrokeTypes = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Types"):WaitForChild("StrokeTypes")
)
local LegCollisionSafety = require(script.Parent:WaitForChild("LegCollisionSafety"))
local LegDriveAssembly = require(script.Parent:WaitForChild("LegDriveAssembly"))

local LegPairAssembly = {}
LegPairAssembly.__index = LegPairAssembly

type ShapeSpec = StrokeTypes.ShapeSpec

export type BuildParams = {
	racerModel: Model,
	shapeSpec: ShapeSpec,
	motorEnabled: boolean?,
	initialPhaseDegrees: number?,
}

local function validateShapeSpec(shapeSpec: ShapeSpec)
	assert(type(shapeSpec) == "table", "LegPairAssembly requires authoritative shapeSpec")
	assert(type(shapeSpec.segmentPlan) == "table" and #shapeSpec.segmentPlan > 0, "shapeSpec missing physical segmentPlan")
end

local function ensureLegMount(body: Part, name: string, sideSign: number): Attachment
	local existing = body:FindFirstChild(name)
	if existing ~= nil and not existing:IsA("Attachment") then
		existing:Destroy()
		existing = nil
	end
	local mount = existing :: Attachment?
	if mount == nil then
		mount = Instance.new("Attachment")
		mount.Name = name
		mount.Parent = body
	end
	local geometry = PhysicsConfig.LegGeometry
	local mountX = body.Size.X * 0.5 * geometry.LegMountHorizontalFraction * sideSign
	local mountY = body.Size.Y * 0.5 * geometry.LegMountVerticalFraction
	mount.Position = Vector3.new(mountX, mountY, 0)
	mount.Axis = Vector3.zAxis
	mount.SecondaryAxis = Vector3.xAxis
	return mount
end

function LegPairAssembly.new(params: BuildParams)
	validateShapeSpec(params.shapeSpec)
	local racerModel = params.racerModel
	local body = racerModel:FindFirstChild("BodyCollider")
	local legsFolder = racerModel:FindFirstChild("Legs")
	assert(body and body:IsA("Part"), "racerModel missing BodyCollider")
	assert(legsFolder and legsFolder:IsA("Folder"), "racerModel missing Legs folder")

	local leftMount = ensureLegMount(body, "LeftLegMount", -1)
	local rightMount = ensureLegMount(body, "RightLegMount", 1)
	local initialPhase = params.initialPhaseDegrees or 0
	local leftDrive = LegDriveAssembly.new({
		body = body,
		bodyMount = leftMount,
		container = legsFolder,
		side = "Left",
		initialPhaseDegrees = initialPhase,
	})
	local rightDrive = LegDriveAssembly.new({
		body = body,
		bodyMount = rightMount,
		container = legsFolder,
		side = "Right",
		initialPhaseDegrees = initialPhase + PhysicsConfig.Motor.RightPhaseOffsetDegrees,
	})

	local self = setmetatable({
		racerModel = racerModel,
		body = body,
		leftMount = leftMount,
		rightMount = rightMount,
		leftDrive = leftDrive,
		rightDrive = rightDrive,
		currentShapeSpec = params.shapeSpec,
		currentMountOffsetDegrees = 0,
		stagedShapeSpec = nil :: ShapeSpec?,
		stagedMountOffsetDegrees = nil :: number?,
		motorEnabled = false,
		stepConnection = nil :: RBXScriptConnection?,
		destroyed = false,
	}, LegPairAssembly)

	local initialOffset, safetyError = LegCollisionSafety.FindSafeMountOffset(
		params.shapeSpec,
		leftDrive:GetRoot(),
		rightDrive:GetRoot()
	)
	if initialOffset == nil then
		leftDrive:Destroy()
		rightDrive:Destroy()
		leftMount:Destroy()
		rightMount:Destroy()
		error(safetyError or "NO_SAFE_REDRAW_PHASE")
	end
	self.currentMountOffsetDegrees = initialOffset
	leftDrive:GetLeg():InstallGeometry(params.shapeSpec, initialOffset)
	rightDrive:GetLeg():InstallGeometry(params.shapeSpec, initialOffset)

	self.stepConnection = RunService.Heartbeat:Connect(function()
		self:Step()
	end)
	self:SetEnabled(params.motorEnabled == true)
	return self
end

function LegPairAssembly:GetLeftDrive()
	assert(not self.destroyed, "LegPairAssembly is destroyed")
	return self.leftDrive
end

function LegPairAssembly:GetRightDrive()
	assert(not self.destroyed, "LegPairAssembly is destroyed")
	return self.rightDrive
end

function LegPairAssembly:GetLeftLeg()
	assert(not self.destroyed, "LegPairAssembly is destroyed")
	return self.leftDrive:GetLeg()
end

function LegPairAssembly:GetRightLeg()
	assert(not self.destroyed, "LegPairAssembly is destroyed")
	return self.rightDrive:GetLeg()
end

function LegPairAssembly:GetPhaseErrorDegrees(): number
	assert(not self.destroyed, "LegPairAssembly is destroyed")
	return LegDriveMath.PairPhaseErrorDegrees(
		self.leftDrive:GetPhaseDegrees(),
		self.rightDrive:GetPhaseDegrees(),
		PhysicsConfig.Motor.RightPhaseOffsetDegrees
	)
end

function LegPairAssembly:Step()
	if self.destroyed or self.currentShapeSpec == nil then return end
	local motor = PhysicsConfig.Motor
	local baseOmega = LegDriveMath.ComputeAngularVelocity(self.currentShapeSpec.extent, motor)
	-- CR3: LegPairAssembly is the single movement/phase command owner. Both physical
	-- hinges receive the same command; phase error is observation only, never chased.
	self.leftDrive:SetMotorVelocity(baseOmega)
	self.rightDrive:SetMotorVelocity(baseOmega)
	local phaseError = LegDriveMath.PairPhaseErrorDegrees(
		self.leftDrive:GetPhaseDegrees(),
		self.rightDrive:GetPhaseDegrees(),
		motor.RightPhaseOffsetDegrees
	)
	self.racerModel:SetAttribute("DebugPairPhaseErrorDegrees", phaseError)
	self.racerModel:SetAttribute("DebugDriveAngularVelocity", baseOmega)
end

function LegPairAssembly:StageRedraw(shapeSpec: ShapeSpec): (boolean, string?)
	assert(not self.destroyed, "LegPairAssembly is destroyed")
	validateShapeSpec(shapeSpec)
	if self.stagedShapeSpec ~= nil then
		return false, "REDRAW_PENDING"
	end
	local offset, safetyError = LegCollisionSafety.FindSafeMountOffset(
		shapeSpec,
		self.leftDrive:GetRoot(),
		self.rightDrive:GetRoot()
	)
	if offset == nil then
		return false, safetyError or "NO_SAFE_REDRAW_PHASE"
	end
	self.stagedShapeSpec = shapeSpec
	self.stagedMountOffsetDegrees = offset
	self.leftDrive:GetLeg():StageGeometry(shapeSpec, offset)
	self.rightDrive:GetLeg():StageGeometry(shapeSpec, offset)
	return true, nil
end

function LegPairAssembly:SetStageProgress(progress: number)
	assert(not self.destroyed, "LegPairAssembly is destroyed")
	if self.stagedShapeSpec == nil then return end
	self.leftDrive:GetLeg():SetStageProgress(progress)
	self.rightDrive:GetLeg():SetStageProgress(progress)
end

function LegPairAssembly:CommitStagedRedraw(): (boolean, string?)
	assert(not self.destroyed, "LegPairAssembly is destroyed")
	local shapeSpec = self.stagedShapeSpec
	if shapeSpec == nil then
		return false, "NO_PENDING_REDRAW"
	end

	local offset, safetyError = LegCollisionSafety.FindSafeMountOffset(
		shapeSpec,
		self.leftDrive:GetRoot(),
		self.rightDrive:GetRoot()
	)
	if offset == nil then
		self:CancelStagedRedraw()
		return false, safetyError or "NO_SAFE_REDRAW_PHASE"
	end
	if self.stagedMountOffsetDegrees ~= offset then
		self.stagedMountOffsetDegrees = offset
		self.leftDrive:GetLeg():StageGeometry(shapeSpec, offset)
		self.rightDrive:GetLeg():StageGeometry(shapeSpec, offset)
		self:SetStageProgress(1)
	end

	local leftCommitted = self.leftDrive:GetLeg():CommitStagedGeometry()
	local rightCommitted = self.rightDrive:GetLeg():CommitStagedGeometry()
	if not leftCommitted or not rightCommitted then
		self:CancelStagedRedraw()
		return false, "BUILD_FAILED"
	end
	self.currentShapeSpec = shapeSpec
	self.currentMountOffsetDegrees = offset
	self.stagedShapeSpec = nil
	self.stagedMountOffsetDegrees = nil
	self:Step()
	return true, nil
end

function LegPairAssembly:CancelStagedRedraw()
	if self.destroyed then return end
	self.leftDrive:GetLeg():CancelStagedGeometry()
	self.rightDrive:GetLeg():CancelStagedGeometry()
	self.stagedShapeSpec = nil
	self.stagedMountOffsetDegrees = nil
end

function LegPairAssembly:PrepareForRecovery()
	assert(not self.destroyed, "LegPairAssembly is destroyed")
	self:CancelStagedRedraw()
end

function LegPairAssembly:SetEnabled(enabled: boolean)
	assert(not self.destroyed, "LegPairAssembly is destroyed")
	self.motorEnabled = enabled
	self.leftDrive:SetEnabled(enabled)
	self.rightDrive:SetEnabled(enabled)
	if enabled then self:Step() end
end

function LegPairAssembly:Destroy()
	if self.destroyed then return end
	self:CancelStagedRedraw()
	self.destroyed = true
	if self.stepConnection then self.stepConnection:Disconnect() end
	if self.leftDrive then self.leftDrive:Destroy() end
	if self.rightDrive then self.rightDrive:Destroy() end
	if self.leftMount then self.leftMount:Destroy() end
	if self.rightMount then self.rightMount:Destroy() end
	self.stepConnection = nil
	self.leftDrive = nil
	self.rightDrive = nil
	self.leftMount = nil
	self.rightMount = nil
	self.body = nil
	self.racerModel = nil
	self.currentShapeSpec = nil
end

return LegPairAssembly