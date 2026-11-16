# Fresh rejoin benchmark

`rejoin_probe.lua` is an unsynced development widget. Copy it into the local
widget directory of an isolated test client that permits user widgets. The
widget logs `RejoinBenchmark begin` when a server progress packet reports a
backlog of at least five game seconds during the client's first simulated second.
It logs `RejoinBenchmark end` when the client reaches the highest server frame
reported so far. The `source=progress` elapsed time starts at the first
qualifying progress packet and excludes any earlier startup or loading time.

## Run a baseline

1. Start a private localhost match with two clients using identical engine,
   game and map builds. Run the probe on the client that will rejoin.
2. Close that client after the match starts. Keep the host and the other client
   running. Pause at a fixed frame at least five game seconds after match start.
3. In the rejoining client's isolated `springsettings.cfg`, set
   `RejoinBenchmarkTargetFrame` to the exact paused frame. Start a fresh engine
   process for the same player. Check `infolog.txt` for one `begin` line at the
   first simulation frame and one `end` line at the paused server frame.
   Resume the match and check that it continues without sync errors.
4. Repeat with the same starting conditions and target frame when comparing
   builds or client settings. Record the engine, game, map, target frame, wall
   time from process launch and probe time as separate measurements.

To log the exact pause frame, add this call-in to a temporary widget on the
client that stays in the match, then check its `infolog.txt`.

```lua
function widget:GamePaused(_, paused)
	if paused then
		Spring.Echo("Paused frame", Spring.GetGameFrame())
	end
end
```

Fixed-frame timing uses `source=fixed_frame` and starts at the first
`GameFrame` event. Use it with a paused match so the target stays fixed. Remove
the setting to measure progress events. In a running match the reported frame
can lag the server, and if the initial progress event is missed a paused server
may never report another target. Compare only runs with the same source and
target. Use the graphical client for player-facing performance numbers. Headless
runs can check packet flow and sync, and have their own per-frame pacing. Use a
Tracy capture or host/network metrics to attribute the time to specific work.

## Check the probe

From the checkout root, run `lua5.1 tools/benchmark/test_rejoin_probe.lua`.
The test uses a fake clock and progress events to exercise ordinary startup,
catch-up to a moving target, a stale progress packet, a configured fixed frame,
and replay exclusion.
