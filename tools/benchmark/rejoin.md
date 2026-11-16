# Fresh rejoin benchmark

`rejoin_probe.lua` is an unsynced development widget. Copy it into the local
widget directory of an isolated test client that permits user widgets. The
widget logs `RejoinBenchmark begin` when a server progress packet reports a
backlog of at least five game seconds during the client's first simulated second.
It logs `RejoinBenchmark end` when the client reaches the highest server frame
reported so far. The elapsed time starts at the first qualifying progress
packet and excludes any earlier startup or loading time.

## Run a baseline

1. Start a private localhost match with two clients using identical engine,
   game and map builds. Run the probe on the client that will rejoin.
2. Close that client after the match starts. Keep the host and the other client
   running. Pause at a fixed frame at least five game seconds after match start.
3. Start a fresh engine process for the same player. Check `infolog.txt` for one
   `begin` line near frame zero and one `end` line at or past the paused server
   frame. Resume the match and check that it continues without sync errors.
4. Repeat with the same starting conditions and target frame when comparing
   builds or client settings. Record the engine, game, map, target frame, wall
   time from process launch and probe time as separate measurements.

In a running match the last reported server frame can lag the live server.
Use the paused match for timing comparisons. Run the same test with an ordinary
client and a headless client to help distinguish rendering cost. Use a Tracy
capture or host/network metrics to attribute the time to specific work.

## Check the probe

From the checkout root, run `lua5.1 tools/benchmark/test_rejoin_probe.lua`.
The test uses a fake clock and progress events to exercise ordinary startup,
catch-up to a moving target, a stale progress packet, and replay exclusion.
