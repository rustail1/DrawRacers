--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local PhysicsConfig = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("PhysicsConfig")
)
local StrokeMath = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Math"):WaitForChild("StrokeMath")
)
local LegShapeMath = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Math"):WaitForChild("LegShapeMath")
)
local StrokeTypes = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Types"):WaitForChild("StrokeTypes")
)

local DrawingController = {}
DrawingController.__index = DrawingController

-- RCP-03: increase the gameplay drawing surface to roughly 2x its former area
-- while keeping height as the responsive owner of the canonical 1.75:1 surface.
local DESKTOP_CANVAS_SIZE = UDim2.fromScale(0.70, 0.40)
local TOUCH_CANVAS_SIZE = UDim2.fromScale(0.84, 0.48)
local DRAW_INPUT_SIZE = UDim2.fromScale(1, 1)

local DESKTOP_VALIDATION_POSITION = UDim2.fromScale(0.5, 0.565)
local DESKTOP_VALIDATION_SIZE = UDim2.fromScale(0.32, 0.052)
local TOUCH_VALIDATION_POSITION = UDim2.fromScale(0.5, 0.475)
local TOUCH_VALIDATION_SIZE = UDim2.fromScale(0.44, 0.058)
local DESKTOP_HINT_POSITION = UDim2.fromScale(0.5, 0.565)
local DESKTOP_HINT_SIZE = UDim2.fromScale(0.38, 0.06)
local TOUCH_HINT_POSITION = UDim2.fromScale(0.5, 0.475)
local TOUCH_HINT_SIZE = UDim2.fromScale(0.50, 0.064)

local DESKTOP_THICKNESS = 6
local TOUCH_THICKNESS = 8
local VALIDATION_TOAST_DURATION = 2.0
local PRESENTATION_ANCHOR_HISTORY_MULTIPLIER = 4
local DEFAULT_GRAPHITE_COLOR = Color3.fromRGB(23, 32, 51)
local DRAW_SURFACE_COLOR = Color3.fromRGB(243, 240, 232)

type SemanticPoint = StrokeTypes.SemanticPoint
type SubmitStrokePayload = StrokeTypes.SubmitStrokePayload

type PendingStroke = {
	points: { SemanticPoint },
	generation: number,
}

local function isFiniteNumber(value: any): boolean
	return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

local function validationMessageForReason(reasonCode: string): string
	if reasonCode == "TOO_FEW_POINTS"
		or reasonCode == "TOO_SHORT"
		or reasonCode == "INVALID_STROKE"
	then
		return "DRAW A DIFFERENT SHAPE"
	end
	return "TRY AGAIN"
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
		if child.Name == "Segment" or child.Name == "Joint" then
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
	segment.BackgroundColor3 = DEFAULT_GRAPHITE_COLOR
	segment.BackgroundTransparency = transparency or 0
	segment.BorderSizePixel = 0
	segment.ZIndex = 24
	segment.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = segment
end

local function drawJoint(parent: Instance, point: Vector2, thickness: number, transparency: number?)
	local joint = Instance.new("Frame")
	joint.Name = "Joint"
	joint.AnchorPoint = Vector2.new(0.5, 0.5)
	joint.Position = UDim2.fromOffset(point.X, point.Y)
	joint.Size = UDim2.fromOffset(thickness, thickness)
	joint.BackgroundColor3 = DEFAULT_GRAPHITE_COLOR
	joint.BackgroundTransparency = transparency or 0
	joint.BorderSizePixel = 0
	joint.ZIndex = 25
	joint.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = joint
end

local function renderPolyline(layer: Frame, points: { Vector2 }, thickness: number, transparency: number?)
	clearSegments(layer)
	for index = 2, #points do
		drawSegment(layer, points[index - 1], points[index], thickness, transparency)
	end
	for index = 2, #points - 1 do
		drawJoint(layer, points[index], thickness, transparency)
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

local function copySemanticPoint(point: SemanticPoint): SemanticPoint
	return { x = point.x, y = point.y }
end

local function vector2ToSemanticPoints(points: { Vector2 }): { SemanticPoint }
	local result = table.create(#points)
	for index, point in points do
		result[index] = { x = point.X, y = point.Y }
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
		if math.abs(point.x) > config.RawSemanticHalfWidth * 2 + 1e-6
			or math.abs(point.y) > config.RawSemanticHalfHeight * 2 + 1e-6
		then
			return false
		end
	end
	local first = points[1]
	return math.abs(first.x) <= 1e-6 and math.abs(first.y) <= 1e-6
end

-- Fixed isotropic gameplay mapping. No per-shape fit is allowed here: semantic
-- size on the canvas must preserve the same relative size used by world legs.
local function semanticPointsToPixels(
	points: { SemanticPoint },
	size: Vector2,
	presentationAnchor: SemanticPoint?
): { Vector2 }
	local result = table.create(#points)
	local unit = size.Y * 0.5
	local center = size * 0.5
	local anchor = presentationAnchor or { x = 0, y = 0 }
	for index, point in points do
		local x = point.x + anchor.x
		local y = point.y + anchor.y
		result[index] = Vector2.new(center.X + x * unit, center.Y - y * unit)
	end
	return result
end

local function vectorPointsToPixels(points: { Vector2 }, size: Vector2, presentationAnchor: Vector2): { Vector2 }
	local result = table.create(#points)
	local unit = size.Y * 0.5
	local center = size * 0.5
	for index, point in points do
		local positioned = point + presentationAnchor
		result[index] = Vector2.new(center.X + positioned.X * unit, center.Y - positioned.Y * unit)
	end
	return result
end

-- Auto-fit is intentionally thumbnail-only and never used by the main gameplay preview.
local function fitSemanticPointsToPixels(points: { SemanticPoint }, size: Vector2): { Vector2 }
	if #points == 0 then
		return {}
	end
	local minX = points[1].x
	local maxX = points[1].x
	local minY = points[1].y
	local maxY = points[1].y
	for index = 2, #points do
		local point = points[index]
		minX = math.min(minX, point.x)
		maxX = math.max(maxX, point.x)
		minY = math.min(minY, point.y)
		maxY = math.max(maxY, point.y)
	end
	local spanX = math.max(maxX - minX, 1e-4)
	local spanY = math.max(maxY - minY, 1e-4)
	local scale = math.min(size.X * 0.75 / spanX, size.Y * 0.75 / spanY)
	local centerSemantic = Vector2.new((minX + maxX) * 0.5, (minY + maxY) * 0.5)
	local centerPixel = size * 0.5
	local result = table.create(#points)
	for index, point in points do
		local localPoint = Vector2.new(point.x, point.y) - centerSemantic
		result[index] = Vector2.new(centerPixel.X + localPoint.X * scale, centerPixel.Y - localPoint.Y * scale)
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

	local canvasAspect = Instance.new("UIAspectRatioConstraint")
	canvasAspect.Name = "R16WideDrawSurfaceConstraint"
	canvasAspect.AspectRatio = PhysicsConfig.StrokeProcessing.RawSemanticHalfWidth
		/ PhysicsConfig.StrokeProcessing.RawSemanticHalfHeight
	canvasAspect.DominantAxis = Enum.DominantAxis.Height
	canvasAspect.Parent = drawCanvas

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
	drawInputRect.BackgroundColor3 = DRAW_SURFACE_COLOR
	drawInputRect.BackgroundTransparency = 0.08
	drawInputRect.Active = true
	drawInputRect.ClipsDescendants = true
	drawInputRect.ZIndex = 21

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

	local acceptedShapeThumbnail = Instance.new("Frame")
	acceptedShapeThumbnail.Name = "AcceptedShapeThumbnail"
	acceptedShapeThumbnail.AnchorPoint = Vector2.new(1, 0)
	acceptedShapeThumbnail.Position = UDim2.fromScale(0.975, 0.025)
	acceptedShapeThumbnail.Size = UDim2.fromScale(0.14, 0.25)
	acceptedShapeThumbnail.BackgroundColor3 = DRAW_SURFACE_COLOR
	acceptedShapeThumbnail.BackgroundTransparency = 0.08
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
	emptyGhost.TextColor3 = DEFAULT_GRAPHITE_COLOR
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
		_acceptedPresentationAnchor = nil :: SemanticPoint?,
		_presentationAnchors = {} :: { [number]: SemanticPoint },
		acceptedPoints = {} :: { Vector2 },
		livePoints = {} :: { Vector2 },
		_drawing = false,
		_hasStartedStroke = false,
		_pointerFamily = layoutFamily,
		_layoutFamily = layoutFamily,
		_pendingLayoutFamily = nil,
		_validationGeneration = 0,
		_pendingGeneration = 0,
		_nextSequence = 1,
		_latestSubmittedSequence = 0,
		_lastAcceptedSequence = 0,
		_pendingStrokes = {} :: { [number]: PendingStroke },
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

	self.acceptedPoints = semanticPointsToPixels(
		self._acceptedSemanticPoints,
		inputSize,
		self._acceptedPresentationAnchor
	)
	renderPolyline(self._ui.acceptedLayer, self.acceptedPoints, self:_strokeThickness(), 0.35)
end

function DrawingController:_renderThumbnail()
	local thumbnail = self._ui.acceptedShapeThumbnail
	clearSegments(thumbnail)

	local thumbSize = thumbnail.AbsoluteSize
	if thumbSize.X <= 0 or thumbSize.Y <= 0 then
		return
	end

	local mapped = fitSemanticPointsToPixels(self._acceptedSemanticPoints, thumbSize)
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

function DrawingController:_setValidationReason(reasonCode: string)
	print(("[DrawRacers][Validation] reason=%s"):format(reasonCode))
	self:_setValidation(validationMessageForReason(reasonCode))
end

function DrawingController:_normalizedPixelDistance(a: Vector2, b: Vector2): number
	local inputSize = self._ui.drawInputRect.AbsoluteSize
	if inputSize.X <= 0 or inputSize.Y <= 0 then
		return math.huge
	end
	local unit = inputSize.Y * 0.5
	return (a - b).Magnitude / unit
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
	end
	table.insert(points, point)
end

function DrawingController:_buildCanonicalFromPixels(pixelPoints: { Vector2 }): (any?, { Vector2 }?, string?)
	local inputSize = self._ui.drawInputRect.AbsoluteSize
	if inputSize.X <= 0 or inputSize.Y <= 0 then
		return nil, nil, "DRAW_SURFACE_NOT_READY"
	end
	if #pixelPoints < PhysicsConfig.StrokeProcessing.MinimumRawPoints then
		return nil, nil, "TOO_FEW_POINTS"
	end

	local normalized = StrokeMath.Normalize(pixelPoints, inputSize)
	local canonical, canonicalError = LegShapeMath.BuildCanonical(
		normalized,
		PhysicsConfig.StrokeProcessing,
		PhysicsConfig.LegGeometry
	)
	if canonical == nil then
		return nil, normalized, canonicalError or "INVALID_STROKE"
	end
	return canonical, normalized, nil
end

function DrawingController:_renderLiveCanonicalPreview()
	local inputSize = self._ui.drawInputRect.AbsoluteSize
	if inputSize.X <= 0 or inputSize.Y <= 0 then
		clearSegments(self._ui.liveLayer)
		return
	end

	local canonical = self:_buildCanonicalFromPixels(self._semanticPixelPoints)
	if canonical == nil then
		-- Before a valid gameplay shape exists, keep a faint immediate trace for input feedback.
		-- As soon as the shared builder accepts the stroke, this is replaced by canonical geometry.
		renderPolyline(self._ui.liveLayer, self._semanticPixelPoints, self:_strokeThickness(), 0.55)
		return
	end

	local pixels = vectorPointsToPixels(canonical.normalizedPoints, inputSize, canonical.presentationAnchor)
	renderPolyline(self._ui.liveLayer, pixels, self:_strokeThickness(), 0)
end

function DrawingController:_prepareRawSemanticPoints(pixelPoints: { Vector2 }): ({ SemanticPoint }?, any?, string?)
	local canonical, normalized, canonicalError = self:_buildCanonicalFromPixels(pixelPoints)
	if canonical == nil or normalized == nil then
		return nil, nil, canonicalError or "INVALID_STROKE"
	end
	local rawSemanticPoints = vector2ToSemanticPoints(normalized)
	return rawSemanticPoints, canonical, nil
end

function DrawingController:_pendingStrokeCount(): number
	local count = 0
	for _, _ in self._pendingStrokes do
		count += 1
	end
	return count
end

function DrawingController:_prunePresentationAnchors(referenceSequence: number)
	local keepCount = PhysicsConfig.StrokeProcessing.MaxPendingStrokes * PRESENTATION_ANCHOR_HISTORY_MULTIPLIER
	local minimumSequence = math.max(1, referenceSequence - keepCount)
	for sequence, _ in self._presentationAnchors do
		if sequence < minimumSequence then
			self._presentationAnchors[sequence] = nil
		end
	end
end

function DrawingController:_submitStrokeIntent(semanticPixelPoints: { Vector2 })
	if self._submitStroke == nil then
		self:_setValidationReason("NETWORK_NOT_READY")
		return
	end

	local rawSemanticPoints, canonical, prepareError = self:_prepareRawSemanticPoints(semanticPixelPoints)
	if rawSemanticPoints == nil or canonical == nil then
		self:_setValidationReason(prepareError or "INVALID_STROKE")
		return
	end

	local config = PhysicsConfig.StrokeProcessing
	if self:_pendingStrokeCount() >= config.MaxPendingStrokes then
		self:_setValidationReason("CLIENT_PENDING_LIMIT")
		return
	end

	local sequence = self._nextSequence
	self._nextSequence += 1
	self._latestSubmittedSequence = sequence
	self._pendingGeneration += 1
	local generation = self._pendingGeneration
	self._pendingStrokes[sequence] = {
		points = copySemanticPoints(rawSemanticPoints),
		generation = generation,
	}
	local presentationAnchor: SemanticPoint = {
		x = canonical.presentationAnchor.X,
		y = canonical.presentationAnchor.Y,
	}
	self._presentationAnchors[sequence] = presentationAnchor
	self:_prunePresentationAnchors(sequence)
	self:_setValidation(nil)

	task.delay(config.StrokeResultTimeout, function()
		if self._ui.safeRoot.Parent == nil then
			return
		end
		local pending = self._pendingStrokes[sequence]
		if pending ~= nil and pending.generation == generation then
			self._pendingStrokes[sequence] = nil
			print(("[DrawRacers][R14.5] stroke result timeout sequence=%d"):format(sequence))
			if sequence == self._latestSubmittedSequence then
				self:_setValidationReason("NETWORK_TIMEOUT")
			end
		end
	end)

	local payload: SubmitStrokePayload = {
		sequence = sequence,
		points = rawSemanticPoints,
	}
	self._submitStroke:FireServer(payload)
	print(("[DrawRacers][B12] stroke submitted sequence=%d points=%d"):format(sequence, #rawSemanticPoints))
end

function DrawingController:_onStrokeResult(result: any)
	if type(result) ~= "table" then
		return
	end

	local sequence = result.sequence
	if type(sequence) ~= "number" or math.floor(sequence) ~= sequence then
		return
	end

	self._pendingStrokes[sequence] = nil

	if result.accepted == true then
		if not validServerSemanticPoints(result.acceptedPoints) then
			warn(("[DrawRacers][R14.1] malformed authoritative acceptedPoints sequence=%d"):format(sequence))
			if sequence == self._latestSubmittedSequence then
				self:_setValidationReason("INVALID_SERVER_RESULT")
			end
			return
		end
		if sequence > self._lastAcceptedSequence then
			self._lastAcceptedSequence = sequence
			self._acceptedSemanticPoints = copySemanticPoints(result.acceptedPoints)
			local presentationAnchor = self._presentationAnchors[sequence]
			self._acceptedPresentationAnchor = if presentationAnchor ~= nil then copySemanticPoint(presentationAnchor) else nil
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
		self._presentationAnchors[sequence] = nil
		self:_prunePresentationAnchors(sequence)
		print(("[DrawRacers][B12] stroke accepted sequence=%d shapeVersion=%s"):format(
			sequence,
			tostring(result.shapeVersion)
		))
		return
	end

	self._presentationAnchors[sequence] = nil
	self:_renderAcceptedStroke()
	self:_renderThumbnail()
	self._ui.emptyGhost.Visible = not self._hasStartedStroke
	if sequence == self._latestSubmittedSequence then
		local rejectReasonCode = if type(result.rejectReasonCode) == "string"
			then result.rejectReasonCode
			else "STROKE_REJECTED"
		self:_setValidationReason(rejectReasonCode)
		print(("[DrawRacers][B12] stroke rejected sequence=%d reason=%s"):format(sequence, rejectReasonCode))
	end
end

function DrawingController:_capturePointerPoint(point: Vector2, forceFinal: boolean)
	self:_appendLivePoint(point, forceFinal)
	self:_tryAppendSemanticPoint(point, forceFinal)
	self:_renderLiveCanonicalPreview()
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
		self:_capturePointerPoint(self:_toLocal(event.position), false)
	elseif event.phase == "move" then
		if not self._drawing then
			return
		end
		self:_capturePointerPoint(self:_toLocal(event.position), false)
	elseif event.phase == "end" then
		if not self._drawing then
			return
		end

		self:_capturePointerPoint(self:_toLocal(event.position), true)
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
			self:_setValidationReason("TOO_FEW_POINTS")
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
		if family == nil or self._drawing or family == self._layoutFamily then
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
	self._pendingGeneration += 1
	table.clear(self._pendingStrokes)
	table.clear(self._presentationAnchors)
	table.clear(self._acceptedSemanticPoints)
	self._acceptedPresentationAnchor = nil
	self._inputController:Unbind()
	if self._ui.safeRoot then
		self._ui.safeRoot:Destroy()
	end
end

return DrawingController