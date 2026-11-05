# Lumos dev toolkit

Five independent plugins covering one workflow: context, scaffolding, dispatch, recording, delivery.

| Plugin | Focus | What it does |
|---|---|---|
| **guster** | Context audit | Scans every project for stale, unread or duplicated context. Scores whether an agent would actually load it. |
| **galadon** | Project lifecycle | Drives a project through five phases, one artifact and one gate each. Deploys, probes, and rolls back on failure. |
| **baton** | Task dispatch | Turns one approved change into a ticket DAG for parallel subagents. A task counts as done only with a hash-bound receipt. |
| **malo-browser** | Demo recording | Records a scripted demo in headless Chromium at 1080p30 without taking the window. Each take is bound to its script by evidence. |
| **delivery-video** | Delivery video | Turns a real recording into a narrated, subtitled video. Refuses to ship unless it clears the hard quality gate. |

## Install

```bash
# DeepSeek Harness
curl -fsSL https://raw.githubusercontent.com/Lumos-789/Lumos-dev-toolkit/main/install.sh | bash

# any host without a plugin system (Cursor and similar): CLIs on PATH, skills linked
curl -fsSL https://raw.githubusercontent.com/Lumos-789/Lumos-dev-toolkit/main/install.sh | bash -s -- --mode cli
```
