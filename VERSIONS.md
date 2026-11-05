# Versions

This toolkit was assembled on **2026-11-05** from the `main` branch of each
repository. Only `malo-browser` has a version tag upstream; the other four do
not, so `install.sh` installs their default branch and this file records the
commit that was current when the set was put together.

| Plugin | Version | Commit | Installed from |
|---|---|---|---|
| `guster` | 0.6.1 | `a6ee57a` | `https://github.com/Lumos-789/guster` (main) |
| `galadon` | 0.3.3 | `0d49ecc` | `https://github.com/Lumos-789/galadon` (main) |
| `baton` | 0.3.2 | `6190d61` | `https://github.com/Lumos-789/baton` (main) |
| `malo-browser` | 0.1.6 | `1a53964` | release tarball `v0.1.6` |
| `delivery-video` | 1.1.2 | `1a32ddd` | `https://github.com/Lumos-789/delivery-video-plugin` (main) |

## Why malo-browser uses a tarball

Its `out/` directory is gitignored and produced by `npm run build`. A source
install leaves `index.js` pointing at `out/main/index.js`, which does not exist,
so the plugin fails to load. The `v0.1.6` release tarball ships `out/` prebuilt.
Do not switch it to a source install unless you also run the build.

## What has been verified

- `compat/malo_to_dv.py` converts a real malo evidence file into something
  `delivery-video`'s `preflight.check_demo_stage_evidence` accepts
  (11 tests, including the real contract check).
- `install.sh` emits the right five commands, stops at the first failure, and
  refuses to run without a `dsh` binary (tested with a stub CLI).

## What has not been verified

- A real `dsh plugin add` against these URLs on a clean machine. The command
  form comes from each plugin's own README; the URLs and the malo tarball were
  checked over HTTP, but the install itself was not executed here.
- The five plugins running together in one DSH session.

If you hit a problem, open an issue on the repo you installed from and note
which plugin and which of the above two items it falls under.
