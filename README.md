# Lumos dev toolkit

把「上下文 → 工程骨架 → 任务派发 → 真实录制 → 交付视频」这一条链路一次装齐：
五个独立插件，五个独立仓库，这里是**一键安装 + 接缝说明**。

不打包、不改它们的源码，仓库里没有一行插件代码。

## 先搞清楚一件事

这五个东西的**主体不是插件，是「CLI + 一份 SKILL.md」**。插件壳（DSH 的
`dsh.bundle`、ZCode 的 marketplace 条目）只是宿主适配层，而各宿主的适配能力并不一样：

| 宿主 | 能拿到什么 | 怎么装 |
|---|---|---|
| **DeepSeek Harness** | 原生插件，装完 skill 自动挂载 | `--mode dsh`（默认） |
| **Codex** | 5 个里 4 个带 `.codex-plugin`（`baton` 没有），可走本地 marketplace | 见下 |
| **Cursor** 等只有 rules 的宿主 | 没有插件机制，但 **CLI 照样能用** | `--mode cli` |
| 任意 shell / CI | CLI 直接可用 | `--mode cli` |

所以「一条命令装进 agent」没有通用解——插件安装是宿主私有的。能做的是：
**一条命令把命令放到 PATH、把说明书放到该放的位置**，剩下的由各宿主的读取习惯决定。

## 快速开始

不用 clone，分两种模式。

**DeepSeek Harness（原生插件）**

```bash
curl -fsSL https://raw.githubusercontent.com/Lumos-789/Lumos-dev-toolkit/main/install.sh | bash
```

**Cursor / 其它宿主（便携 CLI）**

```bash
curl -fsSL https://raw.githubusercontent.com/Lumos-789/Lumos-dev-toolkit/main/install.sh | bash -s -- --mode cli
```

它做三件事：把五个仓库取到 `~/.local/share/lumos-dev-toolkit`、把 `guster` /
`galadon` / `baton` 链接进 `~/.local/bin`、把六份 skill 链接进 `~/.agents/skills`。

**两种都要**

```bash
curl -fsSL https://raw.githubusercontent.com/Lumos-789/Lumos-dev-toolkit/main/install.sh | bash -s -- --mode all
```

**先看再装**（不写任何东西，也不需要 dsh）

```bash
curl -fsSL https://raw.githubusercontent.com/Lumos-789/Lumos-dev-toolkit/main/install.sh | bash -s -- --dry-run
curl -fsSL https://raw.githubusercontent.com/Lumos-789/Lumos-dev-toolkit/main/install.sh | bash -s -- --list
```

**只装其中几个**

```bash
curl -fsSL https://raw.githubusercontent.com/Lumos-789/Lumos-dev-toolkit/main/install.sh | bash -s -- --mode cli --only guster,malo-browser
```

找不到 `dsh` 时脚本直接停下，打印完整命令并告诉你改走 `--mode cli`，不会假装成功。

> 可覆盖的路径：`LUMOS_HOME`（源）、`BIN_DIR`（命令）、`SKILLS_DIR`（技能）。
> 想改脚本或习惯先读一遍：`git clone` 后 `./install.sh`，行为完全一致。
> 更新：`git -C ~/.local/share/lumos-dev-toolkit/<name> pull`，skill 链接会跟着变。

## Cursor 里怎么让它真的用上

CLI 进了 PATH 不等于 agent 会调用。Cursor 只读项目内的规则文件，所以在那类宿主里
把这一句放进 `.cursor/rules`（或项目 `AGENTS.md`）即可：

```text
需要上下文治理 / 工程循环 / 任务派发 / 演示录制 / 交付视频时，
先读 ~/.agents/skills/<name>/SKILL.md，按里面的命令执行。
```

DSH 和 Codex 读 `~/.agents/skills`，不需要这句。

## 五个插件

| 插件 | 干什么 | 什么时候用 |
|---|---|---|
| `guster` | 全机 agent 上下文的控制面：发现/诊断/打分 `.agents`、AGENTS.md、skills、knowledge、凭据引用 | 接手新机器、上下文乱了、想知道哪里在漂 |
| `galadon` | 单工程的五阶段循环 `Spec → Build → Verify → Ship → Learn`，含生成器、部署闸、探针、回滚 | 起一个新工程、要把一个工程从骨架推到上线 |
| `baton` | OpenSpec change 的执行控制面：ticket/DAG、子代理派发、sealed receipt 校验、worktree 隔离 | 一个已批准的 change 要拆成并发任务干完 |
| `malo-browser` | Electron + Chromium 的脚本化 demo 运行时：场景脚本、隐藏录制、1080p30、证据文件 | 需要没人盯着也能录出干净、可复现的操作视频 |
| `delivery-video` | 真实录制 + TTS + 字幕 + 确定性质量闸，出交付/验收视频 | 要把「确实能跑」的功能录成给客户看的片子 |

## 它们怎么串成一条链

```text
        guster                      ← 上下文对不对
          |
        galadon  Spec → Build      ← 工程骨架与规范
          |
        baton   change → 并发执行   ← 任务拆解与派发
          |
        galadon  Verify → Ship     ← 验证、部署、回滚
          |
        malo-browser  真实录制      ← 在真浏览器里跑一遍并留证
          |
        delivery-video  交付视频    ← 质量闸通过的成片
```

`guster` 是横跨所有工程的元层，其余四个工作在单个工程的生命周期里。
`malo-browser` 和 `delivery-video` 是整条链末端的两级：前者负责「录出可信的原始
素材」，后者负责「把它剪成过闸的成片」。

## 装完先看这一页

两处**开箱不能直接对接**的地方写在 [docs/seams.md](docs/seams.md)：

1. `malo-browser` 的 evidence 文件和 `delivery-video` 的 `demo-stage-recording`
   契约差两个字段，直接喂会被 preflight 拒。仓库里的 `compat/malo_to_dv.py` 负责转。
2. `guster` 和 `galadon` 都会生成同一套 `.agents/` 六槽位，重复执行会互相覆盖。

另外三个插件之间是松耦合：`galadon` 的 `spec/` 到 `baton` 的 OpenSpec change
中间没有自动转换器，需要 agent 手动做一步。

## 运行前提

| 插件 | 需要 |
|---|---|
| `guster` | Python 3.9+，无第三方依赖 |
| `galadon` | Python 3.10+，`PyYAML` |
| `baton` | Python 3.10+，OpenSpec；`--mode dsh` 还要 DSH 0.2.1-rc.2+（`subagent` 工具） |
| `malo-browser` | Node 22.12+ / 24 / 26+，`ffmpeg`+`ffprobe`，macOS（已验证路径） |
| `delivery-video` | Python 3.9+，`ffmpeg`+`ffprobe`，`pip install "edge-tts>=7.3.1" Pillow`，中文字体 |

缺依赖时这些工具大多会自己 fail-loud 报出来，不会静默降级。

## 目录

```text
install.sh             一键装（--mode dsh|cli|all / --dry-run / --only / --dsh / --list）
VERSIONS.md            这次组合对应的版本与提交，以及哪些验证过、哪些没有
docs/seams.md          两处接缝和三个松耦合点
compat/malo_to_dv.py   把 malo evidence 转成 delivery-video 认的格式
compat/test_malo_to_dv.py  转换器的测试（含真实契约校验）
compat/fixtures/       malo evidence 样例
```

跑转换器的测试：

```bash
python3 compat/test_malo_to_dv.py -v

# 连真实 delivery-video 契约一起验（指到它的 scripts 目录）
DELIVERY_VIDEO_SCRIPTS=/path/to/delivery-video-plugin/skills/delivery-video/scripts \
  python3 compat/test_malo_to_dv.py -v
```

## 状态

- 五个插件都是各自仓库的当前 `main`，提交见 [VERSIONS.md](VERSIONS.md)。
- **`--mode cli` 在临时 HOME 里真跑过**：五个源到位、`guster`/`galadon`/`baton`
  三个命令可执行、六份 skill 链接可解析、重跑幂等。
- **未验证**：`dsh plugin add` 在干净机器上的真实安装；Codex 本地 marketplace 的
  安装步骤；Cursor 是否按上面的规则正确调用 CLI。

## License

MIT，见 [LICENSE](LICENSE)。
