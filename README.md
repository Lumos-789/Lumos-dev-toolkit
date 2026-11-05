# Lumos dev toolkit

一套自己用的 DeepSeek Harness 插件组合：把「上下文 → 工程骨架 → 任务派发 →
真实环境录制 → 交付视频」这一条链路一次装齐。

不是官方市场包，只放在这里给自己人用。五个插件各自独立、各自有仓库，这里只做
**一键安装 + 接缝说明**，不打包、不改它们的源码。

## 快速开始

```bash
git clone https://github.com/Lumos-789/Lumos-dev-toolkit.git
cd Lumos-dev-toolkit
./install.sh
```

先看会装什么、不实际安装：

```bash
./install.sh --dry-run
```

只装其中几个：

```bash
./install.sh --only guster,malo-browser
```

脚本会依次执行 `dsh plugin add <来源>`。找不到 `dsh` 时它直接停下并打印完整命令，
不会假装成功。装完在 DSH 里用 `dsh plugin list` 或直接让 agent 加载对应技能名确认。

> `dsh` 不在 PATH 上时：`./install.sh --dsh /path/to/dsh` 或
> `DSH_BIN=/path/to/dsh ./install.sh`。

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
| `baton` | Python 3.10+，DSH 0.2.1-rc.2+（要 `subagent` 工具） |
| `malo-browser` | Node 22.12+ / 24 / 26+，`ffmpeg`+`ffprobe`，macOS（已验证路径） |
| `delivery-video` | Python 3.9+，`ffmpeg`+`ffprobe`，`pip install "edge-tts>=7.3.1" Pillow`，中文字体 |

缺依赖时这些工具大多会自己 fail-loud 报出来，不会静默降级。

## 目录

```text
install.sh             一键装五个（--dry-run / --only / --dsh / --list）
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
- 未做端到端联调：没有在干净机器上真跑过 `dsh plugin add`，也没有五个同时在
  一个 DSH 会话里跑过。首次安装若失败，按脚本打印的命令手工重试并回报。

## License

MIT，见 [LICENSE](LICENSE)。
