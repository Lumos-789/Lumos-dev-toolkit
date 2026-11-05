# 接缝

五个插件各自独立、互不 import，装在一起不会自动互相认识。有**两处**它们会碰到
同一份数据或同一个目录，直接混用会出错；另外几处只是「能串，但中间那一步没人做」。
这篇把每处的现象、后果和做法写清楚。

---

## 1. malo-browser 的 evidence 喂不进 delivery-video

两个项目对同一种产物用了**同一个名字** `demo-stage-recording`，但结构不同：

| 字段 | malo-browser 写的 | delivery-video 要的 |
|---|---|---|
| 自检 | `checks` 是 dict：`{"node_isolated": {"passed": true, "detail": "..."}}` | `checks` 是 **list**：`[{"id": "node_isolated", "passed": true}]` |
| 无头 | `run.headless: true` | `capture.headless: true`（必须为 true） |
| 其余 | `kind`、`status`、`capture.window_visible`、`video.{sha256,fps,frames,duration_s}` | 一致 |

**后果**：把 malo 录出来的 `xxx.evidence.json` + `xxx.mp4` 直接写进
`delivery-video` 的 episode（`source: "demo-stage"`），`preflight.py` 会直接拒：

```text
FAIL: xxx: demo-stage evidence has no self-checks
FAIL: xxx: demo-stage recording must be headless (capture.headless=true)
```

**做法**：过一层 `compat/malo_to_dv.py`。

```bash
python3 compat/malo_to_dv.py <malo 的 evidence.json> <take-01.mp4>
# 默认输出 <take-01>.evidence.json，与 mp4 同名同目录，正好是 preflight 找的位置
```

转换器会**重算** sha256 和 duration（而不是复制旧值），所以拿错 take 会当场报错，
不会把证据悄悄绑到另一段视频上。

**为什么不直接改两个仓库**：两者都是独立发布物，改任一边都会影响另一边已装的
用户。转一层最便宜，也不妨碍以后两边各自修好（malo 把 `checks` 写成 list 并把
`headless` 复制进 `capture`，或 delivery-video 兼容 dict 和 `run.headless`）。

---

## 2. guster 和 galadon 都会生成 `.agents/`

两边的目标布局其实是**同一组六个槽位**，只是顺序不同：

| | 槽位 |
|---|---|
| `guster` | `plans, wiki, evidence, skills, tmp, archive` |
| `galadon` | `plans, evidence, archive, skills, tmp, wiki` |

问题不在布局，在**重复执行**：两边都会写 `.agents/README.md`，`guster` 还会在
`AGENTS.md` 不存在时创建一个。先后各跑一遍，说明文字会互相覆盖；如果后跑的版本
措辞不同，你会得到一份「看起来被改过」的索引。

**建议的分工**：

- 新工程用 `galadon init --layout ...` 一次建好——它同时生成 `spec/`、
  `openspec/` 等，不只是 `.agents/`
- 之后用 `guster scan` / `guster doctor` **只读审计**，不要在新工程上再跑
  `guster plan init --yes`
- 只有「已有工程缺 `.agents/`」时才用 guster 的 init 去补

---

## 3. galadon 的 `spec/` 到 baton 的 change 没有转换器

`galadon` 的 `spec/` 是单工程的真值层（`INDEX.md`、`domains/`、`TESTING.md`、
`CONSTITUTION.md`）；`baton` 吃的是 OpenSpec change（`proposal → tasks`）。
中间这一跳目前靠 agent 手工：

1. 从 `spec/` 里挑出一个功能点
2. 按 OpenSpec 写成 change
3. `baton` 才能把它拆成 ticket 派发

没有工具做这个转换，也不打算做——两者服务于不同粒度（工程级真值 vs 变更级执行）。

---

## 4. 三处松耦合（不报错，但要知道）

- **baton** 依赖 DSH 的 `subagent` 工具，以及本机已装 OpenSpec（`openspec` 在
  npm 全局里）。缺任一个，`actions` 能算出来但派不出去。
- **galadon** 的 deploy 端口默认 `local` / `ssh`。`ssh` 需要目标机可连，并且
  它会真的改远端目录、写 systemd unit / Caddy 配置。
- **delivery-video** 的旁白走 edge-tts 公网端点。内网或断网环境下渲染会失败，
  这不是 bug，是设计上不做的离线降级。

---

## 附：装完自检

```bash
# 1) 五个插件都装上了
dsh plugin list

# 2) malo 的 evidence 能过 delivery-video 的闸（需要本机有 ffmpeg 和一个 malo take）
DELIVERY_VIDEO_SCRIPTS=<delivery-video>/skills/delivery-video/scripts \
  python3 compat/test_malo_to_dv.py -v

# 3) 上下文没被两个 init 打架
guster scan && guster doctor
```
