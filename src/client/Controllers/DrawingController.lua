--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local PhysicsConfig = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("PhysicsConfig")
)
local StrokeMath = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Math"):WaitForChild("StrokeMath")
)

local DrawingController = {}
DrawingController.__index = DrawingController

local DESKTOP_CANVAS_SIZE = UDim2.fromScale(0.46, 0.255)
local TOUCH_CANVAS_SIZE = UDim2.fromScale(0.64, 0.285)
local DRAW_INPUT_SIZE = UDim2.fromScale(0.92, 0.82)

local DESKTOP_VALIDATION_POSITION = UDim2.fromScale(0.5, 0.705)
local DESKTOP_VALIDATION_SIZE = UDim2.fromScale(0.32, 0.052)
local TOUCH_VALIDATION_POSITION = UDim2.fromScale(0.5, 0.675)
local TOUCH_VALIDATION_SIZE = UDim2.fromScale(0.44, 0.058)
local DESKTOP_HINT_POSITION = UDim2.fromScale(0.5, 0.705)
local DESKTOP_HINT_SIZE = UDim2.fromScale(0.38, 0.06)
local TOUCH_HINT_POSITION = UDim2.fromScale(0.5, 0.675)
local TOUCH_HINT_SIZE = UDim2.fromScale(0.50, 0.064)

local DESKTOP_THICKNESS = 6
local TOUCH_THICKNESS = 8
local VALIDATION_TOAST_DURATION = 2.0

type SemanticPoint = {
	x: number,
	y: number,
}

local function isFiniteNumber(value: any): boolean
	return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

local function inputTypeFamily(inputType: Enum.UserInputType): string?
	if inputType == Enum.UserInputType.Touch then
		return "touch"
	end
	if inputType == Enum.UserInputType.Keyboard
		or inputType == Enum.UserInputType.MouseMovement
		or inputType == Enum.UserInputType.MouseButton1
		or inputType == Enum.UserInputType.MouseButton2
		or inputType == Enum.UserInputType.MouseButton3
		or inputType == Enum.UserInputType.MouseWheel
	then
		return "mouse"
	end
	return nil
end

local function initialLayoutFamily(): string
	if UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
		return "touch"
	end

	local family = inputTypeFamily(UserInputService:GetLastInputType())
	if family ~= nil then
		return family
	end
	if UserInputService.MouseEnabled or UserInputService.KeyboardEnabled then
		return "mouse"
	end
	return if UserInputService.TouchEnabled then "touch" else "mouse"
end

local function makeFrame(name: string, parent: Instance): Frame
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.Parent = parent
	return frame
end

local function clearSegments(layer: Instance)
	for _, child in layer:GetChildren() do
		if child.Name == "Segment" then
			child:Destroy()
		end
	end
end

local function drawSegment(parent: Instance, a: Vector2, b: Vector2, thickness: number, transparency: number?)
	local delta = b - a
	local length = delta.Magnitude
	if length <= 0 then
		return
	end

	local segment = Instance.new("Frame")
	segment.Name = "Segment"
	segment.AnchorPoint = Vector2.new(0.5, 0.5)
	segment.Position = UDim2.fromOffset((a.X + b.X) * 0.5, (a.Y + b.Y) * 0.5)
	segment.Size = UDim2.fromOffset(length, thickness)
	segment.Rotation = math.deg(math.atan2(delta.Y, delta.X))
	segment.BackgroundColor3 = Color3.fromRGB(55, 190, 255)
	segment.BackgroundTransparency = transparency or 0
	segment.BorderSizePixel = 0
	segment.ZIndex = 24
	segment.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = segment
end

local function renderPolyline(layer: Frame, points: { Vector2 }, thickness: number, transparency: number?)
	clearSegments(layer)
	for index = 2, #points do
		drawSegment(layer, points[index - 1], points[index], thickness, transparency)
	end
end

local function copyPoints(points: { Vector2 }): { Vector2 }
	local result = table.create(#points)
	for index, point in points do
		result[index] = point
	end
	return result
end

local function copySemanticPoints(points: { SemanticPoint }): { SemanticPoint }
	local result = table.create(#points)
	for index, point in points do
		result[index] = { x = point.x, y = point.y }
	end
	return result
end

local function validServerSemanticPoints(points: any): boolean
	if type(points) ~= "table" then
		return false
	end
	local config = PhysicsConfig.StrokeProcessing
	local count = 0
	local maxIndex = 0
	for key, _ in points do
		if type(key) ~= "number" or key < 1 or math.floor(key) ~= key then
			return false
		end
		count += 1
		if count > config.MaxCleanedPoints or key > config.MaxCleanedPoints then
			return false
		end
		maxIndex = math.max(maxIndex, key)
	end
	if count < 2 or maxIndex ~= count then
		return false
	end
	for index = 1, count do
		local point = points[index]
		if type(point) ~= "table" or not isFiniteNumber(point.x) or not isFiniteNumber(point.y) then
			return false
		end
		if point.x < config.NormalizedMin or point.x > config.NormalizedMax
			or point.y < config.NormalizedMin or point.y > config.NormalizedMax
		then
			return false
		end
	end
	return true
end

local function semanticPointsToPixels(points: { SemanticPoint }, size: Vector2): { Vector2 }
	local result = table.create(#points)
	for index, point in points do
		result[index] = Vector2.new(
			((point.x + 1) * 0.5) * size.X,
			((1 - point.y) * 0.5) * size.Y
		)
	end
	return result
end

local function createUi(drawHud: ScreenGui, layoutFamily: string)
	local oldSafeRoot = drawHud:FindFirstChild("SafeRoot")
	if oldSafeRoot then
		oldSafeRoot:Destroy()
	end

	local touchLayout = layoutFamily == "touch"

	drawHud.Enabled = true
	drawHud.DisplayOrder = 20
	drawHud.ResetOnSpawn = false

	local safeRoot = Instance.new("Frame")
	safeRoot.Name = "SafeRoot"
	safeRoot.BackgroundTransparency = 1
	safeRoot.AnchorPoint = Vector2.zero
	safeRoot.Position = UDim2.fromScale(0.025, 0.02)
	safeRoot.Size = UDim2.fromScale(0.95, 0.96)
	safeRoot.Parent = drawHud

	local drawCanvas = Instance.new("Frame")
	drawCanvas.Name = "DrawCanvas"
	drawCanvas.AnchorPoint = Vector2.new(0.5, 1)
	drawCanvas.Position = UDim2.fromScale(0.5, 0.975)
	drawCanvas.Size = if touchLayout then TOUCH_CANVAS_SIZE else DESKTOP_CANVAS_SIZE
	drawCanvas.BackgroundColor3 = Color3.fromRGB(24, 31, 42)
	drawCanvas.BackgroundTransparency = 0.18
	drawCanvas.BorderSizePixel = 0
	drawCanvas.ZIndex = 20
	drawCanvas.Parent = safeRoot

	local canvasCorner = Instance.new("UICorner")
	canvasCorner.CornerRadius = UDim.new(0, 22)
	canvasCorner.Parent = drawCanvas

	local canvasStroke = Instance.new("UIStroke")
	canvasStroke.Thickness = 2
	canvasStroke.Transparency = 0.25
	canvasStroke.Parent = drawCanvas

	local drawInputRect = makeFrame("DrawInputRect", drawCanvas)
	drawInputRect.AnchorPoint = Vector2.new(0.5, 0.5)
	drawInputRect.Position = UDim2.fromScale(0.5, 0.5)
	drawInputRect.Size = DRAW_INPUT_SIZE
	drawInputRect.BackgroundColor3 = Color3.fromRGB(31, 39, 52)
	drawInputRect.BackgroundTransparency = 0.72
	drawInputRect.Active = true
	drawInputRect.ClipsDescendants = true
	drawInputRect.ZIndex = 21

	local semanticSquareConstraint = Instance.new("UIAspectRatioConstraint")
	semanticSquareConstraint.Name = "SemanticSquareConstraint"
	semanticSquareConstraint.AspectRatio = 1
	semanticSquareConstraint.DominantAxis = Enum.DominantAxis.Height
	semanticSquareConstraint.Parent = drawInputRect

	local drawInputSurfaceStroke = Instance.new("UIStroke")
	drawInputSurfaceStroke.Name = "DrawInputSurfaceStroke"
	drawInputSurfaceStroke.Thickness = 1
	drawInputSurfaceStroke.Transparency = 0.45
	drawInputSurfaceStroke.Parent = drawInputRect

	local strokePreview = makeFrame("StrokePreview", drawInputRect)
	strokePreview.AnchorPoint = Vector2.new(0, 0)
	strokePreview.Position = UDim2.fromScale(0, 0)
	strokePreview.Size = UDim2.fromScale(1, 1)
	strokePreview.ClipsDescendants = true
	strokePreview.ZIndex = 23

	local acceptedLayer = makeFrame("AcceptedLayer", strokePreview)
	acceptedLayer.Size = UDim2.fromScale(1, 1)
	acceptedLayer.ZIndex = 23

	local liveLayer = makeFrame("LiveLayer", strokePreview)
	liveLayer.Size = UDim2.fromScale(1, 1)
	liveLayer.ZIndex = 24

	local pivotMarker = Instance.new("Frame")
	pivotMarker.Name = "PivotMarker"
	pivotMarker.AnchorPoint = Vector2.new(0.5, 0.5)
	pivotMarker.Position = UDim2.fromScale(0.5, 0.5)
	pivotMarker.Size = UDim2.fromOffset(8, 8)
	pivotMarker.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	pivotMarker.BackgroundTransparency = 0.75
	pivotMarker.BorderSizePixel = 0
	pivotMarker.ZIndex = 25
	pivotMarker.Parent = drawInputRect

	local pivotCorner = Instance.new("UICorner")
	pivotCorner.CornerRadius = UDim.new(1, 0)
	pivotCorner.Parent = pivotMarker

	local acceptedShapeThumbnail = Instance.new("Frame")
	acceptedShapeThumbnail.Name = "AcceptedShapeThumbnail"
	acceptedShapeThumbnail.AnchorPoint = Vector2.new(1, 0)
	acceptedShapeThumbnail.Position = UDim2.fromScale(0.975, 0.025)
	acceptedShapeThumbnail.Size = UDim2.fromScale(0.14, 0.25)
	acceptedShapeThumbnail.BackgroundColor3 = Color3.fromRGB(13, 18, 26)
	acceptedShapeThumbnail.BackgroundTransparency = 0.25
	acceptedShapeThumbnail.BorderSizePixel = 0
	acceptedShapeThumbnail.ClipsDescendants = true
	acceptedShapeThumbnail.ZIndex = 26
	acceptedShapeThumbnail.Parent = drawCanvas

	local thumbnailAspect = Instance.new("UIAspectRatioConstraint")
	thumbnailAspect.AspectRatio = 1
	thumbnailAspect.DominantAxis = Enum.DominantAxis.Width
	thumbnailAspect.Parent = acceptedShapeThumbnail

	local emptyGhost = Instance.new("TextLabel")
	emptyGhost.Name = "EmptyGhost"
	emptyGhost.AnchorPoint = Vector2.new(0.5, 0.5)
	emptyGhost.Position = UDim2.fromScale(0.5, 0.5)
	emptyGhost.Size = UDim2.fromScale(0.24, 0.32)
	emptyGhost.BackgroundTransparency = 1
	emptyGhost.Text = "✎"
	emptyGhost.TextColor3 = Color3.fromRGB(255, 255, 255)
	emptyGhost.TextTransparency = 0.82
	emptyGhost.TextScaled = true
	emptyGhost.ZIndex = 22
	emptyGhost.Parent = drawCanvas

	local validationToast = Instance.new("TextLabel")
	validationToast.Name = "ValidationToast"
	validationToast.AnchorPoint = Vector2.new(0.5, 1)
	validationToast.Position = if touchLayout then TOUCH_VALIDATION_POSITION else DESKTOP_VALIDATION_POSITION
	validationToast.Size = if touchLayout then TOUCH_VALIDATION_SIZE else DESKTOP_VALIDATION_SIZE
	validationToast.BackgroundTransparency = 1
	validationToast.Text = ""
	validationToast.Visible = false
	validationToast.ZIndex = 30
	validationToast.Parent = safeRoot

	local drawHint = Instance.new("TextLabel")
	drawHint.Name = "DrawHint"
	drawHint.AnchorPoint = Vector2.new(0.5, 1)
	drawHint.Position = if touchLayout then TOUCH_HINT_POSITION else DESKTOP_HINT_POSITION
	drawHint.Size = if touchLayout then TOUCH_HINT_SIZE else DESKTOP_HINT_SIZE
	drawHint.BackgroundTransparency = 1
	drawHint.Text = ""
	drawHint.Visible = false
	drawHint.ZIndex = 30
	drawHint.Parent = safeRoot

	return {
		safeRoot = safeRoot,
		drawCanvas = drawCanvas,
		drawInputRect = drawInputRect,
		strokePreview = strokePreview,
		acceptedLayer = acceptedLayer,
		liveLayer = liveLayer,
		acceptedShapeThumbnail = acceptedShapeThumbnail,
		emptyGhost = emptyGhost,
		validationToast = validationToast,
		drawHint = drawHint,
	}
end

function DrawingController.new(inputController: any, drawHud: ScreenGui, submitStroke: any?, strokeResult: any?)
	local layoutFamily = initialLayoutFamily()
	local ui = createUi(drawHud, layoutFamily)

	local self = setmetatable({
		_inputController = inputController,
		_submitStroke = submitStroke,
		_strokeResult = strokeResult,
		_ui = ui,
		_connection = nil,
		_resultConnection = nil,
		_layoutConnection = nil,
		_livePoints = {} :: { Vector2 },
		_semanticPixelPoints = {} :: { Vector2 },
		_acceptedSemanticPoints = {} :: { SemanticPoint },
		acceptedPoints = {} :: { Vector2 },
		livePoints = {} :: { Vector2 },
		_drawing = false,
		_hasStartedStroke = false,
		_pointerFamily = layoutFamily,
		_layoutFamily = layoutFamily,
		_pendingLayoutFamily = nil,
		_validationGeneration = 0,
		_nextSequence = 1,
		_latestSubmittedSequence = 0,
		_lastAcceptedSequence = 0,
		_pendingStrokes = {} :: { [number]: { SemanticPoint } },
	}, DrawingController)

	self.livePoints = self._livePoints
	return self
end

function DrawingController:_strokeThickness(): number
	local family = if self._drawing then self._pointerFamily else self._layoutFamily
	return if family == "touch" then TOUCH_THICKNESS else DESKTOP_THICKNESS
end

function DrawingController:_renderAcceptedStroke()
	local inputSize = self._ui.drawInputRect.AbsoluteSize
	if inputSize.X <= 0 or inputSize.Y <= 0 then
		table.clear(self.acceptedPoints)
		clearSegments(self._ui.acceptedLayer)
		return
	end

	self.acceptedPoints = semanticPointsToPixels(self._acceptedSemanticPoints, inputSize)
	renderPolyline(self._ui.acceptedLayer, self.acceptedPoints, self:_strokeThickness(), 0.35)
end

function DrawingController:_renderThumbnail()
	local thumbnail = self._ui.acceptedShapeThumbnail
	clearSegments(thumbnail)

	local thumbSize = thumbnail.AbsoluteSize
	if thumbSize.X <= 0 or thumbSize.Y <= 0 then
		return
	end

	local mapped = semanticPointsToPixels(self._acceptedSemanticPoints, thumbSize)
	renderPolyline(thumbnail, mapped, math.max(2, self:_strokeThickness() * 0.45), 0.1)
end

function DrawingController:_applyLayout(family: string)
	if self._drawing then
		self._pendingLayoutFamily = family
		return
	end

	self._layoutFamily = family
	self._pendingLayoutFamily = nil
	local validationToast = self._ui.validationToast
	local drawHint = self._ui.drawHint
	if family == "touch" then
		self._ui.drawCanvas.Size = TOUCH_CANVAS_SIZE
		validationToast.Position = TOUCH_VALIDATION_POSITION
		validationToast.Size = TOUCH_VALIDATION_SIZE
		drawHint.Position = TOUCH_HINT_POSITION
		drawHint.Size = TOUCH_HINT_SIZE
	else
		self._ui.drawCanvas.Size = DESKTOP_CANVAS_SIZE
		validationToast.Position = DESKTOP_VALIDATION_POSITION
		validationToast.Size = DESKTOP_VALIDATION_SIZE
		drawHint.Position = DESKTOP_HINT_POSITION
		drawHint.Size = DESKTOP_HINT_SIZE
	end

	-- AbsoluteSize is updated by Roblox layout after the size token changes. Re-render
	-- the accepted semantic shape on the next task so pixel Frames match the new square.
	task.defer(function()
		if self._ui.safeRoot.Parent ~= nil and not self._drawing then
			self:_renderAcceptedStroke()
			self:_renderThumbnail()
		end
	end)
end

function DrawingController:_applyPendingLayout()
	local family = self._pendingLayoutFamily
	if family == nil then
		return
	end
	self._pendingLayoutFamily = nil
	self:_applyLayout(family)
end

function DrawingController:_toLocal(screenPoint: Vector2): Vector2
	return screenPoint - self._ui.drawInputRect.AbsolutePosition
end

function DrawingController:_clearLiveStroke()
	table.clear(self._livePoints)
	table.clear(self._semanticPixelPoints)
	clearSegments(self._ui.liveLayer)
end

function DrawingController:_setValidation(message: string?)
	self._validationGeneration += 1
	local generation = self._validationGeneration
	local toast = self._ui.validationToast
	if message == nil or message == "" then
		toast.Text = ""
		toast.Visible = false
		return
	end

	self._ui.drawHint.Visible = false
	toast.Text = message
	toast.Visible = true
	task.delay(VALIDATION_TOAST_DURATION, function()
		if generation == self._validationGeneration and self._ui.safeRoot.Parent ~= nil then
			toast.Text = ""
			toast.Visible = false
		end
	end)
end

function DrawingController:_normalizedPixelDistance(a: Vector2, b: Vector2): number
	local inputSize = self._ui.drawInputRect.AbsoluteSize
	if inputSize.X <= 0 or inputSize.Y <= 0 then
		return math.huge
	end
	local delta = a - b
	return Vector2.new((delta.X / inputSize.X) * 2, (delta.Y / inputSize.Y) * 2).Magnitude
end

function DrawingController:_compactSemanticPixelPoints()
	local samples = self._semanticPixelPoints
	if #samples <= 2 then
		return
	end

	local compacted = table.create(math.ceil(#samples / 2) + 1)
	table.insert(compacted, samples[1])
	for index = 3, #samples - 1, 2 do
		table.insert(compacted, samples[index])
	end
	local finalPoint = samples[#samples]
	if compacted[#compacted] ~= finalPoint then
		table.insert(compacted, finalPoint)
	end

	table.clear(self._semanticPixelPoints)
	for _, point in compacted do
		table.insert(self._semanticPixelPoints, point)
	end
end

function DrawingController:_tryAppendSemanticPoint(point: Vector2, forceFinal: boolean)
	local samples = self._semanticPixelPoints
	local config = PhysicsConfig.StrokeProcessing
	local last = samples[#samples]
	if last == nil then
		table.insert(samples, point)
		return
	end
	if (point - last).Magnitude <= 0 then
		return
	end

	if #samples >= config.MaxRawPoints then
		self:_compactSemanticPixelPoints()
		last = samples[#samples]
	end

	if forceFinal then
		table.insert(samples, point)
		return
	end

	if self:_normalizedPixelDistance(point, last) >= config.RawSampleMinMovementNormalized then
		table.insert(samples, point)
	end
end

function DrawingController:_compactLivePoints()
	local points = self._livePoints
	if #points <= 2 then
		return
	end

	local compacted = table.create(math.ceil(#points / 2) + 1)
	table.insert(compacted, points[1])
	for index = 3, #points - 1, 2 do
		table.insert(compacted, points[index])
	end
	local finalPoint = points[#points]
	if compacted[#compacted] ~= finalPoint then
		table.insert(compacted, finalPoint)
	end

	table.clear(self._livePoints)
	for _, point in compacted do
		table.insert(self._livePoints, point)
	end
	renderPolyline(self._ui.liveLayer, self._livePoints, self:_strokeThickness(), 0)
end

function DrawingController:_appendLivePoint(point: Vector2, _forceFinal: boolean)
	local points = self._livePoints
	local previous = points[#points]
	if previous == nil then
		table.insert(points, point)
		return
	end
	if (point - previous).Magnitude <= 0 then
		return
	end

	local maxPoints = PhysicsConfig.StrokeProcessing.MaxRawPoints
	if #points >= maxPoints then
		self:_compactLivePoints()
		previous = points[#points]
	end

	table.insert(points, point)
	if previous ~= nil then
		drawSegment(self._ui.liveLayer, previous, point, self:_strokeThickness(), 0)
	end
end

function DrawingController:_prepareSemanticPoints(pixelPoints: { Vector2 }): ({ SemanticPoint }?, string?)
	local inputSize = self._ui.drawInputRect.AbsoluteSize
	if inputSize.X <= 0 or inputSize.Y <= 0 then
		return nil, "DRAW_SURFACE_NOT_READY"
	end

	local config = PhysicsConfig.StrokeProcessing
	if #pixelPoints < config.MinimumRawPoints then
		return nil, "TOO_FEW_POINTS"
	end

	local normalized = StrokeMath.Normalize(pixelPoints, inputSize)
	local clamped, clampError = StrokeMath.Clamp(normalized, {
		minCoordinate = config.NormalizedMin,
		maxCoordinate = config.NormalizedMax,
		maxPoints = config.MaxRawPoints,
	})
	if clamped == nil then
		return nil, clampError or "INVALID_STROKE"
	end

	local deduped = StrokeMath.Dedupe(clamped, config.DedupeDistance)
	if #deduped < 2 then
		return nil, "TOO_SHORT"
	end

	local simplified = StrokeMath.SimplifyRDP(deduped, config.RDPEpsilon)
	if #simplified < 2 then
		return nil, "TOO_SHORT"
	end

	local targetPoints = math.min(config.ResampleTargetPoints, config.MaxCleanedPoints)
	local cleaned = StrokeMath.Resample(simplified, targetPoints)
	if #cleaned < 2 or StrokeMath.MeasureLength(cleaned) < config.MinimumCleanedPolylineLength then
		return nil, "TOO_SHORT"
	end

	local points = table.create(#cleaned)
	for index, point in cleaned do
		points[index] = {
			x = point.X,
			y = point.Y,
		}
	end
	return points, nil
end

function DrawingController:_submitStrokeIntent(semanticPixelPoints: { Vector2 })
	if self._submitStroke == nil then
		self:_setValidation("NETWORK_NOT_READY")
		return
	end

	local semanticPoints, prepareError = self:_prepareSemanticPoints(semanticPixelPoints)
	if semanticPoints == nil then
		self:_setValidation(prepareError or "INVALID_STROKE")
		return
	end

	local sequence = self._nextSequence
	self._nextSequence += 1
	self._latestSubmittedSequence = sequence
	self._pendingStrokes[sequence] = copySemanticPoints(semanticPoints)
	self:_setValidation(nil)

	self._submitStroke:FireServer({
		sequence = sequence,
		points = semanticPoints,
	})
	print(("[DrawRacers][B12] stroke submitted sequence=%d points=%d"):format(sequence, #semanticPoints))
end

function DrawingController:_onStrokeResult(result: any)
	if type(result) ~= "table" then
		return
	end

	local sequence = result.sequence
	if type(sequence) ~= "number" or math.floor(sequence) ~= sequence then
		return
	end

	local pending = self._pendingStrokes[sequence]
	if pending == nil then
		return
	end
	self._pendingStrokes[sequence] = nil

	if result.accepted == true then
		if not validServerSemanticPoints(result.acceptedPoints) then
			warn(("[DrawRacers][R14.1] malformed authoritative acceptedPoints sequence=%d"):format(sequence))
			if sequence == self._latestSubmittedSequence then
				self:_setValidation("INVALID_SERVER_RESULT")
			end
			return
		end
		if sequence > self._lastAcceptedSequence then
			self._lastAcceptedSequence = sequence
			self._acceptedSemanticPoints = copySemanticPoints(result.acceptedPoints)
			self:_renderAcceptedStroke()
			self:_renderThumbnail()
			self._ui.emptyGhost.Visible = not self._hasStartedStroke
			self:_setValidation(nil)

			for pendingSequence, _ in self._pendingStrokes do
				if pendingSequence < sequence then
					self._pendingStrokes[pendingSequence] = nil
				end
			end
		end
		print(("[DrawRacers][B12] stroke accepted sequence=%d shapeVersion=%s"):format(
			sequence,
			tostring(result.shapeVersion)
		))
		return
	end

	self:_renderAcceptedStroke()
	self:_renderThumbnail()
	self._ui.emptyGhost.Visible = not self._hasStartedStroke
	if sequence == self._latestSubmittedSequence then
		local rejectReasonCode = if type(result.rejectReasonCode) == "string"
			then result.rejectReasonCode
			else "STROKE_REJECTED"
		self:_setValidation(rejectReasonCode)
		print(("[DrawRacers][B12] stroke rejected sequence=%d reason=%s"):format(sequence, rejectReasonCode))
	end
end

function DrawingController:_onPointer(event)
	if event.phase == "start" then
		self._pointerFamily = event.family
		if event.family ~= self._layoutFamily then
			self._pendingLayoutFamily = event.family
		end
		self._drawing = true
		self._hasStartedStroke = true
		self._ui.emptyGhost.Visible = false
		self._ui.acceptedLayer.Visible = false
		self:_setValidation(nil)
		self:_clearLiveStroke()

		local point = self:_toLocal(event.position)
		self:_appendLivePoint(point, false)
		self:_tryAppendSemanticPoint(point, false)
	elseif event.phase == "move" then
		if not self._drawing then
			return
		end

		local point = self:_toLocal(event.position)
		self:_appendLivePoint(point, false)
		self:_tryAppendSemanticPoint(point, false)
	elseif event.phase == "end" then
		if not self._drawing then
			return
		end

		local point = self:_toLocal(event.position)
		self:_appendLivePoint(point, true)
		self:_tryAppendSemanticPoint(point, true)

		local pendingPixels = copyPoints(self._livePoints)
		local semanticPixels = copyPoints(self._semanticPixelPoints)
		self._drawing = false
		self:_clearLiveStroke()
		self._ui.acceptedLayer.Visible = true
		self:_renderAcceptedStroke()
		self._ui.emptyGhost.Visible = not self._hasStartedStroke

		if #semanticPixels >= PhysicsConfig.StrokeProcessing.MinimumRawPoints then
			self:_submitStrokeIntent(semanticPixels)
		else
			self:_setValidation("TOO_FEW_POINTS")
		end
		print(("[DrawRacers][B02] local stroke complete pending=%d semantic=%d accepted=%d"):format(
			#pendingPixels,
			#semanticPixels,
			#self.acceptedPoints
		))
		self:_applyPendingLayout()
	elseif event.phase == "cancel" then
		if not self._drawing then
			return
		end

		self._drawing = false
		self:_clearLiveStroke()
		self._ui.acceptedLayer.Visible = true
		self:_renderAcceptedStroke()
		self._ui.emptyGhost.Visible = not self._hasStartedStroke
		print(("[DrawRacers][B02] stroke cancelled; accepted preserved=%d"):format(#self.acceptedPoints))
		self:_applyPendingLayout()
	end
end

function DrawingController:Start()
	if self._connection then
		return
	end

	local inputController = self._inputController
	local drawInputRect = self._ui.drawInputRect
	inputController:Bind(drawInputRect)
	self._connection = inputController:Connect(function(event)
		self:_onPointer(event)
	end)
	self._layoutConnection = UserInputService.LastInputTypeChanged:Connect(function(inputType)
		local family = inputTypeFamily(inputType)
		if family == nil then
			return
		end
		if self._drawing then
			return
		end
		if family == self._layoutFamily then
			return
		end
		self:_applyLayout(family)
	end)

	if self._strokeResult ~= nil and self._resultConnection == nil then
		self._resultConnection = self._strokeResult.OnClientEvent:Connect(function(result)
			self:_onStrokeResult(result)
		end)
	end

	print("[DrawRacers][B02] local draw preview ready")
end

function DrawingController:Destroy()
	if self._connection then
		self._connection:Disconnect()
		self._connection = nil
	end
	if self._resultConnection then
		self._resultConnection:Disconnect()
		self._resultConnection = nil
	end
	if self._layoutConnection then
		self._layoutConnection:Disconnect()
		self._layoutConnection = nil
	end
	self._validationGeneration += 1
	table.clear(self._pendingStrokes)
	table.clear(self._acceptedSemanticPoints)
	self._inputController:Unbind()
	if self._ui.safeRoot then
		self._ui.safeRoot:Destroy()
	end
end

return DrawingController
