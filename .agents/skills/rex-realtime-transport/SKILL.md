---
name: rex-realtime-transport
description: "Engineer reliable per-seat event delivery, ack, resume, order and backpressure."
---

# rex-realtime-transport

## When to use
Engineer reliable per-seat event delivery, ack, resume, order and backpressure.

## Workflow
1. Separate lobby polling from real match networking; gather approved transport constraints.
2. Design authenticated event envelope, version, action ID, ack/resume cursor and reconnect snapshot.
3. Simulate delay, duplication, loss, reordering, slow clients and server restarts.
4. Keep hidden cards scoped to seat, never broadcast internal state; verify error cases.
5. Propose D2 transport choice with measurable tradeoffs for Abdulaziz.

## Checks to run when appropriate
- `cd production/server && go test -race ./internal/api/...`

## Delivery standard
Record branch and exact SHA, reviewed files, commands actually run, failure evidence, human approvals still needed, and verdict PASS / REQUEST_CHANGES / BLOCK. Never fabricate tools, real subagents, tests or approval.
