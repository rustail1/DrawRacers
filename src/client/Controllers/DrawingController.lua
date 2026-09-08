--!strict

local DrawingController = {}
DrawingController.__index = DrawingController

local DESKTOP_CANVAS_SIZE = UDim2.fromScale(0.46, 0.255)
local TOUCH_CANVAS_SIZE = UDim2.fromScale(0.64, 0.285)
local DRAW_INPUT_SIZE = UDim2.fromScale(0.92, 0.82)

local DESKTOP_THICKNESS = 6
local TOUCH_THICKNESS = 8

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

local function createUi(drawHud: ScreenGui)
	local oldSafeRoot = drawHud:FindFirstChild("SafeRoot")
	if oldSafeRoot then
		oldSafeRoot:Destroy()
	end

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
	drawCanvas.Size = DESKTOP_CANVAS_SIZE
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
	drawInputRect.Active = true
	drawInputRect.ClipsDescendants = true
	drawInputRect.ZIndex = 21

	local strokePreview = makeFrame("StrokePreview", drawCanvas)
	strokePreview.AnchorPoint = Vector2.new(0.5, 0.5)
	strokePreview.Position = UDim2.fromScale(0.5, 0.5)
	strokePreview.Size = DRAW_INPUT_SIZE
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
	validationToast.Position = UDim2.fromScale(0.5, 0.705)
	validationToast.Size = UDim2.fromScale(0.32, 0.052)
	validationToast.BackgroundTransparency = 1
	validationToast.Text = ""
	validationToast.Visible = false
	validationToast.ZIndex = 30
	validationToast.Parent = safeRoot

	local drawHint = Instance.new("TextLabel")
	drawHint.Name = "DrawHint"
	drawHint.AnchorPoint = Vector2.new(0.5, 1)
	drawHint.Position = UDim2.fromScale(0.5, 0.705)
	drawHint.Size = UDim2.fromScale(0.38, 0.06)
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

function DrawingController.new(inputController: any, drawHud: ScreenGui)
	local ui = createUi(drawHud)

	local self = setmetatable({
		_inputController = inputController,
		_ui = ui,
		_connection = nil,
		_livePoints = {} :: { Vector2 },
		acceptedPoints = {} :: { Vector2 },
		livePoints = {} :: { Vector2 },
		_drawing = false,
		_pointerFamily = "mouse",
	}, DrawingController)

	-- Alias names are intentionally explicit for the B02 contract/readability.
	self.livePoints = self._livePoints

	return self
end

function DrawingController:_strokeThickness(): number
	return if self._pointerFamily == "touch" then TOUCH_THICKNESS else DESKTOP_THICKNESS
end

function DrawingController:_applyLayout(family: string)
	if family == "touch" then
		self._ui.drawCanvas.Size = TOUCH_CANVAS_SIZE
	else
		self._ui.drawCanvas.Size = DESKTOP_CANVAS_SIZE
	end
end

function DrawingController:_toLocal(screenPoint: Vector2): Vector2
	return screenPoint - self._ui.drawInputRect.AbsolutePosition
end

function DrawingController:_renderAcceptedStroke()
	renderPolyline(self._ui.acceptedLayer, self.acceptedPoints, self:_strokeThickness(), 0.35)
end

function DrawingController:_clearLiveStroke()
	table.clear(self._livePoints)
	clearSegments(self._ui.liveLayer)
end

local function renderThumbnail(self)
	local thumbnail = self._ui.acceptedShapeThumbnail
	clearSegments(thumbnail)

	local inputSize = self._ui.drawInputRect.AbsoluteSize
	local thumbSize = thumbnail.AbsoluteSize
	if inputSize.X <= 0 or inputSize.Y <= 0 or thumbSize.X <= 0 or thumbSize.Y <= 0 then
		return
	end

	local mapped = table.create(#self.acceptedPoints)
	for index, point in self.acceptedPoints do
		mapped[index] = Vector2.new(
			(point.X / inputSize.X) * thumbSize.X,
			(point.Y / inputSize.Y) * thumbSize.Y
		)
	end
	renderPolyline(thumbnail, mapped, math.max(2, self:_strokeThickness() * 0.45), 0.1)
end

function DrawingController:_onPointer(event)
	if event.phase == "start" then
		self._pointerFamily = event.family
		self:_applyLayout(event.family)
		self._drawing = true
		self._ui.emptyGhost.Visible = false
		self._ui.acceptedLayer.Visible = false
		self:_clearLiveStroke()

		local point = self:_toLocal(event.position)
		table.insert(self._livePoints, point)
	elseif event.phase == "move" then
		if not self._drawing then
			return
		end

		local point = self:_toLocal(event.position)
		local previous = self._livePoints[#self._livePoints]
		table.insert(self._livePoints, point)
		if previous then
			drawSegment(self._ui.liveLayer, previous, point, self:_strokeThickness(), 0)
		end
	elseif event.phase == "end" then
		if not self._drawing then
			return
		end

		local point = self:_toLocal(event.position)
		local previous = self._livePoints[#self._livePoints]
		if previous and (point - previous).Magnitude > 0 then
			table.insert(self._livePoints, point)
			drawSegment(self._ui.liveLayer, previous, point, self:_strokeThickness(), 0)
		end

		if #self._livePoints >= 2 then
			self.acceptedPoints = copyPoints(self._livePoints)
			self:_renderAcceptedStroke()
			renderThumbnail(self)
		end

		self._drawing = false
		self:_clearLiveStroke()
		self._ui.acceptedLayer.Visible = true
		print(("[DrawRacers][B02] local stroke complete points=%d"):format(#self.acceptedPoints))
	elseif event.phase == "cancel" then
		if not self._drawing then
			return
		end

		self._drawing = false
		self:_clearLiveStroke()
		self._ui.acceptedLayer.Visible = true
		self:_renderAcceptedStroke()
		print(("[DrawRacers][B02] stroke cancelled; accepted preserved=%d"):format(#self.acceptedPoints))
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

	print("[DrawRacers][B02] local draw preview ready")
end

function DrawingController:Destroy()
	if self._connection then
		self._connection:Disconnect()
		self._connection = nil
	end
	self._inputController:Unbind()
	if self._ui.safeRoot then
		self._ui.safeRoot:Destroy()
	end
end

return DrawingController
