-- This file is part of the Spring engine (GPL v2 or later), see LICENSE.html

function widget:GetInfo()
	return {
		name = "Rejoin Benchmark",
		desc = "Time a fresh midgame client's catch-up to a reported server frame",
		license = "GPL v2 or later",
		enabled = true,
	}
end

local startFrame, targetFrame, startTime
local finished = false

function widget:Initialize()
	finished = Spring.IsReplay()
end

function widget:GameProgress(serverFrame)
	if finished then
		return
	end
	if startTime then
		targetFrame = math.max(targetFrame, serverFrame)
		return
	end

	local clientFrame = Spring.GetGameFrame()
	-- Ignore ordinary progress reports and stalls in an already-running client.
	if clientFrame > Game.gameSpeed or serverFrame - clientFrame < 5 * Game.gameSpeed then
		return
	end

	startFrame = clientFrame
	targetFrame = serverFrame
	startTime = Spring.GetTimer()
	Spring.Echo(("RejoinBenchmark begin client_frame=%d server_frame=%d"):format(startFrame, targetFrame))
end

function widget:Update()
	if finished or not startTime then
		return
	end
	local clientFrame = Spring.GetGameFrame()
	if clientFrame < targetFrame then
		return
	end

	local elapsedMs = Spring.DiffTimers(Spring.GetTimer(), startTime, true)
	Spring.Echo(("RejoinBenchmark end client_frame=%d server_frame=%d frames_simulated=%d elapsed_ms=%.1f")
		:format(clientFrame, targetFrame, clientFrame - startFrame, elapsedMs))
	finished = true
end
