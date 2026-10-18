---
name: rex-performance-load
description: "Benchmark actual match throughput and failure modes instead of extrapolating room-lobby HTTP tests."
---

# rex-performance-load

## When to use
Benchmark actual match throughput and failure modes instead of extrapolating room-lobby HTTP tests.

## Workflow
1. Specify realistic mixed read/play/ack/reconnect/settle profile and size of test game state.
2. Measure p50/p95/p99, errors, CPU, memory, file descriptors, lock contention and commit latency.
3. Inject network faults and load spikes; reproduce on a documented test environment.
4. Differentiate synthetic 4096 lobby requests from concurrent online matches.
5. Never claim millions of players before real representative capacity planning.

## Checks to run when appropriate
- `cd production/server && go test ./...`

## Delivery standard
Record branch and exact SHA, reviewed files, commands actually run, failure evidence, human approvals still needed, and verdict PASS / REQUEST_CHANGES / BLOCK. Never fabricate tools, real subagents, tests or approval.
