--!strict

local LegShapeService = require(script.Parent:WaitForChild("LegShapeService"))

local StrokeRemoteTransport = {}

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
		local ok, resultOrError = xpcall(function()
			return processor:Handle(player, payload)
		end, debug.traceback)

		if not ok then
			warn("[DrawRacers][R14.5] SubmitStroke processor failure: " .. tostring(resultOrError))
			local sequence = LegShapeService.ExtractSafeSequence(payload)
			if sequence ~= nil then
				strokeResult:FireClient(player, {
					sequence = sequence,
					accepted = false,
					rejectReasonCode = "SERVER_ERROR",
				})
			end
			return
		end

		local result = resultOrError
		if result ~= nil then
			strokeResult:FireClient(player, result)
		end
	end)

	return connection
end

return StrokeRemoteTransport
