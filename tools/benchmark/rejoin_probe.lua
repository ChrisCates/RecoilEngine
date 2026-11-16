-- This file is part of the Spring engine (GPL v2 or later), see LICENSE.html

function widget:GetInfo()
	return {
		name = "Rejoin Benchmark",
		desc = "Time a fresh midgame client's catch-up to a reported server frame",
		license = "GPL v2 or later",
		enabled = true,
	}
end

local startFrame, targetFrame, startTime, source
local fixedTargetFrame
local finished = false

function widget:Initialize()
	finished = Spring.IsReplay()
	fixedTargetFrame = Spring.GetConfigInt("RejoinBenchmarkTargetFrame", 0)
end

local function begin(clientFrame, serverFrame, measurementSource)
	startFrame = clientFrame
	targetFrame = serverFrame
	startTime = Spring.GetTimer()
	source = measurementSource
	Spring.Echo(("RejoinBenchmark begin source=%s client_frame=%d server_frame=%d")
		:format(source, startFrame, targetFrame))
end

function widget:GameFrame(clientFrame)
	if not finished and not startTime and fixedTargetFrame > 0 then
		begin(clientFrame, fixedTargetFrame, "fixed_frame")
	end
end

function widget:GameProgress(serverFrame)
	if finished or fixedTargetFrame > 0 then
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

	begin(clientFrame, serverFrame, "progress")
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
	Spring.Echo(("RejoinBenchmark end source=%s client_frame=%d server_frame=%d frames_advanced=%d elapsed_ms=%.1f")
		:format(source, clientFrame, targetFrame, clientFrame - startFrame, elapsedMs))
	finished = true
end
