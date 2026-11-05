# Lumos dev toolkit

Five independent plugins, installed together.

- **guster** — context management. Audits and evolves agent context across a machine: instruction files, skills, knowledge, credentials, project state.
- **galadon** — project framework. A five-stage engineering loop (spec, build, verify, ship, learn) with a layout/stack scaffold generator and a deploy port.
- **baton** — task dispatch. A ticket/DAG control plane that turns an OpenSpec change into parallel subagent work and only accepts sealed receipts.
- **malo-browser** — browser and recording. A scripted demo runtime on Electron + Chromium: headless capture, 1080p30, evidence files, port leases for concurrent agents.
- **delivery-video** — delivery video. Real recordings plus narration, word-synced subtitles and a deterministic quality gate that refuses a fake or broken demo.

## Install

```bash
# DeepSeek Harness
curl -fsSL https://raw.githubusercontent.com/Lumos-789/Lumos-dev-toolkit/main/install.sh | bash

# any host without a plugin system (Cursor and similar): CLIs on PATH, skills linked
curl -fsSL https://raw.githubusercontent.com/Lumos-789/Lumos-dev-toolkit/main/install.sh | bash -s -- --mode cli
```
