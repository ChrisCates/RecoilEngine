-- This file is part of the Spring engine (GPL v2 or later), see LICENSE.html

local function loadProbe(isReplay, fixedTargetFrame)
	local gameFrame, clock = 0, 0
	local messages = {}
	local environment = {
		widget = {},
		Game = { gameSpeed = 30 },
		Spring = {
			IsReplay = function() return isReplay end,
			GetConfigInt = function(key, default)
				assert(key == "RejoinBenchmarkTargetFrame")
				return fixedTargetFrame or default
			end,
			GetGameFrame = function() return gameFrame end,
			GetTimer = function() return clock end,
			DiffTimers = function(finish, start, milliseconds)
				assert(milliseconds)
				return finish - start
			end,
			Echo = function(message) messages[#messages + 1] = message end,
		},
		math = math,
	}
	local chunk = assert(loadfile("tools/benchmark/rejoin_probe.lua"))
	setfenv(chunk, environment)
	chunk()
	local probe = environment.widget
	probe:Initialize()
	return probe, messages, function(frame, time)
		gameFrame, clock = frame, time
	end
end

local probe, messages, setState = loadProbe(false)
probe:Update()
probe:GameProgress(149)
assert(#messages == 0, "normal startup must stay silent")

setState(1, 100)
probe:GameProgress(151)
assert(messages[1] == "RejoinBenchmark begin source=progress client_frame=1 server_frame=151")
probe:GameProgress(300)
probe:GameProgress(150)
setState(299, 200)
probe:Update()
assert(#messages == 1, "wait for the highest reported frame")
setState(300, 350)
probe:Update()
assert(messages[2] == "RejoinBenchmark end source=progress client_frame=300 server_frame=300 frames_advanced=299 elapsed_ms=250.0")
probe:GameProgress(450)
probe:Update()
assert(#messages == 2, "emit a single measurement per session")

probe, messages, setState = loadProbe(false)
setState(31, 100)
probe:GameProgress(300)
probe:Update()
assert(#messages == 0, "a running client falling behind must stay silent")

probe, messages, setState = loadProbe(true, 300)
probe:GameProgress(300)
probe:GameFrame(0)
setState(300, 200)
probe:Update()
assert(#messages == 0, "demo playback must stay silent")

probe, messages, setState = loadProbe(false, 550)
probe:GameProgress(300)
assert(#messages == 0, "fixed-frame measurement waits for the first simulation frame")
setState(0, 100)
probe:GameFrame(0)
assert(messages[1] == "RejoinBenchmark begin source=fixed_frame client_frame=0 server_frame=550")
probe:GameProgress(600)
probe:GameFrame(100)
setState(549, 150)
probe:Update()
assert(#messages == 1, "fixed-frame measurement waits until its target is reached")
setState(550, 240)
probe:Update()
assert(messages[2] == "RejoinBenchmark end source=fixed_frame client_frame=550 server_frame=550 frames_advanced=550 elapsed_ms=140.0")

print("rejoin probe checks passed")
