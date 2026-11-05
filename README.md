# Lumos dev toolkit

Five independent plugins covering one workflow: context, scaffolding, dispatch, recording, delivery.

| Plugin | Focus | What it does |
|---|---|---|
| **guster** | Context&nbsp;audit | Scans every project for stale, unread or duplicated context, then scores whether an agent would load it. |
| **galadon** | Project&nbsp;lifecycle | Runs five phases, one artifact and one gate each. Deploys, probes, rolls back on failure. |
| **baton** | Task&nbsp;dispatch | Turns one change into a ticket DAG for parallel subagents. Only a hash-bound receipt closes a task. |
| **malo-browser** | Demo&nbsp;recording | Records a scripted demo headlessly at 1080p30 without taking the window. Each take is bound to its script. |
| **delivery-video** | Delivery&nbsp;video | Turns a real recording into a narrated, subtitled video. Refuses to ship unless the quality gate passes. |

## Install

```bash
# DeepSeek Harness
curl -fsSL https://raw.githubusercontent.com/Lumos-789/Lumos-dev-toolkit/main/install.sh | bash

# any host without a plugin system (Cursor and similar): CLIs on PATH, skills linked
curl -fsSL https://raw.githubusercontent.com/Lumos-789/Lumos-dev-toolkit/main/install.sh | bash -s -- --mode cli
```
