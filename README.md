# Lumos dev toolkit

Five independent plugins covering one loop — from knowing your context to shipping the proof.

- **guster** — *the map.* Walks every project on the machine, reads the instruction files, skills, knowledge and credential pointers, then names the ones that have gone stale, unread or duplicated. Scores how much context an agent would actually load.
- **galadon** — *the rails.* Five phases — spec, build, verify, ship, learn — one artifact and one gate each, so the agent never has to guess the next action. Scaffolds a project's internal layering, and its deploy port ships, probes and rolls back on its own.
- **baton** — *the conductor.* Turns one approved change into a DAG of tickets and hands them to parallel subagents in isolated worktrees. A task counts as done only when a hash-bound receipt proves its verification ran green; "it works" in prose is ignored.
- **malo-browser** — *the stage.* A real Chromium that runs a scripted demo headlessly and records it at 1080p30 without ever stealing the window. Each take gets an evidence file binding the video to the script that produced it, and several agents can drive it at once on leased ports.
- **delivery-video** — *the proof.* Turns a recording that actually ran into a narrated, subtitled delivery video, then refuses to hand it over unless it clears hard checks on resolution, frame rate, audio, loudness, black frames and freeze frames. The file you get is the file the gate passed, bound by hash.

## Install

```bash
# DeepSeek Harness
curl -fsSL https://raw.githubusercontent.com/Lumos-789/Lumos-dev-toolkit/main/install.sh | bash

# any host without a plugin system (Cursor and similar): CLIs on PATH, skills linked
curl -fsSL https://raw.githubusercontent.com/Lumos-789/Lumos-dev-toolkit/main/install.sh | bash -s -- --mode cli
```
