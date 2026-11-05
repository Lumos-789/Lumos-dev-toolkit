# Lumos dev toolkit

Five independent plugins covering one workflow: context, project scaffolding, task dispatch, demo recording and delivery video.

- **guster** — Context audit. It scans every project on a machine and reports which instruction files, skills, knowledge and credential pointers are stale, unread or duplicated. It scores the result, so you can tell whether an agent would actually load the context you wrote.
- **galadon** — Project lifecycle. It runs a project through five phases (spec, build, verify, ship, learn), one artifact and one gate per phase, so the next action is never ambiguous. Its deploy port ships, probes the running service and rolls back when the probe fails.
- **baton** — Task dispatch. It turns one approved OpenSpec change into a DAG of tickets and dispatches them to parallel subagents in isolated worktrees. A task is complete only when a hash-bound receipt shows its verification passed.
- **malo-browser** — Demo recording. It drives a real Chromium through a scripted demo headlessly and records at 1080p30 without taking the window. Each take gets an evidence file binding the video to the script that produced it, and several agents can run separate sessions through port leases.
- **delivery-video** — Delivery video. It turns a real recording into a narrated, subtitled video and runs a hard quality gate on resolution, frame rate, audio, loudness, black frames and freeze frames. The file it hands over is the gated file, bound by hash.

## Install

```bash
# DeepSeek Harness
curl -fsSL https://raw.githubusercontent.com/Lumos-789/Lumos-dev-toolkit/main/install.sh | bash

# any host without a plugin system (Cursor and similar): CLIs on PATH, skills linked
curl -fsSL https://raw.githubusercontent.com/Lumos-789/Lumos-dev-toolkit/main/install.sh | bash -s -- --mode cli
```
