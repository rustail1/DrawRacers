--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local StrokeTypes = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Types"):WaitForChild("StrokeTypes")
)
local LegShapeService = require(script.Parent:WaitForChild("LegShapeService"))

local StrokeRemoteTransport = {}

type StrokeResultPayload = StrokeTypes.StrokeResultPayload

function StrokeRemoteTransport.ProcessSafely(processor: any, player: any, payload: any): StrokeResultPayload?
	local ok, resultOrError = xpcall(function()
		return processor:Handle(player, payload)
	end, debug.traceback)

	if not ok then
		warn("[DrawRacers][R14.5] SubmitStroke processor failure: " .. tostring(resultOrError))
		local sequence = LegShapeService.ExtractSafeSequence(payload)
		if sequence ~= nil then
			return {
				sequence = sequence,
				accepted = false,
				rejectReasonCode = "SERVER_ERROR",
			}
		end
		return nil
	end

	return resultOrError
end

function StrokeRemoteTransport.Bind(deps: any)
	assert(type(deps) == "table", "StrokeRemoteTransport.Bind requires deps")
	assert(type(deps.resolveRacer) == "function", "StrokeRemoteTransport.Bind requires resolveRacer")

	local submitStroke = deps.submitStroke
	local strokeResult = deps.strokeResult
	assert(typeof(submitStroke) == "Instance" and submitStroke:IsA("RemoteEvent"), "submitStroke must be RemoteEvent")
	assert(typeof(strokeResult) == "Instance" and strokeResult:IsA("RemoteEvent"), "strokeResult must be RemoteEvent")

	local processor = LegShapeService.CreateSubmitProcessor({
		resolveRacer = deps.resolveRacer,
		now = deps.now,
	})

	local connection = submitStroke.OnServerEvent:Connect(function(player, payload)
		local result = StrokeRemoteTransport.ProcessSafely(processor, player, payload)
		if result ~= nil then
			strokeResult:FireClient(player, result)
		end
	end)

	return connection
end

return StrokeRemoteTransport
